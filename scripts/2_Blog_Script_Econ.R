# load in libraries 

library(tidyverse)
library(maps)
library(usmap)

# load data

pop <- read_csv("data/popvote_1948-2016.csv")
pop_state <- read_csv("data/popvote_bystate_1948-2016.csv")
econ_state <- read_csv("data/local.csv")
econ <- read_csv("data/econ.csv")

