label_facets <- partial(egg::tag_facet, open = "", close = "")

format_thousands <- partial(format, big.mark = ",")

get_n_data <- function(x) {
  x <- nrow(x)
  x <- round_nearest(x, -1000)
  format_thousands(x)
}

get_n_location <- function(x, min_elev_span, land_type) {
  if (!missing(land_type)) {
    x <- x[x$land_type == land_type, ]
  }
  if (!missing(min_elev_span)) {
    x <- x[x$elev_span >= min_elev_span, ]
  }
  x <- unique(x$location)
  length(x)
}

get_slope_perc <- function(x, .model, direction = c("+", "-"), certainty, excl_zone = 250) {
  certainty <- if (!missing(certainty)) glue("_{certainty}") else "$"
  direction <- if (match.arg(direction) == "+") "positive" else "negative"
  x <- filter(x, model == .model, exclusion_zone == excl_zone)
  x <- select(x, matches(glue("{direction}{certainty}")))
  pull(x)
}

get_regression_stats <- function(x, .model, var = c("r2", "p_beta")) {
  var <- if (match.arg(var) == "r2") 1 else 2
  x <- filter(x, model == .model)
  x <- select(x, matches("r_squared|beta"))
  pull(x, var)
}


make_conceptual_data <- function(concept) {
  x_min_a <- 1.6
  x_max_a <- 2
  x_min_b <- 6.5
  x_max_b <- 8.5

  x_base <- c(x_min_a, x_max_a, x_min_b, x_max_b)
  x_mean <- list(
    a = mean(x_base[1:2]),
    b = mean(x_base[3:4])
  )

  y_inner <- c(2, 38, 10, 30)
  y_outer <- c(-2, 42, -10, 50)
  y_hab_lim <- if (concept == "trs") y_inner else  y_outer
  y_max <- max(y_outer) + 5
  y_min <- min(y_outer) - 5

  make_poly_data = function() {
    tibble(
      mountain = rep(c("a", "b"), each = 12),
      x = rep(c(x_base[1:2], x_base[3:4]), each = 6),
      y = list(c(-2, 38, y_max, 42, 2), c(-10, 30, y_max, 50, 10)) %>%
        map(~ c(y_min, rep(.x, each = 2), y_min)) %>%
        unlist(),
      id = rep(c(1, 2, 3, 3, 2, 1), 2, each = 2) %>% as.factor()
    )
  }

  x_arr_suit_hab <- c(x_max_a + .5, x_min_b - .5)

  make_arrow_data = function() {
    if (concept == "trs") {
      df_arr_temporal <- tibble(
        x = c(x_min_a, x_min_b),
        xend = c(x_max_a, x_max_b),
        y = rep(y_min - 2, 2),
        yend = y
      )
    } else {
      df_arr_temporal <- NULL
    }

    df_arr_hab <- tibble(
      x = x_arr_suit_hab,
      xend = x,
      y = y_hab_lim[c(1, 3)],
      yend = y_hab_lim[c(2, 4)]
    )

    list("temporal" = df_arr_temporal, "hab" = df_arr_hab) %>%
      bind_rows(.id = "name") %>%
      mutate(id_arr_end = factor(2))
  }

  make_segment_data = function() {
    df_seg_hab <- tibble(
      x = rep(c(x_min_a, x_max_b), each = 2),
      xend = rep(c(x_max_a + .5, x_min_b - .5), each = 2),
      y = y_hab_lim,
      yend = y
    ) %>%
      mutate(id_color = 1, id_line = 1)

    df_seg_iso <- tibble(
      x = rep(c(x_min_a, x_min_b), 2),
      xend = rep(c(x_max_a, x_max_b), 2),
      y = c(y_outer[c(1, 3)], y_inner[c(2, 4)]),
      yend = y + c(4, 20),
      id_color = rep(c(2, 3), each = 2)
    ) %>%
      mutate(id_line = 2)

    list("hab. lims" = df_seg_hab, "iso" = df_seg_iso) %>%
      bind_rows(.id = "name") %>%
      add_row(
        name = "connector",
        x = x_max_a + .5, xend = x_min_b - .5,
        y = 20, yend = y,
        id_color = 1,
        id_line = 3
      ) %>%
      mutate(across(starts_with("id"), as.factor))
  }

  make_label_data = function() {
    if (concept == "trs") {
      df_lab_temporal <- tibble(
        x = x_base,
        y = rep(y_min - 2, 4),
        label = rep(c("Cold", "Warm"), 2),
        hjust = rep(c(1, 0), 2)
      ) %>%
        mutate(id_fill = 1)
    } else {
      df_lab_temporal <- NULL
    }

    df_lab_tr <- tibble(
      x = c(x_mean$a, x_mean$b),
      y = rep(y_min - 6, 2),
      label = c("∆T = 2°C", "∆T = 20°C"),
      hjust = rep(.5, 2),
    ) %>%
      mutate(id_fill = 1)

    df_lab_hab <- tibble(
      x = mean(x_arr_suit_hab),
      y = mean(c(y_min, y_max)),
      label = "Suitable habitat",
      hjust = .5,
      id_fill = 2
    )

    bind_rows(df_lab_temporal, df_lab_tr, df_lab_hab)
  }

  list(
    x_mean = x_mean,
    poly = make_poly_data(),
    df_arrows = make_arrow_data(),
    df_segments = make_segment_data(),
    df_lab = make_label_data()
  )
}


make_conceptual_fig <- function(concept = c("trs", "gilchrist"), label_size = 10 / .pt) {
  concept <- match.arg(concept)
  obj <- make_conceptual_data(concept)

  if (concept == "trs") {
    x_labels <- c(
      "Low thermal variation\n(mountain 1)",
      "High thermal variation\n(mountain 2)"
    )
  } else {
    x_labels <- c(
      "Low\namong-generation\nvariation",
      "High\namong-generation\nvariation"
    )
  }

  ggplot() +
    map(
      c("a", "b"),
      ~ geom_polygon(
        aes(x, y, fill = id, group = id),
        data = filter(obj$poly, mountain == .x),
        alpha = .3
      )
    ) +
    scale_fill_manual(values = c("#ff6b6c", "#85a9d6", "#ff6b6c")) +
    map2(
      c(1, 2),
      c("last", "both"),
      ~ geom_segment(
        aes(x = x, xend = xend, y = y, yend = yend),
        data = filter(obj$df_arrows, id_arr_end == .x),
        arrow = arrow(angle = 15, length = grid::unit(3, "pt"), ends = .y, type = "closed"),
        size = .3
      )
    ) +
    geom_segment(
      aes(
        x = x, xend = xend,
        y = y, yend = yend,
        color = id_color,
        linetype = id_line,
        size = id_line
      ),
      lineend = "round",
      data = arrange(obj$df_segments, desc(name)),
    ) +
    scale_linetype_manual(values = c("dotted", "solid", "solid")) +
    scale_size_manual(values = c(.3, .8, .3)) +
    map2(
      c(1, 2),
      c(NA, "white"),
      ~ geom_label(
        aes(x, y, label = label, hjust = hjust),
        data = filter(obj$df_lab, id_fill == .x),
        size = label_size,
        label.size = NA,
        fill = .y,
        inherit.aes = FALSE
      )
    ) +
    scale_color_manual(values = c("black", "#D23C28", "#1D6DC3")) +
    scale_y_continuous(
      breaks = seq(0, 40, 10),
      labels = seq(0, 4000, 1000),
      sec.axis = sec_axis(
        ~ .,
        breaks = seq(0, 40, 10),
        labels = abs(seq(0, 20, 5) - 20),
        name = "Mean temperature (°C)"
      )
    ) +
    scale_x_continuous(
      breaks = c(obj$x_mean$a, obj$x_mean$b),
      labels = x_labels,
      limits = c(0, 10)
    ) +
    ylab("Elevation (m)") +
    theme(
      panel.grid.major.y = element_line(size = .3, color = "gray90"),
      axis.title.y.left = element_text(margin = margin(0, 10, 0, 0)),
      axis.title.y.right = element_text(margin = margin(0, 0, 0, 10)),
      axis.text.x = element_text(size = 11),
      axis.title.x = element_blank(),
      axis.ticks.y = element_blank(),
      axis.line.y = element_blank()
    )
}
