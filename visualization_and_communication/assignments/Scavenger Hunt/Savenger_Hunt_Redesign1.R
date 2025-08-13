library(ggplot2)

# Create a data frame
data <- data.frame(
  Age_Group = c("16-24", "25-34", "35-44", "45-54", "55+"),
  Percentage = c(35, 32, 27, 37, 30)
)

# Create the plot
ggplot(data, aes(x = Age_Group, y = Percentage, fill = Age_Group)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = c("red", "black", "yellow", "blue", "green")) +
  labs(
    title = "Is Masculinity in Crisis?",
    x = "Age Group",
    y = "Percentage"
  ) +
  theme_minimal() +
  theme(legend.position = "none")


# Create a data frame with the data
data2 <- data.frame(
  Intelligence_Type = c("Mathematical", "Naturalist", "Existential", "Linguistic", 
                        "Visual", "Logical", "Musical"),
  Percentage = c(1, 41, 3, 32, 17, 23, 8),
  Color = c("pink", "yellow", "orange", "purple", "red", "green", "black")
)