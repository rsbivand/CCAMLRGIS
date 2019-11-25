
<!-- README.md is generated from README.Rmd. Please edit that file -->

# CCAMLRGIS R package

The CCAMLRGIS package was developed to simplify the production of maps
in the CCAMLR Convention Area. It provides two categories of functions:
load functions and create functions. Load functions are used to import
spatial layers from the online CCAMLR GIS (<https://gis.ccamlr.org/>)
such as the ASD boundaries. Create functions are used to create layers
from user data such as polygons and grids.

## Installation

You can install CCAMLRGIS from github with:

``` r
#First install devtools:
install.packages("devtools")
#rlang is also needed:
install.packages("rlang")
#Then install the package:
devtools::install_github("ccamlr/CCAMLRGIS",build_vignettes=TRUE)
```

Or from CRAN with:

``` r
install.packages("CCAMLRGIS")
```
