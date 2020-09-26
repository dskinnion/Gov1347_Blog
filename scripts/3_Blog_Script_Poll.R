# Load libraries

library(tidyverse)

# Load in data

polls_2020 <- read_csv('data/polls_2020.csv')
polls_2016 <- read_csv('data/polls_2020.csv')
poll_avg_state <- read_csv('data/pollavg_bystate_1968-2016.csv')
poll_avg <- read_csv('data/pollavg_1968-2016.csv')

# Data Cleaning

polls_2020 <- polls_2020 %>%
  pivot_wider(names_from = "candidate_party", values_from = "pct") %>%
  group_by(question_id) %>%
  fill(DEM, REP, OTH, GRE, LIB, CON, IND, .direction = "downup")

polls_2016 <- polls_2016 %>%
  pivot_wider(names_from = "candidate_party", values_from = "pct") %>%
  group_by(question_id) %>%
  fill(DEM, REP, OTH, GRE, LIB, CON, IND, .direction = "downup")