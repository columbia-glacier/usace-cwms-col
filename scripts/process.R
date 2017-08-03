library(magrittr)

# ---- Load functions ----

#' Get CWMS Metadata for Locations
#'
#' @param db_office_id Office id.
#' @param unit_system Locations usually has two database representations, one for each unit system ('SI': International System of Units, 'EN': English units).
#' @references Parsed from API calls (\url{http://www.gadom.ski/cwms-jsonapi/}) mimicking those made by \url{http://glacierresearch.org/}.
get_cwms_locations <- function(db_office_id = "NAE", unit_system = c("SI", "EN")) {
  url <- "https://reservoircontrol.usace.army.mil/NE/pls/cwmsweb/cwms_web.jsonapi.locations"
  query <- list(db_office_id = match.arg(db_office_id), unit_system = match.arg(unit_system))
  response <- httr::GET(url, query = query)
  json <- jsonlite::fromJSON(rawToChar(response$content))
}

#' Get CWMS Metadata for Timeseries at Location
#'
#' @param location_id Location id.
#' @references Parsed from API calls (\url{http://www.gadom.ski/cwms-jsonapi/}) mimicking those made by \url{http://glacierresearch.org/}.
get_cwms_timeseries <- function(location_id) {
  url <- "https://reservoircontrol.usace.army.mil/NE/pls/cwmsweb/cwms_web.jsonapi.timeseries"
  query <- list(location_id = location_id)
  response <- httr::GET(url, query = query)
  json <- jsonlite::fromJSON(rawToChar(response$content))
}

#' Get CWMS Timeseries Data
#'
#' @param ts_codes Timeseries codes. If multiple are specified, the values for each are averaged together by timestamp.
#' @param summary_interval Time interval over which the data are resampled through averaging. If \code{"none"} or \code{NULL}, the raw data is returned.
#' @param floor Minimum value below which values are dropped. Useful in combination with \code{summary_interval}, since timeseries are averaged before resampling.
#' @param circular Whether to use circular (rather than regular) averaging (e.g. for wind direction).
#' @references Parsed from API calls (\url{http://www.gadom.ski/cwms-jsonapi/}) mimicking those made by \url{http://glacierresearch.org/}.
get_cwms_timeseries_data <- function(ts_codes, summary_interval = c("none", "hourly", "daily", "weekly", "monthly"), floor = NULL, circular = FALSE) {
  url <- "https://reservoircontrol.usace.army.mil/NE/pls/cwmsweb/cwms_web.jsonapi.timeseriesdata"
  query <- list(ts_codes = paste(ts_codes, sep = ","), summary_interval = match.arg(summary_interval), floor = floor, circular = tolower(as.character(circular)))
  response <- httr::GET(url, query = query)
  # Valid format for negative numbers
  char <- gsub(":([\\-]*)\\.", ":\\10.", rawToChar(response$content))
  json <- jsonlite::fromJSON(char)
  # Valid ISO 8601 date time
  json$date_time <- paste0(json$date_time, "Z")
  return(json)
}

# ---- Load parsers ----

station_parsers <- list(
  id = function(location_id) {
    location_id
  },
  name = function(long_name) {
    long_name
  },
  longitude = function(longitude) {
    longitude %>%
      units2::as_units("°") %>%
      dpkg::set_field(description = "Longitude (WGS84, EPSG:4326)")
  },
  latitude = function(latitude) {
    latitude %>%
      units2::as_units("°") %>%
      dpkg::set_field(description = "Latitude (WGS84, EPSG:4326)")
  },
  elevation = function(elevation, unit_id) {
    elevation %>%
      units2::as_units(unique(unit_id)) %>%
      dpkg::set_field(description = "Elevation (unknown datum)")
  }
)

data_parsers <- list(
  station_id = function(location_id) {
    location_id
  },
  t = function(date_time) {
    date_time %>%
      dpkg::set_field(type = "datetime", format = "%Y-%m-%dT%H:%M:%SZ")
  },
  air_temperature_1 = function(`Temp-AIR1`) {
    `Temp-AIR1` %>%
      units2::as_units("°C")
  },
  air_temperature_2 = function(`Temp-AIR2`) {
    `Temp-AIR2` %>%
      units2::as_units("°C")
  },
  relative_humitidy = function(`%-RELHUM`) {
    `%-RELHUM` %>%
      units2::as_units("%")
  },
  wind_speed_1 = function(`Speed-WIND1`) {
    `Speed-WIND1` %>%
      units2::convert_units("km / hour", "m / sec")
  },
  wind_speed_2 = function(`Speed-WIND2`) {
    `Speed-WIND2` %>%
      units2::convert_units("km / hour", "m / sec")
  },
  wind_direction_1 = function(`Dir-WIND1`) {
    `Dir-WIND1` %>%
      units2::convert_units("°", "rad") %>%
      dpkg::set_field(description = "Wind direction (reference and direction unknown)")
  },
  wind_direction_2 = function(`Dir-WIND2`) {
    `Dir-WIND2` %>%
      units2::convert_units("°", "rad") %>%
      dpkg::set_field(description = "Wind direction (reference and direction unknown)")
  },
  air_pressure = function(Pres) {
    Pres %>%
      units2::convert_units("kPa", "Pa")
  },
  voltage = function(Volt) {
    Volt %>%
      units2::as_units("V")
  }
)

# ---- Get CWMS data ----

location_id <- "COL"

# Get location metadata
locations <- get_cwms_locations(db_office_id = "NAE", unit_system = "SI")
location <- locations[locations$location_id == location_id, ]

# Get timeseries metadata
timeseries <- get_cwms_timeseries(location_id)

# Get timeseries data (slow)
timeseries_data <- lapply(timeseries$ts_code, get_cwms_timeseries_data, summary_interval = NULL, floor = NULL)
names(timeseries_data) <- timeseries$ts_code
# Tabulate values by timestamp (discarding count and quality_code)
unique_timestamps <- sort(unique(unlist(sapply(timeseries_data, "[[", "date_time"))))
merged_timeseries <- data.frame(date_time = unique_timestamps, stringsAsFactors = FALSE)
for (i in seq_along(timeseries_data)) {
  merged_timeseries <- merge(merged_timeseries, timeseries_data[[i]][, c("date_time", "value")], by = "date_time", all = TRUE)
  colnames(merged_timeseries)[ncol(merged_timeseries)] <- names(timeseries_data)[i]
}
ind <- 2:ncol(merged_timeseries)
ts_codes <- as.numeric(colnames(merged_timeseries)[ind])
parameter_ids <- timeseries$parameter_id[match(ts_codes, timeseries$ts_code)]
colnames(merged_timeseries)[ind] <- parameter_ids

# ---- Build data package ----

dp <- list(
  stations = {
    location %>%
      cgr::parse_table(station_parsers) %>%
      dpkg::set_resource(
        title = "Station metadata",
        path = "data/stations.csv"
      )
  },
  data = {
    merged_timeseries %>%
      cgr::parse_table(data_parsers) %>%
      dpkg::set_resource(
        title = "Station data", 
        path = "data/data.csv", 
        schema = dpkg::schema(foreignKeys = dpkg::foreignKey("station_id", "stations", "id"))
      )
  }
) %>%
  dpkg::set_package(
    name = "usace-cwms-col",
    title = "USACE CWMS Columbia Glacier Data",
    description = "Meteorological observations from the US Army Corps of Engineers Corps Water Management System station at Columbia Glacier.",
    version = "0.1.0",
    contributors = list(
      dpkg::contributor("Ethan Welty", email = "ethan.welty@gmail.com", role = "author"),
      dpkg::contributor("David Finnegan", role = "Coordinated the installation and maintenance of the station"),
      dpkg::contributor("Adam LeWinter", role = "Assisted station deployment"),
      dpkg::contributor("Pete Gadomski", role = "Wrote the API distributing the data from the station")
    ),
    sources = list(
      dpkg::source("Glacier Research: Columbia Glacier", path = "http://glacierresearch.org/locations/columbia/"),
      dpkg::source("Pete Gadomski's CWMS JSON API (cwms-jsonapi)", path = "https://github.com/gadomski/cwms-jsonapi"),
      dpkg::source("CWMS JSON API Endpoints", path = "https://reservoircontrol.usace.army.mil/NE/pls/cwmsweb/cwms_web.jsonapi")
    )
  )

# ---- Write package to file ----

dpkg::write_package(dp)
