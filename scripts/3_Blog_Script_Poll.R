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
         rep_poll_natl_dif = rep_poll - rep_natl_actual) %>%
  distinct()

# Make a state model df to find good weighting averages for two prior years
# to predict this year

state_models <- tibble(A = double(),
                       B = double(),
                       error = double(),
                       state = as.character(),
                       year = double())

datalist = list()

make_state_model_df <- function(statename){
  
  state_df <- pop_vote_state_natl %>%
    filter(state == statename) %>%
    filter(is.na(dem_state_natl_dif) == FALSE) %>%
    arrange(year)
  
  statename = statename
  
  for (i in 0:100)
  {
    a = i / 100
    b = 1 - a
    for (j in 3:length(state_df$dem_state_natl_dif))
    {
      year = state_df$year[j]
      pred = a * state_df$dem_state_natl_dif[j-2] + b * state_df$dem_state_natl_dif[j-1]
      error = pred - state_df$dem_state_natl_dif[j]
      df <- tibble(A = a,
                   B = b,
                   error = error,
                   state = statename,
                   year = year)
      state_models <<- rbind(state_models, df)
    }
  }
}
  

states_list <- pop_vote_state$state %>%
  unique()

map(states_list, make_state_model_df)

state_models <- state_models %>%
  mutate(error_squared = error * error)

state_models_weighted_A_B <- state_models %>%
  group_by(state, A, B) %>%
  summarize(MSE = mean(error_squared)) %>%
  group_by(state) %>%
  arrange(MSE) %>%
  slice(1)

# Predicting 2020 State vs. national Difs

pop_vote_state_natl_2020 <- pop_vote_state_natl %>%
  filter(year %in% c(2012, 2016)) %>%
  pivot_wider(names_from = year,
              values_from = dem_state_natl_dif) %>%
  group_by(state) %>%
  fill('2012', '2016', .direction = "updown") %>%
  select(state, '2012', '2016') %>%
  distinct() %>%
  mutate(dem_state_natl_dif_2012 = '2012',
         dem_state_natl_dif_2016 = '2016') %>%
  select(state, dem_state_natl_dif_2012, dem_state_natl_dif_2016)

state_models_predicted <- inner_join(state_models_weighted_A_B, pop_vote_state_natl_2020,
                                     by = 'state')

