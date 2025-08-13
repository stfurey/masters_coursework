library(ggplot2)

down_data <- data.frame(
  Down = c("1st Down", "2nd Down", "3rd Down", "4th Down"),
  SuccessRate = c(72.1, 69.5, 61.0, 47.3)
)

ggplot(down_data, aes(x = Down, y = SuccessRate)) +
  geom_bar(stat = "identity", fill = "skyblue", color = "black") +
  ylim(0, 100) +
  labs(y = "Success Rate", x = "Down") +
  theme_minimal()

distance_data <- data.frame(
  Distance = factor(c("0-3", "4-7", "8-10", "11-20", "21+"), 
                    levels = c("0-3", "4-7", "8-10", "11-20", "21+")),
  SuccessRate = c(66.7, 67, 70.2, 63.4, 71.6)
)

ggplot(distance_data, aes(x = Distance, y = SuccessRate)) +
  geom_bar(stat = "identity", fill = "skyblue", color = "black") +
  ylim(0, 100) +
  labs(y = "Success Rate", x = "Yards to 1st Down") +
  theme_minimal()

conversionRate <- data.frame(
  YardsToGoGroup = c("0-7 Yards", "0-7 Yards", "8+ Yards", "8+ Yards"),
  down = c("3rd", "4th", "3rd", "4th"),
  SuccessRate = c(53.0, 51.2, 23.6, 12.0)
)

ggplot(conversionRate, aes(x = down, y = SuccessRate, fill = YardsToGoGroup)) +
  geom_bar(stat = "identity", position = position_dodge(), color = "black") +
  labs(
    x = "Down",
    y = "Conversion Rate",
    fill = "Yards to Go"
  ) +
  theme_minimal() +
  scale_fill_manual(values = c("0-7 Yards" = "darkgreen", "8+ Yards" = "red")) +
  ylim(0, 100)

##############################################################################

field_position <- data.frame(
  FP = factor(c("Own 1-20", "Own 21-50", "Opp 49-21", "Opp 20-1", "Own 1-20", "Own 21-50", "Opp 49-21", "Opp 20-1"), 
              levels = c("Own 1-20", "Own 21-50", "Opp 49-21", "Opp 20-1")),
  RunPass = c("Run", "Run", "Run", "Run", "Pass", "Pass", "Pass", "Pass"),
  SuccessRate = c(74, 74.2, 71.2, 69.5, 69.6, 67.4, 66.3, 59.9)
)

# Create the side-by-side bar plot with Run and Pass as colors
ggplot(field_position, aes(x = FP, y = SuccessRate, fill = RunPass)) +
  geom_bar(stat = "identity", position = position_dodge(), color = "black") +
  ylim(0, 100) +
  labs(y = "Success Rate", x = "Field Position", fill = "Play Type") +
  theme_minimal() +
  scale_fill_manual(values = c("Run" = "lightblue", "Pass" = "lightgreen"))

##############################################################################

o_form_data <- data.frame(
  Formation = factor(c("Empty", "Shotgun", "Pistol", "SingleBack", "I-Form"), 
                     levels = c("Empty", "Shotgun", "Pistol", "SingleBack", "I-Form")),
  SuccessRate = c(61.2, 66.1, 72.2, 73.6, 75.8),
  ExplosiveRate = c(25.5, 23.7, 18.4, 18.6, 18.4)
)

o_form_data_long <- reshape(o_form_data, 
                            varying = c("SuccessRate", "ExplosiveRate"), 
                            v.names = "Rate", 
                            timevar = "RateType", 
                            times = c("SuccessRate", "ExplosiveRate"), 
                            direction = "long")

# Create the side-by-side bar plot
ggplot(o_form_data_long, aes(x = Formation, y = Rate, fill = RateType)) +
  geom_bar(stat = "identity", position = position_dodge(), color = "black") +
  labs(
    x = "Formation",
    y = "Rate (%)",
    fill = "Rate Type"
  ) +
  ylim(0, 100) +
  theme_minimal() +
  scale_fill_manual(values = c("SuccessRate" = "gold", "ExplosiveRate" = "purple"),
                    labels = c("Explosive", "Success"))

d_scheme_data <- data.frame(
  Scheme = factor(c("Cover 0", "Cover 1", "Cover 2", "Cover 3", "Cover 6","Quarters"), 
                     levels = c("Cover 0", "Cover 1", "Cover 2", "Cover 3", "Cover 6", "Quarters")),
  SuccessRate = c(56.7, 64.8, 68.4, 69.2, 70.6, 71.8),
  ExplosiveRate = c(10.3, 22.7, 24.1, 22.2, 22.0, 21.7)
)

d_scheme_data_long <- reshape(d_scheme_data, 
                            varying = c("SuccessRate", "ExplosiveRate"), 
                            v.names = "Rate", 
                            timevar = "RateType", 
                            times = c("SuccessRate", "ExplosiveRate"), 
                            direction = "long")

# Create the side-by-side bar plot
ggplot(d_scheme_data_long, aes(x = Scheme, y = Rate, fill = RateType)) +
  geom_bar(stat = "identity", position = position_dodge(), color = "black") +
  labs(
    x = "Scheme",
    y = "Rate (%)",
    fill = "Rate Type"
  ) +
  ylim(0, 100) +
  theme_minimal() +
  scale_fill_manual(values = c("SuccessRate" = "gold", "ExplosiveRate" = "purple"),
                    labels = c("Explosive", "Success"))

#################################################################

runPassUsage <- data.frame(
  playType = c("Run", "Pass"),
  Usage = c(47.7, 52.3)
)

runPassUsage <- runPassUsage %>%
  mutate(
    label = paste0(playType, ": ", round(Usage, 1), "%"),
    ypos = cumsum(Usage) - 0.5 * Usage
  )

ggplot(runPassUsage, aes(x = "", y = Usage, fill = playType)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar(theta = "y") +
  geom_text(aes(label = label, y = ypos), color = "black", size = 5) +
  labs(fill = "Play Type") +
  theme_void() +
  scale_fill_manual(values = c("Pass" = "lightgreen", "Run" = "lightblue"))

offFormUsage <- data.frame(
  Formation = c("Empty", "Shotgun", "Pistol", "Singleback", "I-Form"),
  Usage = c(8.7, 55.1, 4, 25.5, 6.7)
)

ggplot(offFormUsage, aes(x = "", y = Usage, fill = Formation)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar(theta = "y") +
  labs(fill = "Formation") +
  theme_void()

defSchemeUsage <- data.frame(
  Scheme =c("Cover 0", "Cover 1", "Cover 2", "Cover 3", "Cover 6","Quarters"),
  Usage = c(4.2, 22.2, 12.9, 37.9, 9.3, 13.5)
)

ggplot(defSchemeUsage, aes(x = "", y = Usage, fill = Scheme)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar(theta = "y") +
  labs(fill = "Scheme") +
  theme_void()




