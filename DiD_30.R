library(did)
library(fixest)
library(tidyverse)
library(dplyr)
library(stringr)
library(zoo)

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

test_grants_merged$funding2022[is.na(test_grants_merged$funding2022)] <- 0

#interpolate violent crime data

grants_interpolated <- test_grants_merged

grants_interpolated$violent_crime <- na.approx(test_grants_merged$violent_crime)

#Filters out total population outliers

grants_no_outliers <- filter(grants_interpolated, total_population < 2500000) %>% 
                      filter(funding2022>0 | total_population > 275000)

# Find name combinations that appear in all years
grants_no_outliers_fullyears <- grants_no_outliers %>% 
  group_by(name) %>% 
  count() %>% 
  ungroup() %>% 
  filter(n == 9) %>% 
  pull(name)

# Create new table with only those name combinations that appear in all years
grants_no_outliers <- grants_no_outliers %>%
  filter(name %in% grants_no_outliers_fullyears)

#Summary statistics for 30 treated cities received from using unbalanced crime data

filter(grants_no_outliers, funding2022>0) %>% 
  sumstats()

filter(grants_no_outliers, funding2022==0) %>% 
  sumstats()

# Modelling
# Rename for simplicity
grants <- filter(grants_no_outliers, year != 2021)

# Switch grant $ to binary
grants$funding2022 <- ifelse(grants$funding2022 >0, 1, 0)

# Transform Control Variables
grants_did <- grants %>% 
  mutate(
    ## Demographics ---------------------------------------------------------
    pct_white           = white_alone            / total_population,   # share White
    pct_bach_degree     = bachelor_degree        / education_universe_25plus,
    pct_associate       = associate_degree       / education_universe_25plus,
    pct_no_schooling    = no_schooling_completed / education_universe_25plus,
    
    ## Labour force ---------------------------------------------------------
    unemployment_rate   = civilian_unemployed    / civilian_labor_force_16plus,
    labor_force_part    = civilian_labor_force_16plus / total_population,
    
    ## Poverty --------------------------------------------------------------
    poverty_rate        = income_below_poverty_level / total_population)

# Create treatment columns for DiD regression
grants_did <- grants_did %>% 
  ## 1. City–level treatment status: 1 if the city ever got funding in 2022
  group_by(place_id) %>%                           
  mutate(treated = as.integer(any(funding2022 > 0))) %>% 
  ungroup() %>% 
  
  ## 2. Post-treatment dummy: 1 for years on/after 2022
  mutate(post = year >= 2022) %>% 
  
  ## 3. DiD interaction: 1 only for treated cities *and* post period
  mutate(D = treated & post)

# Regular Model
did_2022 <- lm(violent_crime ~ treated * post + factor(name) + factor(year),
   data = grants_did)

did_2022_fe <- did_2022_control_fe <- feols(violent_crime ~ treated * post | name + year, cluster = ~name, data = grants_did)

# Controlled Model
did_2022_control <- lm(violent_crime ~ treated * post + pct_white + pct_bach_degree +
  unemployment_rate + poverty_rate + factor(name) + factor(year), data = grants_did)

# Controlled Model with fixest library (cleaner output same exact model)
did_2022_control_fe <- feols(violent_crime ~ treated * post + pct_white + pct_bach_degree +
                  + unemployment_rate + poverty_rate |
                  name + year,
                cluster = ~name,
                data = grants_did)

# Get treatment Effects
## Regular
Reg_coefs <- summary(did_2022)$coefficients
Reg_coefs[grep("treated:post", rownames(Reg_coefs)), ]
## Controlled Model
Con_coefs <- summary(did_2022_control)$coefficients
Con_coefs[grep("treated:post", rownames(Con_coefs)), ]

# Parallel Trends
avg <- grants_did %>% 
  group_by(year, treated) %>%                
  summarise(mean_y = mean(violent_crime, na.rm = TRUE), .groups = "drop")

ggplot(avg, aes(year, mean_y, colour = factor(treated))) +
  geom_line() + geom_point() +
  scale_colour_manual(values = c("0" = "grey40", "1" = "steelblue"),
                      labels  = c("Control", "Treated"),
                      name    = "") +
  labs(y = "Mean violent‐crime rate")

# Empirical Parallel Trends
pre <- grants_did %>% filter(year < 2022)

summary(
  lm(violent_crime ~ treated * year + factor(place_id) + factor(year), data = pre)
)

