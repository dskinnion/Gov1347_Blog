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

# Load data

pv_county_2020_raw <- read_csv("data/popvote_bycounty_2020.csv")
covid_ed_raw <- read_csv("data/covid_election_day.csv")
covid_deaths_county_raw <- read_csv("data/covid_deaths_by_county.csv")
pv_county_hist_raw <- read_csv("data/popvote_bycounty_2000-2016.csv")

# Clean data

pv_county_2020 <- pv_county_2020_raw %>%
  tail(3152) %>%
  mutate(fips = ifelse(as.integer(FIPS) <=2799 & as.integer(FIPS) >= 2700, as.integer(FIPS) - 700, as.integer(FIPS)),
         fips = as.character(fips),
         D_2020 = 100 * as.integer(`Joseph R. Biden Jr.`) / as.integer(`Total Vote`),
         R_2020 = 100 * as.integer(`Donald J. Trump`) / as.integer(`Total Vote`),
         D_win_margin_2020 = D_2020 - R_2020) %>%
  select(fips, D_win_margin_2020)

pv_county_2016 <- pv_county_hist_raw %>%
  filter(year == 2016) %>%
  mutate(D_win_margin_2016 = D_win_margin,
         fips = as.character(fips)) %>%
  select(fips, D_win_margin_2016)

covid_county <- covid_ed_raw %>%
  filter(Country_Region == "US") %>%
  mutate(fips = as.character(FIPS),
         cases = Confirmed,
         deaths = Deaths,
         cases_p100k = Incidence_Rate,
         case_fatality = `Case-Fatality_Ratio`,
         pop = cases * 100000 / cases_p100k,
         deaths_p100k = deaths / pop * 100000,
         county = Combined_Key,
         log_cases = ifelse(cases == 0, 0, log(cases)),
         log_deaths = ifelse(deaths == 0, 0, log(deaths)),
         log_cases_p100k = ifelse(cases_p100k == 0, 0, log(cases_p100k)),
         log_deaths_p100k = ifelse(deaths_p100k == 0, 0, log(deaths_p100k)),
         log_case_fatality = ifelse(case_fatality == 0, 0, log(case_fatality)),
         log_pop = log(pop)) %>%
  select(fips, county, pop, log_pop, cases, log_cases, deaths, log_deaths, cases_p100k, log_cases_p100k, deaths_p100k, log_deaths_p100k, case_fatality, log_case_fatality) %>%
  drop_na()

avg_cases = mean(covid_county$cases)
avg_deaths = mean(covid_county$deaths)
avg_cases_pc = mean(covid_county$cases_p100k)
avg_deaths_pc = mean(covid_county$deaths_p100k)
avg_cf = mean(covid_county$case_fatality)
avg_log_cases = mean(covid_county$log_cases)
avg_log_deaths = mean(covid_county$log_deaths)
avg_log_cases_pc = mean(covid_county$log_cases_p100k)
avg_log_deaths_pc = mean(covid_county$log_deaths_p100k)
avg_log_cf = mean(covid_county$log_case_fatality)

std_cases = sd(covid_county$cases)
std_deaths = sd(covid_county$deaths)
std_cases_pc = sd(covid_county$cases_p100k)
std_deaths_pc = sd(covid_county$deaths_p100k)
std_cf = sd(covid_county$case_fatality)
std_log_cases = sd(covid_county$log_cases)
std_log_deaths = sd(covid_county$log_deaths)
std_log_cases_pc = sd(covid_county$log_cases_p100k)
std_log_deaths_pc = sd(covid_county$log_deaths_p100k)
std_log_cf = sd(covid_county$log_case_fatality)

covid_county$cases_dif = covid_county$cases - avg_cases
covid_county$deaths_dif = covid_county$deaths - avg_deaths
covid_county$cases_pc_dif = covid_county$cases_p100k - avg_cases_pc
covid_county$deaths_pc_dif = covid_county$deaths_p100k - avg_deaths_pc
covid_county$cf_dif = covid_county$case_fatality - avg_cf
covid_county$log_cases_dif = covid_county$log_cases - avg_log_cases
covid_county$log_deaths_dif = covid_county$log_deaths - avg_log_deaths
covid_county$log_cases_pc_dif = covid_county$log_cases_p100k - avg_log_cases_pc
covid_county$log_deaths_pc_dif = covid_county$dlog_eaths_p100k - avg_log_deaths_pc
covid_county$log_cf_dif = covid_county$log_case_fatality - avg_log_cf

covid_county$cases_zs = covid_county$cases_dif / std_cases
covid_county$deaths_zs = covid_county$deaths_dif / std_deaths
covid_county$cases_pc_zs = covid_county$cases_pc_dif / std_cases_pc
covid_county$deaths_pc_zs = covid_county$deaths_pc_dif / std_deaths_pc
covid_county$cf_zs = covid_county$cf_dif / std_cf
covid_county$log_cases_zs = covid_county$log_cases_dif / std_log_cases
covid_county$log_deaths_zs = covid_county$log_deaths_dif / std_log_deaths
covid_county$log_cases_pc_zs = covid_county$log_cases_pc_dif / std_log_cases_pc
covid_county$log_deaths_pc_zs = covid_county$log_deaths_pc_dif / std_log_deaths_pc
covid_county$log_cf_zs = covid_county$log_cf_dif / std_log_cf

county_stats <- covid_deaths_county_raw %>%
  mutate(fips = as.character(`FIPS County Code`),
         type = `Urban Rural Code`,
         state = State) %>%
  select(fips, type, state)

# Data joining

pv_county <- inner_join(pv_county_2016, pv_county_2020, by = "fips") %>%
  drop_na()

avg_D_win_margin_2020 <- mean(pv_county$D_win_margin_2020)
avg_D_win_margin_2016 <- mean(pv_county$D_win_margin_2016)
std_D_win_margin_2020 <- sd(pv_county$D_win_margin_2020)
std_D_win_margin_2016 <- sd(pv_county$D_win_margin_2016)

pv_county$D_margin_dif_avg_2016 = pv_county$D_win_margin_2016 - avg_D_win_margin_2016
pv_county$D_margin_dif_avg_2020 = pv_county$D_win_margin_2020 - avg_D_win_margin_2020
pv_county$D_margin_zs_2016 = pv_county$D_margin_dif_avg_2016 / std_D_win_margin_2016
pv_county$D_margin_zs_2020 = pv_county$D_margin_dif_avg_2020 / std_D_win_margin_2020

pv_county$abs_change = pv_county$D_win_margin_2020 - pv_county$D_win_margin_2016
pv_county$dif_change = pv_county$D_margin_dif_avg_2020 - pv_county$D_margin_dif_avg_2016
pv_county$D_zs_change = pv_county$D_margin_zs_2020 - pv_county$D_margin_zs_2016

county_cv_pv <- inner_join(covid_county, pv_county, by = "fips")

county_cv_pv$winner_2020 = ifelse(county_cv_pv$D_win_margin_2020 > 0, 100, -100)
county_cv_pv$winner_2016 = ifelse(county_cv_pv$D_win_margin_2016 > 0, 100, -100)

# Plots

ggplot(county_cv_pv) +
  geom_point(aes(x = log_cases_pc_zs, y = abs_change, alpha = 0.5)) +
  geom_smooth(aes(x = log_cases_pc_zs, y = abs_change), method = 'lm') 

ggplot(county_cv_pv) +
  geom_point(aes(x = log_cases_pc_zs, y = D_win_margin_2020, alpha = 0.5)) +
  geom_smooth(aes(x = log_cases_pc_zs, y = D_win_margin_2020), method = 'lm')

ggplot(county_cv_pv) +
  geom_point(aes(x = log_cases_pc_zs, y = D_win_margin_2016, alpha = 0.5)) +
  geom_smooth(aes(x = log_cases_pc_zs, y = D_win_margin_2016), method = 'lm')

ggplot(county_cv_pv) +
  geom_point(aes(x = log_cases_p100k, y = dif_change, alpha = 0.5)) +
  geom_smooth(aes(x = log_cases_p100k, y = dif_change), method = 'lm')

ggplot(county_cv_pv) +
  geom_point(aes(x = log_cases_p100k, y = D_zs_change, alpha = 0.5)) +
  geom_smooth(aes(x = log_cases_p100k, y = D_zs_change), method = 'lm')

ggplot(county_cv_pv) +
  geom_point(aes(x = D_win_margin_2016, y = dif_change, alpha = 0.5)) +
  geom_smooth(aes(x = D_win_margin_2016, y = dif_change), method = 'lm')

ggplot(county_cv_pv) +
  geom_point(aes(x = log_deaths_p100k, y = dif_change, alpha = 0.5, color = D_win_margin_2020)) +
  geom_smooth(aes(x = log_deaths_p100k, y = dif_change, group = winner_2020, color = winner_2020), method = 'lm', se = FALSE) +
  scale_color_gradient2(low = 'red',
                        mid = 'purple',
                        high = 'blue',
                        midpoint = 0) +
  scale_alpha(guide = 'none') +
  labs(color = "Dem. Win Margin \n (2020)",
       x = 'Log(COVID Deaths per 100k)',
       y = 'Change in Dem. Win Margin (2020 - 2016)',
       title = 'How did COVID-19 Deaths \n Affect the 2020 Election?') +
  theme_classic()

ggsave("figures/Narrative_byparty.png", height = 4, width = 6)

ggplot(county_cv_pv) +
  geom_point(aes(y = log_deaths_p100k, x = D_win_margin_2016, alpha = 0.5)) +
  geom_smooth(aes(y = log_deaths_p100k, x = D_win_margin_2016), method = 'lm', se = FALSE, color = 'red') +
  scale_color_gradient2(low = 'red',
                        mid = 'purple',
                        high = 'blue',
                        midpoint = 0) +
  scale_alpha(guide = 'none') +
  labs(x = 'Dem. Win Margin in 2016',
       y = 'Log(COVID Deaths per 100k)',
       title = 'How are COVID Deaths Related to Party?') +
  theme_classic()

ggsave("figures/Narrative_deaths_party.png", height = 4, width = 6)

# Model

margin_model <- lm(data = county_cv_pv, formula = D_win_margin_2020 ~ log_cases_p100k + D_win_margin_2016)

summary(margin_model)

change_model <- lm(data = county_cv_pv, formula = dif_change ~ log_cases_p100k + D_win_margin_2016)

summary(change_model)



  