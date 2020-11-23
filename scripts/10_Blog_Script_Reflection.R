# WIll also need to run 8_Blog_Script_Final.R before this one, since this script
# Builds on that one

# Load libraries

library(usmap)
library(loo)
library(geofacet)
library(broom)
library(caret)
library(stringr)
library(gt)
library(statebins)
library(gridExtra)
library(grid)
library(tidyverse)

# Load Data

pres_poll_avg_2020 <- read_csv("data/polls_final/presidential_poll_averages_2020.csv")
pres_appr_2020 <- read_csv("data/trump_approval_final/approval_topline.csv")
pres_appr_hist <- read_csv("data/approval_gallup_1941-2020.csv")
pres_poll_avg_hist_natl <- read_csv("data/pollavg_1968-2016.csv")
pres_poll_avg_hist_state <- read_csv("data/pollavg_bystate_1968-2016.csv")
demog <- read_csv("data/demographic_1990-2018.csv")
pv_hist_natl <- read_csv("data/popvote_1948-2016.csv")
pv_hist_state <- read_csv("data/popvote_bystate_1948-2016.csv")
state_abbs <- read_csv("data/state_abb.csv")
ec <- read_csv("data/electoralcollegepost1948.csv")
state_pv_2020 <- read.csv('data/popvote_bystate_1948-2020.csv')
pv_county_2020 <- read_csv("data/popvote_bycounty_2020.csv")
pv_county_hist <- read_csv("data/popvote_bycounty_2000-2016.csv")

# New calcs

final_comps <- inner_join(R_state_preds_2020_final, state_pv_2020, by = c("state", "year")) %>%
  select(state, fit, upr, OOS_upr, R_pv2p)

poll_comps <- inner_join(state_2020, R_state_preds_2020_final, by = c("state", "year")) %>%
  inner_join(state_pv_2020, by = c("state", "year"))

# Scatters

ggplot(final_comps, aes(x = fit, y = R_pv2p)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1) +
  geom_hline(yintercept = 0.5, color = 'red') +
  geom_vline(xintercept = 0.5, color = 'red') +
  labs(x = "Trump's Predicted Vote Share",
       y = "Trump's Actual Vote Share",
       title = "Actual vs. Predicted Trump Two-Party Vote Share (State-Level)") +
  theme_classic()

ggplot(poll_comps, aes(x = R_pa2p_weighted, y = fit)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1) +
  geom_hline(yintercept = 0.5, color = 'red') +
  geom_vline(xintercept = 0.5, color = 'red') +
  labs(x = "Trump's Weighted Polling Average",
       y = "Trump's Predicted Vote Share",
       title = "Trump's Predicted Vote Share vs. Polling Average (State-Level)") +
  theme_classic()

ggplot(poll_comps, aes(x = R_pa2p_weighted, y = R_pv2p)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1) +
  geom_hline(yintercept = 0.5, color = 'red') +
  geom_vline(xintercept = 0.5, color = 'red') +
  labs(x = "Trump's Weighted Polling Average",
       y = "Trump's Actual Vote Share",
       title = "Trump's Actual Vote Share vs. Polling Average (State-Level)") +
  theme_classic()

# RMSE

RMSE <- final_comps %>%
  mutate(error = R_pv2p - fit) %>%
  mutate(squared_error = error ^2) %>%
  summarize(rmse = sqrt(mean(squared_error))) %>%
  select(rmse) %>%
  pull(1)

