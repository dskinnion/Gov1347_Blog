# Load libraries

library(gt)
library(webshot)
library(mlr3)
library(maps)
library(usmap)
library(tidyverse)

# Load in data

options(scipen = 999)

polls_2020 <- read_csv('data/polls_2020.csv')
polls_2016 <- read_csv('data/polls_2020.csv')
poll_avg_state <- read_csv('data/pollavg_bystate_1968-2016.csv')
poll_avg <- read_csv('data/pollavg_1968-2016.csv')
pop_vote <- read_csv('data/popvote_1948-2016.csv')
pop_vote_state <- read_csv('data/popvote_bystate_1948-2016.csv')
ec <- read_csv('data/electoralcollegepost1948.csv')

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

state_models_dem_dif <- tibble(A = double(),
                               B = double(),
                               error = double(),
                               state = as.character(),
                               year = double())

state_models_rep_dif <- tibble(A = double(),
                               B = double(),
                               error = double(),
                               state = as.character(),
                               year = double())

make_state_model_dem_dif_df <- function(statename){
  
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
      state_models_dem_dif <<- rbind(state_models_dem_dif, df)
    }
  }
}

make_state_model_rep_dif_df <- function(statename){
  
  state_df <- pop_vote_state_natl %>%
    filter(state == statename) %>%
    filter(is.na(rep_state_natl_dif) == FALSE) %>%
    arrange(year)
  
  statename = statename
  
  for (i in 0:100)
  {
    a = i / 100
    b = 1 - a
    for (j in 3:length(state_df$rep_state_natl_dif))
    {
      year = state_df$year[j]
      pred = a * state_df$rep_state_natl_dif[j-2] + b * state_df$rep_state_natl_dif[j-1]
      error = pred - state_df$rep_state_natl_dif[j]
      df <- tibble(A = a,
                   B = b,
                   error = error,
                   state = statename,
                   year = year)
      state_models_rep_dif <<- rbind(state_models_rep_dif, df)
    }
  }
}

states_list <- pop_vote_state$state %>%
  unique()

map_dfr(states_list, make_state_model_dem_dif_df)
map_dfr(states_list, make_state_model_rep_dif_df)

state_models_dem_dif <- state_models_dem_dif %>%
  mutate(error_squared = error * error)

state_models_rep_dif <- state_models_rep_dif %>%
  mutate(error_squared = error * error)

state_models_dem_weighted_A_B <- state_models_dem_dif %>%
  group_by(state, A, B) %>%
  summarize(MSE = mean(error_squared)) %>%
  group_by(state) %>%
  arrange(MSE) %>%
  slice(1)

state_models_rep_weighted_A_B <- state_models_rep_dif %>%
  group_by(state, A, B) %>%
  summarize(MSE = mean(error_squared)) %>%
  group_by(state) %>%
  arrange(MSE) %>%
  slice(1)

# Predicting 2020 State vs. national Difs

pop_vote_state_natl_2020_dem <- pop_vote_state_natl %>%
  filter(year %in% c(2012, 2016)) %>%
  pivot_wider(names_from = year,
              values_from = dem_state_natl_dif) %>%
  group_by(state) %>%
  fill('2012', '2016', .direction = "updown") %>%
  select(state, '2012', '2016') %>%
  distinct() %>%
  rename(dem_state_natl_dif_2012 = '2012',
         dem_state_natl_dif_2016 = '2016') %>%
  select(state, dem_state_natl_dif_2012, dem_state_natl_dif_2016)

state_models_predicted_dem <- inner_join(state_models_dem_weighted_A_B, pop_vote_state_natl_2020_dem,
                                     by = 'state')

state_models_predicted_dem <- state_models_predicted_dem %>%
  mutate(dem_state_natl_dif_2020_pred = A * dem_state_natl_dif_2012 + B * dem_state_natl_dif_2016) %>%
  rename(dem_A = A,
         dem_B = B,
         dem_MSE = MSE)

pop_vote_state_natl_2020_rep <- pop_vote_state_natl %>%
  filter(year %in% c(2012, 2016)) %>%
  pivot_wider(names_from = year,
              values_from = rep_state_natl_dif) %>%
  group_by(state) %>%
  fill('2012', '2016', .direction = "updown") %>%
  select(state, '2012', '2016') %>%
  distinct() %>%
  rename(rep_state_natl_dif_2012 = '2012',
         rep_state_natl_dif_2016 = '2016') %>%
  select(state, rep_state_natl_dif_2012, rep_state_natl_dif_2016)

state_models_predicted_rep <- inner_join(state_models_rep_weighted_A_B, pop_vote_state_natl_2020_rep,
                                         by = 'state')

state_models_predicted_rep <- state_models_predicted_rep %>%
  mutate(rep_state_natl_dif_2020_pred = A * rep_state_natl_dif_2012 + B * rep_state_natl_dif_2016) %>%
  rename(rep_A = A,
         rep_B = B,
         rep_MSE = MSE)

state_models_predicted <- inner_join(state_models_predicted_dem, state_models_predicted_rep,
                                     by = 'state')
# Finding weighted ensembles for state poll avg

polls_2020_dte <- polls_2020_wider %>%
  mutate(election_day = as.Date.character(election_date, "%m/%d/%y"),
         start_day = as.Date.character(start_date, "%m/%d/%y"),
         end_day = as.Date.character(end_date, "%m/%d/%y"),
         days_until_election = as.integer(election_day - end_day))

polls_2020_dte_state <- polls_2020_dte %>%
  filter(state %in% states_list) %>%
  group_by(state) %>%
  summarise(total_days_until_election = sum(days_until_election))

polls_2020_dte_weights <- inner_join(polls_2020_dte, polls_2020_dte_state, by = 'state') %>%
  mutate(rel_weight = 1 - (days_until_election / (total_days_until_election + 1)))

polls_2020_dte_weights_state <- polls_2020_dte_weights %>%
  group_by(state) %>%
  summarise(total_rel_weights = sum(rel_weight))

polls_2020_dte_weights_2 <- inner_join(polls_2020_dte_weights, polls_2020_dte_weights_state, by = 'state') %>%
  mutate(weight = rel_weight / total_rel_weights) %>%
  mutate(weighted_dem = weight * DEM / 100,
         weighted_rep = weight * REP / 100)

polls_2020_weighted_avg <- polls_2020_dte_weights_2 %>%
  group_by(state) %>%
  summarise(dem_weighted_avg = sum(weighted_dem),
            rep_weighted_avg = sum(weighted_rep)) %>%
  mutate(state_winner_pred = ifelse(dem_weighted_avg > rep_weighted_avg, 'democrat', 'republican')) %>%
  mutate(dem_margin = dem_weighted_avg - rep_weighted_avg,
         rep_margin = rep_weighted_avg - dem_weighted_avg)

polls_2020_natl_pred <- inner_join(state_models_predicted, polls_2020_weighted_avg, by = 'state') %>%
  mutate(natl_dem_pred = dem_weighted_avg - dem_state_natl_dif_2020_pred,
         natl_rep_pred = rep_weighted_avg - rep_state_natl_dif_2020_pred,
         natl_winner_pred = ifelse(natl_dem_pred > natl_rep_pred, 'democrat', 'republican'))

# Map of state predictions

states_map <- map_data("state")

polls_2020_natl_pred$region <- tolower(polls_2020_natl_pred$state)

polls_2020_map <- left_join(states_map, polls_2020_natl_pred, by = 'region')

ggplot(polls_2020_map, aes(long, lat, group = group)) +
  geom_polygon(aes(fill = dem_margin), color = "black") +
  scale_fill_gradient2(
    low = "red", 
    # mid = scales::muted("purple"),
    mid = "white",
    high = "blue",
    breaks = c(-0.5, -0.25, 0, 0.25, 0.5),
    limits = c(-0.5, 0.5),
    name = "Dem. Margin"
  ) +
  theme_void() +
  labs(title = "2020 Presidential Election State Dem. Margin \n Predictions from Weighted Polling Averages") +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("figures/Poll_margin_map.png", height = 3, width = 5)

new_EVs <- data.frame(region = c('wyoming', 'south dakota', 'nebraska', 'rhode island', 'illinois', 'district of columbia'),
                      state_winner_pred = c('republican', 'republican', 'republican', 'democrat', 'democrat', 'democrat'),
                      state = c('Wyoming', 'South Dakota', 'Nebraska', 'Rhode Island', 'Illinois', 'District of Columbia'))

EV_2020_pred <- polls_2020_natl_pred %>%
  select(state, region, state_winner_pred) %>%
  rbind(new_EVs)

EV_2020_map <- left_join(states_map, EV_2020_pred, by = 'region')

ggplot(EV_2020_map, aes(long, lat, group = group)) +
  geom_polygon(aes(fill = state_winner_pred), color = "black") +
  scale_fill_manual(values = c('blue', 'red'),
                    name = "State Winner") +
  theme_void() +
  labs(title = "2020 Presidential Election State Predictions \n from Weighted Polling Averages") +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("figures/Poll_EV_map.png", height = 3, width = 5)

ec2020 <- ec %>%
  rename(state = X1) %>%
  rename(electors_2020 = '2020') %>%
  select(state, electors_2020)

EV_2020_preds <- inner_join(EV_2020_pred, ec2020, by = 'state')

EV_totals <- EV_2020_preds %>%
  group_by(state_winner_pred) %>%
  summarise(total_EV = sum(electors_2020)) %>%
  mutate(year = 2020)

dem_EV <- EV_totals$total_EV[1]
rep_EV <- EV_totals$total_EV[2]

ggplot(EV_totals) +
  geom_bar(aes(fill = state_winner_pred, y = total_EV, x = year),
           position = "stack",
           stat = 'identity') +
  scale_fill_manual(values = c('blue', 'red')) +
  coord_flip() +
  theme_classic() +
  theme(legend.position = 'none',
        axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.line.y = element_blank(),
        plot.title = element_text(hjust = 0.5)) +
  geom_hline(yintercept = 270, size = 2) +
  labs(y = 'Electoral Votes',
       title = "2020 Predicted Electoral Votes \n from Weighted Polling Averages")

ggsave("figures/Poll_EV.png", height = 2, width = 5)

table_preds <- polls_2020_natl_pred %>%
  mutate('National Dem. Percent' = (natl_dem_pred / (natl_dem_pred + natl_rep_pred)) * 100,
         'National Rep. Percent' = (natl_rep_pred / (natl_dem_pred + natl_rep_pred)) * 100,
         'Predicted Winner' = ifelse(natl_winner_pred == 'democrat', 'Biden', 'Trump')) %>%
  select(state, 
         'National Dem. Percent',
         'National Rep. Percent',
         'Predicted Winner')

table <- table_preds %>%
  gt() %>%
  tab_header(
    title = "National Election Predictions Based on State Polls",
    subtitle = "Percentages are of the Two-Party Vote Share"
  ) %>%
  data_color(
    columns = vars('National Dem. Percent'),
    colors = scales::col_numeric(
      palette = c("red", "white", "blue"),
      domain = c(35, 65))
  ) %>%
  data_color(
    columns = vars('National Rep. Percent'),
    colors = scales::col_numeric(
      palette = c("blue", "white", "red"),
      domain = c(35, 65))
  ) %>%
  data_color(
    columns = vars('Predicted Winner'),
    colors = scales::col_factor(
      palette = c("blue", "red"),
      domain = c('Biden', 'Trump'))
  )

gtsave(table, "figures/Poll_GT_Natl_Preds.png")



