# Load Libraries

library(tidyverse)
library(readxl)
library(lubridate)
library(sjPlot)
library(sjmisc)
library(sjlabelled)
library(gt)

# Load in data

grants_by_state <- read_csv('data/fedgrants_bystate_1988-2008.csv')
grants_by_county <- read_csv('data/fedgrants_bycounty_1988-2008.csv')
approval <- read_csv('data/approval_gallup_1941-2020.csv')
pop_vote_state <- read_csv('data/popvote_bystate_1948-2016.csv')
pop_vote_natl <- read_csv('data/popvote_1948-2016.csv')
poll_avg_by_state <- read_csv('data/pollavg_bystate_1968-2016.csv')
poll_avg_natl <- read_csv('data/pollavg_1968-2016.csv')
polls_2020 <- read_csv('data/polls_2020.csv')
ec <- read_csv('data/electoralcollegepost1948.csv')
covid_grants_by_state <- read_xlsx('data/covid19_grants_by_state.xlsx')
state_abbs <- read_csv('data/state_abb.csv')
econ <- read_csv('data/econ.csv')

# TFC Model

approval_final <- approval %>%
  mutate(net_approval = approve - disapprove) %>%
  mutate(month = month(poll_enddate)) %>%
  filter(month %in% c(6, 7)) %>%
  filter(year %in% c(1948, 1952, 1956, 1960, 1964, 1968, 1972, 1976, 1980,
                     1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016, 2020)) %>%
  group_by(year) %>%
  arrange(desc(poll_enddate)) %>%
  slice(1) %>%
  select(year, net_approval)

econ_final <- econ %>%
  filter(year %in% c(1948, 1952, 1956, 1960, 1964, 1968, 1972, 1976, 1980,
                     1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016, 2020)) %>%
  filter(quarter == 2) %>%
  select(year, GDP_growth_qt)

incumbency <- tibble(
  "year" = c(1948, 1952, 1956, 1960, 1964, 1968, 1972, 1976, 1980,
             1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016, 2020),
  "first_term" = c(0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1)
)

pop_vote_natl_final <- pop_vote_natl %>%
  filter(incumbent_party == TRUE) %>%
  mutate(inc_party_pv2p = pv2p) %>%
  select(year, inc_party_pv2p)

TFC <- inner_join(approval_final, econ_final, by = 'year') %>%
  inner_join(incumbency, by = 'year') %>%
  full_join(pop_vote_natl_final, by = 'year')

TFC_test <- TFC %>%
  filter(year != 2020)

TFC_model <- lm(data = TFC_test, inc_party_pv2p ~ net_approval + GDP_growth_qt + first_term)

tab_model(TFC_model,
          dv.labels = c('Incumbent Party Vote Share'),
          pred.labels = c('Constant', 'Net Approval', 'Q2 GDP Growth', 'First Term'))

preds <- predict(TFC_model, TFC, interval = 'confidence')

preds <- as.data.frame(preds)

TFC$pred <- preds$fit
TFC$lower <- preds$lwr
TFC$upper <- preds$upr

TFC_2020 <- TFC %>%
  filter(year == 2020) %>%
  select(year, pred, lower, upper)


gt_2020 <- gt(data = TFC_2020)

gt_2020 <- gt_2020 %>%
    tab_header(title = "Trump's Predicted Two-Party Vote Share",
               subtitle = 'Based on the Time-For-Change Model') %>%
    tab_source_note('Methods used from Abramowitz (2016)') %>%
    cols_label(pred = 'Prediction', 
               lower = 'Lower', 
               upper = 'Upper')

gt_2020

gtsave(gt_2020, "figures/TFC_2020_prediction.png") 

ev_incumbents <- tibble(
  "year" = c(1956, 1964, 1972, 1980, 1984, 1992, 1996, 2004, 2012, 2020),
  "ev" = c(457, 486, 520, 49, 525, 168, 379, 286, 332, NA)
)

approval_final2 <- approval %>%
  mutate(net_approval = approve - disapprove) %>%
  mutate(month = month(poll_enddate)) %>%
  filter(month %in% c(10, 9, 8, 7, 6)) %>%
  filter(year %in% c(1956, 1964, 1972, 1980, 1984, 1992, 1996, 2004, 2012, 2020)) %>%
  group_by(year) %>%
  arrange(desc(poll_enddate)) %>%
  slice(1) %>%
  select(year, net_approval)

TFC_2 <- inner_join(ev_incumbents, approval_final2, by = 'year')

TFC_2_test <- TFC_2 %>%
  filter(year != 2020)

TFC_2_model <- lm(data = TFC_2_test, ev ~ net_approval)

tab_model(TFC_2_model,
          dv.labels = c('Incumbent President Electoral Vote'),
          pred.labels = c('Constant', 'Net Approval'))

preds_2 <- predict(TFC_2_model, TFC_2, interval = 'confidence')

preds_2 <- as.data.frame(preds_2)

TFC_2$pred <- preds_2$fit
TFC_2$lower <- preds_2$lwr
TFC_2$upper <- preds_2$upr

TFC_2_2020 <- TFC_2 %>%
  filter(year == 2020) %>%
  select(year, pred, lower, upper)

gt_2_2020 <- gt(data = TFC_2_2020)

gt_2_2020 <- gt_2_2020 %>%
  tab_header(title = "Trump's Predicted Electoral Vote Share",
             subtitle = "Based on Abramowitz's Simplified Model") %>%
  tab_source_note('Methods used from Abramowitz (2020)') %>%
  cols_label(pred = 'Prediction', 
             lower = 'Lower', 
             upper = 'Upper')

gt_2_2020

gtsave(gt_2_2020, "figures/TFC_2_2020_prediction.png") 


