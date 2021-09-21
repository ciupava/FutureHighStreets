---
# Workflow to create a SIM of individuals to retails flow in UK high streets
*author:* azanchetta@turing.ac.uk

*date:* 20/09/2021

---

*Bibliography:*

Lovelace, R., Birkin, M., Cross, P., Clarke, M. (2016). ‘From Big Noise to Big Data: Toward the Verification of Large Data sets for Understanding Regional Retail Flows’, Geographical Analysis 48, 59–81

Wilson, A.G. (1971). ‘A Family of Spatial Interaction Models, and Associated Developments’. Environment and Planning, 3, 1-32

---

### Data:
UK Office for National Statistics (ONS):
- demographic data (population characteristics, occupation) at LSOA levels (Census 2011)
- geographic data from the Open Geography portal
- list of UK retail centres, with their boundaries, is provided by the University of Liverpool and is available at CDRC (2021)

Data | Use | Resolution | format | comments | link to source
---- | --- | ---------- | ------ | -------- | --- 
Demographic data | No. residents | LSOAs | csv | table KS101EW - Usual resident population | [Census 2011](https://www.nomisweb.co.uk/query/select/getdatasetbytheme.asp?theme=75&subgrp=Key+Statistics)
- | No. students | - | - | Table QS601EW - Economic activity, Students | -
- | No. employed per industry | - | - | Table QS605EW - Industry | - 
Geospatial data | calculate distances | LSOAs (centroids) | shp (points) | Population weighted centroids | [ONS geoportal](https://geoportal.statistics.gov.uk/datasets/lower-layer-super-output-areas-december-2011-population-weighted-centroids/explore)
Retail centres boundaries | calculate distances | retail areas | shp (polygons) | centroids calculated in Qgis | [CDRC](https://data.cdrc.ac.uk/dataset/retail-centre-boundaries)

### Open questions:
- At which level to run the analysis: national scale or regional/LAD
- Dimension of attractiveness values
- Calibration of the model

### Workflow:

#### First attempt: Leeds, student population
(Working, but to be improved and automated)
* Qgis
    * Import shps in QGIS
    * Generate centroids for the retail centres (destinations)
    * Join students table to the LSOAs centroids shp (some data tudy up must be needed, as titles are present in the spreadsheet)
    * Export shp as csv file to be used in *R* (necessary? we actually need the shp in order to calcularte the distances origins and destination IE the OD matrix)
* R
    * open SpaInteModel.R
    * follow the steps:
        * import the csv tables and shp
        * obtain the coordinates of O and D both from the shp
        * use them to originate the distance matrix with function *pointDistance* (package ...)
        * calculate other arrays (vectors) for the model: balance factor, population, attractiveness
        * calculate the flows matrix
    * export back to plot in Qgis
- Run the model on the student population, then perform calibration
- Run the model on different scenarios for different groups of individuals and perform analysis of the results

#### Improved workflow
* Reproduce in Python?
* Automate the process of centroids creation in R/Python - or - one single time process in QGIS?
* resize the attractiveness
* depending on scale, understand how to access the data (national/ conties / ...?)
* find data for calibration
* understand if calibration is needed IE maybe use radiation models?
* 
*


--------------

The [R plugin](https://www.jetbrains.com/help/pycharm/r-plugin-support.html) for IntelliJ-based IDEs provides
handy capabilities to work with the [R Markdown](https://www.jetbrains.com/help/pycharm/r-markdown.html) files.
To [add](https://www.jetbrains.com/help/pycharm/r-markdown.html#add-code-chunk) a new R chunk,
position the caret at any line or the code chunk, then click "+".

The code chunk appears:
```{r}
```

Type any R code in the chunk, for example:
```{r}
mycars <- within(mtcars, { cyl <- ordered(cyl) })
mycars
```

Now, click the **Run** button on the chunk toolbar to [execute](https://www.jetbrains.com/help/pycharm/r-markdown.html#run-r-code) the chunk code. The result should be placed under the chunk.
Click the **Knit and Open Document** to built and preview an output.