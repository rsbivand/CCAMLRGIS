% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/load.R
\name{load_RefAreas}
\alias{load_RefAreas}
\title{Load CCAMLR Reference Areas}
\usage{
load_RefAreas(p4s = "+proj=laea +lat_0=-90 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs")
}
\arguments{
  \item{p4s}{Coordinate reference system in proj4string representation.}
}
\description{
Download the up-to-date spatial layer from the \href{http://gis.ccamlr.org/}{online CCAMLRGIS} and load it to your environment.
The layer's Metadata is accessible by clicking on the red 'i' in the list of layers available on the \href{http://gis.ccamlr.org/}{online CCAMLRGIS}.
See examples for offline use.
}
\examples{
 
\donttest{

#When online:
RefAreas=load_RefAreas()
plot(RefAreas)

#If going offline in the future: load and save as RData when online,
# then reload RData when offline:
RefAreas=load_RefAreas()
EEZs=load_EEZs()
save(list=c('RefAreas','EEZs'), file = file.path(tempdir(), "CCAMLRLayers.RData"))
rm(RefAreas,EEZs)
load(file.path(tempdir(), "CCAMLRLayers.RData"))

}

}
\seealso{
\code{\link{load_ASDs}}, \code{\link{load_SSRUs}}, \code{\link{load_RBs}},
\code{\link{load_SSMUs}}, \code{\link{load_MAs}}, \code{\link{load_Coastline}},
\code{\link{load_MPAs}}, \code{\link{load_EEZs}}.
}
