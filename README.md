
ACE CWMS Columbia Glacier Data
==============================

Preview this [Data Package](http://specs.frictionlessdata.io/data-packages/) using the [Data Package Viewer](http://data.okfn.org/tools/view?url=https://github.com/columbia-glacier/usace-cwms-col).

Data
----

<details style="background-color: #eee;padding: 5px;"><summary>View metadata (<i>datapackage.json</i>)</summary>

-   **name**: usace-cwms-col
-   **title**: USACE CWMS Columbia Glacier Data
-   **description**: Meteorological observations from the US Army Corps of Engineers Corps Water Management System station at Columbia Glacier.
-   **version**: 0.1.0
-   **sources**:
    -   \[1\]
        -   **title**: Glacier Research: Columbia Glacier
        -   **path**: <http://glacierresearch.org/locations/columbia/>
    -   \[2\]
        -   **title**: Pete Gadomski's CWMS JSON API (cwms-jsonapi)
        -   **path**: <https://github.com/gadomski/cwms-jsonapi>
    -   \[3\]
        -   **title**: CWMS JSON API Endpoints
        -   **path**: <https://reservoircontrol.usace.army.mil/NE/pls/cwmsweb/cwms_web.jsonapi>
-   **contributors**:
    -   \[1\]
        -   **title**: Ethan Welty
        -   **email**: <ethan.welty@gmail.com>
        -   **role**: author
    -   \[2\]
        -   **title**: David Finnegan
        -   **role**: Coordinated the installation and maintenance of the station
    -   \[3\]
        -   **title**: Adam LeWinter
        -   **role**: Assisted station deployment
    -   \[4\]
        -   **title**: Pete Gadomski
        -   **role**: Wrote the API distributing the data from the station
-   **resources**:
    -   \[1\]
        -   **name**: stations
        -   **path**: data/stations.csv
        -   **title**: Station metadata
        -   **schema**:
            -   **fields**:
                -   \[1\]
                    -   **name**: id
                    -   **type**: string
                -   \[2\]
                    -   **name**: name
                    -   **type**: string
                -   \[3\]
                    -   **name**: longitude
                    -   **type**: number
                    -   **description**: Longitude (WGS84, EPSG:4326)
                    -   **unit**: °
                -   \[4\]
                    -   **name**: latitude
                    -   **type**: number
                    -   **description**: Latitude (WGS84, EPSG:4326)
                    -   **unit**: °
                -   \[5\]
                    -   **name**: elevation
                    -   **type**: number
                    -   **description**: Elevation (unknown datum)
                    -   **unit**: m
    -   \[2\]
        -   **name**: data
        -   **path**: data/data.csv
        -   **title**: Station data
        -   **schema**:
            -   **foreignKeys**:
                -   **fields**: station\_id
                -   **reference**:
                    -   **resource**: stations
                    -   **fields**: id
            -   **fields**:
                -   \[1\]
                    -   **name**: t
                    -   **type**: datetime
                    -   **format**: %Y-%m-%dT%H:%M:%SZ
                -   \[2\]
                    -   **name**: air\_temperature\_1
                    -   **type**: number
                    -   **unit**: °C
                -   \[3\]
                    -   **name**: air\_temperature\_2
                    -   **type**: number
                    -   **unit**: °C
                -   \[4\]
                    -   **name**: relative\_humitidy
                    -   **type**: number
                    -   **unit**: %
                -   \[5\]
                    -   **name**: wind\_speed\_1
                    -   **type**: number
                    -   **unit**: m s-1
                -   \[6\]
                    -   **name**: wind\_speed\_2
                    -   **type**: number
                    -   **unit**: m s-1
                -   \[7\]
                    -   **name**: wind\_direction\_1
                    -   **type**: number
                    -   **description**: Wind direction (reference and direction unknown)
                    -   **unit**: rad
                -   \[8\]
                    -   **name**: wind\_direction\_2
                    -   **type**: number
                    -   **description**: Wind direction (reference and direction unknown)
                    -   **unit**: rad
                -   \[9\]
                    -   **name**: air\_pressure
                    -   **type**: number
                    -   **unit**: Pa
                -   \[10\]
                    -   **name**: voltage
                    -   **type**: number
                    -   **unit**: V </details>

### Description

The data includes meteorological observations from the active US Army Corps of Engineers (USACE) Corps Water Management System (CWMS) [Columbia Glacier](http://glacierresearch.com/locations/columbia/) (COL) station:

-   Air temperature
-   Relative humidity
-   Wind speed & direction
-   Pressure
-   Voltage

### Sources

-   Glacier Research: Columbia Glacier ([glacierresearch.org](http://glacierresearch.org/))
-   Pete Gadomski's [cwms-jsonapi](https://github.com/gadomski/cwms-jsonapi) (live at <https://reservoircontrol.usace.army.mil/NE/pls/cwmsweb/cwms_web.jsonapi>)

To Do
-----

-   Meaning of `quality_code` (a bitmask) returned by the CWMS API `timeseriesdata` endpoint.
-   Reference and direction of `wind_direction` values.
-   Datum of location `elevation`.
-   Physical description of the `Pressure` and `Voltage` timeseries.
-   Convert values to SI (derived) units (kph -&gt; m/s, deg -&gt; rad, kPa -&gt; Pa).
-   Locate pre-August 2012 data (although the station was installed in May 2009, the API only returns data since August 2012).
