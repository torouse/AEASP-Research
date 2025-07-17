library(did)
library(fixest)
library(tidyverse)
library(dplyr)
library(stringr)
library(zoo)
library(broom)
library(fixest)
library(modelsummary)
library(MatchIt)
library(gtsummary)
library(gt)
remotes::install_github("UrbanInstitute/urbnthemes", build_vignettes = TRUE)
library(urbnthemes)
set_urbn_defaults(base_size = 16)

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

# Remove one incorrect observation in Crime dataset and treat years as numeric
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

#filter out by 2022 issue year
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

# RAW MERGED DATA FOR 2022 -> test_grants_merged

# If funding2022 is NA change it to 0
test_grants_merged$funding2022[is.na(test_grants_merged$funding2022)] <- 0

## Independents variables have 1% of obs missing, so we carry backwards
### Check for NA values
columns_to_carry <- c(
  "white_alone",
  "education_universe_25plus",
  "no_schooling_completed",
  "high_school_graduate",
  "ged_alternative_credential",
  "some_college_less_than_1_year",
  "some_college_1_or_more_years",
  "associate_degree",
  "bachelor_degree",
  "income_below_poverty_level"
)

test_grants_merged %>%
  group_by(year) %>%
  summarise(across(all_of(columns_to_carry), ~ sum(is.na(.)))) %>%
  arrange(year)

## Carry Covariates
test_grants_merged <- test_grants_merged %>% 
  group_by(name) %>%                       
  arrange(year, .by_group = TRUE) %>%        
  fill(all_of(columns_to_carry),            
       .direction = "downup") %>%            
  ungroup()

### Check for NA again
test_grants_merged %>%
  group_by(year) %>%
  summarise(across(all_of(columns_to_carry), ~ sum(is.na(.)))) %>%
  arrange(year)

# Linear interpolation
## Drop NAs pre-treatment (pre-2022)
test_grants_merged <- test_grants_merged %>%
  filter(!(is.na(violent_crime) & year > 2021))

## Interpolate the rest 
test_grants_merged$violent_crime <- na.approx(test_grants_merged$violent_crime)

# Examine any remaining NAs
city_na_status <- test_grants_merged %>% 
  group_by(name) %>%                                           # one row per city
  summarise(
    any_na   = any(across(all_of(columns_to_carry), ~ is.na(.))),    # does this city still have an NA?
    treated  = any(funding2022 == 1, na.rm = TRUE),            # ever treated?
    .groups  = "drop"
  ) %>% 
  filter(any_na)                                               # keep only cities with NAs

city_na_status
## We find only 6 control cities have NAs, lets drop them
names_to_drop <- city_na_status$name

test_grants_merged <- test_grants_merged %>%
  filter(! name %in% names_to_drop)
# Check again for NAs
city_na_status <- test_grants_merged %>% 
  group_by(name) %>%                                           # one row per city
  summarise(
    any_na   = any(across(all_of(columns_to_carry), ~ is.na(.))),    # does this city still have an NA?
    treated  = any(funding2022 == 1, na.rm = TRUE),            # ever treated?
    .groups  = "drop"
  ) %>% 
  filter(any_na)

if (nrow(city_na_status) == 0) {
  message("🎉 No more NAs in the inspected columns!")
} else {
  print(city_na_status)
}

# No more NAs

## Split for outliers here later

# Rename the data for simplicity in modelling
funded2022 <- test_grants_merged

# Find name combinations that appear in all years
years_total <- n_distinct(funded2022$year)

funded2022 <- funded2022 %>% 
  group_by(name) %>% 
  filter(n_distinct(year) == years_total) %>% 
  ungroup()

# Summary statistics for 30 treated cities received from using unbalanced crime data

filter(funded2022, funding2022>0) %>% 
  sumstats()

filter(funded2022, funding2022==0) %>% 
  sumstats()

# Modelling
# Rename for simplicity
grants <- funded2022

# adjust grants per capita
grants$funding <- (grants$funding2022 / grants$total_population) * 100000

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

# Violent Crime per capita
grants_did$violent_crime_pc <- (grants_did$violent_crime / grants_did$total_population) * 100000
grants_did$log_v_crime_rate <- log((grants_did$violent_crime / grants_did$total_population) * 100000)

#Sum stats for per capita covariates
filter(grants_did, funding2022==1) %>% 
  sumstats()

filter(grants_did, funding2022==0) %>% 
  sumstats()

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

# Parallel Trends
avg <- grants_did %>% 
  group_by(year, treated) %>%                
  summarise(mean_y = mean(violent_crime_pc, na.rm = TRUE), .groups = "drop")

avglog <- grants_did %>% 
  group_by(year, treated) %>%                
  summarise(mean_y = mean(log_v_crime_rate, na.rm = TRUE), .groups = "drop")


ggplot(avg, aes(year, mean_y, colour = factor(treated))) +
  geom_line() + geom_point() +
  scale_colour_manual(values = c("0" = "grey40", "1" = "steelblue"),
                      labels  = c("Control", "Treated"),
                      name    = "") +
  labs(y = "Violent Crime per 100k")

ggplot(avglog, aes(year, mean_y, colour = factor(treated))) +
  geom_line() + geom_point() +
  scale_colour_manual(values = c("0" = "grey40", "1" = "steelblue"),
                      labels  = c("Control", "Treated"),
                      name    = "") +
  labs(y = "Violent Crime per 100k")

# Empirical Parallel Trends
pre <- grants_did %>% filter(year < 2022)

# Perform Regression 
# Per capita - Base
model_pc <- feols(violent_crime_pc ~ treated * post | name + year, cluster = ~name, data = grants_did)

# Per capita - Controls
model_pc_control <- feols(violent_crime_pc ~ treated * post + pct_white + pct_bach_degree +
                  + unemployment_rate + poverty_rate | name + year, cluster = ~name, data = grants_did)

# Controlling for grants per 100k without controls
model_pc_grant <- feols(violent_crime_pc ~ funding * post | name + year, cluster = ~name, data = grants_did)

# Controlling for grants per 100k
model_pc_control_grant <- feols(violent_crime_pc ~ funding * post + pct_white + pct_bach_degree +
                           + unemployment_rate + poverty_rate | name + year, cluster = ~name, data = grants_did)

logmodel_pc_control_grant <- feols(log_v_crime_rate ~ funding * post + pct_white + pct_bach_degree +
                                  + unemployment_rate + poverty_rate | name + year, cluster = ~name, data = grants_did)


#Create regression output table
AllControlModel1<- tbl_regression(model_pc_control_grant_psm,
                               "funding:post" ~ "Treatment Effect",
                               include = "funding:post",
                               estimate_fun = purrr::partial(style_ratio, digits = 7),
                               conf.int=F)

AllControlModel2<- tbl_regression(logmodel_pc_control_grant_psm,
                               "funding:post" ~ "Treatment Effect",
                               include = "funding:post",
                               estimate_fun = purrr::partial(style_sigfig, digits = 7),
                               conf.int= F)

AllControlModelResults <- tbl_merge(
  tbls = list(ControlModel1, ControlModel2),
  tab_spanner = c("**Crime Rate per 100k**", "**Logged Crime Rate per 100k**")) %>% 
  as_gt

gtsave(ControlModelResults, "ControlModelResults.png")

logmodel_pc_control_grant <- feols(log_v_crime_rate ~ funding * post + pct_white + pct_bach_degree +
                                  + unemployment_rate + poverty_rate | name + year, cluster = ~name, data = grants_did)

## Self contained resid plot ------------------------------------------------------------
# --- 1. Re-run the two models -------------------------------------------------
# run any new models here (outlier vs non-outlier)
# --- 2. Grab the residuals ----------------------------------------------------
#r$res_pc_control <- resid(model_pc_control)   # residuals from the raw-count model
#r$res_pc_control_grant  <- resid(model_pc_control_grant)    # residuals from the per-capita model

# --- 3. Plot residual on residual --------------------------------------------
#plot(
#  r$res_pc_control, r$res_control_grant,
#  xlab = "Residuals (raw violent_crime)",
#  ylab = "Residuals (violent_crime_pc)",
#  main = "Residual-on-Residual Plot",
#  pch  = 19, cex = 0.6
#)
#abline(lm(res_pc ~ res_raw, data = pre), lwd = 2, lty = 2)  # OLS fit
#abline(0, 1, col = "grey50")                                # 45-degree line

#--------------------------------------------------------------------------------------------------

#Rerunning everything after filtering out cities using propensity score matching

#Create a dataset with all the mean values of the key variables for all cities
grants_match <- grants_did %>% 
  group_by(name) %>%                
  summarise(violent_crime_pc = mean(violent_crime_pc, na.rm = TRUE),
            total_population = mean(total_population, na.rm = TRUE),
            pct_white = mean(pct_white, na.rm = TRUE),
            pct_bach_degree = mean(pct_bach_degree, na.rm = TRUE),
            unemployment_rate = mean(unemployment_rate, na.rm = TRUE),
            poverty_rate = mean(poverty_rate, na.rm = TRUE),
            funding2022 = mean(funding2022, na.rm = TRUE),
            .groups = "drop")

#Find two control cities for each treated city by choosing control cities that
#are most likely to be chosen to receive funding based on total population and
#present results
funding_match <- matchit(funding2022 ~ total_population + 
                                       violent_crime_pc + 
                                       pct_white +
                                       pct_bach_degree + 
                                       unemployment_rate + 
                                       poverty_rate,
                         data = grants_match, method = "nearest", distance ="glm",
                         ratio = 2,
                         replace = FALSE)

summary(funding_match)

#Compile all the names of the matched control cities into a vector
grants_did_psm_controls <- grants_match[funding_match[["match.matrix"]],]$name


#Filter out the grants_did dataset by cities that receive funding or were chosen
#as matched controls
grants_did_psm <- filter(grants_did, funding2022==1 | name %in% grants_did_psm_controls)

grants_did <- mutate(grants_did, treated = case_when(treated == 0 ~ 2))
grants_did <- filter(grants_did, treated== 2)

grants_did_final <- rbind(grants_did, grants_did_psm)

#Sum stats for per capita covariates from the PSM chosen control group
filter(grants_did_final, treated==1) %>% 
  sumstats()

filter(grants_did_final, treated==0) %>% 
  sumstats()

filter(grants_did_final, treated==2) %>% 
  sumstats()


filter(grants_did_psm, funding2022==1) %>% 
  sumstats()

filter(grants_did_psm, funding2022==0) %>% 
  sumstats()

#Create summary statistics table
grants_did_psm <- grants_did_psm %>% mutate(CVIP_funding = case_when(
  funding2022 == 0 ~ "Did Not Receive CVIP Funding",
  funding2022 == 1 ~ "Received CVIP Funding"))

grants_did_final <- grants_did_final %>% mutate(CVIP_funding = case_when(
  treated == 0 ~ "Propensity Score Matched",
  treated == 1 ~ "Received CVIP Funding",
  treated == 2 ~ "All Possible Control Cities"))

my_theme <-
  list(
    "tbl_summary-str:default_con_type" = "continuous2",
    "tbl_summary-str:continuous_stat" = c(
      "{median} ({p25} - {p75})",
      "{mean} ({sd})",
      "{min} - {max}"
    ),
   )
set_gtsummary_theme(my_theme)

SummaryStats <- group_by(grants_did_psm, CVIP_funding) %>%                
  select(funding, violent_crime_pc, total_population) %>% 
tbl_summary(
    by = CVIP_funding,
    list(
      violent_crime_pc ~ "Crime Rate per 100,000 People",
      total_population ~ "Total Population",
      funding ~ "CVIP Grant Spending per 100,000 People"),
    type = all_continuous() ~ "continuous2",
    statistic = all_continuous() ~ c(
      "{median}",
      "{mean} ({sd})")
  ) %>%
  bold_labels() %>%
  modify_header(label ~ "**Variable**") %>% 
  as_gt()

SummaryStatsFinal <- group_by(grants_did_final, CVIP_funding) %>%                
  select(funding, violent_crime_pc, total_population) %>% 
  tbl_summary(
    by = CVIP_funding,
    list(
      violent_crime_pc ~ "Crime Rate per 100,000 People",
      total_population ~ "Total Population",
      funding ~ "CVIP Grant Spending per 100,000 People"),
    type = all_continuous() ~ "continuous2",
    statistic = all_continuous() ~ c(
      "{median}",
      "{mean} ({sd})")
  ) %>%
  bold_labels() %>%
  modify_header(label ~ "**Variable**") %>% 
  as_gt()

gtsave(SummaryStats, "SummaryStatistics.png")

gtsave(SummaryStatsFinal, "FinalSummaryStatistics.png", )


# Create treatment columns for PSM chosen control group DiD regression
grants_did_psm <- grants_did_psm %>% 
  ## 1. City–level treatment status: 1 if the city ever got funding in 2022
  group_by(place_id) %>%                           
  mutate(treated = as.integer(any(funding2022 > 0))) %>% 
  ungroup() %>% 
  
  ## 2. Post-treatment dummy: 1 for years on/after 2022
  mutate(post = year >= 2022) %>% 
  
  ## 3. DiD interaction: 1 only for treated cities *and* post period
  mutate(D = treated & post)

# Parallel Trends for Violent Crim Rate DiD with PSM control group
avg_psm <- grants_did_psm %>% 
  group_by(year, treated) %>%                
  summarise(mean_y = mean(violent_crime_pc, na.rm = TRUE), .groups = "drop")

ParallelTrendsPlot <- ggplot(avg_psm, aes(year, mean_y, colour = factor(treated))) +
  geom_line() + geom_point() +
  scale_colour_manual(values = c("0" = "grey40", "1" = "gold"),
                      labels  = c("Control", "Treated"),
                      name    = "") +
  labs(y = "Violent Crime per 100k", x= "Year")

ggsave(filename = "ParallelTrendsPlot.png", plot = ParallelTrendsPlot, height = 3.5, width = 4)

avg_final <- grants_did_final %>% 
  group_by(year, treated) %>%                
  summarise(mean_y = mean(violent_crime_pc, na.rm = TRUE), .groups = "drop")

FinalParallelTrendsPlot <- ggplot(avg_final, aes(year, mean_y, colour = factor(treated))) +
  geom_line() + geom_point() +
  scale_colour_manual(values = c("0" = "grey40", "1" = "gold", "2" = "black"),
                      labels  = c("Propensity Score Matched", 
                                  "Treated", 
                                  "All Possible Control Cities"),
                      name    = "") +
  labs(y = "Violent Crime per 100k", x= "Year")

ggsave(filename = "FinalParallelTrendsPlot.png", plot = FinalParallelTrendsPlot, height = 3, width = 6.5)


# Parallel Trends for Logged Violent Crime RateDiD with PSM control group

logavg_psm <- grants_did_psm %>% 
  group_by(year, treated) %>%                
  summarise(mean_y = mean(log_v_crime_rate, na.rm = TRUE), .groups = "drop")

LogParallelTrendsPlot <- ggplot(logavg_psm, aes(year, mean_y, colour = factor(treated))) +
  geom_line() + geom_point() +
  scale_colour_manual(values = c("0" = "grey40", "1" = "gold"),
                      labels  = c("Control", "Treated"),
                      name    = "") +
  labs(y = "Logged Violent Crime per 100k", x= "Year")

ggsave(filename = "LogParallelTrendsPlot.png", plot = LogParallelTrendsPlot, height = 3.5, width = 4)

logavg_final <- grants_did_final %>% 
  group_by(year, treated) %>%                
  summarise(mean_y = mean(log_v_crime_rate, na.rm = TRUE), .groups = "drop")

FinalLogParallelTrendsPlot <- ggplot(logavg_final, aes(year, mean_y, colour = factor(treated))) +
  geom_line() + geom_point() +
  scale_colour_manual(values = c("0" = "grey40", "1" = "gold", "2" = "black"),
                      labels  = c("Propensity Score Matched", 
                                  "Treated", 
                                  "All Possible COntrol Cities"),
                      name    = "") +
  labs(y = "Violent Crime per 100k", x= "Year")

ggsave(filename = "FinalLogParallelTrendsPlot.png", plot = FinalLogParallelTrendsPlot, height = 3.5, width = 6)


# Perform Regressions with PSM chosen control group
# Per capita - Base
model_pc_psm <- feols(violent_crime_pc ~ treated * post | name + year, cluster = ~name, data = grants_did_psm)

# Per capita - Controls
model_pc_control_psm <- feols(violent_crime_pc ~ treated * post + pct_white + pct_bach_degree +
                                + unemployment_rate + poverty_rate | name + year, cluster = ~name, data = grants_did_psm)


# OPTIMAL MODELS
#Controlling for grants per 100k without using controls
model_pc_grant_psm <- feols(violent_crime_pc ~ funding * post | name + year, cluster = ~name, data = grants_did_psm)

#Regressing log crime rate and controlling for grants per 100k without using controls
logmodel_pc_grant_psm <- feols(log_v_crime_rate ~ funding * post | name + year, cluster = ~name, data = grants_did_psm)

#Create regression output table
Model1<- tbl_regression(model_pc_grant_psm,
                        include = "funding:post",
                        estimate_fun = purrr::partial(style_ratio, digits = 9)) %>% 
  modify_column_hide(c(conf.low, conf.high)) 

Model2<- tbl_regression(logmodel_pc_grant_psm,
                        include = "funding:post",
                        estimate_fun = purrr::partial(style_ratio, digits = 9)) %>% 
  modify_column_hide(c(conf.low, conf.high)) 

ModelResults <- tbl_merge(
  tbls = list(Model1, Model2),
  tab_spanner = c("**Crime Rate per 100k**", "**Logged Crime Rate per 100k**")) %>% 
  as_gt

gtsave(ModelResults, "ModelResults.png")

# Controlling for grants per 100k with controls
model_pc_control_grant_psm <- feols(violent_crime_pc ~ funding * post + pct_white + pct_bach_degree +
                                      + unemployment_rate + poverty_rate | name + year, cluster = ~name, data = grants_did_psm)

#Regressing log crime rate and controlling for grants per 100k with controls
logmodel_pc_control_grant_psm <- feols(log_v_crime_rate ~ funding * post + pct_white + pct_bach_degree +
                                         + unemployment_rate + poverty_rate | name + year, cluster = ~name, data = grants_did_psm)


#Create regression output table
ControlModel1<- tbl_regression(model_pc_control_grant_psm,
                        "funding:post" ~ "Treatment Effect",
                        include = "funding:post",
                        estimate_fun = purrr::partial(style_ratio, digits = 7),
                        conf.int=F)

ControlModel2<- tbl_regression(logmodel_pc_control_grant_psm,
                        "funding:post" ~ "Treatment Effect",
                        include = "funding:post",
                        estimate_fun = purrr::partial(style_sigfig, digits = 7),
                        conf.int= F)

ControlModelResults <- tbl_merge(
  tbls = list(ControlModel1, ControlModel2),
  tab_spanner = c("**Crime Rate per 100k**", "**Logged Crime Rate per 100k**")) %>% 
  as_gt

gtsave(ControlModelResults, "ControlModelResults.png")

#Create regression output table
FinalModel1<- tbl_regression(model_pc_control_grant_psm,
                               "funding:post" ~ "Treatment Effect",
                               include = "funding:post",
                               estimate_fun = purrr::partial(style_ratio, digits = 7),
                               conf.int=F)

FinalModel2<- tbl_regression(model_pc_control_grant,
                               "funding:post" ~ "Treatment Effect",
                               include = "funding:post",
                               estimate_fun = purrr::partial(style_sigfig, digits = 7),
                               conf.int= F)

FinalModelResults <- tbl_merge(
  tbls = list(FinalModel1, FinalModel2),
  tab_spanner = c("**Propensity Score Matched**", "**All Possible Control Cities**")) %>% 
  as_gt

gtsave(FinalModelResults, "FinalModelResults.png")


# No fixed effects controls
model_pc_control_nofixed_psm <- feols(violent_crime_pc ~ funding * post + pct_white + pct_bach_degree +
                                        + unemployment_rate + poverty_rate, cluster = ~name, data = grants_did_psm)

#--------------------------------------------------------------------------------------------------

#filter control group for violent crime rates less than 3600 and greater than 500

grants_did_crime_controlled <- filter(grants_did, funding2022==1 | violent_crime_pc > 500 & violent_crime_pc < 3600)

crime_controlled_full_cities <- grants_did_crime_controlled %>% 
  group_by(name) %>% 
  count() %>% 
  ungroup() %>% 
  filter(n == 9) %>% 
  pull(name)

grants_did_crime_controlled <- grants_did_crime_controlled %>%
  filter(name %in% crime_controlled_full_cities)

#Sum stats for per capita covariates and crime filtered control group
filter(grants_did_crime_controlled, funding2022==1) %>% 
  sumstats()

filter(grants_did_crime_controlled, funding2022==0) %>% 
  sumstats()

# Create treatment columns for crime controlled DiD regression
grants_did_crime_controlled <- grants_did_crime_controlled %>% 
  ## 1. City–level treatment status: 1 if the city ever got funding in 2022
  group_by(place_id) %>%                           
  mutate(treated = as.integer(any(funding2022 > 0))) %>% 
  ungroup() %>% 
  
  ## 2. Post-treatment dummy: 1 for years on/after 2022
  mutate(post = year >= 2022) %>% 
  
  ## 3. DiD interaction: 1 only for treated cities *and* post period
  mutate(D = treated & post)

# Parallel Trends for crime controlled DiD
avg_crime_controleld <- grants_did_crime_controlled %>% 
  group_by(year, treated) %>%                
  summarise(mean_y = mean(violent_crime_pc, na.rm = TRUE), .groups = "drop")

ggplot(avg_crime_controleld, aes(year, mean_y, colour = factor(treated))) +
  geom_line() + geom_point() +
  scale_colour_manual(values = c("0" = "grey40", "1" = "steelblue"),
                      labels  = c("Control", "Treated"),
                      name    = "") +
  labs(y = "Violent Crime per 100k")

# Perform Crime controlled Regressions
# Per capita - Base
model_pc_crime_controlled <- feols(violent_crime_pc ~ treated * post | name + year, cluster = ~name, data = grants_did_crime_controlled)

# Per capita - Controls
model_pc_control_crime_controlled <- feols(violent_crime_pc ~ treated * post + pct_white + pct_bach_degree +
                            + unemployment_rate + poverty_rate | name + year, cluster = ~name, data = grants_did_crime_controlled)

# Controlling for grants per 100k
model_pc_control_grant_crime_controlled <- feols(violent_crime_pc ~ funding * post + pct_white + pct_bach_degree +
                                  + unemployment_rate + poverty_rate | name + year, cluster = ~name, data = grants_did_crime_controlled)

# No fixed effects controls
model_pc_control_nofixed_crime_controlled <- feols(violent_crime_pc ~ funding * post + pct_white + pct_bach_degree +
                                                   + unemployment_rate + poverty_rate, cluster = ~name, data = grants_did_crime_controlled)

#--------------------------------------------------------------------------------------------------

#Rerunning everything after filtering out by cities with population greater than 375000
grants_did_pop_con <- filter(grants_did, funding2022==1 | total_population > 375000)

pop_con_full_cities <- grants_did_pop_con %>% 
  group_by(name) %>% 
  count() %>% 
  ungroup() %>% 
  filter(n == 9) %>% 
  pull(name)

grants_did_pop_con <- grants_did_pop_con %>%
  filter(name %in% pop_con_full_cities)

#Sum stats for per capita covariates and crime filtered control group
filter(grants_did_pop_con, funding2022==1) %>% 
  sumstats()

filter(grants_did_pop_con, funding2022==0) %>% 
  sumstats()

# Create treatment columns for crime controlled DiD regression
grants_did_pop_con <- grants_did_pop_con %>% 
  ## 1. City–level treatment status: 1 if the city ever got funding in 2022
  group_by(place_id) %>%                           
  mutate(treated = as.integer(any(funding2022 > 0))) %>% 
  ungroup() %>% 
  
  ## 2. Post-treatment dummy: 1 for years on/after 2022
  mutate(post = year >= 2022) %>% 
  
  ## 3. DiD interaction: 1 only for treated cities *and* post period
  mutate(D = treated & post)

# Parallel Trends for crime controlled DiD
avg_pop_con <- grants_did_pop_con %>% 
  group_by(year, treated) %>%                
  summarise(mean_y = mean(violent_crime_pc, na.rm = TRUE), .groups = "drop")


ggplot(avg_pop_con, aes(year, mean_y, colour = factor(treated))) +
  geom_line() + geom_point() +
  scale_colour_manual(values = c("0" = "grey40", "1" = "steelblue"),
                      labels  = c("Control", "Treated"),
                      name    = "") +
  labs(y = "Violent Crime per 100k")

logavg_pop_con <- grants_did_pop_con %>% 
  group_by(year, treated) %>%                
  summarise(mean_y = mean(log_v_crime_rate, na.rm = TRUE), .groups = "drop")

ggplot(logavg_pop_con, aes(year, mean_y, colour = factor(treated))) +
  geom_line() + geom_point() +
  scale_colour_manual(values = c("0" = "grey40", "1" = "steelblue"),
                      labels  = c("Control", "Treated"),
                      name    = "") +
  labs(y = "Violent Crime per 100k")


# Perform Crime controlled Regressions
# Per capita - Base
model_pc_pop_con <- feols(violent_crime_pc ~ treated * post | name + year, cluster = ~name, data = grants_did_pop_con)

# Per capita - Controls
model_pc_control_pop_con <- feols(violent_crime_pc ~ treated * post + pct_white + pct_bach_degree +
                                             + unemployment_rate + poverty_rate | name + year, cluster = ~name, data = grants_did_pop_con)

# Controlling for grants per 100k
model_pc_grant_pop_con <- feols(violent_crime_pc ~ funding * post | name + year, cluster = ~name, data = grants_did_pop_con)

logmodel_pc_grant_pop_con <- feols(log_v_crime_rate ~ funding * post | name + year, cluster = ~name, data = grants_did_pop_con)

# Controlling for grants per 100k
model_pc_control_grant_pop_con <- feols(violent_crime_pc ~ funding * post + pct_white + pct_bach_degree +
                                                   + unemployment_rate + poverty_rate | name + year, cluster = ~name, data = grants_did_pop_con)

logmodel_pc_control_grant_pop_con <- feols(log_v_crime_rate ~ funding * post + pct_white + pct_bach_degree +
                                          + unemployment_rate + poverty_rate | name + year, cluster = ~name, data = grants_did_pop_con)

# No fixed effects controls
model_pc_control_nofixed_pop_con <- feols(violent_crime_pc ~ funding * post + pct_white + pct_bach_degree +
                                                     + unemployment_rate + poverty_rate, cluster = ~name, data = grants_did_pop_con)

