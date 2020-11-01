# Load libraries

library(tidyverse)
library(usmap)
library(maps)
library(loo)
library(geofacet)
library(broom)
library(caret)
library(stringr)
library(gt)
library(statebins)

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

# Data Wrangling

set.seed(123)

# National Data

pres_poll_avg_2020_natl <- pres_poll_avg_2020 %>%
  filter(state == "National") %>%
  filter(candidate_name %in% c("Joseph R. Biden Jr.", "Donald Trump")) %>%
  mutate(year = cycle) %>%
  mutate(date = modeldate) %>%
  mutate(candidate = candidate_name) %>%
  mutate(poll_avg = pct_estimate) %>%
  select(date, year, candidate, poll_avg) %>%
  mutate(election_day = "11/03/2020") %>%
  mutate(days_left = as.numeric(difftime(as.Date.character(election_day, format = "%m/%d/%Y"), 
                                         as.Date.character(date, format = "%m/%d/%Y"), 
                                         units = "days"))) %>%
  mutate(party = ifelse(candidate == "Donald Trump", "republican", "democrat")) %>%
  select(year, party, candidate, poll_avg, days_left) %>%
  pivot_wider(id_cols = c(year, days_left), names_from = party, values_from = poll_avg) %>%
  mutate(D_pa = democrat,
         R_pa = republican,
         D_pa2p = D_pa / (D_pa + R_pa),
         R_pa2p = R_pa / (D_pa + R_pa)) %>%
  select(year, days_left, D_pa2p, R_pa2p) %>%
  mutate(weight = 1 / days_left) %>%
  filter(days_left > 0) %>%
  filter(days_left < 63) %>%
  drop_na() %>%
  group_by(year) %>%
  mutate(weight = 1 / days_left) %>%
  mutate(rel_weight = weight / sum(weight)) %>%
  ungroup() %>%
  mutate(D_pa2p_rw = D_pa2p * rel_weight,
         R_pa2p_rw = R_pa2p * rel_weight) %>%
  group_by(year) %>%
  summarize(D_pa2p_weighted = sum(D_pa2p_rw),
            R_pa2p_weighted = sum(R_pa2p_rw))

pres_poll_avg_hist_natl <- pres_poll_avg_hist_natl %>%
  mutate(candidate = candidate_name) %>%
  mutate(poll_avg = avg_support) %>%
  select(year, party, candidate, poll_avg, days_left) %>%
  pivot_wider(id_cols = c(year, days_left), names_from = party, values_from = poll_avg) %>%
  mutate(D_pa = democrat,
         R_pa = republican,
         D_pa2p = D_pa / (D_pa + R_pa),
         R_pa2p = R_pa / (D_pa + R_pa)) %>%
  select(year, days_left, D_pa2p, R_pa2p) %>%
  filter(days_left > 0) %>%
  filter(days_left < 63) %>%
  drop_na() %>%
  group_by(year) %>%
  mutate(weight = 1 / days_left) %>%
  mutate(rel_weight = weight / sum(weight)) %>%
  ungroup() %>%
  mutate(D_pa2p_rw = D_pa2p * rel_weight,
         R_pa2p_rw = R_pa2p * rel_weight) %>%
  group_by(year) %>%
  summarize(D_pa2p_weighted = sum(D_pa2p_rw),
            R_pa2p_weighted = sum(R_pa2p_rw))


pres_appr_2020 <- pres_appr_2020 %>%
  filter(subgroup == "Voters") %>%
  mutate(net_approval = approve_estimate - disapprove_estimate) %>%
  mutate(date = modeldate) %>%
  mutate(president = "Donald Trump") %>%
  select(date, net_approval, president) %>%
  mutate(election_day = "11/03/2020") %>%
  mutate(days_left = as.numeric(difftime(as.Date.character(election_day, format = "%m/%d/%Y"), 
                                         as.Date.character(date, format = "%m/%d/%Y"), 
                                         units = "days"))) %>%
  filter(days_left > 0) %>%
  filter(days_left < 63) %>%
  drop_na() %>%
  mutate(weight = 1 / days_left) %>%
  mutate(rel_weight = weight / sum(weight)) %>%
  mutate(net_approval_rw = net_approval * rel_weight) %>%
  summarize(net_approval_weighted = sum(net_approval_rw) / 100) %>%
  mutate(year = 2020) %>%
  select(year, net_approval_weighted)

pres_appr_hist <- pres_appr_hist %>%
  filter(president != "Donald Trump") %>%
  mutate(net_approval = approve - disapprove) %>%
  mutate(date = poll_enddate) %>%
  select(date, net_approval, president) %>%
  separate(col = date, into = c("year", "month", "day"), sep = "-", remove = FALSE) %>%
  filter(year %in% c(1944, 1948, 1952, 1956, 1960, 1964, 1968, 1972, 1976, 1980, 1984, 1988,
                     1992, 1996, 2000, 2004, 2008, 2012, 2016)) %>%
  mutate(election_day = case_when(
    year == "2016" ~ "2016-11-08",
    year == "2012" ~ "2012-11-06",
    year == "2008" ~ "2008-11-04",
    year == "2004" ~ "2004-11-02",
    year == "2000" ~ "2000-11-07",
    year == "1996" ~ "1996-11-05",
    year == "1992" ~ "1992-11-03",
    year == "1988" ~ "1988-11-08",
    year == "1984" ~ "1984-11-06",
    year == "1980" ~ "1980-11-04",
    year == "1976" ~ "1976-11-02",
    year == "1972" ~ "1972-11-07",
    year == "1968" ~ "1968-11-05",
    year == "1964" ~ "1964-11-03",
    year == "1960" ~ "1960-11-08",
    year == "1956" ~ "1956-11-06",
    year == "1952" ~ "1952-11-04",
    year == "1948" ~ "1948-11-02",
    year == "1944" ~ "1944-11-07")) %>%
  mutate(days_left = as.numeric(difftime(as.Date.character(election_day, format = "%Y-%m-%d"), 
                                         as.Date.character(date, format = "%Y-%m-%d"), 
                                         units = "days"))) %>%
  filter(days_left > 0) %>%
  filter(days_left < 63) %>%
  drop_na() %>%
  group_by(year) %>%
  mutate(weight = 1 / days_left) %>%
  mutate(rel_weight = weight / sum(weight)) %>%
  ungroup() %>%
  mutate(net_approval_rw = net_approval * rel_weight) %>%
  group_by(year) %>%
  summarize(net_approval_weighted = sum(net_approval_rw) / 100) %>%
  mutate(year = as.integer(year))

pv_hist_natl <- pv_hist_natl %>%
  select(year, party, candidate, pv2p, winner, incumbent) %>%
  mutate(D_inc = ifelse(party == "democrat" & incumbent == "TRUE", "TRUE", "FALSE")) %>%
  mutate(R_inc = ifelse(party == "republican" & incumbent == "TRUE", "TRUE", "FALSE")) %>%
  pivot_wider(id_cols = "year", names_from = party, values_from = pv2p) %>%
  mutate(D_pv2p = democrat / 100,
         R_pv2p = republican / 100) %>%
  mutate(fmr_D_pv2p = lag(D_pv2p),
         fmr_R_pv2p = lag(R_pv2p)) %>%
  select(year, D_pv2p, R_pv2p, fmr_D_pv2p, fmr_R_pv2p)

pv_hist_natl[1, 4] = 0.5377380
pv_hist_natl[1, 5] = 0.4622619

demog_2020 <- demog %>%
  filter(year == 2018) %>%
  select(year, state, White, total) %>%
  mutate(white_ttl = White * total / 100) %>%
  group_by(year) %>%
  summarize(white_sum = sum(white_ttl),
            total = sum(total)) %>%
  mutate(white_pct = white_sum / total) %>%
  mutate(year = 2020) %>%
  select(year, white_pct)

demog_hist <- demog %>%
  filter(year %in% c(1944, 1948, 1952, 1956, 1960, 1964, 1968, 1972, 1976, 1980, 1984, 1988,
                     1992, 1996, 2000, 2004, 2008, 2012, 2016)) %>%
  select(year, state, White, total) %>%
  mutate(white_ttl = White * total / 100) %>%
  group_by(year) %>%
  summarize(white_sum = sum(white_ttl),
            total = sum(total)) %>%
  mutate(white_pct = white_sum / total) %>%
  select(year, white_pct)

hist_natl <- full_join(pv_hist_natl, pres_poll_avg_hist_natl, by = "year") %>%
  full_join(demog_hist, by = "year") %>%
  full_join(pres_appr_hist, by = "year") %>%
  mutate(R_inc = case_when(
    year == "2016" ~ 0,
    year == "2012" ~ 0,
    year == "2008" ~ 0,
    year == "2004" ~ 1,
    year == "2000" ~ 0,
    year == "1996" ~ 0,
    year == "1992" ~ 1,
    year == "1988" ~ 0,
    year == "1984" ~ 1,
    year == "1980" ~ 0,
    year == "1976" ~ 1,
    year == "1972" ~ 1,
    year == "1968" ~ 0,
    year == "1964" ~ 0,
    year == "1960" ~ 0,
    year == "1956" ~ 1,
    year == "1952" ~ 0,
    year == "1948" ~ 0)) %>%
  mutate(D_inc = case_when(
    year == "2016" ~ 0,
    year == "2012" ~ 1,
    year == "2008" ~ 0,
    year == "2004" ~ 0,
    year == "2000" ~ 0,
    year == "1996" ~ 1,
    year == "1992" ~ 0,
    year == "1988" ~ 0,
    year == "1984" ~ 0,
    year == "1980" ~ 1,
    year == "1976" ~ 0,
    year == "1972" ~ 0,
    year == "1968" ~ 0,
    year == "1964" ~ 1,
    year == "1960" ~ 0,
    year == "1956" ~ 0,
    year == "1952" ~ 0,
    year == "1948" ~ 1)) %>%
  mutate(inc_pv2p = ifelse(D_inc == 1, D_pv2p, ifelse(R_inc == 1, R_pv2p, NA))) %>%
  mutate(inc_pa2p_weighted = ifelse(D_inc == 1, D_pa2p_weighted, ifelse(R_inc == 1, R_pa2p_weighted, NA))) %>%
  mutate(fmr_inc_pv2p = ifelse(D_inc == 1, fmr_D_pv2p, ifelse(R_inc ==1, fmr_R_pv2p, NA))) %>%
  mutate(inc_net_approval_weighted = ifelse(is.na(inc_pv2p) == FALSE, net_approval_weighted, NA)) %>%
  mutate(inc_party = ifelse(D_inc == 1, "Democrat", ifelse(R_inc == 1, "Republican", NA)))

fmr_2020 <- pv_hist_natl %>%
  filter(year == 2016) %>%
  select(D_pv2p, R_pv2p) %>%
  mutate(fmr_D_pv2p = D_pv2p,
         fmr_R_pv2p = R_pv2p) %>%
  mutate(year = 2020) %>%
  select(year, fmr_D_pv2p, fmr_R_pv2p)
# Model Fitting

# D_polls_model_df <- hist_natl %>%
#   select(year, D_pv2p, D_pa2p_weighted) %>%
#   drop_na()
# 
# D_polls_model <- train(D_pv2p ~ D_pa2p_weighted, 
#                            data = D_polls_model_df, method = "lm", trControl = trainControl(method = "LOOCV"))

R_polls_model_df <- hist_natl %>%
  select(year, R_pv2p, R_pa2p_weighted) %>%
  drop_na()

R_polls_model <- train(R_pv2p ~ R_pa2p_weighted, 
                       data = R_polls_model_df, method = "lm", trControl = trainControl(method = "LOOCV"))

# D_polls_fmr_model_df <- hist_natl %>%
#   select(year, D_pv2p, fmr_D_pv2p, D_pa2p_weighted) %>%
#   drop_na()
# 
# D_polls_fmr_model <- train(D_pv2p ~ fmr_D_pv2p + D_pa2p_weighted, 
#                          data = D_polls_fmr_model_df, method = "lm", trControl = trainControl(method = "LOOCV"))

R_polls_fmr_model_df <- hist_natl %>%
  select(year, R_pv2p, fmr_R_pv2p, R_pa2p_weighted) %>%
  drop_na()

R_polls_fmr_model <- train(R_pv2p ~ fmr_R_pv2p + R_pa2p_weighted, 
                           data = R_polls_fmr_model_df, method = "lm", trControl = trainControl(method = "LOOCV"))

# D_polls_fmr_demog_model_df <- hist_natl %>%
#   select(year, D_pv2p, fmr_D_pv2p, D_pa2p_weighted, white_pct) %>%
#   drop_na()
# 
# D_polls_fmr_demog_model <- train(D_pv2p ~ fmr_D_pv2p + D_pa2p_weighted + white_pct, 
#                                  data = D_polls_fmr_demog_model_df, method = "lm", trControl = trainControl(method = "LOOCV"))

R_polls_fmr_demog_model_df <- hist_natl %>%
  select(year, R_pv2p, fmr_R_pv2p, R_pa2p_weighted, white_pct) %>%
  drop_na()

R_polls_fmr_demog_model <- train(R_pv2p ~ fmr_R_pv2p + R_pa2p_weighted + white_pct, 
                                 data = R_polls_fmr_demog_model_df, method = "lm", trControl = trainControl(method = "LOOCV"))

inc_df <- hist_natl %>%
  select(year, inc_party, inc_pv2p, fmr_inc_pv2p, inc_pa2p_weighted, inc_net_approval_weighted)

inc_polls_model_df <- inc_df %>%
  select(year, inc_pv2p, inc_pa2p_weighted) %>%
  drop_na()

inc_polls_model <- train(inc_pv2p ~ inc_pa2p_weighted, 
                   data = inc_polls_model_df, method = "lm", trControl = trainControl(method = "LOOCV"))

inc_polls_approval_model_df <- inc_df %>%
  select(year, inc_pv2p, inc_pa2p_weighted, inc_net_approval_weighted) %>%
  drop_na()

inc_polls_approval_model <- train(inc_pv2p ~ inc_pa2p_weighted + inc_net_approval_weighted, 
                                  data = inc_polls_approval_model_df, method = "lm", trControl = trainControl(method = "LOOCV"))

summary(inc_polls_approval_model)

R_models <- tibble(model = c("R_polls_model", "R_polls_fmr_model", "R_polls_fmr_demog_model"))
inc_models <- tibble(model = c("inc_polls_model", "inc_polls_approval_model"))

R_loocv_results <- rbind(R_polls_model$results, R_polls_fmr_model$results, R_polls_fmr_demog_model$results)
inc_loocv_results <- rbind(inc_polls_model$results, inc_polls_approval_model$results)

R_loocv_results_table <- R_models %>% 
  cbind(R_loocv_results) %>% 
  tibble()
inc_loocv_results_table <- inc_models %>% 
  cbind(inc_loocv_results) %>% 
  tibble()

R_model_outputs <- export_summs(R_polls_model$finalModel, R_polls_fmr_model$finalModel, R_polls_fmr_demog_model$finalModel,
                                error_format = "({round(std.error, 3)})",
                                coefs = c("Intercept" = "(Intercept)",
                                          "Republican Weighted Poll Avg." = "R_pa2p_weighted",
                                          "Last Rep. 2 Party Pop. Vote" = "fmr_R_pv2p",
                                          "White % of Pop." = "white_pct"),
                                statistics = c(N = "nobs",
                                               R2 = "r.squared",
                                               R2.adj = "adj.r.squared",
                                               sigma = "sigma")) %>%
  filter(`Model 1` != "Model 1")

gt_R_models <- R_model_outputs %>%
  gt(rowname_col = "names") %>%
  tab_header(
    title = "Model Outputs Predicting Republican Two-Party Popular Vote"
  )

inc_model_outputs <- export_summs(inc_polls_model$finalModel, inc_polls_approval_model$finalModel,
                                  error_format = "({round(std.error, 3)})",
                                  coefs = c("Intercept" = "(Intercept)",
                                            "Incumbent's Weighted Poll Avg." = "inc_pa2p_weighted",
                                            "Incumbent's Weighted Net Approval" = "inc_net_approval_weighted"),
                                  statistics = c(N = "nobs",
                                                R2 = "r.squared",
                                                R2.adj = "adj.r.squared",
                                                sigma = "sigma")) %>%
  filter(`Model 1` != "Model 1")

gt_inc_models <- inc_model_outputs %>%
  gt(rowname_col = "names") %>%
  tab_header(
    title = "Model Outputs Predicting Incumbent Two-Party Popular Vote"
  )

natl_2020 <- full_join(fmr_2020, pres_poll_avg_2020_natl, by = "year") %>%
  full_join(demog_2020, by = "year") %>%
  full_join(pres_appr_2020, by = "year") %>%
  mutate(R_inc = 1,
         D_inc = 0,
         inc_pa2p_weighted = R_pa2p_weighted,
         fmr_inc_pv2p = fmr_R_pv2p,
         inc_net_approval_weighted = net_approval_weighted,
         inc_party = "Republican")

R_natl_2020 <- natl_2020 %>%
  select(year, fmr_R_pv2p, R_pa2p_weighted, white_pct)

inc_natl_2020 <- natl_2020 %>%
  select(year, inc_pa2p_weighted, fmr_inc_pv2p, inc_net_approval_weighted, inc_party)

R_natl_model_final <- lm(R_pv2p ~ fmr_R_pv2p + R_pa2p_weighted, data = R_polls_fmr_model_df)

R_natl_pred_final_df <- predict.lm(object = R_natl_model_final, newdata = R_natl_2020, se.fit=TRUE, interval="confidence", level=0.95)

R_natl_pred_est <- R_natl_pred_final_df$fit[1, 1]
R_natl_pred_lwr <- R_natl_pred_final_df$fit[1, 2]
R_natl_pred_upr <- R_natl_pred_final_df$fit[1, 3]

sim_R_natl_2020 <- tibble(id = as.numeric(1:10000),
                   pred_fit = rep(R_natl_pred_est, 10000),
                   pred_se = rep(R_natl_pred_final_df$se.fit, 10000)) %>% 
  mutate(pred_prob = map_dbl(.x = pred_fit, .y = pred_se, ~rnorm(n = 1, mean = .x, sd = .y))) %>% 
  mutate(id = case_when(
    id %% 2 == 1 ~ id,
    id %% 2 == 0 ~ id - 1))

sim_R_2020_plot <- sim_R_natl_2020 %>% 
  ggplot(aes(x = pred_prob, fill = "red")) +
  geom_density(alpha = 0.2) +
  theme_classic() +
  labs(
    title = "Trump's Two-Party Popular Vote Predictive Interval",
    subtitle = "10,000 simulations of Republican Vote Model",
    x = "Trump's Predicted Two-Party Popular Vote",
    y = "Density" ) + 
  #scale_x_continuous(breaks = seq(46, 60, by = 2), labels = percent_format(accuracy = 1, scale = 1)) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  theme(legend.position = "none") +
  geom_vline(xintercept = 0.5)

ggsave("figures/Final_R_natl_sim.png", height = 4, width = 6)

inc_natl_model_final <- lm(inc_pv2p ~ inc_pa2p_weighted + inc_net_approval_weighted, data = inc_polls_approval_model_df)

inc_natl_pred_final_df <- predict.lm(object = inc_natl_model_final, newdata = inc_natl_2020, se.fit=TRUE, interval="confidence", level=0.95)
  
inc_natl_pred_est <- inc_natl_pred_final_df$fit[1, 1]
inc_natl_pred_lwr <- inc_natl_pred_final_df$fit[1, 2]
inc_natl_pred_upr <- inc_natl_pred_final_df$fit[1, 3]

sim_inc_natl_2020 <- tibble(id = as.numeric(1:10000),
                          pred_fit = rep(inc_natl_pred_est, 10000),
                          pred_se = rep(inc_natl_pred_final_df$se.fit, 10000)) %>% 
  mutate(pred_prob = map_dbl(.x = pred_fit, .y = pred_se, ~rnorm(n = 1, mean = .x, sd = .y))) %>% 
  mutate(id = case_when(
    id %% 2 == 1 ~ id,
    id %% 2 == 0 ~ id - 1)) %>%
  mutate(pred_winner = ifelse(pred_prob > 0.5, 1, 0))

sim_inc_2020_plot <- sim_inc_natl_2020 %>% 
  ggplot(aes(x = pred_prob, fill = "red")) +
  geom_density(alpha = 0.2) +
  theme_classic() +
  labs(
    title = "Trump's Two-Party Popular Vote Predictive Interval",
    subtitle = "10,000 simulations of Incumbent Vote Model",
    x = "Trump's Predicted Two-Party Popular Vote",
    y = "Density" ) + 
  #scale_x_continuous(breaks = seq(46, 60, by = 2), labels = percent_format(accuracy = 1, scale = 1)) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  theme(legend.position = "none") +
  geom_vline(xintercept = 0.5, color = "black")

ggsave("figures/Final_inc_natl_sim.png", height = 4, width = 6)

# State Data

pres_poll_avg_2020_state <- pres_poll_avg_2020 %>%
  filter(state != "National") %>%
  filter(candidate_name %in% c("Joseph R. Biden Jr.", "Donald Trump")) %>%
  mutate(year = cycle) %>%
  mutate(date = modeldate) %>%
  mutate(candidate = candidate_name) %>%
  mutate(poll_avg = pct_estimate) %>%
  select(date, state, year, candidate, poll_avg) %>%
  mutate(election_day = "11/03/2020") %>%
  mutate(days_left = as.numeric(difftime(as.Date.character(election_day, format = "%m/%d/%Y"), 
                                         as.Date.character(date, format = "%m/%d/%Y"), 
                                         units = "days"))) %>%
  mutate(party = ifelse(candidate == "Donald Trump", "republican", "democrat")) %>%
  select(state, year, party, candidate, poll_avg, days_left) %>%
  pivot_wider(id_cols = c(year, state, days_left), names_from = party, values_from = poll_avg) %>%
  mutate(D_pa = democrat,
         R_pa = republican,
         D_pa2p = D_pa / (D_pa + R_pa),
         R_pa2p = R_pa / (D_pa + R_pa)) %>%
  select(year, state, days_left, D_pa2p, R_pa2p) %>%
  mutate(weight = 1 / days_left) %>%
  filter(days_left > 0) %>%
  filter(days_left < 63) %>%
  drop_na() %>%
  group_by(year, state) %>%
  mutate(weight = 1 / days_left) %>%
  mutate(rel_weight = weight / sum(weight)) %>%
  ungroup() %>%
  mutate(D_pa2p_rw = D_pa2p * rel_weight,
         R_pa2p_rw = R_pa2p * rel_weight) %>%
  group_by(year, state) %>%
  summarize(D_pa2p_weighted = sum(D_pa2p_rw),
            R_pa2p_weighted = sum(R_pa2p_rw)) %>%
  filter(state != "ME-1",
         state != "ME-2", 
         state != "NE-1", 
         state != "NE-2")

pres_poll_avg_hist_state <- pres_poll_avg_hist_state %>%
  mutate(poll_avg = avg_poll) %>%
  select(year, state, party, days_left, poll_avg) %>%
  pivot_wider(id_cols = c(year, state, days_left), names_from = party, values_from = poll_avg) %>%
  mutate(D_pa = democrat,
         R_pa = republican,
         D_pa2p = D_pa / (D_pa + R_pa),
         R_pa2p = R_pa / (D_pa + R_pa)) %>%
  select(year, state, days_left, D_pa2p, R_pa2p) %>%
  mutate(weight = 1 / days_left) %>%
  filter(days_left > 0) %>%
  filter(days_left < 63) %>%
  drop_na() %>%
  group_by(year, state) %>%
  mutate(weight = 1 / days_left) %>%
  mutate(rel_weight = weight / sum(weight)) %>%
  ungroup() %>%
  mutate(D_pa2p_rw = D_pa2p * rel_weight,
         R_pa2p_rw = R_pa2p * rel_weight) %>%
  group_by(year, state) %>%
  summarize(D_pa2p_weighted = sum(D_pa2p_rw),
            R_pa2p_weighted = sum(R_pa2p_rw)) %>%
  filter(state != "ME-1",
         state != "ME-2", 
         state != "NE-1", 
         state != "NE-2")

pv_hist_state <- pv_hist_state %>%
  select(state, year, R_pv2p, D_pv2p) %>%
  mutate(R_pv2p = R_pv2p / 100,
         D_pv2p = D_pv2p / 100) %>%
  mutate(R_inc = case_when(
    year == "2016" ~ 0,
    year == "2012" ~ 0,
    year == "2008" ~ 0,
    year == "2004" ~ 1,
    year == "2000" ~ 0,
    year == "1996" ~ 0,
    year == "1992" ~ 1,
    year == "1988" ~ 0,
    year == "1984" ~ 1,
    year == "1980" ~ 0,
    year == "1976" ~ 1,
    year == "1972" ~ 1,
    year == "1968" ~ 0,
    year == "1964" ~ 0,
    year == "1960" ~ 0,
    year == "1956" ~ 1,
    year == "1952" ~ 0,
    year == "1948" ~ 0)) %>%
  group_by(state) %>%
  mutate(fmr_D_pv2p = lag(D_pv2p),
         fmr_R_pv2p = lag(R_pv2p)) %>%
  ungroup() %>%
  drop_na()

demog_hist_state <- demog %>%
  mutate(white_pct = White / 100) %>%
  select(year, state, white_pct) %>%
  left_join(state_abbs, by = c("state" = "Code")) %>%
  select(year, State, white_pct) %>%
  mutate(state = State) %>%
  select(year, state, white_pct) %>%
  filter(year %in% c(1976, 1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016))

demog_2020_state <- demog %>%
  filter(year == 2018) %>%
  mutate(year = 2020) %>%
  mutate(white_pct = White / 100) %>%
  select(year, state, white_pct) %>%
  left_join(state_abbs, by = c("state" = "Code")) %>%
  select(year, State, white_pct) %>%
  mutate(state = State) %>%
  select(year, state, white_pct)

state_hist <- full_join(pres_poll_avg_hist_state, pv_hist_state, by = c("year", "state")) %>%
  full_join(demog_hist_state, by = c("year", "state"))

fmr_state_2020 <- pv_hist_state %>%
  filter(year == 2016) %>%
  select(state, R_pv2p, D_pv2p) %>%
  mutate(fmr_D_pv2p = D_pv2p,
         fmr_R_pv2p = R_pv2p) %>%
  mutate(year = 2020) %>%
  select(year, state, fmr_R_pv2p, fmr_D_pv2p)

state_2020 <- full_join(pres_poll_avg_2020_state, demog_2020_state, by = c("year", "state")) %>%
  full_join(fmr_state_2020, by = c("year", "state")) %>%
  mutate(R_inc = 1)

# State Models

R_state_polls_fmr_model_df <- state_hist %>%
  select(year, state, R_pa2p_weighted, R_pv2p, fmr_R_pv2p) %>%
  drop_na()

R_state_polls_fmr_model <- train(R_pv2p ~ fmr_R_pv2p + R_pa2p_weighted, 
                                     data = R_state_polls_fmr_model_df, method = "lm", trControl = trainControl(method = "LOOCV"))

summary(R_state_polls_fmr_model)

R_state_polls_fmr_inc_model_df <- state_hist %>%
  select(year, state, R_pa2p_weighted, R_pv2p, R_inc, fmr_R_pv2p) %>%
  drop_na()

R_state_polls_fmr_inc_model <- train(R_pv2p ~ fmr_R_pv2p + R_pa2p_weighted + R_inc, 
                                 data = R_state_polls_fmr_inc_model_df, method = "lm", trControl = trainControl(method = "LOOCV"))

summary(R_state_polls_fmr_inc_model)

R_state_polls_fmr_inc_demog_model_df <- state_hist %>%
  select(year, state, R_pa2p_weighted, R_pv2p, R_inc, fmr_R_pv2p, white_pct) %>%
  drop_na()

R_state_polls_fmr_inc_demog_model <- train(R_pv2p ~ fmr_R_pv2p + R_pa2p_weighted + R_inc + white_pct, 
                                     data = R_state_polls_fmr_inc_demog_model_df, method = "lm", trControl = trainControl(method = "LOOCV"))

summary(R_state_polls_fmr_inc_demog_model)

R_state_polls_fmr_demog_model_df <- state_hist %>%
  select(year, state, R_pa2p_weighted, R_pv2p, fmr_R_pv2p, white_pct) %>%
  drop_na()

R_state_polls_fmr_demog_model <- train(R_pv2p ~ fmr_R_pv2p + R_pa2p_weighted + white_pct, 
                                           data = R_state_polls_fmr_demog_model_df, method = "lm", trControl = trainControl(method = "LOOCV"))

summary(R_state_polls_fmr_demog_model)

R_state_models <- tibble(model = c("R_state_polls_fmr_mode", "R_state_polls_fmr_inc_model", "R_state_polls_fmr_inc_demog_model", "R_state_polls_fmr_demog_model"))

R_state_loocv_results <- rbind(R_state_polls_fmr_model$results, R_state_polls_fmr_inc_model$results, R_state_polls_fmr_inc_demog_model$results, R_state_polls_fmr_demog_model$results)

R_state_loocv_results_table <- R_state_models %>% 
  cbind(R_state_loocv_results) %>% 
  tibble()

R_state_model_outputs <- export_summs(R_state_polls_fmr_model$finalModel, R_state_polls_fmr_inc_model$finalModel, R_state_polls_fmr_inc_demog_model$finalModel, R_state_polls_fmr_demog_model$finalModel,
                                error_format = "({round(std.error, 3)})",
                                coefs = c("Intercept" = "(Intercept)",
                                          "Republican Weighted Poll Avg." = "R_pa2p_weighted",
                                          "Last Rep. 2 Party Pop. Vote" = "fmr_R_pv2p",
                                          "Republican Incumbent" = "R_inc",
                                          "White % of Pop." = "white_pct"),
                                statistics = c(N = "nobs",
                                               R2 = "r.squared",
                                               R2.adj = "adj.r.squared",
                                               sigma = "sigma")) %>%
  filter(`Model 1` != "Model 1")

gt_R_state_models <- R_state_model_outputs %>%
  gt(rowname_col = "names") %>%
  tab_header(
    title = "Model Outputs Predicting State-Level Republican Two-Party Popular Vote"
  )

smp_size <- floor(0.75 * nrow(R_state_polls_fmr_inc_demog_model_df))
train_ind <- sample(seq_len(nrow(R_state_polls_fmr_inc_demog_model_df)), size = smp_size)
R_state_train <- R_state_polls_fmr_inc_demog_model_df[train_ind, ]
R_state_test <- R_state_polls_fmr_inc_demog_model_df[-train_ind, ]

R_state_model_final <- lm(R_pv2p ~ fmr_R_pv2p + R_pa2p_weighted + R_inc + white_pct, data = R_state_train)

R_state_pred_final_df <- predict.lm(object = R_state_model_final, newdata = state_2020, se.fit=TRUE, interval="confidence", level=0.95)

R_state_preds <- as.data.frame(R_state_pred_final_df$fit)
R_state_errors <- as.data.frame(R_state_pred_final_df$se.fit)

R_state_preds_2020 <- cbind(state_2020, R_state_preds) %>%
  select(year, state, fit, lwr, upr) %>%
  cbind(R_state_errors)

R_state_model_OOS_MSE = mean((R_state_test$R_pv2p - predict.lm(R_state_model_final, R_state_test)) ^ 2)
R_state_model_OOS_RMSE = sqrt(R_state_model_OOS_MSE)

ec_2020 <- ec %>%
  select(X1, `2020`) %>%
  mutate(state = X1,
         ev = `2020`) %>%
  select(state, ev) %>%
  drop_na()

R_state_preds_2020_final <- inner_join(R_state_preds_2020, ec_2020, by = "state") %>%
  mutate(est_winner = ifelse(fit > 0.5, "Trump", "Biden"),
         lwr_winner = ifelse(lwr > 0.5, "Trump", "Biden"),
         upr_winner = ifelse(upr > 0.5, "Trump", "Biden")) %>%
  mutate(est_R_margin = (fit - 0.5) * 2,
         lwr_R_margin = (lwr - 0.5) * 2,
         upr_R_margin = (upr - 0.5) * 2) %>%
  mutate(est_type = ifelse(est_R_margin > 0.1, "Solid Trump",
                           ifelse(est_R_margin > 0.05, "Lean Trump",
                                  ifelse(est_R_margin > -0.05, "Toss-Up",
                                         ifelse(est_R_margin > -0.1, "Lean Biden", "Solid Biden"))))) %>%
  mutate(OOS_lwr = fit - 2 * R_state_model_OOS_RMSE,
         OOS_upr = fit + 2 * R_state_model_OOS_RMSE,
         OOS_lwr_winner = ifelse(OOS_lwr > 0.5, "Trump", "Biden"),
         OOS_upr_winner = ifelse(OOS_upr > 0.5, "Trump", "Biden"))

state_2020_plot <- R_state_preds_2020_final %>% 
  ggplot(aes(state = state, 
             fill = est_type, 
             name = "Predicted Win Margin")) +
  geom_statebins(border_col = "black", border_size = 0.25) + 
  theme_statebins() +
  scale_fill_manual(values = c("#619CFF", "#C3D7F7", "#ECCB9C", "#FACECA", "#F8766D"),
                    breaks = c("Solid Biden", "Lean Biden", "Toss-Up", "Lean Trump", "Solid Trump")) +
  labs(title = "2020 Presidential Election Prediction Map",
       fill = "")

ggsave("figures/Final_R_state_map.png", height = 4, width = 6)

state_2020_ev <- R_state_preds_2020_final %>%
  group_by(est_type) %>%
  summarize(total = sum(ev))

ev_bar <- state_2020_ev %>% 
  ggplot(aes(x = "2020", y = total, fill = fct_relevel(est_type, "Solid Trump", "Lean Trump", "Toss-Up", "Lean Biden", "Solid Biden"), label = total)) +
  geom_col(show.legend = FALSE, width = 0.25) + 
  geom_text(position = position_stack(vjust = 0.5)) +
  geom_hline(yintercept = 270) +
  annotate(geom = 'text', x = 0.7, y = 300, label = '270') +
  coord_flip() + 
  theme_void() + 
  labs(fill = "") +
  scale_fill_manual(values = c("#619CFF", "#C3D7F7", "#ECCB9C", "#FACECA", "#F8766D"),
                    breaks = c("Solid Biden", "Lean Biden", "Toss-Up", "Lean Trump", "Solid Trump"))

ggsave("figures/Final_R_ev_bar.png", height = 1, width = 4)

est_ev <- R_state_preds_2020_final %>%
  group_by(est_winner) %>%
  summarize(total = sum(ev))

lwr_ev <- R_state_preds_2020_final %>%
  group_by(lwr_winner) %>%
  summarize(total = sum(ev))

upr_ev <- R_state_preds_2020_final %>%
  group_by(upr_winner) %>%
  summarize(total = sum(ev))

OOS_lwr_ev <- R_state_preds_2020_final %>%
  group_by(OOS_lwr_winner) %>%
  summarize(total = sum(ev))

OOS_upr_ev <- R_state_preds_2020_final %>%
  group_by(OOS_upr_winner) %>%
  summarize(total = sum(ev))



