library(dplyr)
library(stringr)
library(ggplot2)

setwd("C:/Users/sfure/OneDrive - University of North Carolina at Chapel Hill/DATA 760 VIZ AND COMM/Project/")
play_data <- read.csv("data/preprocessed_plays.csv")

play_data <- play_data %>%
  mutate(runPass = if_else(
    is.na(targetX),
    "Run",
    "Pass"
  ))

down_success_rate <- play_data %>%
  group_by(down) %>%
  summarise(SuccessRate = sum(yardsGained > 0, na.rm = TRUE) / n(),
            RunPerc = sum(runPass == "Run", na.rm = TRUE) / n())

distance_success_rate <- play_data %>%
  mutate(YardsToGoGroup = case_when(
    yardsToGo <= 3 ~ "0-3 Yards",
    yardsToGo <= 7 ~ "4-7 Yards",
    yardsToGo <= 10 ~ "8-10 Yards",
    yardsToGo <= 20 ~ "11-20 Yards",
    TRUE ~ "21+ Yards"
  )) %>%
  group_by(YardsToGoGroup, down) %>%
  summarise(SuccessRate = round(100 * sum(yardsGained > 0, na.rm = TRUE) / n(), 1),
            RunPerc = sum(runPass == "Run", na.rm = TRUE) / n()) %>%
  arrange(factor(YardsToGoGroup, levels = c("0-3 Yards", "4-7 Yards", "8-10 Yards", "11-20 Yards", "21+ Yards")))

distance_success_rate <- play_data %>%
  mutate(YardsToGoGroup = case_when(
    yardsToGo <= 3 ~ "0-3 Yards",
    yardsToGo <= 7 ~ "4-7 Yards",
    yardsToGo <= 10 ~ "8-10 Yards",
    yardsToGo <= 20 ~ "11-20 Yards",
    TRUE ~ "21+ Yards"
  )) %>%
  group_by(YardsToGoGroup, down) %>%
  summarise(SuccessRate = sum(yardsGained >= yardsToGo, na.rm = TRUE) / n(),
            RunPerc = sum(runPass == "Run", na.rm = TRUE) / n()) %>%
  arrange(factor(YardsToGoGroup, levels = c("0-3 Yards", "4-7 Yards", "8-10 Yards", "11-20 Yards", "21+ Yards"))) %>%
  filter(down %in% c("3rd", "4th"))

distance_success_rate <- play_data %>%
  mutate(YardsToGoGroup = case_when(
    yardsToGo <= 7 ~ "0-7 Yards",
    TRUE ~ "8+ Yards"
  )) %>%
  group_by(YardsToGoGroup, down) %>%
  summarise(SuccessRate = sum(yardsGained >= yardsToGo, na.rm = TRUE) / n(),
            RunPerc = sum(runPass == "Run", na.rm = TRUE) / n()) %>%
  filter(down %in% c("3rd", "4th"))


off_success_rate <- play_data %>%
  group_by(offenseFormation) %>%
  summarise(SuccessRate = sum(yardsGained > 0, na.rm = TRUE) / n(),
            ExplosivePlayRate = sum(yardsGained >= 10, na.rm = TRUE) / n(),
            UsageRate = n() / nrow(play_data))

def_success_rate <- play_data %>%
  group_by(pff_passCoverage) %>%
  summarise(SuccessRate = sum(yardsGained > 0, na.rm = TRUE) / n(),
            ExplosivePlayRate = sum(yardsGained >= 10, na.rm = TRUE) / n(),
            UsageRate = n() / nrow(play_data))

play_type_success_rate <- play_data %>%
  group_by(runPass) %>%
  summarise(SuccessRate = sum(yardsGained > 0, na.rm = TRUE) / n(),
            ExplosivePlayRate = sum(yardsGained >= 10, na.rm = TRUE) / n())

field_pos_success_rate <- play_data %>%
  mutate(FieldPosition = case_when(
    absoluteYardlineNumber >= 1 & absoluteYardlineNumber <= 20 ~ "Own 1-20 Yard Line",
    absoluteYardlineNumber >= 21 & absoluteYardlineNumber <= 50 ~ "Own 21-50 Yard Line",
    absoluteYardlineNumber >= 51 & absoluteYardlineNumber <= 79 ~ "Opponent 49-21 Yard Line",
    absoluteYardlineNumber >= 80 & absoluteYardlineNumber <= 99 ~ "Red Zone (Opponent 20-1 Yard Line)",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(FieldPosition)) %>%
  group_by(FieldPosition,) %>%
  summarise(SuccessRate = round(100 * sum(yardsGained > 0, na.rm = TRUE) / n(), 1)) %>%
  arrange(factor(FieldPosition, levels = c(
    "Own 1-20 Yard Line",
    "Own 21-50 Yard Line",
    "Opponent 49-21 Yard Line",
    "Red Zone (Opponent 20-1 Yard Line)"
  )))

field_pos_usage_rate <- play_data %>%
  mutate(FieldPosition = case_when(
    absoluteYardlineNumber >= 1 & absoluteYardlineNumber <= 20 ~ "Own 1-20 Yard Line",
    absoluteYardlineNumber >= 21 & absoluteYardlineNumber <= 50 ~ "Own 21-50 Yard Line",
    absoluteYardlineNumber >= 51 & absoluteYardlineNumber <= 79 ~ "Opponent 49-21 Yard Line",
    absoluteYardlineNumber >= 80 & absoluteYardlineNumber <= 99 ~ "Red Zone (Opponent 20-1 Yard Line)",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(FieldPosition)) %>%
  group_by(FieldPosition, runPass) %>%
  summarise(Plays = n(),
            SuccessRate = round(100 * sum(yardsGained > 0, na.rm = TRUE) / n(), 1),
            .groups = "drop_last") %>%
  mutate(UsageRate = Plays / sum(Plays),) %>%
  ungroup() %>%
  arrange(factor(FieldPosition, levels = c(
    "Own 1-20 Yard Line",
    "Own 21-50 Yard Line",
    "Opponent 49-21 Yard Line",
    "Red Zone (Opponent 20-1 Yard Line)"
  )))



