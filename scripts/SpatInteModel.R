# Title     : SpatInteModel.R
# Objective : Build a spatial interaction model to analyse the high streets population patterns in UK
# Created by: azanchetta
# Created on: 19/08/2021


# *Load libraries ----
#  Necessary packages, install if needed
# install.packages(c("sp", "MASS", "reshape2","geojsonio","rgdal","downloader","maptools","dplyr","broom"
#                    ,"stplanr", "ggplot2", "leaflet"))

#  From source:
library(tidyverse)
library(plyr)
library(sp)
library(MASS)
library(reshape2) # to change long/wide format in database
# library(geojsonio) # not managing to install it
library(rgdal)
library(downloader)
library(maptools)
library(broom) # function tidy for shapefile
library(stplanr)
library(leaflet)
library(sf)
library(tmap)
library(raster)


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
beta <- 0.34 # Souce: https://eprints.whiterose.ac.uk/134554/1/Wadington%20et%20al_Accounting%20for%20Temporal%20Demand.pdf
#--
attractiveness <- as.integer(destination_shp@data$Rank)
# --
students_per_lsoa <- as.integer(origin_shp@data$STUD_TOT)

# *Calculations* ----
# A. Generate necessary variables ----

## Distance matrix: ###
# It is a i*j matrix with:
# i (origins) rows
# j (destinations) columns
origin_coords <- origin_shp@data[,c("X_COORD", "Y_COORD")]
destination_coords <- destination_shp@data[,c("x_coord","y_coord")]
# distance_matrix <- "" # sqrt[(xi - xj)^2 + (yi - yj)^2]/1000 .... find automatic way in R?
# matrix generation using (x,y) coordinates from the data:
dist_matrix <- round(pointDistance(origin_coords,
                                   destination_coords,
                                   lonlat = F) # with EPSG:27700 we don't have lat lon
                     / 1000, #(to convert to km)
                     1) # rounding to 1 decimal place

## Balance factor array ###
# formula: balf = 1/ sum[attractiveness * exp(-beta * dist))]
expon <- exp(-beta * dist_matrix) # exp(-beta * dist)
balancefactor_array <- 1/ (expon %*% attractiveness)

# manually checking results!! 
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
# start <- students_per_lsoa %*% attractiveness  # doesn't work
# trying to generate a df or matrix that has repeated rows, to multiply them for the same column n-times
# try <- matrix(attractiveness,
#               nrow = length(students_per_lsoa),
#               ncol = length(attractiveness))
# try2 <- apply(try,1, function(x) x*attractiveness)
try <- data.frame(matrix(NA,
                         nrow = 1,
                         ncol = length(attractiveness)))
try[1,] <- attractiveness # dataframe with as one row the attractiveness
nrows <- length(students_per_lsoa)
try2 <- try[rep(seq_len(nrow(try)),
                each = nrows), ] # dataframe with the attractiveness road repeated n*stud times

try3 <- adply(try2, 1, function(x) x * students_per_lsoa) # function from package plyr  ## actual multiplication
product <- try3

try4 <- product * expon
flows_matrix <- try4 * balancefactor_array
summary(flows_matrix)
colnames(flows_matrix) <- destination_shp@data$RC_ID
rownames(flows_matrix) <- origin_shp@data$LSOA11CD
flows_matrix <- format(flows_matrix, digits = 2)



# Checking input and output flows
flows_matrix_numerical <- lapply(flows_matrix, as.numeric)
tot_col <- mapply(sum,flows_matrix_numerical) #colSums(flows_matrix_numerical)



# C. Plots?? ----
# Note: decided to use Qgis for mapping as it is more functional
# the lines below provide some trials in R and the process to create the shp used in Qgis

# Converting flows matrix to long format to be able to plot it as flows
for_long_format <- flows_matrix
for_long_format$lsoa_id <- origin_shp@data$LSOA11CD

flows_long <- melt(for_long_format,
                  id.vars="lsoa_id")

# Understanding how the flowlines creation works
# od_data <- stplanr::flow[1:20, ]
# l <- od2line(flow = od_data, zones = cents_sf)
# plot(sf::st_geometry(cents_sf))
# plot(l, lwd = l$All / mean(l$All), add = TRUE)
# l <- od2line(flow = od_data, zones = cents)
# # When destinations are different
# head(destinations[1:5])
# od_data2 <- flow_dests[1:12, 1:3]
# od_data2
# flowlines_dests <- od2line(od_data2, cents_sf, destinations = destinations_sf)
# flowlines_dests
# plot(flowlines_dests)


# converting to sf object in order to run od2linw (from stplanr package)
# https://gis.stackexchange.com/questions/222978/lon-lat-to-simple-features-sfg-and-sfc-in-r
library(data.table)
library(sf)

origin_dt <- data.table(
  ID=origin_shp@data$LSOA11CD,
  lon=origin_shp@data$X_COORD,
  lat=origin_shp@data$Y_COORD)
origin_sf = st_as_sf(origin_dt,
                     coords = c("lon","lat"),
                     crs = 27700,
                     agr = "constant")
plot(origin_sf)

destination_dt <- data.table(
  ID=destination_shp@data$RC_ID,
  lon=destination_shp@data$x_coord,
  lat=destination_shp@data$y_coord)
destination_sf = st_as_sf(destination_dt,
                          coords = c("lon", "lat"),
                          crs = 27700,
                          agr = "constant")
plot(destination_sf)

flow_lines <- od2line(flows_long,
                      origin_sf,
                      destinations = destination_sf)
plot(flow_lines)  # it plots the 3 graphs...

# Convert sf object to sp object in order to export it as shp
# https://gis.stackexchange.com/questions/239118/r-convert-sf-object-back-to-spatialpolygonsdataframe
flowlines_sp <- sf:::as_Spatial(flow_lines)
plot(flowlines_sp)

flowlines_sp@data$value <- as.integer(flowlines_sp@data$value) # adding this line to avoid the error:
# Error in writeOGR(obj = flowlines_sp, dsn = data_path, layer = "flow_lines",  : 
#                     Can't convert columns of class: AsIs; column names: value
writeOGR(obj = flowlines_sp,
         dsn = data_path,
         layer = "flow_lines",
         driver = "ESRI Shapefile") # exporting shp

# trying to plot in leaflet
library(leaflet)
leaflet() %>%
  addTiles() %>%
  addPolygons(data = flow_lines)
# gives projection error
# epsg27700 <- leafletCRS(
#   crsClass = "L.Proj.CRS",
#   code = "EPSG:27700",
#   proj4def = "+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +units=m +no_defs",
#   resolutions = 2^(16:7))
# leaflet(options = leafletOptions(crs = epsg27700)) %>%
#   addPolygons(data = flow_lines)
flowlines_wgs <- flow_lines %>% sf::st_transform('+proj=longlat +datum=WGS84')
leaflet() %>%
  addTiles() %>%
  addPolygons(data = flowlines_wgs)

# another simple plot option:
copy_flow <- flow_lines
copy_flow$value <- as.numeric(as.character(copy_flow$value))
tmap_mode("view")
qtm(copy_flow, lines.lwd = "value", scale = 6)


# Trying more with leaflet
# https://cran.r-project.org/web/packages/stplanr/vignettes/stplanr-od.htmlhttps://cran.r-project.org/web/packages/stplanr/vignettes/stplanr-od.htmlhttps://cran.r-project.org/web/packages/stplanr/vignettes/stplanr-od.html
lwd <- copy_flow$value / mean(copy_flow$value) / 10
copy_flow$percent <- 100 - copy_flow$value / max(copy_flow$value) * 100
plot(copy_flow["percent"], lwd = lwd, breaks = c(0, 50, 70, 80, 90, 95, 100))



# Notes  -----
# Tries to use as reference the instructions for R that one can find here:
# https://rpubs.com/adam_dennett/257231
# https://rpubs.com/adam_dennett/259068
# Actually used the formulas from Khawaldah et al 2012
# Lovelace instructions on "A demand-constrained spatial interaction model in R":
# https://rpubs.com/RobinLovelace/11685