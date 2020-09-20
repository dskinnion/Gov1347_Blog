# load in libraries 

library(tidyverse)
library(maps)
library(usmap)
library(rstanarm)

# load data

pop <- read_csv("data/popvote_1948-2016.csv")
pop_state <- read_csv("data/popvote_bystate_1948-2016.csv")
econ_state <- read_csv("data/local.csv")
econ <- read_csv("data/econ.csv")

# Make a new column for values corresponding to different types of incumbency
# Make sure popular vote percent is a decimal

pop <- pop %>%
  mutate(incumbent_2 = ifelse(incumbent == "TRUE", "Incumbent President", 
                              ifelse(incumbent_party == 'TRUE', "Prospective Same-Party Heir", "Non-Incumbent"))) %>%
  mutate(pv2p = pv2p / 100)

# Add in 2020 rows

election_2020_R <- data.frame(2020, "republican", NA, "Trump, Donald J.", NA, NA, TRUE, TRUE, NA, "Incumbent President")
names(election_2020_R) <- c("year", "party", "winner", "candidate", "pv", "pv2p", "incumbent", "incumbent_party", "prev_admin", "incumbent_2")
pop <- rbind(pop, election_2020_R)

election_2020_D <- data.frame(2020, "democrat", NA, "Biden, Joe", NA, NA, FALSE, FALSE, NA, "Non-Incumbent")
names(election_2020_D) <- c("year", "party", "winner", "candidate", "pv", "pv2p", "incumbent", "incumbent_party", "prev_admin", "incumbent_2")
pop <- rbind(pop, election_2020_D)

# Join popular vote and economy data frames
pop_and_econ <-
  inner_join(pop, econ, by = "year")

# I had to filter by a single party in order to remove duplicate rows
# For each quarter, make a new column to add stats instead of separate rows

pop_and_econ_Q1 <- pop_and_econ %>%
  filter(quarter == 1) %>%
  filter(party == "democrat") %>%
  mutate(GDP_growth_Q1 = GDP_growth_qt) %>%
  mutate(RDI_growth_Q1 = RDI_growth) %>%
  select(year, GDP_growth_Q1, RDI_growth_Q1)

pop_and_econ_Q2 <- pop_and_econ %>%
  filter(quarter == 2) %>%
  filter(party == "democrat") %>%
  mutate(GDP_growth_Q2 = GDP_growth_qt) %>%
  mutate(RDI_growth_Q2 = RDI_growth) %>%
  select(year, GDP_growth_Q2, RDI_growth_Q2)

pop_and_econ_Q3 <- pop_and_econ %>%
  filter(quarter == 3) %>%
  filter(party == "democrat") %>%
  mutate(GDP_growth_Q3 = GDP_growth_qt) %>%
  mutate(RDI_growth_Q3 = RDI_growth) %>%
  select(year, GDP_growth_Q3, RDI_growth_Q3)

pop_and_econ_Q4 <- pop_and_econ %>%
  filter(quarter == 4) %>%
  filter(party == "democrat") %>%
  mutate(GDP_growth_Q4 = GDP_growth_qt) %>%
  mutate(RDI_growth_Q4 = RDI_growth) %>%
  select(year, GDP_growth_Q4, RDI_growth_Q4)

# Join all these quarters together
# Filter for incumbent party

pop_and_econ_Q1_Q4 <- 
  inner_join(pop, pop_and_econ_Q1, by = 'year') %>%
  full_join(pop_and_econ_Q2, by = 'year') %>%
  full_join(pop_and_econ_Q3, by = 'year') %>%
  full_join(pop_and_econ_Q4, by = 'year') %>%
  filter(incumbent_party == 'TRUE')

# Make the model from past elections (not including 2020)

training <- pop_and_econ_Q1_Q4 %>%
  head(18)

# Model pop vote by incumbent and GDP

GDPQ2_model <- 
  lm(pv2p ~ incumbent_2 * GDP_growth_Q2, data = training)

RDIQ2_model <-
  lm(pv2p ~ incumbent_2 * RDI_growth_Q2, data = training)

# Put predictions into the data frame

GDPQ2_preds_pv2p <- predict(GDPQ2_model, newdata = pop_and_econ_Q1_Q4)
pop_and_econ_Q1_Q4$GDPQ2_preds_pv2p = GDPQ2_preds_pv2p

RDIQ2_preds_pv2p <- predict(RDIQ2_model, newdata = pop_and_econ_Q1_Q4)
pop_and_econ_Q1_Q4$RDIQ2_preds_pv2p = RDIQ2_preds_pv2p

# add residuals to data frame
pop_and_econ_Q1_Q4 <- pop_and_econ_Q1_Q4 %>%
  mutate(GDPQ2_residuals = pv2p - GDPQ2_preds_pv2p) %>%
  mutate(RDIQ2_residuals = pv2p - RDIQ2_preds_pv2p)

# 2020 prediction as separate data frame

GDPQ2_prediction = pop_and_econ_Q1_Q4 %>%
  filter(year == 2020)

RDIQ2_prediction = pop_and_econ_Q1_Q4 %>%
  filter(year == 2020)

# Plot the points and models for GDPQ2
# Also plot 2020 prediction
# I didn't like how the se made the graph look very grey, I will
# discuss those in the actual blog post

ggplot(pop_and_econ_Q1_Q4, aes(x = GDP_growth_Q2, 
                               y = pv2p,
                               color = incumbent_2, 
                               shape = incumbent_2)) +
  geom_point(data = GDPQ2_prediction, aes(x = GDP_growth_Q2, y = GDPQ2_preds_pv2p),
             color = 'red', shape = 13, size = 5) +
  geom_point(size = 2) +
  geom_smooth(formula = y~x,
              method = "lm",
              se = FALSE,
              fullrange = TRUE) +
  labs(x = "GDP Growth in Q2 of Election Year",
       y = "Two Party Vote Share",
       title = " 2nd Quarter GDP Growth's effect on Two Party \n Vote Share for Incumbent Party",
       subtitle = "Incumbent Presidents More Strongly Affected by the Economy") +
  scale_color_manual(values = c('green', 'purple')) +
  theme_classic() +
  theme(legend.title = element_blank()) +
  theme(plot.subtitle = element_text(hjust = 0.5)) +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("figures/Econ_GDPQ2_model.png", height = 3, width = 6)

# plot RDIQ2
ggplot(pop_and_econ_Q1_Q4, aes(x = RDI_growth_Q2, 
                               y = pv2p,
                               color = incumbent_2, 
                               shape = incumbent_2)) +
  geom_point(data = RDIQ2_prediction, aes(x = RDI_growth_Q2, y = RDIQ2_preds_pv2p),
             color = 'red', shape = 13, size = 5) +
  geom_point(size = 2) +
  geom_smooth(formula = y~x,
              method = "lm",
              se = FALSE,
              fullrange = TRUE) +
  labs(x = "RDI Growth in Q2 of Election Year",
       y = "Two Party Vote Share",
       title = " 2nd Quarter RDI Growth's effect on Two Party \n Vote Share for Incumbent Party",
       subtitle = "Incumbent Presidents More Strongly Affected by the Economy") +
  scale_color_manual(values = c('green', 'purple')) +
  theme_classic() +
  theme(legend.title = element_blank()) +
  theme(plot.subtitle = element_text(hjust = 0.5)) +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("figures/Econ_RDIQ2_model.png", height = 3, width = 6)

pop_and_econ_Q1_Q4 %>%
  ggplot(aes(x = year, y = GDPQ2_residuals)) +
    geom_point() +
    labs(x = "Year", 
         y = "Residual", 
         title = "Residuals for Q2 GDP Growth Model",
         subtitle = "No Discernable Pattern Over Time") +
    theme_classic() +
    theme(plot.title = element_text(hjust = 0.5)) +
    theme(plot.subtitle = element_text(hjust = 0.5))

ggsave("figures/Econ_GDPQ2_residuals.png", height = 3, width = 4)

pop_and_econ_Q1_Q4 %>%
  ggplot(aes(x = year, y = RDIQ2_residuals)) +
    geom_point() +
    labs(x = "Year", 
         y = "Residual", 
         title = "Residuals for Q2 RDI Growth Model",
         subtitle = "No Discernable Pattern Over Time") +
    theme_classic() +
    theme(plot.title = element_text(hjust = 0.5)) +
    theme(plot.subtitle = element_text(hjust = 0.5))

ggsave("figures/Econ_RDIQ2_residuals.png", height = 3, width = 4)
