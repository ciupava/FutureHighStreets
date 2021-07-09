# Libraries install
library(dplyr)
library(readxl)


# Importing excel spreadsheet to R
path <- "/Users/azanchetta/OneDrive - The Alan Turing Institute/Research/Data/FutureCityCentres/highstreetemploymentlanduseandresidentpopulation.xlsx"
sheetnames <- excel_sheets(path)
mylist <- lapply(excel_sheets(path), read_excel, path = path)

# name the dataframes
names(mylist) <- sheetnames

# Extract the tables from the list
list2env(mylist ,.GlobalEnv)

# 