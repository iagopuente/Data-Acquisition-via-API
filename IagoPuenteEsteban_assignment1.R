# Install necessary packages
install.packages("httr")
install.packages("jsonlite")
install.packages("tidyverse") # For data manipulation
install.packages("RSQLite")
install.packages("openxlsx")

# Load required libraries
library(httr)
library(jsonlite)
library(tidyverse)
library(RSQLite)
library(openxlsx)

# Step 1: Set API keys
weather_api_key <- "067ecdcb94cbb7dd15eaee38d2e0f7b4"  # Weatherstack API key
population_api_key <- "hpFtzMbwrXZgVQD2Nf1R/Q==pWyDXCFZTkRfIbzd"  # Api-Ninjas API key

# Step 2: Define a list of cities for which we want to gather weather and population data
cities <- c("London", "Paris", "Berlin", "Amsterdam", "Madrid", 
            "Rome", "Athens", "Istanbul", "Lisbon", "Kyiv")

# Function to get weather data for a given city using the Weatherstack API
get_weather_data <- function(city) {
  base_url <- "http://api.weatherstack.com/current"  # API endpoint
  response <- GET(
    url = base_url,  # Send GET request to API
    query = list(access_key = weather_api_key, query = city)  # Pass API key and city as query parameters
  )
  
  # Check if the API request was successful (HTTP status code 200)
  if (response$status_code != 200) {
    stop(paste("Failed to retrieve weather data for", city))  # Stop execution if there's an error
  }
  
  content <- content(response)  # Parse the response content
  
  # Handle case where API returns an error (e.g., invalid city name)
  if (!is.null(content$error)) {
    warning(paste("Error fetching weather data for:", city))
    return(NULL)
  }
  
  # Extract relevant weather information and return it as a list
  list(
    city_name = content$location$name,
    temperature = content$current$temperature,
    humidity = content$current$humidity,
    wind_speed = content$current$wind_speed,
    weather_description = content$current$weather_descriptions[[1]],
    observation_time = content$current$observation_time
  )
}

# Function to get population data for a given city using the Api-Ninjas API
get_population_data <- function(city) {
  base_url <- "https://api.api-ninjas.com/v1/city"  # API endpoint
  response <- GET(
    url = base_url,  # Send GET request to API
    query = list(name = city),  # Pass city as query parameter
    add_headers("X-Api-Key" = population_api_key)  # Include API key in headers
  )
  
  # Check if the API request was successful (HTTP status code 200)
  if (response$status_code != 200) {
    stop(paste("Failed to retrieve population data for", city))  # Stop execution if there's an error
  }
  
  content <- content(response)  # Parse the response content
  
  # Handle case where no population data is found
  if (length(content) == 0) {
    warning(paste("No population data found for city:", city))
    return(NULL)
  }
  
  # Extract relevant population information and return it as a list
  population_info <- content[[1]]
  list(
    city_name = population_info$name,
    population = population_info$population,
    latitude = population_info$latitude,
    longitude = population_info$longitude,
    country = population_info$country
  )
}

# Step 3: Retrieve weather and population data for all cities in the list
# Using `map_df` to apply the function to each city and combine results into a data frame
weather_data <- map_df(cities, ~ {
  Sys.sleep(1)  # Pause between API calls to avoid rate limiting
  weather_info <- get_weather_data(.x)  # Fetch weather data for each city
  if (!is.null(weather_info)) {
    return(as_tibble(weather_info))  # Convert list to tibble (data frame)
  } else {
    return(NULL)  # Return NULL if no data
  }
})

population_data <- map_df(cities, ~ {
  Sys.sleep(1)  # Pause between API calls to avoid rate limiting
  population_info <- get_population_data(.x)  # Fetch population data for each city
  if (!is.null(population_info)) {
    return(as_tibble(population_info))  # Convert list to tibble (data frame)
  } else {
    return(NULL)  # Return NULL if no data
  }
})

# Step 4: Create and populate SQLite database
# Establish a connection to the SQLite database
con <- dbConnect(SQLite(), dbname = "city_data.db")

# Create the 'weather_data' table if it doesn't exist
dbExecute(con, "
CREATE TABLE IF NOT EXISTS weather_data (
  city_name TEXT PRIMARY KEY,
  temperature REAL,
  humidity REAL,
  wind_speed REAL,
  weather_description TEXT,
  observation_time TEXT
)")

# Create the 'population_data' table if it doesn't exist
dbExecute(con, "
CREATE TABLE IF NOT EXISTS population_data (
  city_name TEXT PRIMARY KEY,
  population INTEGER,
  latitude REAL,
  longitude REAL,
  country TEXT
)")

# Insert weather data into the 'weather_data' table
dbWriteTable(
  conn = con,
  name = "weather_data",
  value = weather_data,
  append = TRUE,
  row.names = FALSE
)

# Insert population data into the 'population_data' table
dbWriteTable(
  conn = con,
  name = "population_data",
  value = population_data,
  append = TRUE,
  row.names = FALSE
)

# Step 5: Run queries and export results

# Query 1: List cities ordered by temperature (ascending order)
temp_order_query <- dbGetQuery(con, "
SELECT city_name, temperature, observation_time
FROM weather_data
ORDER BY temperature ASC;
")

# Query 2: List cities ordered by population (ascending order), along with temperature
population_order_query <- dbGetQuery(con, "
SELECT p.city_name, p.population, w.temperature, w.observation_time
FROM population_data p
JOIN weather_data w ON p.city_name = w.city_name
ORDER BY p.population ASC;
")

# Query 3: Calculate the dew point temperature for each city
dew_point_query <- dbGetQuery(con, "
SELECT city_name, temperature, humidity, 
       (temperature - (100 - humidity) / 5) AS dew_point_temperature, observation_time
FROM weather_data;
")

# Query 4: Calculate the absolute temperature difference between cities
temp_difference_query <- dbGetQuery(con, "
SELECT w1.city_name AS city_1, w2.city_name AS city_2,
       w1.temperature AS temp_1, w2.temperature AS temp_2,
       ABS(w1.temperature - w2.temperature) AS temp_difference
FROM weather_data w1
JOIN weather_data w2 ON w1.city_name <> w2.city_name;
")

# Close the database connection after queries are run
dbDisconnect(con)

# Step 6: Save all data and query results into an Excel workbook
# Create a new workbook
workbook <- createWorkbook()

# Add a sheet and write the weather data to the 'Weather Data Table' sheet
addWorksheet(workbook, "Weather Data Table")
writeData(workbook, "Weather Data Table", weather_data)

# Add a sheet and write the population data to the 'Population Data Table' sheet
addWorksheet(workbook, "Population Data Table")
writeData(workbook, "Population Data Table", population_data)

# Add a sheet and write the first query result (Temperature order) to 'Query 1' sheet
addWorksheet(workbook, "Query 1")
writeData(workbook, "Query 1", temp_order_query)

# Add a sheet and write the second query result (Population order) to 'Query 2' sheet
addWorksheet(workbook, "Query 2")
writeData(workbook, "Query 2", population_order_query)

# Add a sheet and write the third query result (Dew point calculation) to 'Query 3' sheet
addWorksheet(workbook, "Query 3")
writeData(workbook, "Query 3", dew_point_query)

# Add a sheet and write the fourth query result (Temperature difference) to 'Query 4' sheet
addWorksheet(workbook, "Query 4")
writeData(workbook, "Query 4", temp_difference_query)

# Save the workbook as an Excel file
saveWorkbook(workbook, "IagoPuenteEsteban_assignment1_data.xlsx", overwrite = TRUE)