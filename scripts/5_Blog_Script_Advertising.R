# Load Libraries

library(tidyverse)
library(readxl)
library(lubridate)

# Load Data

ad_campaigns <- read_csv('data/ad_campaigns_2000-2012.csv')
ad_creative <- read_csv('data/ad_creative_2000-2012.csv')
ads_2020 <- read_csv('data/ads_2020.csv')
polls_2020 <- read_csv('data/polls_2020.csv')
poll_avg_2020 <- read_csv('data/presidential_poll_averages_2020.csv')

# EDA

polls_avg_2020_recent <- poll_avg_2020 %>%
  filter(modeldate == "10/10/2020") %>%
  filter(candidate_name %in% c('Joseph R. Biden Jr.', 'Donald Trump'))
