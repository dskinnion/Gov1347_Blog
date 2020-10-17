# Load libraries

library(tidyverse)
library(usmap)
library(maps)

# Load data

demographics <- read_csv('data/demographic_1990-2018.csv')
turnout <- read_csv('data/turnout_1980-2016.csv')
field_office_2004_2012_dems <- read_csv('data/fieldoffice_20014-2012_dems.csv')
field_office_2012_2016_address <- read_csv('data/fieldoffice_2012-2016_byaddress.csv')
field_office_2012_county <- read_csv('data/fieldoffice_2012_bycounty.csv')

