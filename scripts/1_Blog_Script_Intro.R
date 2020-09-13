# load in libraries

library(tidyverse)
library(maps)
library(usmap)

# read in data

pop <- read_csv("data/popvote_1948-2016.csv")
pop_state <- read_csv("data/popvote_bystate_1948-2016.csv")

# make a function to create a column for the past
# election's proportions using lag() and making
# sure that it is only within one state using 
# filter()

prior <- function(state_name){
  
  states <- pop_state %>%
    filter(state == state_name) %>%
    arrange(year) %>%
    mutate(D_prior = lag(D)) %>%
    mutate(R_prior = lag(R))
}

# returns a list of the state names

states_list <- unique(pop_state$state)

# creates a data frame using a map function to 
# insert all of the state names into the function
# created above

pop_state_prior <- map_df(states_list, prior)

# calculate swing and absolute value of swing 

pop_state_swing <- pop_state_prior %>%
  mutate(swing = ((D) / (D + R)) - ((D_prior) / (D_prior + R_prior))) %>%
  mutate(abs_swing = abs(swing))

# use the map data to write a data frame to create
# a map of the US

states_map <- map_data("state")

pop_state_swing$region <- tolower(pop_state_swing$state)

pop_swing_map <- pop_state_swing %>%
  filter(year == 2016) %>%
  left_join(states_map, by = "region")

# create a map of the US, colored by swing
# I chose to use white as the middle color because
# I have a hard time distinguishing between purples
# and I wanted to show the differences with a bigger
# contrast between blue and red (through white)
# rather than seeing little difference with the purples

ggplot(pop_swing_map, aes(long, lat, group = group)) +
  geom_polygon(aes(fill = swing), color = "black") +
  scale_fill_gradient2(
    low = "red", 
    # mid = scales::muted("purple"),
    mid = "white",
    high = "blue",
    breaks = c(-0.15, -0.075, 0, 0.075, 0.15),
    limits = c(-0.15, 0.15),
    name = "Vote Swing"
    ) +
  theme_void() +
  labs(title = "Presidential Election Vote Swing from 2012 - 2016") +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("figures/PV_states_swing_2016.png", height = 3, width = 6)

# I only wanted to see elections since 1980 in my
# grid

pop_swing_map_grid <- pop_state_swing %>%
  filter(year >= 1980)

# Again, I used the same reasoning as above to opt
# for white as a mid tone rather than purple

plot_usmap(data = pop_swing_map_grid, regions = "states", values = "swing", color = "black") +
  facet_wrap(facets = year ~.) + 
  scale_fill_gradient2(
    low = "red", 
    # mid = scales::muted("purple"),
    mid = "white",
    high = "blue",
    breaks = c(-0.25, -0.125, 0, 0.125, 0.25),
    limits = c(-0.25, 0.25),
    name = "Vote Swing"
  ) +
  theme_void() +
  theme(strip.text = element_text(size = 12),
        aspect.ratio=1)

ggsave("figures/PV_states_swing.png", height = 6, width = 9)

# Now I wanted to introduce battleground states,
# which I did by finding the win margin (and absolute
# win margin). I also created swing party and winner
# variables so that I could color graphs by either
# if need be.

pop_state_swing_wm <- pop_state_swing %>%
  mutate(win_margin = (D_pv2p - R_pv2p) / 100) %>%
  mutate(abs_win_margin = abs(win_margin)) %>%
  mutate(swing_party = ifelse(swing > 0, "D", "R")) %>%
  mutate(Winner = ifelse(D > R, "D", "R"))

# Here I wanted to look at 2016 battleground states,
# which I defined as states with a win margin within
# 5%. I then wanted to plot these states with their
# swings, to see how they trended in 2016.

pop_state_swing_wm %>%
  filter(year == 2016) %>%
  arrange(desc(abs_win_margin)) %>%
  filter(abs_win_margin <= 0.05) %>%
  ggplot(aes(x = fct_reorder(state, -abs_win_margin), y = swing, fill = swing_party)) +
    scale_fill_manual(values = c("blue", "red")) +
    coord_flip() +
    geom_col() +
    labs(x = "", y = "Vote Swing", title = "2016 Presidential Election Vote Swings \n in Battleground States") +
    theme(legend.position = "none") +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("figures/PV_battleground_swing_2016.png", height = 3, width = 6)


    