library(dplyr)
library(stringr)
library(ggplot2)

setwd("C:/Users/sfure/OneDrive - University of North Carolina at Chapel Hill/DATA 760 VIZ AND COMM/Project/")
play_data <- read.csv("Data/plays.csv")

# Remove Unnecessary Columns
play_data <- play_data %>%
  select(-timeToThrow, -timeInTackleBox, -timeToSack, -passTippedAtLine, 
         -unblockedPressure, -pff_runPassOption, -pff_runConceptPrimary, 
         -pff_runConceptSecondary, -preSnapHomeTeamWinProbability,
         -preSnapVisitorTeamWinProbability, -playClockAtSnap,
         -preSnapHomeScore, -preSnapVisitorScore, -prePenaltyYardsGained, -dropbackDistance, -dropbackType)

# Remove data extra formations
play_data <- play_data %>% 
  filter(offenseFormation != c("WILDCAT", NA))

# Make shotguns with empty categorize as empty
play_data <- play_data %>%
  mutate(offenseFormation = case_when(
    receiverAlignment %in% c("3x2", "4x1") ~ "EMPTY",
    TRUE ~ offenseFormation
  ))

# Make Jumbo categorize as I_FORM
play_data <- play_data %>%
  mutate(offenseFormation = if_else(offenseFormation == "JUMBO", "I_FORM", offenseFormation))

# Count num plays in each formation
# play_data %>%
#   count(pff_passCoverage, name = "num_plays")

# Make formations camelcase
play_data <- play_data %>%
  mutate(offenseFormation = recode(offenseFormation,
                                   "EMPTY" = "Empty",
                                   "I_FORM" = "I-Form",
                                   "PISTOL" = "Pistol",
                                   "SHOTGUN" = "Shotgun",
                                   "SINGLEBACK" = "Singleback"
  ))

play_data <- play_data %>%
  mutate(absoluteYardlineNumber = if_else(
    possessionTeam == yardlineSide,
    yardlineNumber + 10,
    (100 - yardlineNumber) + 10
  ))

play_data <- play_data %>%
  filter(!pff_passCoverage %in% c("Goal Line", "Red Zone", "Bracket", "Miscellaneous", "Prevent")) %>%
  filter(!is.na(pff_passCoverage))

play_data <- play_data %>%
  mutate(pff_passCoverage = case_when(
    pff_passCoverage == "2-Man" ~ "Cover-2",
    str_detect(pff_passCoverage, "Cover-3") ~ "Cover-3",
    str_detect(pff_passCoverage, "Cover 6") ~ "Cover 6",
    str_detect(pff_passCoverage, "Cover-6") ~ "Cover 6",
    str_detect(pff_passCoverage, "Cover-1") ~ "Cover 1",
    TRUE ~ pff_passCoverage  # Keep other values unchanged
  )) %>%
  mutate(pff_passCoverage = str_replace_all(pff_passCoverage, "-", " "))


play_data <- play_data %>%
  mutate(targetX = if_else(
    targetX != absoluteYardlineNumber + passLength & !is.na(targetX),
    absoluteYardlineNumber + passLength,
    targetX
  ))

play_data <- play_data %>%
  mutate(quarter = if_else(
    quarter < 5,
    paste0('Q', quarter),
    'OT'
  ))

play_data <- play_data %>%
  mutate(down = case_when(
    down == 1 ~ "1st",
    down == 2 ~ "2nd",
    down == 3 ~ "3rd",
    down == 4 ~ "4th",
    TRUE ~ as.character(down)  # This handles any other unexpected values
  ))

play_data <- play_data %>%
  mutate(playDescription = str_extract(playDescription, "(?<=\\)\\s)(.*)"))

write.csv(play_data, "data/preprocessed_plays.csv")
