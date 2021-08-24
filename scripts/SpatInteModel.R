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
library(plyr)
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
library(raster)

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
# data_path <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/projects/FutureHighStreets/data/Leeds_data"
data_path <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/Data/FutureCityCentres/Leeds"

# B. Variables definition ----
origin_data_filename <- "LSOAS_pop-weighted-centroids_with-students_Leeds"
destination_data_filename <- "retail-centres_centroids_Leeds"
# --
origin_csv <- read.csv(file.path(data_path,
                                 paste(origin_data_filename,".csv", sep='')))
destination_csv <- read.csv(file.path(data_path,
                                     paste(destination_data_filename,".csv", sep='')))
# --
origin_shp <- readOGR(dsn = data_path,
                      layer = origin_data_filename)
summary(origin_shp)
crs(origin_shp) <- "+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +units=m +no_defs"
destination_shp <- readOGR(dsn = data_path,
                           layer = destination_data_filename)
summary(destination_shp)

# cdata <- read.csv("https://www.dropbox.com/s/7c1fi1txbvhdqby/LondonCommuting2001.csv?raw=1")
# --
beta <- 0.34 # https://eprints.whiterose.ac.uk/134554/1/Wadington%20et%20al_Accounting%20for%20Temporal%20Demand.pdf
#--
attractiveness <- as.integer(destination_shp@data$Rank)
# --
students_per_lsoa <- as.integer(origin_shp@data$STUD_TOT)

# *Calculations* ----
# A. Generate necessary variables ----

# Distance matrix:
origin_coords <- origin_shp@data[,c("X_COORD", "Y_COORD")]
destination_coords <- destination_shp@data[,c("x_coord","y_coord")]
# distance_matrix <- "" # sqrt[(xi - xj)^2 + (yi - yj)^2]/1000 .... find automatic way in R?

dist_matrix <- round(pointDistance(origin_coords,
              destination_coords,
              lonlat = F) # with EPSG:27700 we don't have lat lon
              / 1000, #(to convert to km)
              1) # rounding to 1 decimal place

# Balance factor array:
# formula: balf = 1/ sum[attractiveness * exp(-beta * dist))]
expon <- exp(-beta * dist_matrix) # exp(-beta * dist)
balancefactor_array <- 1/ (expon %*% attractiveness)

# checking results!!
# expon[1,]
# cc <- expon[1,]*attractiveness
# dd <- expon[1,1]*attractiveness[1]
# ee <- expon[1,4]*attractiveness[4]
# sum(cc)
# 
# expon[13,]
# cccc <- expon[13,]*attractiveness
# dddd <- expon[13,1]*attractiveness[1]
# eeed <- expon[13,4]*attractiveness[4]
# sum(cccc)

# B. Flows matrix ----
# flows_matrix = students * attractiveness * balf * exp(-beta * dist)
# start <- students_per_lsoa %*%attractiveness  # doesn't work
# ttrying to generate a df or matrix that has repeated rows, to multiply them for the same column n-times
# try <- matrix(attractiveness,
#               nrow = length(students_per_lsoa),
#               ncol = length(attractiveness))
# try2 <- apply(try,1, function(x) x*attractiveness)
try <- data.frame(matrix(NA, nrow = 1, ncol = length(attractiveness)))
try[1,] <- attractiveness # dataframe with as row the attractiveness
nrows <- length(students_per_lsoa)
try2 <- try[rep(seq_len(nrow(try)), each = nrows), ] # dataframe with the attractiveness road repeated n*stud times

try3 <- adply(try2, 1, function(x) x * students_per_lsoa) # function from package plyr  # # actual multiplication
product <- try3

try4 <- product * expon
flows_matrix <- try4 * balancefactor_array
summary(flows_matrix)
colnames(flows_matrix) <- destination_shp@data$RC_ID
rownames(flows_matrix) <- origin_shp@data$LSOA11CD
flows_matrix <- format(flows_matrix, digits = 2)
# C. Plots?? ----
for_long_format <- flows_matrix
for_long_format$lsoa_id <- origin_shp@data$LSOA11CD
dist_pair <- melt(for_long_format)
dist_pair <- melt(for_long_format,
                  id.vars="lsoa_id")

