# ---- refs ----

data_source <- Sys.getenv("GS_SOURCE") |>
  googlesheets4::read_sheet() |>
  mutate(received_date = lubridate::dmy(received_date))

# ---- bioclim ----

trs_bioclim <- "gis/clim/extracted/present" |>
  list_files("\\.csv$") |>
  read_auto() |>
  mutate(
    across(matches("bio_\\d$"), \(x) x / 10),
    bio_4 = bio_4 / 100
  )

# ---- bioclim (past) ----

past_clim <- read_csv("gis/clim/extracted/past/bioclim_0-1980.csv")

# ---- normalized dfs ----

normalized <- "data/normalized" |>
  list_files(
    "normalized(?:_\\d)?\\.csv$",
    names = \(x) stringr::str_extract(basename(x), "[^-]+")
  ) |>
  read_auto(names_to = "dataset") |>
  rename(
    id_sp = occurrence_id,
    normalized_name = scientific_name,
    accepted_name = species,
    name_status = status
  ) |>
  mutate(name_status = str_to_lower(name_status))

# ---- original dfs ----

# unsuitable data (too large or unknown locations, no min/max elevations,
# doubtful data, etc.)
refs_to_ignore <- c(
  20002,
  20007,
  20015,
  20013,
  20028,
  20039,
  20057,
  20059,
  20066,
  20079,
  20080,
  20094,
  20095
)

dfs <- "data/datasets" |>
  list_files("\\.csv", names = extract_file_name) |>
  read_auto(
    rename = c(
      "^genera$" = "genus",
      "^(?:scientificName|species|tax[aon]+)$" = "original_name",
      "^subsp.*" = "subspecies",
      "^var.*" = "variety",
      "^infra ?sp(?:ecies)?$" = "infraspecies",
      "^(?:author|nomenclat).*$" = "authority",
      "^(?:(?:min|low)[_-]?(?:elev|alt).*|min|(?:elev|alt).*min)$" = "sp_min",
      "^(?:(?:max|high)[_-]?(?:elev|alt).*|max|(?:elev|alt).*max)$" = "sp_max",
      "^ref_id$" = "id_ref"
    ),
    names_to = "dataset"
  ) |>
  mutate(id_ref = if_else(
    str_detect(dataset, "\\d"),
    as.integer(str_extract(dataset, "\\d+")),
    id_ref
  )) |>
  filter(!id_ref %in% refs_to_ignore) |>
  mutate(id_sp = row_number(), .by = dataset) |>
  mutate(
    across(
      c(subspecies, variety, infraspecies, original_name),
      clean_taxa
    ),
    .by = id_ref
  ) |>
  select(dataset, id_ref, id_sp, original_name, sp_min, sp_max) |>
  left_join(data_source, by = "id_ref") |>
  select(
    dataset,
    id_ref,
    location,
    region,
    continent,
    land_type,
    authority_code,
    id_sp:sp_max,
    lat:lon
  )

# ---- normalized df ----

norm_df <- dfs |>
  left_join(normalized, by = c("dataset", "id_sp")) |>
  filter(
    !is.na(accepted_name),
    accepted_name != "",
    kingdom == "Plantae"
  ) |>
  rename(gbif_sp_key = key) |>
  select(
    id_ref:id_sp,
    gbif_sp_key,
    family,
    original_name,
    normalized_name,
    name_status,
    accepted_name,
    sp_min:lon
  )

# ---- main ----

regions <- c(
  "Hawaii",
  "Cape Verde",
  "Canary",
  "Socotra",
  "Azores",
  "Reunion",
  "Taiwan",
  "Nepal"
)

trs <- norm_df |>
  filter(sp_min <= sp_max & sp_max <= 6500) |>
  drop_na(sp_min, sp_max) |>
  mutate(location = case_when(
    region %in% regions ~ region,
    id_ref %in% c(20062, 20082) ~ "South-Eastern Pyrenees",
    id_ref %in% c(20001, 20051, 30045) ~ "Kenya",
    .default = location
  )) |>
  arrange(desc(id_ref)) |>
  group_by(location) |>
  mutate(
    id_ref = first(id_ref),
    lat = mean(lat),
    lon = mean(lon)
  ) |>
  group_by(accepted_name, .add = TRUE) |>
  mutate(
    sp_min = min(sp_min),
    sp_max = max(sp_max)
  ) |>
  distinct(accepted_name, .keep_all = TRUE) |>
  ungroup() |>
  mutate(
    sp_min = if_else(location == "Canary", 0, round_nearest(sp_min)),
    sp_max = round_nearest(sp_max),
    sp_mean = (sp_min + sp_max) / 2,
    sp_range = sp_max - sp_min,
    elev_band = round_nearest(sp_mean, -ELEV_BIN_WIDTH),
    land_type = replace_na(land_type, "continent")
  ) |>
  mutate(
    elev_span_min = min(sp_min),
    elev_span_max = max(sp_max),
    elev_span = elev_span_max - elev_span_min,
    n_sp = n(),
    singleton = proportion(sp_range == 0),
    .by = id_ref
  ) |>
  arrange(location) |>
  select(id_ref:region, land_type, lat:lon, gbif_sp_key:singleton) |>
  left_join(trs_bioclim, by = c("location", "elev_band")) |>
  left_join(past_clim, by = "location")
