# Title     : SpatInteModel.R
# Objective : Build a spatial interaction model to analyse the high streets population patterns in UK
# Created by: azanchetta
# Created on: 19/08/2021

# Using as reference the instructions for R that one can find here:
# https://rpubs.com/adam_dennett/257231
# https://rpubs.com/adam_dennett/259068


# *Load libraries ----
#  Necessary packages, install if needed
# install.packages(c("sp", "MASS", "reshape2","geojsonio","rgdal","downloader","maptools","dplyr","broom"
#                    ,"stplanr", "ggplot2", "leaflet"))

#  From source:
library(tidyverse)
library(sp)
library(MASS)
library(reshape2)
# library(geojsonio) # not managing to install it
library(rgdal)
library(downloader)
library(maptools)
library(broom) 
library(stplanr)
library(leaflet)
library(sf)
library(tmap)

#  From previous scripts:
# library(dplyr) # for R piping and more cool stuff
# library(readxl) # for handling Excel spreasheets
# 
# library(foreign) # for handling databases (dbf)
# # for handling geospatial data
# library(sf)
# library(maps) # actually used?
# library(mapdata)
# library(maptools)
# library(rgdal)
# library(ggmap)
# library(rgeos)
# library(broom)  # function tidy for shapefile
# library(ggplot2) # graphs
# library(plyr)
# library(tidyverse)
# library(tidyr)
# library(reshape2) # to change long/wide format in database
# library(GGally) # to make nice scatter plots
# library(cluster) # for cluster analysis

### *Data import* ----
# A. Paths definition ----
# getwd()
# list.files(getwd())
data_path <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/projects/FutureHighStreets/data/Leeds_data/"

# B. Variables definition ----
origin_data_name <- ""
destination_data_name <- ""

cdata <- read.csv("https://www.dropbox.com/s/7c1fi1txbvhdqby/LondonCommuting2001.csv?raw=1")
