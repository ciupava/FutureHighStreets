---
# Workflow to create a SIM of individuals to retails flow in UK high streets
---
*author:* azanchetta@turing.ac.uk

*date:* 20/09/2021

---
*Bibliography:*

Lovelace, R., Birkin, M., Cross, P., Clarke, M. (2016). ‘From Big Noise to Big Data: Toward the Verification of Large Data sets for Understanding Regional Retail Flows’, Geographical Analysis 48, 59–81

Wilson, A.G. (1971). ‘A Family of Spatial Interaction Models, and Associated Developments’. Environment and Planning, 3, 1-32

Waddington T., Clarke G., Clarke M.C. et al. (2019). ‘Accounting for temporal demand variations in retail location models’, Geographical Analysis, 51(4), 426-447

Khawaldah H., Birkin M. and Clarke G. (2012), 'A review of two alternative retail impact assessment techniques: the caseo f Silverburn in Scotland', The Town Planning Review, 83(2), 233–260
url:http://www.jstor.org/stable/41349096


### Data:
UK Office for National Statistics (ONS):
- demographic data (population characteristics, occupation) at LSOA levels (Census 2011)
- geographic data from the Open Geography portal
- list of UK retail centres, with their boundaries, is provided by the University of Liverpool and is available at CDRC (2021)

Data | Use | Resolution | format | comments | link to source
---- | --- | ---------- | ------ | -------- | --- 
Demographic data | No. residents | LSOAs | csv | table KS101EW - Usual resident population | [Census 2011](https://www.nomisweb.co.uk/query/select/getdatasetbytheme.asp?theme=75&subgrp=Key+Statistics)
"" | No. students | - | - | Table QS601EW - Economic activity, Students | -
"" | No. employed per industry | - | - | Table QS605EW - Industry | - 
Geospatial data | calculate distances | LSOAs (centroids) | shp (points) | Population weighted centroids | [ONS geoportal](https://geoportal.statistics.gov.uk/datasets/lower-layer-super-output-areas-december-2011-population-weighted-centroids/explore)
Retail centres boundaries | calculate distances | retail areas | shp (polygons) | centroids calculated in Qgis | [CDRC](https://data.cdrc.ac.uk/dataset/retail-centre-boundaries)

### Open questions: *Updated at 22/09/2021 after chat with Mark*
- [X] At which level to run the analysis: national scale or regional/LAD --> LAD
- [X] Dimension of attractiveness values --> for the attractiveness array we have used for Leeds a temporary 'rank' from 1 to 10 depending on the type of retail centre (see LUT), this shall be combined with the centre's size, as discussed in the internal document on OneDrive
- [X] Calibration of the model --> we we use (for the moment?) a fixed value for Alpha = 1 and Beta = 0.43 (Waddington et al. 2019)

### Workflow:

#### First attempt: Leeds, student population
(Working, but to be improved and automated)
* Qgis
    * Import shps in QGIS
    * Generate the 'rank' field in the retail shp by joining the relative column of the table RetailCentres_LUT (this is our retail's attractiveness), see table in [data/Leeds_data/RetailCentres_LUT.csv]data/Leeds_data/RetailCentres_LUT.csv])
    * Generate centroids for the retail centres (destinations)
    * Join students table to the LSOAs centroids shp (some data tidy up is needed, as titles are present in the spreadsheet)
    * Export shapefile's attribute tale as csv file to be used in *R* (necessary? we actually need the shp in order to calculate the distances origins and destination IE the OD matrix)
* R
    * open [SpatInteModel.R](scripts/SpatInteModel.R)
    * follow the steps:
        * import the csv tables and shp
        * obtain the coordinates of O and D both from the shp
        * use them to originate the distance matrix with function *pointDistance* (package ...)
        * calculate other arrays (vectors) for the model: balance factor, population, attractiveness
        * calculate the flows matrix
    * export back to plot in Qgis
- (Not performed) Run the model on the student population, then perform calibration
- (Not performed) Run the model on different scenarios for different groups of individuals and perform analysis of the results

#### Improved workflow
List of things to be done in order of priority:
- [X] Reproduce in Python? --> YES
- [X] Automate the process of centroids creation in R/Python - or - one single time process in QGIS? --> upload code online 
- [ ] attractiveness: generate values depending on type and size of retail centres
- [ ] depending on scale, understand how to access the data (national/ counties / ...?) --> generate LUT for accessing the data sources at LAD level by LSOAs list (both for retail centres AND the pop weighted LSOA centroids?)
- [ ] find data for calibration ... only when we actually want to run the calibration
- [ ] understand if calibration is needed IE maybe use radiation models?

Current state of the model (in Python ):
* generated Jupyter notebooks for the SIM analysis and for the data processing -> [SpatInteModel.ipynb](scripts/SpatInteModel.ipynb)
* started the data processing -> see file [data_handling.ipynb](scripts/data_handling.ipynb)




--------------
