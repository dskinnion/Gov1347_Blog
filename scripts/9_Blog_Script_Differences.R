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

# Load Data

pres_poll_avg_2020 <- read_csv("data/polls_final/presidential_poll_averages_2020.csv")
pres_appr_2020 <- read_csv("data/trump_approval_final/approval_topline.csv")
pres_appr_hist <- read_csv("data/approval_gallup_1941-2020.csv")
pres_poll_avg_hist_natl <- read_csv("data/pollavg_1968-2016.csv")
pres_poll_avg_hist_state <- read_csv("data/pollavg_bystate_1968-2016.csv")
demog <- read_csv("data/demographic_1990-2018.csv")
pv_hist_natl <- read_csv("data/popvote_1948-2016.csv")
pv_hist_state <- read_csv("data/popvote_bystate_1948-2016.csv")
state_abbs <- read_csv("data/state_abb.csv")
ec <- read_csv("data/electoralcollegepost1948.csv")
pv_state_all_years <- read_csv("data/popvote_bystate_1948-2020.csv")
pv_county_2020 <- read_csv("data/popvote_bycounty_2020.csv")
pv_county_hist <- read_csv("data/popvote_bycounty_2000-2016.csv")

# Join data
fips <- pv_county_hist %>%
  filter(year == 2016) %>%
  select(state, state_abb, county, fips) %>%
  mutate(fips = as.character(fips))

pv_county_2020 <- pv_county_2020 %>%
  tail(3152) %>%
  left_join(fips, by = c("FIPS" = "fips")) %>%
  mutate(year = 2020) %>%
  mutate(fips = FIPS) %>%
  mutate(total = as.integer(`Total Vote`)) %>%
  mutate(D = as.integer(`Joseph R. Biden Jr.`)) %>%
  mutate(R = as.integer(`Donald J. Trump`)) %>%
  mutate(D_per = D / total) %>%
  mutate(R_per = R / total) %>%
  mutate(D_win_margin = (D_per - R_per) * 100) %>%
  mutate(county = `Geographic Name`) %>%
  select(year, state, state_abb, county, fips, D_win_margin)

pv_county_2020 <- pv_county_2020 %>%
  mutate(state = ifelse(is.na(state) == TRUE, "Alaska", state)) %>%
  mutate(state_abb = ifelse(is.na(state_abb) == TRUE, "AK", state_abb))

pv_counties_all_years <- rbind(pv_county_2020, pv_county_hist)

pv_state_pre_2020 <- pv_state_all_years %>%
  filter(year != 2020)

pv_state_2020 <- pv_state_all_years %>%
  filter(year == 2020) %>%
  mutate(D_pv2p = D_pv2p * 100,
         R_pv2p = R_pv2p * 100)

pv_state_all_years <- rbind(pv_state_2020, pv_state_pre_2020) %>%
  mutate(D_win_margin_pv2p = D_pv2p - R_pv2p) %>%
  mutate(state = ifelse(state == "District of Columbia", "DC", state))
# State plots

make_plots <- function(inp){
    
  pv_state_all_years %>%
    filter(state == inp) %>%
    ggplot() +
    geom_point(aes(x = year, y = D_win_margin_pv2p)) +
    geom_line(aes(x = year, y = D_win_margin_pv2p)) +
    labs(x = "Year",
         y = "Dem. Two-Party Vote Win Margin (%)",
         title = paste(inp, "Dem. Two-Party Win Margin Over Time")) +
    ylim(-100, 100)
    
}

state_list <- pv_state_all_years$state %>%
  unique()

state_d_margin_plots <- purrr::map(state_list, make_plots)

for (i in 1:51)
{
  print(state_d_margin_plots[[i]])
}

# Scatter plot of 2016 vs 2020

pv_counties_wider <- pv_counties_all_years %>%
  filter(year %in% c(2016, 2020)) %>%
  mutate(county_state = paste(county, state, fips, sep = ", ")) %>%
  select(year, county_state, D_win_margin) %>%
  pivot_wider(id_cols = county_state, names_from = year, values_from = D_win_margin) %>%
  mutate(D_win_margin_2016 = `2016`,
         D_win_margin_2020 = `2020`) %>%
  mutate(D_swing = D_win_margin_2020 - D_win_margin_2016,
         abs_swing = abs(D_swing))
  
pv_counties_wider %>%
  ggplot() +
    geom_point(aes(x = D_win_margin_2016, y = D_win_margin_2020, alpha = 0.1)) +
    geom_point(data = pv_counties_wider[pv_counties_wider$county_state %in% c("Miami-Dade, Florida, 12086",
                                                                              "Jackson, Missouri, 29095",
                                                                              "Lake, California, 6033"), ],
               pch = 21, fill = NA, size = 4, color = 'red', stroke = 1,
               aes(x = D_win_margin_2016, y = D_win_margin_2020)) +
    geom_point(data = pv_counties_wider[pv_counties_wider$county_state %in% c("Starr, Texas, 48427",
                                                                              "Hidalgo, Texas, 48215",
                                                                              "Cameron, Texas, 48061",
                                                                              "Maverick, Texas, 48323",
                                                                              "Kenedy, Texas, 48261",
                                                                              "Jim Hogg, Texas, 48247",
                                                                              "Zapata, Texas, 48505",
                                                                              "Duval, Texas, 48131",
                                                                              "Willacy, Texas, 48489",
                                                                              "Brooks, Texas, 48047",
                                                                              "Reeves, Texas, 48389",
                                                                              "Webb, Texas, 48479"), ],
             pch = 21, fill = NA, size = 4, color = 'orange', stroke = 1,
             aes(x = D_win_margin_2016, y = D_win_margin_2020)) +
    geom_abline(color = 'red') +
    labs(x = "Dem. Win Margin in 2016",
         y = "Dem. Win Margin in 2020",
         title = "Dem. Win Margins in 2020 vs. 2016 by County") +
    geom_text(label = "Texas Counties",
               x = 60,
               y = -15,
               color = 'orange') +
    geom_text(label = "Miami Dade, FL",
              x = 40,
              y = -25,
              color = 'red') +
    geom_text(label = "Lake, CA",
              x = 5,
              y = 40,
              color = 'red') +
    geom_text(label = "Jackson, MO",
              x = -25,
              y = 30,
              color = 'red') +
    theme_classic() +
    theme(legend.position = "none")

ggsave("figures/2020_vs_2016.png", height = 5, width = 5)

# Texas 2016 vs 2020

pv_counties_wider %>%
  filter(grepl("Texas", county_state)) %>%
  ggplot() +
  geom_point(aes(x = D_win_margin_2016, y = D_win_margin_2020)) +
  geom_abline(color = 'red') +
  xlim(-100, 100) +
  ylim(-100, 100)

# County Swings 2020 Hist

pv_counties_wider %>%
  ggplot() +
    geom_histogram(aes(x = D_swing), binwidth = 1)

# County Swings 2020 Hist Texas

pv_counties_wider %>%
  filter(grepl("Texas", county_state)) %>%
  ggplot() +
  geom_histogram(aes(x = D_swing), binwidth = 5)

# Swing DF

pv_counties_swings <- pv_counties_wider %>%
  arrange(desc(abs_swing))

# Specific County Plots

Miami_Dade <- pv_counties_all_years %>%
  filter(county == "Miami-Dade", state == "Florida") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Dem. Win Margin in Miami Dade, FL Over Time",
       y = "Dem. Win Margin") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  xlab(NULL) +
  theme_classic()

ggsave("figures/Miami_Dade_FL.png", height = 3, width = 5)

Jackson <- pv_counties_all_years %>%
  filter(county == "Jackson", state == "Missouri") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Dem. Win Margin in Jackson, MO Over Time",
       y = "Dem. Win Margin") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  xlab(NULL) +
  theme_classic()

ggsave("figures/Jackson_MO.png", height = 3, width = 5)

Lake <- pv_counties_all_years %>%
  filter(county == "Lake", state == "California") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Dem. Win Margin in Lake County, CA Over Time",
       y = "Dem. Win Margin") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  xlab(NULL) +
  theme_classic()

ggsave("figures/Lake_CA.png", height = 3, width = 5) 


Starr <- pv_counties_all_years %>%
  filter(county == "Starr", state == "Texas") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Starr") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_classic()

Hidalgo <- pv_counties_all_years %>%
  filter(county == "Hidalgo", state == "Texas") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Hidalgo") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_classic()

Cameron <- pv_counties_all_years %>%
  filter(county == "Cameron", state == "Texas") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Cameron") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_classic()

Maverick <- pv_counties_all_years %>%
  filter(county == "Maverick", state == "Texas") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Maverick") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_classic()

Kenedy <- pv_counties_all_years %>%
  filter(county == "Kenedy", state == "Texas") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Kenedy") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_classic()

Jim_Hogg <- pv_counties_all_years %>%
  filter(county == "Jim Hogg", state == "Texas") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Jim Hogg") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_classic()

Zapata <- pv_counties_all_years %>%
  filter(county == "Zapata", state == "Texas") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Zapata") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_classic()

Duval <- pv_counties_all_years %>%
  filter(county == "Duval", state == "Texas") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Duval") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_classic()

Brooks <- pv_counties_all_years %>%
  filter(county == "Brooks", state == "Texas") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Brooks") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_classic()

Reeves <- pv_counties_all_years %>%
  filter(county == "Reeves", state == "Texas") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Reeves") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_classic()

Webb <- pv_counties_all_years %>%
  filter(county == "Webb", state == "Texas") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Webb") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_classic()

Willacy <- pv_counties_all_years %>%
  filter(county == "Willacy", state == "Texas") %>%
  ggplot() +
  geom_point(aes(x = year, y = D_win_margin)) +
  geom_line(aes(x = year, y = D_win_margin)) +
  ylim(-100, 100) +
  labs(title = "Willacy") +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2016, 2020)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_classic()

grid.arrange(arrangeGrob(Starr, Maverick, Kenedy, Jim_Hogg,
                         Zapata, Duval, Brooks, Reeves,
                         Webb, Willacy, Hidalgo, Cameron, 
                         nrow = 3,
                         top = textGrob("Dem. Win Margins of Texas Counties with Large Trump Swings", vjust = 0.5, gp = gpar(fontface = "bold", cex = 1.5)),
                         left = textGrob("Dem. Win Margin", rot = 90, vjust = 0.5, gp = gpar(fontface = "bold", cex = 1.5))))
