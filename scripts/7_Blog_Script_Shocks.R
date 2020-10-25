# Load libraries

library(tidyverse)
library(usmap)
library(maps)
library(loo)
library(geofacet)
library(broom)
library(stringr)

# Load data

options(scipen = 999)
set.seed(107)

pv_county <- read_csv('data/popvote_bycounty_2000-2016.csv')
demg_county <- read_csv('data/demog_county_1990-2018.csv')
cv_deaths_county <- read_csv('data/Provisional_COVID-19_Death_Counts_in_the_United_States_by_County.csv')
poll_avg <- read_csv('data/presidential_poll_averages_2020_updated_oct_24.csv')
pres_appr_polls <- read_csv('data/president_approval_polls.csv')
pres_appr_topline <- read_csv('data/approval_topline.csv')
appr_polls <- read_csv('data/approval_polllist.csv')
appr_topline <- read_csv('data/approval_topline.csv')
cv_appr_polls_adj <- read_csv('data/covid_approval_polls_adjusted.csv')
cv_appr_topline <- read_csv('data/covid_approval_toplines.csv')
cv_conc_polls_adj <- read_csv('data/covid_concern_polls_adjusted.csv')
cv_conc_topline <- read_csv('data/covid_concern_toplines.csv')
cv_cases_deaths_state <- read_csv('data/United_States_COVID-19_Cases_and_Deaths_by_State_over_Time.csv')
abbs <- read_csv('data/state_abb.csv')
pv_state <- read_csv('data/popvote_bystate_1948-2016.csv')

# EDA

cv_appr_topline %>%
  ggplot(aes(x = modeldate, y = approve_estimate, group = party, color = party)) +
    geom_line() +
    labs(x = 'Date', y = 'Coronavirus Response Approval Rating')

pres_appr_topline %>%
  filter(subgroup == "Voters") %>%
  ggplot() +
    geom_point(aes(x = modeldate, y = approve_estimate)) +
    labs(x = 'Date', y = 'President Response Approval Rating')

pres_and_cv_appr_toplines <- inner_join(cv_appr_topline, pres_appr_topline, by = 'modeldate', suffix = c('_cv', '_pres'))

pres_and_cv_appr_toplines %>%
  filter(party == "all", subgroup == "Voters") %>%
  ggplot() +
    geom_point(aes(x = approve_estimate_cv, y = approve_estimate_pres))

# Joining COVID Data with Polling Data

cv_cases_deaths_state <- cv_cases_deaths_state %>%
  inner_join(abbs, by = c('state' = 'Code'))

cv_poll_state <- cv_cases_deaths_state %>%
  right_join(poll_avg, by = c('submission_date' = 'modeldate', 'State' = 'state')) %>%
  filter(candidate_name %in% c('Donald Trump', 'Joseph R. Biden Jr.'))

cv_poll_state %>%
  ggplot() +
  geom_point(aes(x = tot_cases, y = pct_trend_adjusted, color = candidate_name)) +
  facet_geo(~ State, scales = 'free') +
  scale_x_continuous()

pv_state_2016 <- pv_state %>%
  filter(year == 2016)

cv_poll_prior_state <- cv_poll_state %>%
  inner_join(pv_state_2016, by = c('State' = 'state')) %>%
  drop_na() %>%
  mutate(pct_trend_adjusted_dec = pct_trend_adjusted / 100,
         R_pv2p_dec = R_pv2p / 100,
         D_pv2p_dec = D_pv2p / 100,
         R_pv_dec = R / total,
         D_pv_dec = D / total) %>%
  mutate(D_poll_2016_dif = ifelse(candidate_name == "Joseph R. Biden Jr.", pct_trend_adjusted_dec - D_pv_dec, NA),
         R_poll_2016_dif = ifelse(candidate_name == "Donald Trump", pct_trend_adjusted_dec - R_pv_dec, NA))

# Making Regressions for Biden and Trump

smp_size <- floor(0.75 * nrow(cv_poll_prior_state))
train_ind <- sample(seq_len(nrow(cv_poll_prior_state)), size = smp_size)
train <- cv_poll_prior_state[train_ind, ]
test <- cv_poll_prior_state[-train_ind, ]

train_biden <- train %>%
  filter(candidate_name == "Joseph R. Biden Jr.")
train_trump <- train %>%
  filter(candidate_name == "Donald Trump")

test_biden <- test %>%
  filter(candidate_name == "Joseph R. Biden Jr.")
test_trump <- test %>%
  filter(candidate_name == "Donald Trump")

biden_glm <- train_biden %>%
  glm(formula = pct_trend_adjusted_dec ~ tot_cases * State, family = 'quasibinomial')

summary(biden_glm)  

train_biden$pred = predict.glm(biden_glm, train_biden, type = "response")
test_biden$pred = predict.glm(biden_glm, test_biden, type = "response")

train_biden$residual = train_biden$pct_trend_adjusted_dec - train_biden$pred
test_biden$residual = test_biden$pct_trend_adjusted_dec - test_biden$pred

train_biden_RMSE = mean(sqrt((train_biden$residual)^2))
test_biden_RMSE = mean(sqrt((test_biden$residual)^2))

trump_glm <- train_trump %>%
  glm(formula = pct_trend_adjusted_dec ~ tot_cases * State, family = 'quasibinomial')

summary(trump_glm)  

# Model Accury

train_trump$pred = predict.glm(trump_glm, train_trump, type = "response")
test_trump$pred = predict.glm(trump_glm, test_trump, type = "response")

train_trump$residual = train_trump$pct_trend_adjusted_dec - train_trump$pred
test_trump$residual = test_trump$pct_trend_adjusted_dec - test_trump$pred

train_trump_RMSE = mean(sqrt((train_trump$residual)^2))
test_trump_RMSE = mean(sqrt((test_trump$residual)^2))

# Plotting Accuracy

ggplot() +
  geom_point(data = test_trump, aes(x = pred, y = pct_trend_adjusted_dec, color = candidate_name)) +
  geom_point(data = train_trump, aes(x = pred, y = pct_trend_adjusted_dec, color = candidate_name)) +
  geom_point(data = test_biden, aes(x = pred, y = pct_trend_adjusted_dec, color = candidate_name)) +
  geom_point(data = train_biden, aes(x = pred, y = pct_trend_adjusted_dec, color = candidate_name)) +
  geom_abline(slope = 1, intercept = 0, color = 'black', lty = 2) +
  theme_bw() +
  labs(color = "Candidate") +
  scale_color_manual(values =  c('red', 'blue')) +
  labs(x = "Predicted State Polling Average", y = "Actual Polling Average (Trend Adjusted)",
       title = "Logistic Regression Accuracy (Actual vs. Predicted Values)",
       subtitle = "Line indicates perfect accuracy")

ggsave("figures/Shocks_Model_Accuracy.png", height = 5, width = 8)

trump_glm_baseline <- trump_glm$coefficients[2]
trump_glm_intercept <- trump_glm$coefficients[1]

summary(trump_glm)

#trump_glm_df <- tidy(trump_glm)

#trump_glm_its <- tail(trump_glm_df, 21) %>%
#  mutate(tot_cases_coef = estimate + trump_glm_baseline) %>%
#  separate(col = "term", into = c('term', 'state'), sep = ":State") %>%
#  select(state, tot_cases_coef)

#trump_glm_intercepts <- slice(trump_glm_df, 3:23) %>%
#  mutate(intercepts = estimate + trump_glm_intercept) %>%
#  separate(col = "term", into = c('term', 'state'), sep = "State") %>%
#  select(state, intercepts)

#trump_glm_coefs = inner_join(trump_glm_intercepts, trump_glm_its, by = 'state')
 
arizona <- tibble(
  State = "Arizona",
  tot_cases = 0:1000000
)

arizona$trump_pred_poll_avg = predict.glm(trump_glm, arizona, type = "response")
arizona$biden_pred_poll_avg = predict.glm(biden_glm, arizona, type = "response")
arizona$pred_winner = ifelse(arizona$trump_pred_poll_avg > arizona$biden_pred_poll_avg, "Donald Trump", "Joseph R. Biden Jr.")

# Plotting Battleground States

cv_poll_prior_state %>%
  filter(State == "Arizona") %>%
ggplot(aes(x = tot_cases, y = pct_trend_adjusted_dec, color = candidate_name)) +
  geom_point() +
  theme_bw() +
  labs(color = "Candidate") +
  scale_color_manual(values =  c('red', 'blue')) +
  geom_smooth(method = "glm", 
              method.args = list(family = "quasibinomial"), 
              se = FALSE) +
  labs(x = "Total Coronavirus Cases", y = "Polling Average (Trend Adjusted",
       title = "Arizona Polling Averages Predicted by Coronavirus Cases",
       subtitle = "Logistic Regression Lines Shown")

ggsave("figures/Shocks_Model_Arizona.png", height = 5, width = 8)

cv_poll_prior_state %>%
  filter(State == "Michigan") %>%
  ggplot(aes(x = tot_cases, y = pct_trend_adjusted_dec, color = candidate_name)) +
  geom_point() +
  theme_bw() +
  labs(color = "Candidate") +
  scale_color_manual(values =  c('red', 'blue')) +
  geom_smooth(method = "glm", 
              method.args = list(family = "quasibinomial"), 
              se = FALSE) +
  labs(x = "Total Coronavirus Cases", y = "Polling Average (Trend Adjusted",
       title = "Michigan Polling Averages Predicted by Coronavirus Cases",
       subtitle = "Logistic Regression Lines Shown")

ggsave("figures/Shocks_Model_Michigan.png", height = 5, width = 8)
          
cv_poll_prior_state %>%
  filter(State == "Ohio") %>%
  ggplot(aes(x = tot_cases, y = pct_trend_adjusted_dec, color = candidate_name)) +
  geom_point() +
  theme_bw() +
  labs(color = "Candidate") +
  scale_color_manual(values =  c('red', 'blue')) +
  geom_smooth(method = "glm", 
              method.args = list(family = "quasibinomial"), 
              se = FALSE) +
  labs(x = "Total Coronavirus Cases", y = "Polling Average (Trend Adjusted",
       title = "Ohio Polling Averages Predicted by Coronavirus Cases",
       subtitle = "Logistic Regression Lines Shown")

ggsave("figures/Shocks_Model_Ohio.png", height = 5, width = 8)


           
