####  Init  ####
  {
    source("R/init.R")
  }

####  Global-scale analyses  ####
  {
    # · Instantiate global ----
      {
        trs_global <- global_analyses(PATH_GLOBAL)
      }

    # · Regressions main ----
      {
        trs_global$plot_regressions_(elevation_span = 2500)
      }

    # · Regressions land type ----
      {
        trs_global$plot_regressions_(
          elevation_span = 2500,
          exclusion_zone = 250,
          type = "land_type"
        )
      }

    # · Regressions location names ----
      {
        trs_global$plot_regressions_(
          elevation_span = 2500,
          exclusion_zone = 250,
          point_labels = TRUE
        )
      }

    # · Posterior distributions ----
      {
        trs_global$plot_posterior_distributions_(
          vars = "dtr|ts|dmat",
          yvar = "exclusion_zone",
          std_from = "top",
          scales = c(dtr = .013, ts = .018, past_dmat = .2),
          param_names = c(
            dtr = "β[DTR]",
            ts = "β[TS]",
            past_dmat = "β['∆'*MAT[0-1980]]"
          ),
          fill = c("#5E8CBA", "#CB624D", "#F5B83D")
        )
      }
    # · Model comparison ----
      {
        trs_global$eval_models_(elevation_span = 2500, exclusion_zone = 250, std_from = "top")
      }

    # · Statistical details ----
      {
        View(trs_global$get_statistical_details_())
      }
  }

####  Local-scale analyses  ####
  {
    # · Instantiate local ----
      {
        trs_local <- local_analyses(PATH_LOCAL)
      }

    # · Histogram of slopes ----
      {
        trs_local$plot_slope_histogram_()
      }

    # · Influence of elevation span ----
      {
        trs_local$plot_influence_elev_span_(trs, exclusion_zone = 250)
      }

    # · Slope summary ----
      {
        trs_local$get_slope_summary_()
      }
  }

# ---- map ----
  {
    bubble_colors <- c("#e34326", "#3051b5")

    trs %>%
      distinct(id_ref, .keep_all = TRUE) %>%
      summarise(
        lon,
        lat,
        n_sp,
        span_default = if_else(elev_span >= ELEV_SPAN_DEFAULT, TRUE, FALSE)
      ) %>%
      drop_na() %>%
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
      theme(legend.position = c(.1, .25))
  }

# ---- thermal variability range ----
  {
    trs %>%
      group_by(id_ref) %>%
      distinct(elev_band, .keep_all = TRUE) %>%
      group_by(location) %>%
      summarise(
        amplitude_dtr = max(bio2, na.rm = TRUE) - min(bio2, na.rm = TRUE),
        amplitude_ts = max(bio4, na.rm = TRUE) - min(bio4, na.rm = TRUE)
      ) %>%
      pivot_longer(where(is.numeric)) %>%
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
