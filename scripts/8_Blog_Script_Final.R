# Load libraries

library(tidyverse)
library(usmap)
library(maps)
library(loo)
library(geofacet)
library(broom)
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
  mutate(weight = 1 / days_left)

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
  mutate(weight = 1 / days_left)


pres_appr_2020 <- pres_appr_2020 %>%
  filter(subgroup == "Voters") %>%
  mutate(net_approval = approve_estimate - disapprove_estimate) %>%
  mutate(date = modeldate) %>%
  mutate(president = "Donald Trump") %>%
  select(date, net_approval, president) %>%
  mutate(election_day = "11/03/2020") %>%
  mutate(days_left = as.numeric(difftime(as.Date.character(election_day, format = "%m/%d/%Y"), 
                                         as.Date.character(date, format = "%m/%d/%Y"), 
                                         units = "days")))

pres_appr_hist <- pres_appr_hist %>%
  filter(president != "Donald Trump") %>%
  mutate(net_approval = approve - disapprove) %>%
  mutate(date = poll_enddate) %>%
  select(date, net_approval, president) %>%
  mutate(election_day = "2020-11-03") %>%
  mutate(days_left = as.numeric(difftime(as.Date.character(election_day, format = "%Y-%m-%d"), 
                                         as.Date.character(date, format = "%Y-%m-%d"), 
                                         units = "days")))

pv_hist_natl <- pv_hist_natl %>%
  select(year, party, candidate, pv2p, winner, incumbent) %>%
  mutate(D_inc = ifelse(party == "democrat" & incumbent == "TRUE", "TRUE", "FALSE")) %>%
  mutate(R_inc = ifelse(party == "republican" & incumbent == "TRUE", "TRUE", "FALSE")) %>%
  pivot_wider(id_cols = "year", names_from = party, values_from = pv2p) %>%
  mutate(D_pv2p = democrat,
         R_pv2p = republican) %>%
  mutate(fmr_D_pv2p = lag(D_pv2p),
         fmr_R_pv2p = lag(R_pv2p)) %>%
  select(year, D_pv2p, R_pv2p, fmr_D_pv2p, fmr_R_pv2p)

pv_hist_natl[1, 4] = 53.77380
pv_hist_natl[1, 5] = 46.22619

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


