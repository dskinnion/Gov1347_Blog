# Load libraries

library(tidyverse)
library(mlr3)

# Load in data

polls_2020 <- read_csv('data/polls_2020.csv')
polls_2016 <- read_csv('data/polls_2020.csv')
poll_avg_state <- read_csv('data/pollavg_bystate_1968-2016.csv')
poll_avg <- read_csv('data/pollavg_1968-2016.csv')
pop_vote <- read_csv('data/popvote_1948-2016.csv')
pop_vote_state <- read_csv('data/popvote_bystate_1948-2016.csv')

# Data Cleaning

polls_2020_wider <- polls_2020 %>%
  pivot_wider(names_from = "candidate_party", values_from = "pct") %>%
  group_by(question_id) %>%
  fill(DEM, REP, OTH, GRE, LIB, CON, IND, .direction = "downup") %>%
  select(-answer, -candidate_id, -candidate_name) %>%
  distinct()

polls_2016_wider <- polls_2016 %>%
  pivot_wider(names_from = "candidate_party", values_from = "pct") %>%
  group_by(question_id) %>%
  fill(DEM, REP, OTH, GRE, LIB, CON, IND, .direction = "downup") %>%
  select(-answer, -candidate_id, -candidate_name) %>%
  distinct()

poll_avg_state_wider <- poll_avg_state %>%
  pivot_wider(names_from = "party", values_from = "avg_poll") %>%
  group_by(state, poll_date) %>%
  fill(democrat, republican, .direction = "downup") %>%
  mutate(dem_poll = democrat / 100,
         rep_poll = republican / 100) %>%
  select(year, state, poll_date, weeks_left, days_left, before_convention,
         dem_poll, rep_poll)

pop_vote_wider <- pop_vote %>%
  pivot_wider(names_from = "party", values_from = "pv") %>%
  group_by(year) %>%
  fill(democrat, republican, .direction = "downup") %>%
  mutate(dem_natl_actual = democrat / 100 , 
         rep_natl_actual = republican / 100) %>%
  select(year, dem_natl_actual, rep_natl_actual) %>%
  distinct()

pop_vote_state_wider <- pop_vote_state %>%
  mutate(dem_state_actual = D / total,
         rep_state_actual = R / total,
         votes = total) %>%
  select(year, state, votes, dem_state_actual, rep_state_actual)

pop_vote_state_natl <- inner_join(pop_vote_state_wider, pop_vote_wider, by = "year") %>%
  mutate(dem_state_natl_dif = dem_state_actual - dem_natl_actual,
         rep_state_natl_dif = rep_state_actual - rep_natl_actual)

polls_state <- inner_join(poll_avg_state_wider, pop_vote_state_natl, by = c("year", "state")) %>%
  mutate(dem_poll_state_dif = dem_poll - dem_state_actual,
         rep_poll_state_dif = rep_poll - rep_state_actual,
         dem_poll_natl_dif = dem_poll - dem_natl_actual,
         rep_poll_natl_dif = rep_poll - rep_natl_actual)

# EDA

pop_vote_state_natl %>%
  filter(state == "California") %>%
  ggplot(aes(x = year, y = dem_state_natl_dif)) +
    geom_point()

pop_vote_state_natl %>%
  filter(state == "Massachusetts") %>%
  ggplot(aes(x = year, y = dem_state_natl_dif)) +
    geom_point() 
