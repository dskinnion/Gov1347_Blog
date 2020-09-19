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

# EDA

pop <- pop %>%
  mutate(incumbent_2 = ifelse(incumbent == "TRUE", "Incumbent", "Non-Incumbent")) %>%
  mutate(pv2p = pv2p / 100)

pop_and_econ <-
  inner_join(pop, econ, by = "year")

# I had to filter by party in order to remove duplicate rows

pop_and_econ_Q1 <- pop_and_econ %>%
  filter(quarter == 1) %>%
  filter(party == "democrat") %>%
  mutate(GDP_growth_Q1 = GDP_growth_qt) %>%
  select(year, GDP_growth_Q1)

pop_and_econ_Q2 <- pop_and_econ %>%
  filter(quarter == 2) %>%
  filter(party == "democrat") %>%
  mutate(GDP_growth_Q2 = GDP_growth_qt) %>%
  select(year, GDP_growth_Q2)

pop_and_econ_Q3 <- pop_and_econ %>%
  filter(quarter == 3) %>%
  filter(party == "democrat") %>%
  mutate(GDP_growth_Q3 = GDP_growth_qt) %>%
  select(year, GDP_growth_Q3)

pop_and_econ_Q1_Q3 <- 
  inner_join(pop, pop_and_econ_Q1, by = 'year') %>%
  full_join(pop_and_econ_Q2, by = 'year') %>%
  full_join(pop_and_econ_Q3, by = 'year')

pop_model <- 
  glm(pv2p ~ incumbent * incumbent_party * GDP_growth_Q3, data = pop_and_econ_Q1_Q3, family='binomial')

pop_and_econ_Q1_Q3 %>%
  filter(incumbent_party == 'TRUE') %>%
  ggplot(aes(x = GDP_growth_Q2, y = pv2p, color = incumbent_2, shape = incumbent_2)) +
    geom_point() +
    geom_smooth(method = "lm", 
                se = FALSE, 
                formula = y ~ x,
                method.args = list(family = "quasibinomial")) +
    labs(x = "GDP Growth in Q2 of Election Year",
         y = "Two Party Vote Share",
         title = " 2nd Quarter GDP Growth's effect on Two Party \n Vote Share for Incumbent Party",
         subtitle = "GDP Growth more strongly helps Incumbent \n Presidents compared to Same-Party Heirs") +
    scale_color_manual(values = c('forest green', 'black')) +
    theme_classic() +
    theme(legend.title = element_blank()) +
    theme(plot.subtitle = element_text(hjust = 0.5)) +
    theme(plot.title = element_text(hjust = 0.5))


