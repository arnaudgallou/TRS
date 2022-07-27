####  Imports  ####
  {
    library(tidyverse)
    library(TRS.utilities)
    library(glue)

    source(".env.R")

    if (file.exists(".gs.R")) {
      source(".gs.R")
    }
  }

####  Theme  ####
  {
    theme_set(theme_elesic())
  }

####  Data  ####
  {
    trs <- read_csv("data/trs.csv")
    trs_bioclim <- read_csv("data/trs_bioclim.csv")
  }
