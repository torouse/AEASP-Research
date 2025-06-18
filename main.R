library(tidyverse)
library(dplyr)

crime_data <- read.csv("/Users/jaydenrivera/Documents/Documents - Jayden’s MacBook Air/1. Projects/research/AEASP-Research/Data/ACS/crime_to_check.csv")
df_acs <- read.csv("/Users/jaydenrivera/Documents/Documents - Jayden’s MacBook Air/1. Projects/research/AEASP-Research/Data/ACS/ready_to_merge.csv")

# Remove the fbi notes that got pulled in
# The "^" symbol in "^9" means "start of the string"
filtered_crime_data <- crime_data %>%
  filter(!grepl("^9", State))

cities_per_year <- filtered_crime_data %>%
  group_by(Year) %>%
  summarise(num_cities = n_distinct(City))

# Remove cities before 2014
filtered_crime_data <- filtered_crime_data %>%
  filter(!Year %in% c(2012, 2013))

# First, find out how many unique years you have
total_years <- n_distinct(filtered_crime_data$Year)

# Find cities that appear in all years - Violent Crime
cities_in_all_years <- filtered_crime_data %>%
  group_by(City) %>%
  summarise(years_present = n_distinct(Year)) %>%
  filter(years_present == total_years) %>%
  pull(City)

# Create new table with only those cities
complete_cities_data <- filtered_crime_data %>%
  filter(City %in% cities_in_all_years)

# Find cities that appear in all years - ACS
cities_in_all_years_acs <- df_acs %>%
  group_by(city_name) %>%
  summarise(years_present = n_distinct(year)) %>%
  filter(years_present == total_years) %>%
  pull(city_name)

# Create new table with only those cities
complete_cities_data_acs <- df_acs %>%
  filter(city_name %in% cities_in_all_years_acs)

# Get cities that exist in both
common_cities <- intersect(
  unique(complete_cities_data_acs$city_name), 
  unique(complete_cities_data$City)
)

# Create filtered dataframes with only common cities
filtered_acs <- complete_cities_data_acs[complete_cities_data_acs$city_name %in% common_cities, ]
filtered_crime <- complete_cities_data[complete_cities_data$City %in% common_cities, ]

# Move the crime data over
filtered_acs$violent_crime <- filtered_crime$Violent.Crime

