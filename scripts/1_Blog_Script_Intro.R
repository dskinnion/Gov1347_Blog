library(tidyverse)
library(maps)
library(usmap)

pop <- read_csv("data/popvote_1948-2016.csv")
pop_state <- read_csv("data/popvote_bystate_1948-2016.csv")

prior <- function(state_name){
  
  states <- pop_state %>%
    filter(state == state_name) %>%
    arrange(year) %>%
    mutate(D_prior = lag(D)) %>%
    mutate(R_prior = lag(R))
}

states_list <- unique(pop_state$state)

pop_state_prior <- map_df(states_list, prior)

pop_state_swing <- pop_state_prior %>%
  mutate(swing = ((D) / (D + R)) - ((D_prior) / (D_prior + R_prior)))

states_map <- map_data("state")

pop_state_swing$region <- tolower(pop_state_swing$state)

pop_swing_map <- pop_state_swing %>%
  filter(year == 2016) %>%
  left_join(states_map, by = "region")

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
  theme(plot.title = element_text(hjust = 0.5,))

ggsave("figures/PV_states_swing_2016.png", height = 3, width = 6)

pop_swing_map_grid <- pop_state_swing %>%
  filter(year >= 1980)

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
