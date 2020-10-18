# Load libraries

library(tidyverse)
library(usmap)
library(maps)
library(loo)

# Load data

options(scipen = 999)

demographics <- read_csv('data/demographic_1990-2018.csv')
turnout <- read_csv('data/turnout_1980-2016.csv')
field_office_2004_2012_dems <- read_csv('data/fieldoffice_2004-2012_dems.csv')
field_office_2012_2016_address <- read_csv('data/fieldoffice_2012-2016_byaddress.csv')
field_office_2012_county <- read_csv('data/fieldoffice_2012_bycounty.csv')
pop_vote_state <- read_csv('data/popvote_bystate_1948-2016.csv')
abbs <- read_csv('data/state_abb.csv')
ec <- read_csv('data/electoralcollegepost1948.csv')

# EDA

turnout <- turnout %>%
  mutate(turnout_pct = turnout / VEP) %>%
  filter(year %in% c(1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016)) %>%
  filter(state != "United States")

dem_2020 <- function(State){
  
  state_dem <- demographics %>%
    filter(state == State)
  
  Newdata <- tibble(
    year = 2020
  )
  
  linAsian <- lm(Asian ~ year, state_dem)
  Asian2020 <- predict.lm(linAsian, newdata = Newdata)
  
  linBlack <- lm(Black ~ year, state_dem)
  Black2020 <- predict.lm(linBlack, newdata = Newdata)
  
  linHispanic <- lm(Hispanic ~ year, state_dem)
  Hispanic2020 <- predict.lm(linHispanic, newdata = Newdata)
  
  linIndigenous <- lm(Indigenous ~ year, state_dem)
  Indigenous2020 <- predict.lm(linIndigenous, newdata = Newdata)
  
  linWhite <- lm(White ~ year, state_dem)
  White2020 <- predict.lm(linWhite, newdata = Newdata)
  
  linFemale <- lm(Female ~ year, state_dem)
  Female2020 <- predict.lm(linFemale, newdata = Newdata)
  
  linMale <- lm(Male ~ year, state_dem)
  Male2020 <- predict.lm(linMale, newdata = Newdata)
  
  linage20 <- lm(age20 ~ year, state_dem)
  age20_2020 <- predict.lm(linage20, newdata = Newdata)
  
  linage3045 <- lm(age3045 ~ year, state_dem)
  age3045_2020 <- predict.lm(linage3045, newdata = Newdata)
  
  linage4565 <- lm(age4565 ~ year, state_dem)
  age4565_2020 <- predict.lm(linage4565, newdata = Newdata)
  
  linage65 <- lm(age65 ~ year, state_dem)
  age65_2020 <- predict.lm(linage65, newdata = Newdata)
  
  lintotal <- lm(total ~ year, state_dem)
  total2020 <- predict.lm(lintotal, newdata = Newdata)

  state_pred_2020 <- tibble(
    state = State,
    year = 2020,
    Asian = Asian2020,
    Black = Black2020,
    Hispanic = Hispanic2020,
    Indigenous = Indigenous2020,
    White = White2020,
    Female = Female2020,
    Male = Male2020,
    age20 = age20_2020,
    age3045 = age3045_2020,
    age4565 = age4565_2020,
    age65 = age65_2020,
    total = total2020
  )
  
  demographics <<- rbind(demographics, state_pred_2020)
}

states_list <- demographics$state %>%
  unique()

map_df(states_list, dem_2020)

demographics <- demographics %>%
  filter(state != "KR") %>%
  mutate(Code = state)

pop_vote_state2 <- abbs %>%
  mutate(state = State) %>%
  inner_join(pop_vote_state, by = 'state')

demg_pop_vote <- inner_join(pop_vote_state2, demographics, by = c('Code', 'year'))

set.seed(17)
demg_pop_vote_train <- sample_frac(demg_pop_vote, 0.75, replace = FALSE)

linmodD <- lm(D ~ White * Code, demg_pop_vote_train)
linmodR <- lm(R ~ White * Code, demg_pop_vote_train)

linmodD %>% summary()
linmodR %>% summary()

demg_pop_vote_full <- right_join(pop_vote_state2, demographics, by = c('Code', 'year'))

linmod_Dpreds <- predict.lm(linmodD, demg_pop_vote_full, interval = "confidence")
linmod_Dpreds_df <- as.data.frame(linmod_Dpreds)
  
linmod_Rpreds <- predict.lm(linmodR, demg_pop_vote_full, interval = "confidence")
linmod_Rpreds_df <- as.data.frame(linmod_Rpreds)

demg_pop_vote_full$D_preds = linmod_Dpreds_df$fit
demg_pop_vote_full$R_preds = linmod_Rpreds_df$fit
demg_pop_vote_full$D_preds_lower = linmod_Dpreds_df$lwr
demg_pop_vote_full$R_preds_lower = linmod_Rpreds_df$lwr
demg_pop_vote_full$D_preds_upper = linmod_Dpreds_df$upr
demg_pop_vote_full$R_preds_upper = linmod_Rpreds_df$upr

preds_actual <- demg_pop_vote_full %>%
  select(Code, year, D, R, D_pv2p, R_pv2p, D_preds, R_preds, D_preds_lower, R_preds_lower,
         D_preds_upper, R_preds_upper) %>%
  mutate(D_pv2p_preds = D_preds / (D_preds + R_preds), 
         R_pv2p_preds = R_preds / (D_preds + R_preds),
         D_pv2p_preds_lower = D_preds_lower / (D_preds_lower + R_preds_lower), 
         R_pv2p_preds_lower = R_preds_lower / (D_preds_lower + R_preds_lower),
         D_pv2p_preds_upper = D_preds_upper / (D_preds_upper + R_preds_upper), 
         R_pv2p_preds_upper = R_preds_upper / (D_preds_upper + R_preds_upper),
         ) %>%
  mutate(actual_winner = ifelse(D > R, "D", "R"),
         predicted_winner = ifelse(D_preds > R_preds, "D", "R")) %>%
  mutate(pred_accuracy = ifelse(actual_winner == predicted_winner, 1, 0)) %>%
  mutate(actual_margin = (D - R) / (D + R),
         predicted_margin = (D_preds - R_preds) / (D_preds + R_preds),
         lower_margin = (D_preds_lower - R_preds_lower)/ (D_preds_lower + R_preds_lower),
         upper_margin = (D_preds_upper - R_preds_upper)/ (D_preds_upper + R_preds_upper))

preds_2020 <- preds_actual %>%
  filter(year == 2020) %>%
  inner_join(abbs, by = 'Code')

accuracy <- preds_actual %>%
  drop_na() %>%
  group_by(pred_accuracy) %>%
  count()

accurate_count <- accuracy$n[2]
total <- accuracy$n[1] + accuracy$n[2]

accuracy_pct <- accurate_count / total

states_map <- map_data("state")

preds_2020$region <- tolower(preds_2020$State)

preds_2020_map <- preds_2020 %>%
  left_join(states_map, by = "region")

ggplot(preds_2020_map, aes(long, lat, group = group)) +
  geom_polygon(aes(fill = predicted_margin), color = "black") +
  scale_fill_gradient2(
    low = "red", 
    # mid = scales::muted("purple"),
    mid = "white",
    high = "blue",
    breaks = c(-0.5, -0.25, 0, 0.25, 0.5),
    limits = c(-0.5, 0.5),
    name = "Predicted Margin"
  ) +
  theme_void() +
  labs(title = "2020 Presidential Election Win Margin \n by States' White Population Proportions") +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("figures/GG_map.png", height = 3, width = 5)

ggplot(preds_2020_map, aes(long, lat, group = group)) +
  geom_polygon(aes(fill = predicted_winner), color = "black") +
  scale_fill_manual(values = c("blue", "red")) +
  theme_void() +
  labs(title = "2020 Presidential Election Prediction \n by States' White Population") +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("figures/GG_EV_map.png", height = 3, width = 5)

ec2020 <- ec %>%
  rename(state = X1) %>%
  rename(electors_2020 = '2020') %>%
  select(state, electors_2020)

preds_2020_2 <- preds_2020 %>%
  mutate(state = State)

ev_pred <- inner_join(preds_2020_2, ec2020, by = 'state')

EV_totals <- ev_pred %>%
  group_by(predicted_winner) %>%
  summarise(total_EV = sum(electors_2020)) %>%
  mutate(year = 2020)

dem_EV <- EV_totals$total_EV[1]
rep_EV <- EV_totals$total_EV[2]

ggplot(EV_totals) +
  geom_bar(aes(fill = predicted_winner, y = total_EV, x = year),
           position = "stack",
           stat = 'identity') +
  scale_fill_manual(values = c('blue', 'red')) +
  coord_flip() +
  theme_classic() +
  theme(legend.position = 'none',
        axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.line.y = element_blank(),
        plot.title = element_text(hjust = 0.5)) +
  geom_hline(yintercept = 270, size = 2) +
  labs(y = 'Electoral Votes',
       title = "2020 Predicted Electoral Votes \n from White Population Proportion")

ggsave("figures/GG_EV.png", height = 2, width = 5)

