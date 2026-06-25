# ---- global analyses ----

ga <- GlobalAnalyses$new(PATH_GLOBAL)

ga$regressions(
  elev_span = 2500,
  excl_zone = 250,
  labels = c(
    dtr = "Diurnal temperature range (\u00b0C)",
    ts = "Temperature seasonality (\u00b0C)",
    past_dmat = "\u0394 mean annual temperature\n(0-1980) (\u00b0C)"
  )
)

ga$regressions(
  elev_span = 2500,
  excl_zone = 250,
  by_land_type = TRUE
)

ga$posterior_distributions(
  scales = c(dtr = .013, ts = .018, past_dmat = .2),
  colors = c("#5E8CBA", "#CB624D", "#F5B83D"),
)

ga$eval_models()

ga$get_statistical_details() |> View()

# ---- local analyses ----

la <- LocalAnalyses$new(PATH_LOCAL)

la$slope_histograms()

la$influence_elev_span()

la$tbl_slope_summary()

# ---- map: sites ----

bubble_colors <- c("#e34326", "#3051b5")

load_data() |>
  distinct(id_ref, .keep_all = TRUE) |>
  reframe(
    lon,
    lat,
    n_sp,
    span_default = if_else(elev_span >= ELEV_SPAN_DEFAULT, TRUE, FALSE)
  ) |>
  drop_na() |>
  ggplot() +
  geom_sf(
    data = rnaturalearth::ne_countries(returnclass = "sf"),
    linewidth = NA,
    fill = "#ebebeb"
  ) +
  coord_sf(expand = FALSE) +
  geom_point(
    aes(
      x = lon,
      y = lat,
      size = n_sp,
      color = span_default,
      fill = span_default
    ),
    stroke = .3,
    shape = 21
  ) +
  scale_size_continuous(
    range = c(1, 8),
    name = "No. of species",
    breaks = c(200, 3000, 17000)
  ) +
  scale_color_manual(values = bubble_colors) +
  scale_fill_manual(values = alpha(bubble_colors, .3)) +
  guides(color = "none", fill = "none") +
  theme_void() +
  theme(legend.position = c(.1, .3))

# ---- fig: thermal variability range ----

load_data() |>
  group_by(id_ref) |>
  distinct(elev_band, .keep_all = TRUE) |>
  group_by(location) |>
  summarise(
    range_dtr = calc_max_diff(bio2),
    range_ts = calc_max_diff(bio4)
  ) |>
  pivot_longer(where(is.numeric)) |>
  ggplot(aes(name, value)) +
  geom_violin(
    trim = TRUE,
    fill = "#D4E5ED",
    size = NA,
    alpha = .8
  ) +
  geom_boxplot(
    width = .05,
    size = .3,
    outlier.size = 1,
    outlier.alpha = .6
  ) +
  scale_x_discrete(labels = c(
    "Diurnal\ntemperature\nrange",
    "Temperature\nseasonality"
  )) +
  ylab("Thermal range (°C)") +
  theme(axis.title.x = element_blank())

# ---- map: species range sizes ----

load_data() |>
  mutate(
    span_default = if_else(
      elev_span >= ELEV_SPAN_DEFAULT,
      TRUE,
      FALSE
    )
  ) |>
  summarise(
    mean_rs = mean(sp_range),
    .by = c(id_ref, lon, lat, span_default)
  ) |>
  drop_na() |>
  ggplot() +
  geom_sf(
    data = rnaturalearth::ne_countries(returnclass = "sf"),
    linewidth = NA,
    fill = "#ebebeb"
  ) +
  coord_sf(expand = FALSE) +
  geom_point(
    aes(
      x = lon,
      y = lat,
      size = mean_rs,
      color = span_default,
      fill = span_default
    ),
    stroke = .3,
    shape = 21
  ) +
  scale_size_continuous(
    name = "Mean species' elevational\nrange size (m)",
    breaks = c(500, 1000, 1500)
  ) +
  scale_color_manual(values = bubble_colors) +
  scale_fill_manual(values = alpha(bubble_colors, .3)) +
  guides(color = "none", fill = "none") +
  theme_void() +
  theme(legend.position = c(.15, .3))
