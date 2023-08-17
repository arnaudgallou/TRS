####  Init  ####
  {
    source("R/init.R")
  }

####  Global-scale analyses  ####
  {
    trs_global <- GlobalAnalyses$new(PATH_GLOBAL)

    trs_global$regressions(
      vars = c("dtr", "ts", "past_dmat"),
      elev_span = 2500
    )

    trs_global$regressions(
      vars = "(dtr|ts|dmat)-land_type",
      elev_span = 2500,
      excl_zone = 250,
      by_land_type = TRUE
    )

    trs_global$regressions(
      vars = c("dtr", "ts", "past_dmat"),
      elev_span = 2500,
      excl_zone = 250,
      point_labels = TRUE
    )

    trs_global$posterior_distributions(
      vars = c("dtr", "ts", "past_dmat"),
      yvar = "exclusion_zone",
      std_from = "top",
      scales = c(dtr = .013, ts = .018, past_dmat = .2),
      labels = c(
        dtr = "beta[DTR]",
        ts = "beta[TS]",
        past_dmat = "beta[Delta*MAT[0-1980]]"
      ),
      fill = c("#5E8CBA", "#CB624D", "#F5B83D")
    )

    trs_global$eval_models(
      elev_span = 2500,
      excl_zone = 250,
      std_from = "top"
    )

    View(trs_global$get_statistical_details())
  }

####  Local-scale analyses  ####
  {
    trs_local <- LocalAnalyses$new(PATH_LOCAL)

    trs_local$slope_histograms()

    trs_local$influence_elev_span(trs, excl_zone = 250)

    trs_local$tbl_slope_summary()
  }

# ---- map ----
  {
    bubble_colors <- c("#e34326", "#3051b5")

    trs |>
      distinct(id_ref, .keep_all = TRUE) |>
      reframe(
        lon, lat, n_sp,
        span_default = if_else(elev_span >= ELEV_SPAN_DEFAULT, TRUE, FALSE)
      ) |>
      drop_na() |>
      ggplot() +
      geom_sf(
        data = rnaturalearth::ne_countries(returnclass = "sf"),
        size = 0.02,
        alpha = .25
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
  }

# ---- thermal variability range ----
  {
    trs |>
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
        "Diurnal temperature\nrange",
        "Temperature\nseasonality"
      )) +
      ylab("Thermal range (°C)") +
      theme_elesic() +
      add_facet_lines() +
      theme(
        axis.title.x = element_blank(),
        axis.title.y = element_text(size = 9),
        axis.text.x = element_text(size = 9),
        axis.text.y = element_text(size = 8)
      )
  }
