# Libraries install
library(dplyr) # for R piping and more cool stuff
library(readxl) # for handling Excel spreasheets
#library(sf) # for handling geospatial data
library(foreign) # for handling databases (dbf)
# for handling geospatial data
library(maps) # actually used?
library(mapdata)
library(maptools)
library(rgdal)
library(ggmap)
library(rgeos)
library(broom)  # function tidy for shapefile
library(ggplot2) # graphs
library(plyr)
library(tidyverse)
library(tidyr)
library(reshape2) # to change long/wide format in database
library(GGally) # to make nice scatter plots
library(cluster) # for cluster analysis

### *Data import* ----
# A. Tables ----
# Importing excel spreadsheet to R (High street employment, land use and resident population)
path_to_tables <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/Data/FutureCityCentres/highstreetemploymentlanduseandresidentpopulation.xlsx"
# source: https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/highstreetemploymentlanduseandresidentpopulation

sheetnames <- excel_sheets(path_to_tables)
mylist <- lapply(excel_sheets(path_to_tables), read_excel, path = path_to_tables)

# name the dataframes
names(mylist) <- sheetnames

# Extract the tables from the list
list2env(mylist ,.GlobalEnv)

# Check content of tables
colnames(`Table 1`) #"Table 1: Addresses on the high street, by land use category, local authority"
colnames(`Table 2`) #"Table 2: Counts of employment by combined broad industrial group, local authority"
colnames(`Table 3`) #"Table 3: Counts of high street employment by selected industry sector, country and region"
colnames(`Table 4`) #"Table 4: Resident population on or around high streets, local authority"
colnames(`Table 5`) #"Table  5: Resident population on or around high streets by broad age band, local authority"
colnames(`Table 6`) #"Table 6: Resident population on or around high streets who are students, local authority"

# Getting column names from row 3, as that is where they are actually stored
colnames(`Table 1`) <- `Table 1`[3,]
colnames(`Table 2`) <- `Table 2`[3,]
colnames(`Table 3`) <- `Table 3`[3,]
colnames(`Table 4`) <- `Table 4`[3,]
colnames(`Table 5`) <- `Table 5`[3,]
colnames(`Table 6`) <- `Table 6`[3,]

# Rename the dataframes and select the rows that actually have information
# mainly only the ones where the geographical areas' code/name is not empty
# table 1
addresses_hs_bylanduse_LAD <- `Table 1` %>%
  filter(LAD19NM != "NA" & LAD19NM != "LAD19NM") # 371 obj
# # eliminate Isles of Scilly (empty row)
addresses_hs_bylanduse_clean <- addresses_hs_bylanduse %>%
  subset(LAD19NM != "Isles of Scilly")
# addresses_hs_bylanduse[] <- lapply(addresses_hs_bylanduse_clean, function(x) round(as.numeric(x),2))
cols = colnames(addresses_hs_bylanduse)
landuse_categories <- cols[cols != ("LAD19CD") & cols != ("LAD19NM") ]
# converting to numeric only the columns of the landuse categories
addresses_hs_bylanduse_clean[, landuse_categories] <- lapply(landuse_categories, function(x) as.numeric(addresses_hs_bylanduse_clean[[x]]))

# table 2
employment_BIG_LAD <- `Table 2` %>%
  filter(LAD19NM != "NA" & LAD19NM != "LAD19NM") # 370 obj
# table 3
employment_SIC_region <- `Table 3` %>%
  filter(`SIC 2007`!= "NA" & `SIC 2007`!="SIC 2007")
# table 4
shareHSpop_LAD <- `Table 4` %>%
  filter(LAD19NM != "NA" & LAD19NM != "LAD19NM")
# table 5
shareHSpop_age_LAD <- `Table 5` %>%
  filter(LAD19NM != "NA" & LAD19NM != "LAD19NM")
# table 6
shareHSpop_students <- `Table 6` %>%
  filter(LAD19NM != "NA" & LAD19NM != "LAD19NM")
colnames(shareHSpop_students)
colnames(shareHSpop_students)[4] <- "students_perc"
shareHSpop_students$students_perc <- as.numeric(shareHSpop_students$students_perc)
shareHSpop_students <- shareHSpop_students %>%
  filter(LAD19NM != "Isle of Wight") # eliminating Wight for consistency with the other tables

# B. Geospatial data ----
lad_dbf_path <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/Data/GeoSpatial/Local_Authority_Districts__May_2020__Boundaries_UK_BFC-shp/"
lad_dbf_name <- "Local_Authority_Districts__May_2020__Boundaries_UK_BFC.dbf"
lad_shp_name <- "Local_Authority_Districts__May_2020__Boundaries_UK_BFC"
lad_dbf <- read.dbf(file.path(lad_dbf_path,
                              lad_dbf_name))

### *First analysis* ----
## 0. Joining tables and geospatial data ----
export_path <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/Data/FutureCityCentres/GIS/"
lad_landuse <- left_join(lad_dbf,
                         addresses_hs_bylanduse_clean,
                         by = c("LAD20CD" = "LAD19CD"))
lad_landuse_outputname <- "lad_landuse.dbf"
dbf_lad_landuse <- write.dbf(lad_landuse,
                             file.path(export_path,
                                       lad_landuse_outputname))
# Note: changing only the dbf means needing to create in the folder for each shp manually a copy of the original
# shp files and then renaming them all after, which is time consuming and not helpful
# trying to see if possible to import the shp in R (even if huge memory) and edit/visualise here instead of GIS software
# possibly comparing different classes in the same figure?


# choropleth grids:
# https://stackoverflow.com/questions/9186529/grid-with-choropleth-maps-in-ggplot2
# states.df <- map_data("state")
# states.df = subset(states.df,group!=8) # get rid of DC
# states.df$st <- state.abb[match(states.df$region,tolower(state.name))] # attach state abbreviations
# 
# states.df$value = value[states.df$st]  # 'value' is the df where you have info you want to plot
# 
# p = qplot(long, lat, data = states.df, group = group, fill = value, geom = "polygon", xlab="", ylab="", main=main) + opts(axis.text.y=theme_blank(), axis.text.x=theme_blank(), axis.ticks = theme_blank()) + scale_fill_continuous (name)
# p2 = p + geom_path(data=states.df, color = "white", alpha = 0.4, fill = NA) + coord_map(project="polyconic")
# 
# UK example:
# https://datatricks.co.uk/creating-maps-in-r
# update: https://datatricks.co.uk/creating-maps-in-r-2019

# # Load the shp
# lad_shp <- readOGR(dsn = lad_dbf_path,
#                    layer = lad_shp_name)
# #Reshape for ggplot2 using the Broom package
# lad_fortified <- tidy(lad_shp, region = "NAME")
# name of column you want with regions' name info
#Check the shapefile has loaded correctly by plotting an outline map of the UK
# gg <- ggplot() + geom_polygon(data = mapdata, aes(x = long, y = lat, group = group), color = "#FFFFFF", size = 0.25)
# gg <- gg + coord_fixed(1) #This gives the map a 1:1 aspect ratio to prevent the map from appearing squashed
# print(gg)  # very loooong

# Trying to map some smaller dataset:
UK <- map_data(map = "world", region = "UK")
ggplot(data = UK, aes(x = long, y = lat, group = group)) + 
  geom_polygon() +
  coord_map()

# Trying by transforming the coordinate system:
# wgs84 = '+proj=longlat +datum=WGS84'
# uk_country_trans <- spTransform(lad_shp, CRS(wgs84))
# mapdata <- tidy(uk_country_trans, region="LAD20NM")
# gg <- ggplot() + geom_polygon(data = mapdata, aes(x = long, y = lat, group = group))
# print(gg)

# Trying plotting the countries instead (should be smaller dataset?)
# countries_shp_path <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/Data/GeoSpatial/Countries__December_2016__Boundaries_GB_BFC_V2-shp"
# countries_shp_name <- "Countries__December_2016__Boundaries_GB_BFC_V2"
# countries_shp <- readOGR(dsn = countries_shp_path,
#                        layer = countries_shp_name)
# countries_shp_fortified <- tidy(countries_shp, region = "CTRY16NM")
# ggplot() +
#   geom_polygon(data = countries_shp_fortified, aes( x = long, y = lat, group = group), fill="#69b3a2", color="white") +
#   theme_void() 

## 1. Data plotting ----
## Leaving the idea of plotting the shp, trying to infer information from the data

# Example of stacked plot
# specie <- c(rep("sorgho" , 3) , rep("poacee" , 3) , rep("banana" , 3) , rep("triticum" , 3) )
# condition <- rep(c("normal" , "stress" , "Nitrogen") , 4)
# value <- abs(rnorm(12 , 0 , 15))
# data <- data.frame(specie,condition,value)
# # Stacked
# ggplot(data, aes(fill=condition, y=value, x=specie)) + 
#   geom_bar(position="stack", stat="identity")
addresses_landuse_long <- melt(addresses_hs_bylanduse_clean,
                  # ID variables - all the variables to keep but not split apart on
                  id.vars=c("LAD19CD"),
                  # The source columns
                  measure.vars=c("Retailing", "Offices", "Community", "Leisure", "Residential"),
                  # Name of the destination column that will identify the original
                  # column that the measurement came from
                  variable.name="Landuse",
                  value.name="Rate")
# barplot:
ggplot(addresses_landuse_long, aes(fill=Landuse, y=Rate, x=LAD19CD)) + 
  geom_bar(position="stack", stat="identity") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))


addresses_landuse_long %>%
  ggplot( aes(x=LAD19CD, y=Rate, group=Landuse, color=Landuse)) +
  geom_line()

# Tring to infer something from the data
range(addresses_hs_bylanduse_clean$Retailing) # "11.4" "62.7"     ******
range(addresses_hs_bylanduse_clean$Offices) # "0.5" "37.5"         **
range(addresses_hs_bylanduse_clean$Community) # "0.5" "7.7"       **
range(addresses_hs_bylanduse_clean$Leisure) # "0" "2.3"
range(addresses_hs_bylanduse_clean$Residential) # "11.1" "75.1"   ******

landuse_grouping <- addresses_hs_bylanduse_clean %>%
  mutate(prevalent = case_when(
    Retailing > 50 ~ "Retail>50",
    Residential > 50 ~ "Resid>50",
    TRUE ~ "None_prevalent"
    ),
    compare_ResRet = case_when(
      Retailing > Residential ~ "Retail>Resid",
      Residential > Retailing ~ "Resid>Retail",
      TRUE ~ "No_dominant"
    ),
    compare_OffCom = case_when(
      Offices > Community ~ "Offices>Comm",
      Community > Offices ~ "Comm>Offices",
      TRUE ~ "No_dominant"
    )
  )

# Plotting residentail-retail grouping against offices-communities values
ggplot(landuse_grouping, aes(x=Offices, y=Community, color=compare_ResRet)) + 
  geom_point() +
  scale_x_continuous(breaks = seq(0, 40, by = 2)) +
  scale_y_continuous(breaks = seq(0, 40, by = 2))
  

# Plotting offices-communities grouping against residentail-retail values
ggplot(landuse_grouping, aes(x=Residential, y=Retailing, color=compare_OffCom)) + 
  geom_point() +
  scale_x_continuous(breaks = seq(0, 80, by = 5)) +
  scale_y_continuous(breaks = seq(0, 80, by = 5))

# plotting all the landuse categories one-to-one (scatterplot)
addresses_only_landusecategories <- addresses_hs_bylanduse_clean[,c(3:7)]
plot(addresses_only_landusecategories, pch=20 , cex=1.5 , col="#69b3a2", xlim=c(0,70), ylim=c(0,70))
#other option with more graphics
ggpairs(addresses_only_landusecategories, title="correlogram with ggpairs()") 
upperfun <- function(data,mapping){
  ggplot(data = data, mapping = mapping)+
    geom_density2d()+
    scale_x_continuous(limits = c(0,70))+
    scale_y_continuous(limits = c(0,70))
}   

lowerfun <- function(data,mapping){
  ggplot(data = data, mapping = mapping)+
    geom_point()+
    scale_x_continuous(limits = c(0,70))+
    scale_y_continuous(limits = c(0,70))
}  
ggpairs(addresses_only_landusecategories,
        lower = list(continuous = wrap(lowerfun)))
# frequencies of values by columns:
lapply(landuse_grouping[, -c(1,2)], function(x) as.data.frame(table(x)))
lapply(landuse_grouping[, c(8:10)], function(x) as.data.frame(table(x)))


## 2. Classes (clustering) ----
# Trying to find clusters:
# trying only with the 3 'major' categories as community and leisure have little presence
kmeans3 <- kmeans(addresses_only_landusecategories[,c(1,2,5)], 
                  centers = 3,
                  nstart = 10)
kmeans3$centers
# Retailing  Offices Residential
# 1  42.87294 14.95529    39.15176
# 2  34.41551 10.61337    52.32513
# 3  24.96020  8.40000    64.63776
# Proposed classes:
# A. ret >40, off >12, res <35
# B. ret [30-40], off 9-12, res 35-50
# C. ret <30, off <9, res >50

# addresses_landuse_class <- addresses_hs_bylanduse_clean %>%
#   mutate(class_k3 = case_when(
#     Retailing >= 40 & Offices >= 12 & Residential < 35 ~ "A",
#     Retailing >=30 & Retailing < 40 & Offices >=9 & Offices < 12 & Residential >= 35 & Residential < 50 ~ "B",
#     Retailing < 30 & Offices < 9 & Residential >= 50 ~ "C",
#     TRUE ~ "None"
#   ))


# Adding the clusters classes to the landuse dbf
addresses_landuse_class <- addresses_only_landusecategories
addresses_landuse_class$class <- kmeans3$cluster  
addresses_landuse_class$LAD19CD <- addresses_hs_bylanduse_clean$LAD19CD

# Plotting the categories by clusters
plot(addresses_landuse_class[,c(1, 2, 5)],
     pch = 20,
     cex = 1.5,
     col=c("darkorange", "chartreuse3", "darkorchid")[addresses_landuse_class$class],
     main = "Clusters for retailing, residential, offices")

# exporting to dbf for visualising in Qgis
lad_landuse <- left_join(lad_dbf,
                         addresses_landuse_class,
                         by = c("LAD20CD" = "LAD19CD"))
lad_landuse_outputname <- "lad_landuse.dbf"
dbf_lad_landuse <- write.dbf(lad_landuse,
                             file.path(export_path,
                                       lad_landuse_outputname))

## 3. Simplified geospatial data ----
# Trying again to map after having simplified the shp in Qgis
lad_shp_simple_name <- "LAD_2020_simplified100-area_fixed"
lad_shp_simple_path <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/Data/GeoSpatial/"
lad_simple_shp <- readOGR(dsn = lad_shp_simple_path,
                          layer = lad_shp_simple_name)

#Reshape for ggplot2 using the Broom package
lad_fortified <- tidy(lad_simple_shp, region = "LAD20CD")
# name of column you want with regions' name info
#Check the shapefile has loaded correctly by plotting an outline map of the UK
ggplot() +
  geom_polygon(data = lad_fortified, aes( x = long, y = lat, group = group), fill="#69b3a2", color="white") +
  theme_void()
gg <- ggplot() + geom_polygon(data = lad_fortified, aes(x = long, y = lat, group = group), color = "#FFFFFF", size = 0.25)
gg <- gg + coord_fixed(1) #This gives the map a 1:1 aspect ratio to prevent the map from appearing squashed
print(gg)

p = qplot(long, lat, data = lad_fortified, group = group, fill = value, geom = "polygon", xlab="", ylab="", main=main) + opts(axis.text.y=theme_blank(), axis.text.x=theme_blank(), axis.ticks = theme_blank()) + scale_fill_continuous()
p2 = p + geom_path(data=states.df, color = "white", alpha = 0.4, fill = NA) + coord_map(project="polyconic")



# d1 <- map_data("state")
# d2 <- unique(d1$group)
# n <- length(d2)
# d2 <- data.frame( 
#   group=rep(d2,each=6), 
#   g1=rep(1:3,each=2,length=6*n),
#   g2=rep(1:2,length=6*n),
#   value=runif(6*n)
# )
# d <- merge(d1, d2,  by="group")
# qplot(
#   long, lat, data = d, group = group, 
#   fill = value, geom = "polygon" 
# ) + 
#   facet_wrap( ~ g1 + g2 )

## 4. Adding students ----
lad_landuse_stud <- left_join(lad_landuse,
                              shareHSpop_students,
                              by = c("LAD20CD" = "LAD19CD"))
lad_landuse_stud[, c(landuse_categories, "students_perc")] <- lapply(c(landuse_categories, "students_perc"), function(x) as.numeric(lad_landuse_stud[[x]])) # making sure they are numeric for kmeans to work later
# get rid of rows with NAs, also for kmean to work
# after checking with 'summary(lad_landuse_stud)' that in fact the NAs are in the categories and in the stud percentages, getting rid of NAs rows in students_perc
lad_landuse_stud <- lad_landuse_stud %>%
  filter(students_perc != "NA")

lad_landuse_outputname <- "lad_landuse.dbf"
dbf_lad_landuse <- write.dbf(lad_landuse_stud,
                             file.path(export_path,
                                       lad_landuse_outputname))
# Checking correlation with landuse categories
ggpairs(lad_landuse_stud[,c(11:15,19)], # selecting the 5 landuse categories and the students columns
        lower = list(continuous = wrap(lowerfun)))

# Trying to find clusters:
# trying only with the retailing, residential, students
kmeans2_stud <- kmeans(lad_landuse_stud[,c(15, 11, 19)], # selecting the columns for retail, resid, stud
                  centers = 2,
                  nstart = 25)
kmeans2_stud$centers

stud_clusters <- lad_landuse_stud
stud_clusters$cluster_stud <- kmeans2_stud$cluster

# Plotting the two categories + students% with the clusters
plot(stud_clusters[,c(11,15,19)],
     pch = 20,
     cex = 1.5,
     col=c("brown1", "cornflowerblue", "purple")[stud_clusters$cluster],
     main = "Clusters for retailing, residential VS % of students living near high-streets")

# exporting to dbf for visualising in Qgis
stud_clusters_forjoin <- stud_clusters[,c(11:20)]
lad_landuse_clusterstud <- left_join(lad_dbf,
                         stud_clusters_forjoin,
                         by = c("LAD20NM" = "LAD19NM"))
lad_landuse_outputname <- "lad_landuse.dbf"
dbf_lad_landuse <- write.dbf(lad_landuse_clusterstud,
                             file.path(export_path,
                                       lad_landuse_outputname))
