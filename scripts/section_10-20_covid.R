# Libraries

library(tidyverse)

# Data

county_covid <- read_csv('data/Provisional_COVID-19_Death_Counts_in_the_United_States_by_County.csv')

# EDA

county_covid %>%
  select(`Deaths involving COVID-19`) %>%
  mutate(deaths = `Deaths involving COVID-19`) %>%
  summarize(mean = mean(deaths))

county_covid2 <- county_covid %>%
  select(`Deaths involving COVID-19`) %>%
  mutate(deaths = `Deaths involving COVID-19`) %>%
  summarize(stand_dev = sd(deaths))


hist(x = county_covid$`Deaths involving COVID-19`,
     breaks = 25)
