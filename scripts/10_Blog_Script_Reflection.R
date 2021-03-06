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
       title = "Actual vs. Predicted Trump Two-Party Vote Share") +
  theme_classic()

ggsave("figures/Refl_Pred_vs_actual.png", height = 3, width = 5)

ggplot(poll_comps, aes(x = R_pa2p_weighted, y = fit)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1) +
  geom_hline(yintercept = 0.5, color = 'red') +
  geom_vline(xintercept = 0.5, color = 'red') +
  labs(x = "Trump's Weighted Polling Average",
       y = "Trump's Predicted Vote Share",
       title = "Trump's Predicted Vote Share vs. Polling Average") +
  theme_classic()

ggsave("figures/Refl_Pred_vs_Polls.png", height = 3, width = 5)

ggplot(poll_comps, aes(x = R_pa2p_weighted, y = R_pv2p)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1) +
  geom_hline(yintercept = 0.5, color = 'red') +
  geom_vline(xintercept = 0.5, color = 'red') +
  labs(x = "Trump's Weighted Polling Average",
       y = "Trump's Actual Vote Share",
       title = "Trump's Actual Vote Share vs. Polling Average") +
  theme_classic()

ggsave("figures/Refl_Actual_vs_Poll.png", height = 3, width = 5)

# Electoral Map

state_2020_ec_plot <- R_state_preds_2020_final %>% 
  ggplot(aes(state = state, 
             fill = est_winner, 
             name = "Predicted Winner")) +
  geom_statebins(border_col = "black", border_size = 0.25) + 
  theme_statebins() +
  scale_fill_manual(values = c("#619CFF", "#F8766D"),
                    breaks = c("Biden", "Trump")) +
  labs(title = "2020 Presidential Election Prediction Map",
       fill = "")

ggsave("figures/R_state_ec_map.png", height = 4, width = 6)

# RMSE

RMSE <- final_comps %>%
  mutate(error = R_pv2p - fit) %>%
  mutate(squared_error = error ^2) %>%
  summarize(rmse = sqrt(mean(squared_error))) %>%
  select(rmse) %>%
  pull(1)

# Errors

final_comps <- final_comps %>%
  mutate(error = R_pv2p - fit)

mean_error <- final_comps %>%
  summarize(mean_error = mean(error)) %>%
  select(mean_error) %>%
  pull(1)

ggplot(final_comps) +
  geom_histogram(aes(x = error), binwidth = 0.005, color = 'black', fill = 'white') +
  labs(x = "Residual Error",
       y = "Count",
       title = "Residual Errors from State-Level Model") +
  geom_vline(xintercept = mean_error, color = 'red') +
  theme_classic()

ggsave("figures/Refl_errors_hist.png", height = 4, width = 6)

# Error map

state_2020_error_plot <- final_comps %>% 
  ggplot(aes(state = state, 
             fill = error, 
             name = "Error")) +
  geom_statebins(border_col = "black", border_size = 0.25) + 
  theme_statebins() +
  scale_fill_gradient2(high = "#F8766D",
                       mid = "white",
                       low = "#619CFF",
                       breaks = c(-.125, 0, 0.125),
                       limit = c(-0.125, 0.125)) +
  labs(title = "2020 Presidential Election Prediction Errors",
       fill = "")

ggsave("figures/Refl_errors_map.png", height = 4, width = 6)

# Poll error vs residuals

poll_comps <- poll_comps %>%
  mutate(poll_error = R_pv2p - R_pa2p_weighted,
         model_error = R_pv2p - fit)

poll_comps %>%
  ggplot() +
  geom_point(aes(x = poll_error, y = model_error, color = R_pv2p)) +
  labs(x = "Poll Error (Trump's Actual Vote Share - Polling Average)",
       y = "Model Residual",
       title = "Model Residuals vs. Poll Errors",
       legend = "Trump Two-Party Vote Share") +
  geom_abline(color = 'black') +
  geom_smooth(aes(x = poll_error, y = model_error), formula = y ~ x, method = 'lm', se = FALSE, color = 'red') +
  theme_classic()

ggsave("figures/Refl_poll_error_vs_residuals.png", height = 4, width = 6)

r <- cor(poll_comps$poll_error, poll_comps$model_error)
R2 <- r^2

mean_poll_error <- mean(poll_comps$poll_error)

poll_comps %>%
  select(state, poll_error, R_pv2p, fit, model_error) %>%
  arrange(desc(poll_error))

poll_comps %>%
  filter(state %in% c("Michigan", "Wisconsin", "Pennsylvania", "Texas", "Georgia", "Florida", "North Carolina",
                      "Arizona", "Iowa", "Ohio")) %>%
  select(state, poll_error, R_pv2p, fit, model_error) %>%
  arrange(desc(poll_error))

# Trump PV2p vs poll error

poll_comps %>%
  ggplot() +
  geom_point(aes(x = R_pv2p, y = poll_error)) +
  theme_classic() +
  geom_smooth(aes(x = R_pv2p, y = poll_error), formula = y ~ x, method = 'lm', se = FALSE) +
  geom_hline(yintercept = 0, color = 'red') +
  labs(x = "Trump Two-Party Vote Share",
       y = "Polling Error",
       title = "Polling Error vs. Support for Trump")

ggsave("figures/Refl_poll_error_vs_trump_support.png", height = 4, width = 6)

r <- cor(poll_comps$R_pv2p, poll_comps$poll_error)
R2 <- r^2
