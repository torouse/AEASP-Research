source("C:/Users/gymto/OneDrive/Documents/NCAT/Fall 2024/ECON 290/sumstats.R")
source("C:/Users/gymto/OneDrive/Documents/NCAT/Fall 2024/ECON 290/packages.R")
source("C:/Users/gymto/OneDrive/Documents/Downloads/ipak.R")

ipak(c('dplyr'))
packages("tidyverse")
packages("gridExtra")
packages("remotes")
remotes::install_github("UrbanInstitute/urbnthemes", build_vignettes = TRUE)
library(urbnthemes)

#Step 1: Read in 2012 poverty data
P12  <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Poverty/ACSST5Y2012.S1701-Data.csv")

#Define what columns to use
columns <- c(1,2,3,5,7,51,53,55,57,59,61,111,117,123,129, 135, 141, 159)

#Step 2: Select and renamed necessary columns
P12 <- P12[columns]
colnames(P12) <- c("GEO_ID",
                   "Name",
                   "Total_Pop",
                   "Total_BelowPov",
                   "Total_BelowPovPer", 
                   "White_Pop",
                   "White_BelowPov",
                   "White_BelowPovPer",
                   "Black_Pop",
                   "Black_BelowPov",
                   "Black_BelowPovPer",
                   "<HS_Pop",
                   "HS_Pop",
                   "SomeCollege_Pop",
                   ">Bachelor_Pop",
                   "LaborForce_Pop",
                   "Employed_Pop",
                   "Unemployed_Pop")

#Step 3: Remove previous column names from the data
P12 <- subset(P12, GEO_ID != "Geography")

#Step 4: Treat data as numerical
P12[,3:18] <- sapply(P12[,3:18], as.numeric)

#Step 5: Adds year column
P12$Year <- 2012

#Repeat steps 1-5 for 20XX poverty data
P13  <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Poverty/ACSST5Y2013.S1701-Data.csv")
P13 <- P13[columns]
colnames(P13) <- c("GEO_ID","Name","Total_Pop","Total_BelowPov","Total_BelowPovPer","White_Pop", "White_BelowPov", "White_BelowPovPer", "Black_Pop", "Black_BelowPov", "Black_BelowPovPer", "<HS_Pop", "HS_Pop", "SomeCollege_Pop", ">Bachelor_Pop", "LaborForce_Pop", "Employed_Pop", "Unemployed_Pop")
P13 <- subset(P13, GEO_ID != "Geography")
P13[,3:18] <- sapply(P13[,3:18], as.numeric)
P13$Year <- 2013

P14  <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Poverty/ACSST5Y2014.S1701-Data.csv")
P14 <- P14[columns]
colnames(P14) <- c("GEO_ID","Name","Total_Pop","Total_BelowPov","Total_BelowPovPer","White_Pop", "White_BelowPov", "White_BelowPovPer", "Black_Pop", "Black_BelowPov", "Black_BelowPovPer", "<HS_Pop", "HS_Pop", "SomeCollege_Pop", ">Bachelor_Pop", "LaborForce_Pop", "Employed_Pop", "Unemployed_Pop")
P14 <- subset(P14, GEO_ID != "Geography")
P14[,3: 18] <- sapply(P14[,3: 18], as.numeric)
P14$Year <- 2014

#Fix employment variables

P15  <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Poverty/ACSST5Y2015.S1701-Data.csv")
P15 <- P15[c(1,2,3,5,7,75,77,79,81,83,85,135,141,147,153, 159, 165, 183)]
colnames(P15) <- c("GEO_ID","Name","Total_Pop","Total_BelowPov","Total_BelowPovPer","White_Pop", "White_BelowPov", "White_BelowPovPer", "Black_Pop", "Black_BelowPov", "Black_BelowPovPer", "<HS_Pop", "HS_Pop", "SomeCollege_Pop", ">Bachelor_Pop", "LaborForce_Pop", "Employed_Pop", "Unemployed_Pop")
P15 <- subset(P15, GEO_ID != "Geography")
P15[,3: 18] <- sapply(P15[,3: 18], as.numeric)
P15$Year <- 2015

P16  <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Poverty/ACSST5Y2016.S1701-Data.csv")
P16 <- P16[c(1,2,3,5,7,75,77,79,81,83,85,135,141,147,153, 159, 165, 183)]
colnames(P16) <- c("GEO_ID","Name","Total_Pop","Total_BelowPov","Total_BelowPovPer","White_Pop", "White_BelowPov", "White_BelowPovPer", "Black_Pop", "Black_BelowPov", "Black_BelowPovPer", "<HS_Pop", "HS_Pop", "SomeCollege_Pop", ">Bachelor_Pop", "LaborForce_Pop", "Employed_Pop", "Unemployed_Pop")
P16 <- subset(P16, GEO_ID != "Geography")
P16[,3: 18] <- sapply(P16[,3: 18], as.numeric)
P16$Year <- 2016

#Need to correct P17-23 because there are different variables than P12-17

P17  <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Poverty/ACSST5Y2017.S1701-Data.csv")
P17 <- P17[c(1,2,3,27,29,47,49,51,53,55,57,63,125,149,151,247,271,273)]
colnames(P17) <- c("GEO_ID","Name","Total_Pop","White_Pop", "Black_Pop","<HS_Pop", "HS_Pop", "SomeCollege_Pop", ">Bachelor_Pop","LaborForce_Pop", "Employed_Pop", "Unemployed_Pop", "Total_BelowPov","White_BelowPov","Black_BelowPov","Total_BelowPovPer","White_BelowPovPer","Black_BelowPovPer")
P17 <- subset(P17, GEO_ID != "Geography")
P17[,3:18] <- sapply(P17[,3:18], as.numeric)
P17$Year <- 2017

P18  <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Poverty/ACSST5Y2018.S1701-Data.csv")
P18 <- P18[c(1,2,3,27,29,47,49,51,53,55,57,63, 125, 127, 173, 175, 177, 179)]
colnames(P18) <- c("GEO_ID","Name","Total_Pop","White_Pop", "Black_Pop","<HS_Pop", "HS_Pop", "SomeCollege_Pop", ">Bachelor_Pop","LaborForce_Pop", "Employed_Pop", "Unemployed_Pop", "Total_BelowPov","Total_BelowPovPer","White_BelowPov","White_BelowPovPer","Black_BelowPov","Black_BelowPovPer")
P18 <- subset(P18, GEO_ID != "Geography")
P18[,3:18] <- sapply(P18[,3:18], as.numeric)
P18$Year <- 2018

P19  <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Poverty/ACSST5Y2019.S1701-Data.csv")
P19 <- P19[c(1,2,3,27,29,47,49,51,53,55,57,63,125,149,151,247,271,273)]
colnames(P19) <- c("GEO_ID","Name","Total_Pop","White_Pop", "Black_Pop","<HS_Pop", "HS_Pop", "SomeCollege_Pop", ">Bachelor_Pop","LaborForce_Pop", "Employed_Pop", "Unemployed_Pop", "Total_BelowPov","White_BelowPov","Black_BelowPov","Total_BelowPovPer","White_BelowPovPer","Black_BelowPovPer")
P19 <- subset(P19, GEO_ID != "Geography")
P19[,3:18] <- sapply(P19[,3:18], as.numeric)
P19$Year <- 2019

P20  <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Poverty/ACSST5Y2020.S1701-Data.csv")
P20 <- P20[c(1,2,3,27,29,47,49,51,53,55,57,63,125,149,151,247,271,273)]
colnames(P20) <- c("GEO_ID","Name","Total_Pop","White_Pop", "Black_Pop","<HS_Pop", "HS_Pop", "SomeCollege_Pop", ">Bachelor_Pop","LaborForce_Pop", "Employed_Pop", "Unemployed_Pop", "Total_BelowPov","White_BelowPov","Black_BelowPov","Total_BelowPovPer","White_BelowPovPer","Black_BelowPovPer")
P20 <- subset(P20, GEO_ID != "Geography")
P20[,3:18] <- sapply(P20[,3:18], as.numeric)
P20$Year <- 2020

#Edit 2021-23

P21  <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Poverty/ACSST5Y2021.S1701-Data.csv")
P21 <- P21[c(1,2,3,27,29,47,49,51,53,55,57,63,127,151,153,251,275,277)]
colnames(P21) <- c("GEO_ID","Name","Total_Pop","White_Pop", "Black_Pop","<HS_Pop", "HS_Pop", "SomeCollege_Pop", ">Bachelor_Pop","LaborForce_Pop", "Employed_Pop", "Unemployed_Pop", "Total_BelowPov","White_BelowPov","Black_BelowPov","Total_BelowPovPer","White_BelowPovPer","Black_BelowPovPer")
P21 <- subset(P21, GEO_ID != "Geography")
P21[,3:18] <- sapply(P21[,3:18], as.numeric)
P21$Year <- 2021

P22  <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Poverty/ACSST5Y2022.S1701-Data.csv")
P22 <- P22[c(1,2,3,27,29,47,49,51,53,55,57,63,127,151,153,251,275,277)]
colnames(P22) <- c("GEO_ID","Name","Total_Pop","White_Pop", "Black_Pop","<HS_Pop", "HS_Pop", "SomeCollege_Pop", ">Bachelor_Pop","LaborForce_Pop", "Employed_Pop", "Unemployed_Pop", "Total_BelowPov","White_BelowPov","Black_BelowPov","Total_BelowPovPer","White_BelowPovPer","Black_BelowPovPer")
P22 <- subset(P22, GEO_ID != "Geography")
P22[,3:18] <- sapply(P22[,3:18], as.numeric)
P22$Year <- 2022

P23  <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Poverty/ACSST5Y2023.S1701-Data.csv")
P23 <- P23[c(1,2,3,27,29,47,49,51,53,55,57,63,127,151,153,251,275,277)]
colnames(P23) <- c("GEO_ID","Name","Total_Pop","White_Pop", "Black_Pop","<HS_Pop", "HS_Pop", "SomeCollege_Pop", ">Bachelor_Pop","LaborForce_Pop", "Employed_Pop", "Unemployed_Pop", "Total_BelowPov","White_BelowPov","Black_BelowPov","Total_BelowPovPer","White_BelowPovPer","Black_BelowPovPer")
P23 <- subset(P23, GEO_ID != "Geography")
P23[,3:18] <- sapply(P23[,3:18], as.numeric)
P23$Year <- 2023

#Step 1: Read in median income data
IMed12 <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Income/ACSST5Y2012.S1903-Data.csv")

#Step 2: Select necessary columns
IMed12 <- IMed12[c(1, 5, 9, 13)]

#Step 3: Rename column headers
colnames(IMed12) <- c("GEO_ID",
                      "AllRace_MedianInc",
                      "White_MedianInc", 
                      "Black_MedianInc")

#Step 4: Delete column names within data
IMed12 <- subset(IMed12, GEO_ID != "Geography")

#Step 5: Treat columns as numeric
IMed12[,2:4] <- sapply(IMed12[,2:4], as.numeric)

#Repeat steps 1-5 for all 20XX Income Median datasets
IMed13 <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Income/ACSST5Y2013.S1903-Data.csv")
IMed13 <- IMed13[c(1, 5, 9, 13)]
colnames(IMed13) <- c("GEO_ID", "AllRace_MedianInc", "White_MedianInc", "Black_MedianInc")
IMed13 <- subset(IMed13, GEO_ID != "Geography")
IMed13[,2:4] <- sapply(IMed13[,2:4], as.numeric)

IMed14 <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Income/ACSST5Y2014.S1903-Data.csv")
IMed14 <- IMed14[c(1, 5, 9, 13)]
colnames(IMed14) <- c("GEO_ID", "AllRace_MedianInc", "White_MedianInc", "Black_MedianInc")
IMed14 <- subset(IMed14, GEO_ID != "Geography")
IMed14[,2:4] <- sapply(IMed14[,2:4], as.numeric)

IMed15 <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Income/ACSST5Y2015.S1903-Data.csv")
IMed15 <- IMed15[c(1, 5, 9, 13)]
colnames(IMed15) <- c("GEO_ID", "AllRace_MedianInc", "White_MedianInc", "Black_MedianInc")
IMed15 <- subset(IMed15, GEO_ID != "Geography")
IMed15[,2:4] <- sapply(IMed15[,2:4], as.numeric)

IMed16 <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Income/ACSST5Y2016.S1903-Data.csv")
IMed16 <- IMed16[c(1, 5, 9, 13)]
colnames(IMed16) <- c("GEO_ID", "AllRace_MedianInc", "White_MedianInc", "Black_MedianInc")
IMed16 <- subset(IMed16, GEO_ID != "Geography")
IMed16[,2:4] <- sapply(IMed16[,2:4], as.numeric)

#Edit 17-23

IMed17 <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Income/ACSST5Y2017.S1903-Data.csv")
IMed17 <- IMed17[c(1, 163, 165, 167)]
colnames(IMed17) <- c("GEO_ID", "AllRace_MedianInc", "White_MedianInc", "Black_MedianInc")
IMed17 <- subset(IMed17, GEO_ID != "Geography")
IMed17[,2:4] <- sapply(IMed17[,2:4], as.numeric)

#Edit 2018

IMed18 <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Income/ACSST5Y2018.S1903-Data.csv")
IMed18 <- IMed18[c(1, 85, 89, 93)]
colnames(IMed18) <- c("GEO_ID", "AllRace_MedianInc", "White_MedianInc", "Black_MedianInc")
IMed18 <- subset(IMed18, GEO_ID != "Geography")
IMed18[,2:4] <- sapply(IMed18[,2:4], as.numeric)

IMed19 <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Income/ACSST5Y2019.S1903-Data.csv")
IMed19 <- IMed19[c(1, 163, 165, 167)]
colnames(IMed19) <- c("GEO_ID", "AllRace_MedianInc", "White_MedianInc", "Black_MedianInc")
IMed19 <- subset(IMed19, GEO_ID != "Geography")
IMed19[,2:4] <- sapply(IMed19[,2:4], as.numeric)

IMed20 <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Income/ACSST5Y2020.S1903-Data.csv")
IMed20 <- IMed20[c(1, 163, 165, 167)]
colnames(IMed20) <- c("GEO_ID", "AllRace_MedianInc", "White_MedianInc", "Black_MedianInc")
IMed20 <- subset(IMed20, GEO_ID != "Geography")
IMed20[,2:4] <- sapply(IMed20[,2:4], as.numeric)

IMed21 <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Income/ACSST5Y2021.S1903-Data.csv")
IMed21 <- IMed21[c(1, 163, 165, 167)]
colnames(IMed21) <- c("GEO_ID", "AllRace_MedianInc", "White_MedianInc", "Black_MedianInc")
IMed21 <- subset(IMed21, GEO_ID != "Geography")
IMed21[,2:4] <- sapply(IMed21[,2:4], as.numeric)

IMed22 <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Income/ACSST5Y2022.S1903-Data.csv")
IMed22 <- IMed22[c(1, 163, 165, 167)]
colnames(IMed22) <- c("GEO_ID", "AllRace_MedianInc", "White_MedianInc", "Black_MedianInc")
IMed22 <- subset(IMed22, GEO_ID != "Geography")
IMed22[,2:4] <- sapply(IMed22[,2:4], as.numeric)

IMed23 <- read.csv("C:/Users/gymto/OneDrive/Documents/Professional & Career/Roosevelt Network/Forge/Data/Income/ACSST5Y2023.S1903-Data.csv")
IMed23 <- IMed23[c(1, 163, 165, 167)]
colnames(IMed23) <- c("GEO_ID", "AllRace_MedianInc", "White_MedianInc", "Black_MedianInc")
IMed23 <- subset(IMed23, GEO_ID != "Geography")
IMed23[,2:4] <- sapply(IMed23[,2:4], as.numeric)

#Merge poverty, gini index, mean income, and median income data by year
PMACS12 <- merge(P12, IMed12, by="GEO_ID")
PMACS13 <- merge(P13, IMed13, by="GEO_ID")
PMACS14 <- merge(P14, IMed14, by="GEO_ID")
PMACS15 <- merge(P15, IMed15, by="GEO_ID")
PMACS16 <- merge(P16, IMed16, by="GEO_ID")
PMACS17 <- merge(P17, IMed17, by="GEO_ID")
PMACS18 <- merge(P18, IMed18, by="GEO_ID")
PMACS19 <- merge(P19, IMed19, by="GEO_ID")
PMACS20 <- merge(P20, IMed20, by="GEO_ID")
PMACS21 <- merge(P21, IMed21, by="GEO_ID")
PMACS22 <- merge(P22, IMed22, by="GEO_ID")
PMACS23 <- merge(P23, IMed23, by="GEO_ID")

#Bind rows together
PMACS <- rbind(PMACS12, PMACS13, PMACS14, PMACS15, PMACS16, PMACS17, PMACS18, PMACS19, PMACS20, PMACS21, PMACS22, PMACS23)

#Create usable unit variable and state

PMACS$UnitVariable <- substr(PMACS$GEO_ID,10,16)
PMACS$State <- substr(PMACS$UnitVariable,1,2)
PMACS$UnitVariable <- sapply(PMACS$UnitVariable, as.numeric)
PMACS$State <- sapply(PMACS$State, as.numeric)

#Log Income
PMACS$AllRace_MeanLogInc <-log(PMACS$AllRace_MeanInc)
PMACS$Black_MeanLogInc <- log(PMACS$Black_MeanInc)
PMACS$White_MeanLogInc <- log(PMACS$White_MeanInc)
PMACS$AllRace_MedianLogInc <-log(PMACS$AllRace_MedianInc)
PMACS$Black_MedianLogInc <- log(PMACS$Black_MedianInc)
PMACS$White_MedianLogInc <- log(PMACS$White_MedianInc)

#Compute predictors

PMACS$Unemployment <- PMACS$Unemployed_Pop/PMACS$LaborForce_Pop
PMACS$Bachelor_Percent <- PMACS$`>Bachelor_Pop`/PMACS$Total_Pop
PMACS$NoBachelor_Percent <-  (PMACS$SomeCollege_Pop+PMACS$HS_Pop+PMACS$`<HS_Pop`)/PMACS$Total_Pop

#Compute income growth rate
PMACS <- group_by(PMACS, Name) %>% 
  mutate(MeanIncGrowth = c(NA, diff(AllRace_MeanInc))/lag(AllRace_MeanInc, 1))

PMACS <- group_by(PMACS, Name) %>% 
  mutate(MedianIncGrowth = c(NA, diff(AllRace_MedianInc))/lag(AllRace_MedianInc, 1))

#Compute population percentages by race
PMACS$Black_PopPercent <- PMACS$Black_Pop/PMACS$Total_Pop
PMACS$White_PopPercent <- PMACS$White_Pop/PMACS$Total_Pop

#Compute poverty ratios and income ratios
PMACS$BWPovertyRatio <- PMACS$Black_BelowPovPer/PMACS$White_BelowPovPer
PMACS$BWMedianIncRatio <- PMACS$Black_MedianInc/PMACS$White_MedianInc
PMACS$BWMeanIncRatio <- PMACS$Black_MeanInc/PMACS$White_MeanInc

sumstats(PMACS)

#Add Reparation Program Indicator
PMACS$Reparations <- "No"
PMACS$Reparations[PMACS$GEO_ID == "1600000US3719000"] <- "Yes"
PMACS$Reparations[PMACS$GEO_ID == "1600000US2758000"] <- "Yes"
PMACS$Reparations[PMACS$GEO_ID == "1600000US4459000"] <- "Yes"
PMACS$Reparations[PMACS$GEO_ID == "1600000US1724582"] <- "Yes"

#Eliminate observations with less than 50000
City <- subset(PMACS, PMACS$Total_Pop>50000)

#Eliminate 2012 data
City <- subset(City, City$Year!=2012)

#Eliminate NA values

City <- City[complete.cases(City),]
City <- subset(City, City$UnitVariable != 1823278)
City <- subset(City, City$UnitVariable != 2524960)

#Eliminate unbalanced panel data points

complete <- City %>% 
  group_by(UnitVariable) %>% 
  count() %>% 
  ungroup() %>% 
  filter(n == 11) %>% 
  pull(UnitVariable)

City <- City %>% 
  filter(UnitVariable %in% complete)

#Treat City as a dataframe
City <- as.data.frame(City)

sumstats(City)
