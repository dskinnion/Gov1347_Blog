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
  summarize(net_approval_weighted = sum(net_approval_rw)) %>%
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
  summarize(net_approval_weighted = sum(net_approval_rw)) %>%
  mutate(year = as.integer(year))

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
  full_join(pres_appr_hist, by = "year")


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


