# Load libraries

library(tidyverse)
library(usmap)
library(maps)
library(loo)
library(geofacet)
library(broom)
library(caret)
library(stringr)

# Load Data

pres_poll_avg_2020 <- read_csv("data/polls_final/presidential_poll_averages_2020.csv")
pres_appr_2020 <- read_csv("data/trump_approval_final/approval_topline.csv")
pres_appr_hist <- read_csv("data/approval_gallup_1941-2020.csv")
pres_poll_avg_hist_natl <- read_csv("data/pollavg_1968-2016.csv")
pres_poll_avg_hist_state <- read_csv("data/pollavg_bystate_1968-2016.csv")
demog <- read_csv("data/demographic_1990-2018.csv")
pv_hist_natl <- read_csv("data/popvote_1948-2016.csv")
pv_hist_state <- read_csv("data/popvote_bystate_1948-2016.csv")

# Data Wrangling

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
                              coefs = c("Intercept" = "(Intercept)",
                                        "Republican Weighted Poll Avg." = "R_pa2p_weighted",
                                        "Last Rep. 2 Party Pop. Vote" = "fmr_R_pv2p",
                                        "White % of Pop." = "white_pct"),
                              statistics = c(N = "nobs",
                                             R2 = "r.squared",
                                             R2.adj = "adj.r.squared",
                                             sigma = "sigma"))

quick_pdf(R_model_outputs, file = "graphics/R_national_models.pdf")

inc_model_outputs <- export_summs(inc_polls_model$finalModel, inc_polls_approval_model$finalModel,
                                coefs = c("Intercept" = "(Intercept)",
                                          "Incumbent's Weighted Poll Avg." = "inc_pa2p_weighted",
                                          "Incumbent's Weighted Net Approval" = "inc_net_approval_weighted"),
                                statistics = c(N = "nobs",
                                               R2 = "r.squared",
                                               R2.adj = "adj.r.squared",
                                               sigma = "sigma"))

quick_pdf(inc_model_outputs, file = "graphics/inc_national_models.pdf")

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
  select(state, year, party, candidate, poll_avg, days_left)


