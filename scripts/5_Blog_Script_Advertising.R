# Load Libraries

library(tidyverse)
library(geofacet)
library(lubridate)
library(gt)


# Load Data

options(scipen=999)

ad_campaigns <- read_csv('data/ad_campaigns_2000-2012.csv')
ad_creative <- read_csv('data/ad_creative_2000-2012.csv')
ads_2020 <- read_csv('data/ads_2020.csv')
polls_2020 <- read_csv('data/polls_2020.csv')
polls_state <- read_csv('data/pollavg_bystate_1968-2016.csv')
poll_avg_2020 <- read_csv('data/presidential_poll_averages_2020.csv')
vep <- read_csv('data/vep_1980-2016.csv')
pv_state <- read_csv('data/popvote_bystate_1948-2016.csv')
abbs <- read_csv('data/state_abb.csv')

# Transform Data

polls_avg_2020_recent <- poll_avg_2020 %>%
  filter(modeldate == "10/10/2020") %>%
  filter(candidate_name %in% c('Joseph R. Biden Jr.', 'Donald Trump'))

polls_pv_state_vep <- pv_state %>%
  mutate(D_pv = D / total) %>%
  inner_join(polls_state %>% filter(weeks_left == 5)) %>%
  left_join(vep)
  
states_list <- (vep %>%
  filter(state != 'United States') %>%
  select(state))$state %>%
  unique()

state_distribution <- function(state) {
  
  State <- state
  
  vep_state <- as.integer(vep$VEP[vep$state == State & vep$year == 2016])
  
  Dprob_df <- polls_avg_2020_recent %>%
    filter(state == State) %>%
    filter(candidate_name == 'Joseph R. Biden Jr.') %>%
    select(pct_trend_adjusted)
  
  Dprob <- (Dprob_df$pct_trend_adjusted) / 100
  
  Rprob_df <- polls_avg_2020_recent %>%
    filter(state == State) %>%
    filter(candidate_name == 'Donald Trump') %>%
    select(pct_trend_adjusted)
  
  Rprob <- (Rprob_df$pct_trend_adjusted) / 100
    
  sim_Dvotes <- rbinom(n = 10000, size = vep_state, prob = Dprob)
  sim_Rvotes <- rbinom(n = 10000, size = vep_state, prob = Rprob)
  sim_D_margin <- (sim_Dvotes - sim_Rvotes) / (sim_Dvotes + sim_Rvotes) * 100

  out <- cbind(sim_Dvotes, sim_Rvotes, sim_D_margin)
  output <- as.data.frame(out)
  output$state <- State
  
  return(output)

}

states_dist <- map_df(states_list, state_distribution)

states_dist <- states_dist %>%
  mutate(sim_R_margin = -sim_D_margin) %>%
  mutate(Gerber_D_GRP_Needed = sim_R_margin / 5 * 1000) %>%
  mutate(Huber_D_GRP_Needed = sim_R_margin / 7.5 * 1000) %>%
  mutate(Upper_Gerber_D_GRP_Needed = sim_R_margin / 2.5 * 1000) %>%
  mutate(Upper_Huber_D_GRP_Needed = sim_R_margin / 5 * 1000) %>%
  mutate(Lower_Gerber_D_GRP_Needed = sim_R_margin / 6.5 * 1000) %>%
  mutate(Lower_Huber_D_GRP_Needed = sim_R_margin / 10 * 1000) %>%
  mutate(sim_winner = ifelse(sim_D_margin > sim_R_margin, 'D', 'R'))

states_dist_means <- states_dist %>%
  group_by(state) %>%
  summarize(mean_Gerber_D_GRP_Needed = mean(Gerber_D_GRP_Needed),
            mean_Huber_D_GRP_Needed = mean(Huber_D_GRP_Needed),
            mean_sim_D_margin = mean(sim_D_margin))

states_dist_lower_CIs <- states_dist %>%
  group_by(state) %>%
  summarize(lower_CI_Gerber_D_GRP_Needed = quantile(Lower_Gerber_D_GRP_Needed, 0.025),
            lower_CI_Huber_D_GRP_Needed = quantile(Lower_Huber_D_GRP_Needed, 0.025),
            lower_CI_sim_D_margin = quantile(sim_D_margin, 0.025))

states_dist_upper_CIs <- states_dist %>%
  group_by(state) %>%
  summarize(upper_CI_Gerber_D_GRP_Needed = quantile(Upper_Gerber_D_GRP_Needed, 0.975),
            upper_CI_Huber_D_GRP_Needed = quantile(Upper_Huber_D_GRP_Needed, 0.975),
            upper_CI_sim_D_margin = quantile(sim_D_margin, 0.975))

states_dist_summary <- inner_join(states_dist_means, states_dist_lower_CIs, by = 'state') %>%
  inner_join(states_dist_upper_CIs, by = 'state') %>%
  mutate(mean_Gerber_D_Cash_Needed = 175 * mean_Gerber_D_GRP_Needed,
         lower_CI_Gerber_D_Cash_Needed = 175 * lower_CI_Gerber_D_GRP_Needed,
         upper_CI_Gerber_D_Cash_Needed = 175 * upper_CI_Gerber_D_GRP_Needed) %>%
  mutate(mean_Huber_D_Cash_Needed = 175 * mean_Huber_D_GRP_Needed,
         lower_CI_Huber_D_Cash_Needed = 175 * lower_CI_Huber_D_GRP_Needed,
         upper_CI_Huber_D_Cash_Needed = 175 * upper_CI_Huber_D_GRP_Needed)

#states_dist_Gerber <- states_dist_summary %>%
  #select(state, mean_Gerber_D_GRP_Needed, lower_CI_Gerber_D_GRP_Needed, upper_CI_Gerber_D_GRP_Needed) %>%
  #mutate(mean_Gerber_D_Cash_Needed = 175 * mean_Gerber_D_GRP_Needed,
         #lower_CI_Gerber_D_Cash_Needed = 175 * lower_CI_Gerber_D_GRP_Needed,
         #upper_CI_Gerber_D_Cash_Needed = 175 * upper_CI_Gerber_D_GRP_Needed)
  
#states_dist_Huber <- states_dist_summary %>%
  #select(state, mean_Huber_D_GRP_Needed, lower_CI_Huber_D_GRP_Needed, upper_CI_Huber_D_GRP_Needed) %>%
  #mutate(mean_Huber_D_Cash_Needed = 175 * mean_Huber_D_GRP_Needed,
         #lower_CI_Huber_D_Cash_Needed = 175 * lower_CI_Huber_D_GRP_Needed,
         #upper_CI_Huber_D_Cash_Needed = 175 * upper_CI_Huber_D_GRP_Needed)

ads_2020 <- ads_2020 %>%
  mutate(est_biden_cost = biden_airings / total_airings * total_cost) %>%
  mutate(est_trump_cost = trump_airings / total_airings * total_cost) %>%
  mutate(est_biden_GRPs = est_biden_cost / 175) %>%
  mutate(est_trump_GRPs = est_trump_cost / 175) %>%
  mutate(Code = state) %>%
  inner_join(abbs, by = 'Code') %>%
  select(-state) %>%
  mutate(state = State) %>%
  filter(period_startdate == '2020-04-09')

states_dist_final <- full_join(states_dist_summary, ads_2020, by = 'state')

ad_campaigns_grouped <- ad_campaigns %>%
  mutate(month = month(as.POSIXlt(air_date, format="%Y-%m-%d"))) %>%
  group_by(cycle, month, party, state) %>%
  summarize(monthly_cost = sum(total_cost)) %>%
  filter(month %in% c(4, 5, 6, 7, 8, 9, 10, 11)) %>%
  mutate(period = ifelse(month %in% c(4, 5, 6, 7, 8, 9), 'early', 'late')) %>%
  group_by(period, cycle, party, state) %>%
  summarize(period_cost = sum(monthly_cost))

ad_campaigns_grouped_wider <- ad_campaigns_grouped %>%
  pivot_wider(names_from = period, values_from = period_cost) %>%
  mutate(late_early_ratio = late / early) %>%
  drop_na() %>%
  group_by(party, state) %>%
  summarize(mean_late_early_ratio = mean(late_early_ratio)) %>%
  pivot_wider(names_from = party, values_from = mean_late_early_ratio) %>%
  mutate(D_late_early_ratio = democrat,
         R_late_early_ratio = republican,
         Code = state) %>%
  inner_join(abbs, by = 'Code') %>%
  select(State, D_late_early_ratio, R_late_early_ratio) %>%
  mutate(state = State) %>%
  select(state, D_late_early_ratio, R_late_early_ratio)

states_dist_with_ads <- inner_join(states_dist_final, ad_campaigns_grouped_wider, by = 'state') %>%
  mutate(est_biden_late_cost = est_biden_cost * D_late_early_ratio,
         est_trump_late_cost = est_trump_cost * R_late_early_ratio,
         est_D_cash = (est_biden_late_cost - est_trump_late_cost)/5)

cash <- states_dist_with_ads %>%
  select(state, mean_Gerber_D_Cash_Needed, lower_CI_Gerber_D_Cash_Needed, upper_CI_Gerber_D_Cash_Needed,
         mean_Huber_D_Cash_Needed, lower_CI_Huber_D_Cash_Needed, upper_CI_Huber_D_Cash_Needed, est_D_cash) %>%
  drop_na() %>%
  mutate(above_Gerber_mean = ifelse(est_D_cash > mean_Gerber_D_Cash_Needed, "Yes", "No"),
         above_Huber_mean = ifelse(est_D_cash > mean_Huber_D_Cash_Needed, "Yes", "No"))

Gerber_predictions <- cash %>%
  select(state, mean_Gerber_D_Cash_Needed, est_D_cash, above_Gerber_mean)

Huber_predictions <- cash %>%
  select(state, mean_Huber_D_Cash_Needed, est_D_cash, above_Huber_mean)

Gerber_table <- Gerber_predictions %>%
  gt() %>%
  tab_header(
    title = "Gerber's Method to Predict State Presidential Election Winners"
  ) %>%
  cols_label(
    mean_Gerber_D_Cash_Needed = "Predicted Dem. Extra Cash \n Needed to Win",
    est_D_cash = "Predicted Dem. Extra Cash",
    above_Gerber_mean = "Dem. Win Prediction"
  ) %>%
  data_color(
    columns = vars(above_Gerber_mean),
    colors = scales::col_factor(
      palette = c("red", "blue"),
      domain = c('Yes', 'No'))
  )


gtsave(Gerber_table, "figures/Ads_Gerber_Table.png") 

Huber_table <- Huber_predictions %>%
  gt() %>%
  tab_header(
    title = "Huber's Method to Predict State Presidential Election Winners"
  ) %>%
  cols_label(
    mean_Huber_D_Cash_Needed = "Predicted Dem. Extra Cash \n Needed to Win",
    est_D_cash = "Predicted Dem. Extra Cash",
    above_Huber_mean = "Dem. Win Prediction"
  ) %>%
  data_color(
    columns = vars(above_Huber_mean),
    colors = scales::col_factor(
      palette = c("red", "blue"),
      domain = c('Yes', 'No'))
  )

gtsave(Huber_table, "figures/Ads_Huber_Table.png") 

  