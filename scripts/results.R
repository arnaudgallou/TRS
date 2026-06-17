# ---- fig: regressions ----

PATH_GLOBAL |>
  fetch_jags(
    vars = c("dtr", "ts", "past_dmat"),
    elevation_span = 2500
  ) |>
  make_regression_data() |>
  plot_regressions()

# ---- fig: regressions by land type ----

PATH_GLOBAL |>
  fetch_jags(
    vars = "(dtr|ts|dmat)-land_type",
    elevation_span = 2500,
    exclusion_zone = 250
  ) |>
  make_regression_data(by_land_type = TRUE) |>
  plot_regressions()

# ---- fig: regressions labelled ----

PATH_GLOBAL |>
  fetch_jags(
    vars = c("dtr", "ts", "past_dmat"),
    elevation_span = 2500,
    exclusion_zone = 250
  ) |>
  make_regression_data() |>
  plot_regressions(point_labels = TRUE)

# ---- fig: posterior distributions ----

PATH_GLOBAL |>
  fetch_jags(vars = c("dtr", "ts", "past_dmat")) |>
  make_posterior_data(
    yvar = "exclusion_zone",
    prob = c(.8, .95),
    prob_outer = .99,
    scales = c(dtr = .013, ts = .018, past_dmat = .2),
    labels = c(
      dtr = "beta[DTR]",
      ts = "beta[TS]",
      past_dmat = "beta[Delta*MAT[0-1980]]"
    ),
  ) |>
  plot_posterior_distributions(
    yvar = "exclusion_zone",
    vline_color = "grey70",
    vline_type = 2,
    facet_args = list(
      rows = vars(elevation_span),
      cols = vars(expl_var),
      scales = "free_x",
      switch = "y",
      labeller = label_parsed
    ),
    colors = c("#5E8CBA", "#CB624D", "#F5B83D")
  ) +
  xlab("Posterior parameter estimates") +
  theme(
    strip.placement = "outside",
    strip.background = element_blank(),
    axis.line.y = element_blank(),
    axis.ticks.y = element_blank()
  )

# ---- tbl: model evaluation ----

PATH_GLOBAL |>
  fetch_jags(
    elevation_span = 2500,
    exclusion_zone = 250,
    std_from = "top"
  ) |>
  eval_models()

# ---- tbl: statistical details ----

PATH_GLOBAL |>
  fetch_jags(std_from = "top") |>
  map(\(file) {
    data <- read_rds(file)
    get_statistical_details(data)
  }) |>
  list_rbind() |>
  round_num(2L) |>
  mutate(interaction = if_else(grepl("\\*", model), 1L, 0L)) |>
  arrange(
    desc(std_from),
    interaction,
    elevation_span,
    exclusion_zone,
    model
  ) |>
  select(-c(interaction, std_from))

# ---- data: local ----

local_data <- PATH_LOCAL |>
  fetch_jags(std_from = "none") |>
  read_jags("summary", vars = "beta")

# ---- fig: histogram ----

local_data |>
  filter(exclusion_zone == 250) |>
  extend_jags_summary() |>
  ggplot(aes(beta_std, fill = x95_ci)) +
  ggh4x::facet_grid2(
    rows = vars(exclusion_zone),
    cols = vars(expl_var),
    scales = "free_y",
    axes = "all",
    remove_labels = TRUE
  ) +
  geom_histogram(
    position = "identity",
    binwidth = 2.5,
    color = "white",
    size = .3
  ) +
  line_0("x") +
  scale_fill_manual(values = c("#006699", "#D4E5ED")) +
  scale_y_continuous(breaks = seq(0, 12, 3)) +
  labs(x = "Mean slopes / SD slopes", y = "Count") +
  coord_cartesian(expand = FALSE) +
  theme(strip.background = element_blank())

# ---- fig: elevation span influence ----

local_data |>
  filter(exclusion_zone == 250) |>
  mutate(
    parameter = word(parameter),
    y = mean / sd
  ) |>
  left_join(
    load_data() |>
      summarize(.by = c(location, elev_span)) |>
      rowid_to_column(),
    by = "rowid"
  ) |>
  ggplot(aes(
    x = elev_span,
    y = y,
    color = expl_var,
    fill = expl_var,
    alpha = expl_var
  )) +
  ggh4x::facet_wrap2(
    vars(expl_var),
    axes = "all",
    remove_labels = TRUE
  ) +
  line_0("y") +
  geom_smooth(
    method = "lm",
    size = .5,
    color = "#85A9D6",
    fill = "#85A9D6"
  ) +
  scale_alpha_manual(values = rep(.15, 2L)) +
  labs(
    x = "Elevational gradient length (m)",
    y = "Mean slopes / SD slopes"
  )

# ---- tbl: slope summary ----

local_data |>
  extend_jags_summary() |>
  summarize_slopes(by = c(expl_var, exclusion_zone)) |>
  relocate(contains("low"), .before = "positive_high_uncertainties") |>
  rename(model = expl_var) |>
  round_num(0L)

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
