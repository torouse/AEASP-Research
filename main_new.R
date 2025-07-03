library(tidyverse)
library(dplyr)
library(stringr)
#Import summary statistics command
source("sumstats.R")

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

#Remove one incorrect observation in Crime dataset and treat years as numeric
filtered_crime_data <- filtered_crime_data[-1,]
df_acs$year <- sapply(df_acs$year, as.numeric)
filtered_crime_data$Year <- sapply(filtered_crime_data$Year, as.numeric)

# First, find out how many unique years you have
total_years <- n_distinct(filtered_crime_data$Year)

# Find city-state combinations that appear in all years - Crime Data
city_states_in_all_years_crime <- filtered_crime_data %>% 
  group_by(city_state) %>% 
  count() %>% 
  ungroup() %>% 
  filter(n == 9) %>% 
  pull(city_state)

# Create new table with only those city-state combinations
complete_cities_data <- filtered_crime_data %>%
  filter(city_state %in% city_states_in_all_years_crime)

# Find city-state combinations that appear in all years - ACS
city_states_in_all_years_acs <- df_acs %>% 
  group_by(city_state) %>% 
  count() %>% 
  ungroup() %>% 
  filter(n == 9) %>% 
  pull(city_state)

# Create new table with only those city-state combinations
complete_cities_data_acs <- df_acs %>%
  filter(city_state %in% city_states_in_all_years_acs)

# Get city-state combinations that exist in both datasets
common_city_states <- intersect(
  unique(complete_cities_data_acs$city_state), 
  unique(complete_cities_data$city_state)
)

# Get city-state combinations that exist in both acs dataset and unbalanced crime data

test_intersect <- intersect(
  unique(filtered_crime_data$city_state), 
  unique(complete_cities_data_acs$city_state)
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

#Created a filtered dataframe with only common city-state combinations without
#filtering out cities with missing crime data

test_crime <- filtered_crime_data %>% 
  filter(city_state %in% test_intersect)

test_acs <- complete_cities_data_acs %>%
  filter(city_state %in% test_intersect)


# Use a proper join instead of direct assignment
merged_data <- filtered_acs %>%
  left_join(filtered_crime %>% select(city_state, Year, Violent.Crime), 
            by = c("city_state" = "city_state", "year" = "Year")) %>%
  rename(violent_crime = Violent.Crime)

# Use a proper join instead of direct assignment for acs and unbalanced crime data
test_merged<- test_acs %>%
  left_join(test_crime %>% select(city_state, Year, Violent.Crime), 
            by = c("city_state" = "city_state", "year" = "Year")) %>%
  rename(violent_crime = Violent.Crime)

# Verify the join worked correctly
cat("ACS data rows:", nrow(filtered_acs), "\n")
cat("Crime data rows:", nrow(filtered_crime), "\n") 
cat("Merged data rows:", nrow(merged_data), "\n")
cat("Missing violent crime values:", sum(is.na(merged_data$violent_crime)), "\n")

grants_data <- read.csv("Data/Grants/Assistance_PrimeAwardSummaries_2025-06-25_H22M03S38_1.csv")

#Create issue year
grants_data$issue_year <- substr(grants_data$period_of_performance_start_date, 1, 4)

#filter out by 2021 issue year
grants2022 <- filter(grants_data, issue_year== 2022)

#Select necessary columns and clean city and state names
filtered_grants <- grants2022 [,c("total_funding_amount","issue_year", "recipient_city_name", "recipient_state_name","award_id_fain")]
filtered_grants <- filtered_grants %>%
  mutate(
    City_clean = str_to_title(str_trim(recipient_city_name)),
    State_clean = str_to_title(str_trim(recipient_state_name)),
    city_state = paste(City_clean, State_clean, sep = ", "),
    grant_type= substr(award_id_fain, 16, 19)
  )

#Filter out for only CVIPI grants (ALN code: 16.045)
cvipi <- filtered_grants %>% 
  filter(grant_type== "CVIP" | award_id_fain == c("15PBJA23GG05226MUMU", "15PNIJ23GG04270MUMU", "15PBJA22GG04749MUMU", "15PBJA24GG03106MUMU","15PBJA24AG00119MUMU"))

#Sum the total funding for each grant
total_cvipi <- cvipi %>% 
  select(total_funding_amount, city_state) %>% 
  aggregate(.~city_state, sum)

total_grants <- filtered_grants %>% 
  select(total_funding_amount, city_state) %>% 
  aggregate(.~city_state, sum)

grants_merged <- merged_data %>%
  left_join(filter(total_cvipi, city_state %in% common_grant_city_states), 
            by = c("city_state" = "city_state")) %>%
  rename(funding2022 = total_funding_amount)

#Filter out cities that are in both merged_data and total_cvipi and merge the two datasets
common_grant_city_states <- intersect(
  unique(total_cvipi$city_state), 
  unique(merged_data$city_state)
)

#Filter out cities that are in both test_merged and total_cvipi and merge the two datasets
test_grant <- intersect(
  unique(total_cvipi$city_state), 
  unique(test_merged$city_state)
)

test_grants_merged <- test_merged %>%
  left_join(filter(total_cvipi, city_state %in% test_grant), 
            by = c("city_state" = "city_state")) %>%
  rename(funding2022 = total_funding_amount)


#If funding2022 is NA change it to 0
grants_merged$funding2022[is.na(grants_merged$funding2022)] <- 0

test_grants_merged$funding2022[is.na(test_grants_merged$funding2022)] <- 0


#Summary Statistics from 8 treated cities using balanced crime data
filter(grants_merged, funding2022>0) %>% 
sumstats()
         
filter(grants_merged, funding2022==0) %>% 
sumstats()

#Summary statistics for 33 treated cities received from using unbalanced crime data

filter(test_grants_merged, funding2022>0) %>% 
sumstats()
         
filter(test_grants_merged, funding2022==0) %>% 
sumstats()
