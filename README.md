# Master's Assignment 1: Weather and Population Data Analysis

## Description

This project retrieves, processes, and analyzes real-time weather and population data for a predefined list of European cities. It leverages public APIs to gather current temperature, humidity, wind speed, weather descriptions, and population statistics, organizing the information in a structured SQLite database and exporting results into an Excel workbook.

## Technologies & Tools

- **R Programming Language**
- **APIs**:
  - Weatherstack (Weather data)
  - Api-Ninjas (Population data)
- **Packages Used**:
  - `httr` (API requests)
  - `jsonlite` (JSON parsing)
  - `tidyverse` (Data manipulation)
  - `RSQLite` (Database management)
  - `openxlsx` (Excel workbook management)

## Data Sources

- **Weatherstack API**: Provides real-time weather data.
- **Api-Ninjas API**: Provides population statistics.

## Cities Analyzed

- London
- Paris
- Berlin
- Amsterdam
- Madrid
- Rome
- Athens
- Istanbul
- Lisbon
- Kyiv

## Project Workflow

### 1. Data Retrieval

- Weather data is fetched using Weatherstack API.
- Population data is fetched using Api-Ninjas API.

### 2. Data Storage

- SQLite database created with two tables:
  - `weather_data` (city name, temperature, humidity, wind speed, weather description, observation time)
  - `population_data` (city name, population, latitude, longitude, country)

### 3. Analysis and Queries

Four queries performed on the collected data:

- **Query 1:** Cities ordered by ascending temperature.
- **Query 2:** Cities ordered by ascending population, including temperatures.
- **Query 3:** Calculation of dew point temperature.
- **Query 4:** Absolute temperature differences between pairs of cities.

### 4. Exporting Results

- Results and data tables exported into an Excel workbook (`IagoPuenteEsteban_assignment1_data.xlsx`) with separate worksheets for each dataset and query result.

## Files

- `IagoPuenteEsteban_assignment1.R`: The R script used for data retrieval, processing, analysis, and export.
- `IagoPuenteEsteban_assignment1_data.xlsx`: The Excel workbook containing the results of the data analysis and queries.

## Usage

- Install necessary packages (`httr`, `jsonlite`, `tidyverse`, `RSQLite`, `openxlsx`).
- Ensure API keys for Weatherstack and Api-Ninjas are available.
- Run the R script to perform data collection, analysis, and export the final Excel file.

## Author

- **Iago Puente Esteban**
- Contact: iago.puente@gmail.com
