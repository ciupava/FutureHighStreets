# Libraries install
library(dplyr)
library(readxl)

## Data import ----
# A. Tables ---
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
# table 2
employment_BIG_LAD <- `Table 2` %>%
  filter(LAD19NM != "NA" & LAD19NM != "LAD19NM") # 3705 obj
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

# B. Geospatial data ---
