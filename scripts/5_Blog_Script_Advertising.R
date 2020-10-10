# Load Libraries

library(tidyverse)
library(geofacet)


# Load Data

ad_campaigns <- read_csv('data/ad_campaigns_2000-2012.csv')
ad_creative <- read_csv('data/ad_creative_2000-2012.csv')
ads_2020 <- read_csv('data/ads_2020.csv')
polls_2020 <- read_csv('data/polls_2020.csv')
polls_state <- read_csv('data/pollavg_bystate_1968-2016.csv')
poll_avg_2020 <- read_csv('data/presidential_poll_averages_2020.csv')
vep <- read_csv('data/vep_1980-2016.csv')
pv_state <- read_csv('data/popvote_bystate_1948-2016.csv')

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

ggplot(states_dist, aes(Gerber_D_GRP_Needed, fill = sim_winner)) +
  geom_histogram() +
  facet_geo(~ state, grid = "us_state_grid2")

states_dist_means <- states_dist %>%
  group_by(state) %>%
  summarize(mean_Gerber_D_GRP_Needed = mean(Gerber_D_GRP_Needed),
            mean_Huber_D_GRP_Needed = mean(Huber_D_GRP_Needed))

states_dist_lower_CIs <- states_dist %>%
  group_by(state) %>%
  summarize(lower_CI_Gerber_D_GRP_Needed = quantile(Lower_Gerber_D_GRP_Needed, 0.025),
            lower_CI_Huber_D_GRP_Needed = quantile(Lower_Huber_D_GRP_Needed, 0.025))

states_dist_upper_CIs <- states_dist %>%
  group_by(state) %>%
  summarize(upper_CI_Gerber_D_GRP_Needed = quantile(Upper_Gerber_D_GRP_Needed, 0.975),
            upper_CI_Huber_D_GRP_Needed = quantile(Upper_Huber_D_GRP_Needed, 0.975))

states_dist_summary <- inner_join(states_dist_means, states_dist_lower_CIs, by = 'state') %>%
  inner_join(states_dist_upper_CIs, by = 'state')

states_dist_Gerber <- states_dist_summary %>%
  select(state, mean_Gerber_D_GRP_Needed, lower_CI_Gerber_D_GRP_Needed, upper_CI_Gerber_D_GRP_Needed)

states_dist_Huber <- states_dist_summary %>%
  select(state, mean_Huber_D_GRP_Needed, lower_CI_Huber_D_GRP_Needed, upper_CI_Huber_D_GRP_Needed)
