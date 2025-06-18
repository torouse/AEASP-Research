library(tidyverse)
library(dplyr)
library(stringr)

crime_data <- read.csv("Data/ACS/crime_to_check.csv")
df_acs <- read.csv("Data/ACS/ready_to_merge.csv")

# Remove the fbi notes that got pulled in
filtered_crime_data <- crime_data %>%
  filter(!grepl("^9", State))

# Remove cities before 2014
filtered_crime_data <- filtered_crime_data %>%
  filter(!Year %in% c(2012, 2013))

# Standardize city and state names before creating identifiers
filtered_crime_data <- filtered_crime_data %>%
  mutate(
    City_clean = str_to_title(str_trim(City)),
    State_clean = str_to_title(str_trim(State)),
    city_state = paste(City_clean, State_clean, sep = ", ")
  )

df_acs <- df_acs %>%
  mutate(
    city_name_clean = str_to_title(str_trim(city_name)),
    state_name_clean = str_to_title(str_trim(state_name)),
    city_state = paste(city_name_clean, state_name_clean, sep = ", ")
  )

# Diagnostic: Check some examples from each dataset
cat("Sample crime city-states:\n")
print(head(unique(filtered_crime_data$city_state), 10))
cat("\nSample ACS city-states:\n") 
print(head(unique(df_acs$city_state), 10))
cat("\nTotal unique city-states in crime data:", length(unique(filtered_crime_data$city_state)))
cat("\nTotal unique city-states in ACS data:", length(unique(df_acs$city_state)))

# First, find out how many unique years you have
total_years <- n_distinct(filtered_crime_data$Year)

# Find city-state combinations that appear in all years - Crime Data
city_states_in_all_years_crime <- filtered_crime_data %>%
  group_by(city_state) %>%
  summarise(years_present = n_distinct(Year)) %>%
  filter(years_present == total_years) %>%
  pull(city_state)

# Create new table with only those city-state combinations
complete_cities_data <- filtered_crime_data %>%
  filter(city_state %in% city_states_in_all_years_crime)

# Find city-state combinations that appear in all years - ACS
city_states_in_all_years_acs <- df_acs %>%
  group_by(city_state) %>%
  summarise(years_present = n_distinct(year)) %>%
  filter(years_present == total_years) %>%
  pull(city_state)

# Create new table with only those city-state combinations
complete_cities_data_acs <- df_acs %>%
  filter(city_state %in% city_states_in_all_years_acs)

# Get city-state combinations that exist in both datasets
common_city_states <- intersect(
  unique(complete_cities_data_acs$city_state), 
  unique(complete_cities_data$city_state)
)

cat("\nNumber of common city-states:", length(common_city_states))
if(length(common_city_states) > 0) {
  cat("\nFirst few common city-states:\n")
  print(head(common_city_states, 10))
} else {
  cat("\nNo matches found. Let's investigate...")
  # Check for partial matches
  crime_cities <- unique(complete_cities_data$city_state)
  acs_cities <- unique(complete_cities_data_acs$city_state)
  
  cat("\nSample from crime data after filtering:\n")
  print(head(crime_cities, 5))
  cat("\nSample from ACS data after filtering:\n")
  print(head(acs_cities, 5))
  
  # Check if there are any cities in common (ignoring state)
  crime_city_names <- unique(complete_cities_data$City_clean)
  acs_city_names <- unique(complete_cities_data_acs$city_name_clean)
  common_city_names <- intersect(crime_city_names, acs_city_names)
  cat("\nCommon city names (ignoring state):", length(common_city_names))
}

# Create filtered dataframes with only common city-state combinations
filtered_acs <- complete_cities_data_acs %>%
  filter(city_state %in% common_city_states)

filtered_crime <- complete_cities_data %>%
  filter(city_state %in% common_city_states)

# Use a proper join instead of direct assignment
merged_data <- filtered_acs %>%
  left_join(filtered_crime %>% select(city_state, Year, Violent.Crime), 
            by = c("city_state" = "city_state", "year" = "Year")) %>%
  rename(violent_crime = Violent.Crime)

# Verify the join worked correctly
cat("ACS data rows:", nrow(filtered_acs), "\n")
cat("Crime data rows:", nrow(filtered_crime), "\n") 
cat("Merged data rows:", nrow(merged_data), "\n")
cat("Missing violent crime values:", sum(is.na(merged_data$violent_crime)), "\n")