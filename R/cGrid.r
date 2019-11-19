#cGrid: CCAMLRGIS internal function to create SpatialPolygonsDataFrame grids
cGrid=function(Input,dlon=NA,dlat=NA,Area=NA,cuts=100,cols=c('green','yellow','red')){
require(sp)
require(rgdal)
require(geosphere)
require(rgeos)
require(dplyr)
      
if(is.na(sum(c(dlon,dlat,Area)))==F){
  stop('Values should not be specified for dlon/dlat and Area.')
}  
if(all(is.na(c(dlon,dlat,Area)))){
    stop('Values should be specified for either dlon/dlat or Area.')
}  
  
  data=Input
  colnames(data)[1:2]=c("lat","lon")
  
if(is.na(Area)==T){
  #Prepare Lat/Lon grid
  data$lon=(ceiling((data$lon+dlon)/dlon)*dlon-dlon)-dlon/2
  data$lat=(ceiling((data$lat+dlat)/dlat)*dlat-dlat)-dlat/2
  
  Glon=data$lon
  Glat=data$lat
  
  tmp=distinct(data.frame(Glon,Glat))
  GLONS=tmp$Glon
  GLATS=tmp$Glat
  
  #Loop over cells to generate SpatialPolygon
  Pl=list()
  for (i in (1:length(GLONS))){ #Loop over polygons
    xmin=GLONS[i]-dlon/2
    xmax=GLONS[i]+dlon/2
    ymin=GLATS[i]-dlat/2
    ymax=GLATS[i]+dlat/2
    if(dlon<=0.1){ #don't fortify
      lons=c(xmin,xmax,xmax,xmin)
      lats=c(ymax,ymax,ymin,ymin)
    }else{ #do fortify
      lons=c(xmin,seq(xmin,xmax,by=0.1),xmax)
      lons=unique(lons)
      lats=c(rep(ymax,length(lons)),rep(ymin,length(lons)))
      lons=c(lons,rev(lons))
    }
    
    Pl[[i]]=Polygons(list(Polygon(cbind(lons,lats),hole=F)),as.character(i))
  }
  Group=SpatialPolygons(Pl, proj4string=CRS("+proj=longlat +ellps=WGS84"))
  #project
  Group=spTransform(Group,CRS(CCAMLRp))
  #Get area
  tmp=gArea(Group, byid=T)
  tmp=data.frame(ID=names(tmp),AreaKm2=tmp*1e-6)
  Group=SpatialPolygonsDataFrame(Group,tmp)
  
}else{
  #Equal-area grid
  Area=Area*1e6  #Convert area to sq m
  s=sqrt(Area)   #first rough estimate of length of cell side
  PolyIndx=1     #Index of polygon (cell)
  Group = list() #Initialize storage of cells
  
  StartP=SpatialPoints(cbind(0,ceiling(max(data$lat))),CRS("+proj=longlat +ellps=WGS84"))
  LatS=0
  
  while(LatS>min(data$lat)){
    
    #Compute circumference at Northern latitude of cells
    NLine=SpatialLines(list(Lines(Line(cbind(seq(-180,180,length.out=10000),
                                             rep(coordinates(StartP)[,2],10000))),'N')),CRS("+proj=longlat"))
    NLine=spTransform(NLine,CCAMLRp)
    L=SpatialLinesLengths(NLine)
    #Compute number of cells
    N=floor(L/s)
    lx=L/N
    ly=Area/lx
    #Prepare cell boundaries
    Lons=seq(-180,180,length.out=N)
    LatN=as.numeric(coordinates(StartP)[1,2])
    LatS=as.numeric(destPoint(cbind(Lons[1],LatN), 180, d=ly)[,2])
    #Refine LatS
    lons=unique(c(Lons[1],seq(Lons[1],Lons[2],by=0.1),Lons[2]))
    PLon=c(lons,rev(lons),lons[1])
    PLat=c(rep(LatN,length(lons)),rep(LatS,length(lons)),LatN)
    PRO = project(cbind(PLon, PLat), CCAMLRp)
    Pl = Polygon(cbind(PRO[, 1], PRO[, 2]))
    
    Res=10/10^(0:15)
    while(Area>Pl@area & length(Res)!=0){
      LatSBase=LatS
      LatS=LatS-Res[1]
      if(LatS<(-90)){
        cat('____________________________________________________________________________','\n')
        cat('Southern-most grid cells should not extend below -90deg to maintain equal-area','\n')
        cat('Reduce desired area of cells to avoid this issue','\n')
        cat('____________________________________________________________________________','\n')
        LatS=-90
        break}
      PLat=c(rep(LatN,length(lons)),rep(LatS,length(lons)),LatN)
      PRO = project(cbind(PLon, PLat), CCAMLRp)
      Pl = Polygon(cbind(PRO[, 1], PRO[, 2]))
      if(Area<Pl@area){
        LatS=LatSBase
        PLat=c(rep(LatN,length(lons)),rep(LatS,length(lons)),LatN)
        PRO = project(cbind(PLon, PLat), CCAMLRp)
        Pl = Polygon(cbind(PRO[, 1], PRO[, 2]))
        Res=Res[-1]
      }
    }
    
    #Build polygons at a given longitude
    for (i in seq(1,length(Lons)-1)) {
      lons=unique(c(Lons[i],seq(Lons[i],Lons[i+1],by=0.1),Lons[i+1]))
      PLon=c(lons,rev(lons),lons[1])
      PLat=c(rep(LatN,length(lons)),rep(LatS,length(lons)),LatN)
      PRO = project(cbind(PLon, PLat), CCAMLRp)
      Pl = Polygon(cbind(PRO[, 1], PRO[, 2]))
      Pls = Polygons(list(Pl), ID = PolyIndx)
      Group[[PolyIndx]] = Pls
      PolyIndx=PolyIndx+1
    }
    
    rm(NLine,Pl,Pls,PRO,StartP,i,L,LatSBase,Lons,lons,lx,ly,N,PLat,PLon,Res)
    
    StartP=SpatialPoints(cbind(0,LatS),CRS("+proj=longlat"))
  }
  
  Group = SpatialPolygons(Group)
  proj4string(Group) = CRS(CCAMLRp)
  tmp=gArea(Group, byid=T)
  tmp=data.frame(ID=names(tmp),AreaKm2=tmp*1e-6)
  Group=SpatialPolygonsDataFrame(Group,tmp)
  rm(tmp)
  
}

  #Add cell labels centers
  #Get labels locations
  labs=coordinates(gCentroid(Group,byid=T))
  Group$Labx=labs[match(Group$ID,row.names(labs)),'x']
  Group$Laby=labs[match(Group$ID,row.names(labs)),'y']
  
  #Match data to grid cells
  tmp=over(SpatialPoints(project(cbind(data$lon,data$lat),CCAMLRp),CRS(CCAMLRp)),Group)
  data$ID=as.character(tmp$ID)
  rm(tmp)
  Group=Group[Group$ID%in%unique(data$ID),]
  #Summarise data
  data=as.data.frame(data[,-c(1,2)])
  nums = which(unlist(lapply(data, is.numeric))==T)
  if(length(nums)>0){
    data=data[,c(which(colnames(data)=='ID'),nums)]
    Sdata=data%>%
      group_by(ID)%>%
      summarise_all(list(min=~min(.,na.rm=T),
                         max=~max(.,na.rm=TRUE),
                         mean=~mean(.,na.rm=TRUE),
                         sum=~sum(.,na.rm=TRUE),
                         count=~length(.),
                         sd=~sd(.,na.rm=TRUE),
                         median=~median(.,na.rm=TRUE)))
    Sdata=as.data.frame(Sdata)}else{Sdata=data.frame(ID=as.character(unique(data$ID)))}
  #Merge data to Polygons
  row.names(Sdata)=Sdata$ID
  Group=SpatialPolygonsDataFrame(Group,Sdata)
  
  #Add colors
  for(i in which(unlist(lapply(Group@data, class))%in%c("integer","numeric"))){
    coldata=Group@data[,i]
    if(all(is.na(coldata))){
      Group@data[,paste0('Col_',colnames(Group@data)[i])]=NA
    }else{
      tmp=add_col(var=coldata,cuts=cuts,cols=cols)
      Group@data[,paste0('Col_',colnames(Group@data)[i])]=tmp$varcol
    }
  }
  
return(Group)
}