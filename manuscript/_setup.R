library(plume)
library(pakret)
pkrt_set(bib = "pkrt")

source("manuscript/_utils.R")

ga <- GlobalAnalyses$new(PATH_GLOBAL)
la <- LocalAnalyses$new(PATH_LOCAL)

theme_update(
  legend.position = "none",
  strip.background = element_blank(),
)

size <- list(
  title = 9,
  text = 8,
  label = 10 / .pt,
  tag = 13 / .pt
)

labels <- c(
  dtr = "Diurnal temperature range (\u00b0C)",
  ts = "Temperature seasonality (\u00b0C)",
  past_dmat = "\u0394 mean annual temperature\n(0-1980) (\u00b0C)"
)

trs_raw <- read_csv("data/trs_raw.csv")
trs <- load_data()

data_info <- list(
  n_data_raw = get_n_data(trs_raw),
  n_data = get_n_data(trs),
  n_locations_raw = get_n_location(trs_raw),
  n_locations = get_n_location(trs),
  n_locations_global = get_n_location(trs, min_elev_span = ELEV_SPAN_DEFAULT),
  n_islands = get_n_location(trs, land_type = "island"),
  n_continents = get_n_location(trs, land_type = "continent")
)

df_authors <- googlesheets4::read_sheet(
  Sys.getenv("GS_DATA"),
  sheet = "authors"
)

aut <- Plume$new(
  df_authors,
  roles = c(
    design = "designed the study",
    resources = "collected the data",
    trs = "conceptualized the temperature range squeeze hypothesis",
    methodology = "conceived the methodology",
    preliminary_study = "conducted the preliminary study",
    supervision = "supervised and administrated the project",
    investigation = "curated the data, conducted the investigation, performed the analyses and produced the figures",
    writing = "wrote the manuscript with contributions from all authors"
  ),
  distinct_initials = TRUE
)
aut$set_corresponding_authors(gallou, .by = "family_name")

knitr::read_chunk("scripts/results.R")
