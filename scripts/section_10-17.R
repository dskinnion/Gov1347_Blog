# Section

library(tidycensus)

state_pv_2020 <- read.csv('data/popvote_bystate_1948-2020.csv')

final_comps <- inner_join(R_state_preds_2020_final, state_pv_2020, by = c("state", "year")) %>%
  select(state, fit, R_pv2p)

ggplot(final_comps, aes(x = fit, y = R_pv2p)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1) +
  geom_hline(yintercept = 0.5, color = 'red') +
  geom_vline(xintercept = 0.5, color = 'red')

RMSE <- final_comps %>%
  mutate(error = R_pv2p - fit) %>%
  mutate(squared_error = error ^2) %>%
  summarize(rmse = sqrt(mean(squared_error))) %>%
  select(rmse) %>%
  pull(1)


