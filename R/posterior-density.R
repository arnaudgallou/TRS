add_posterior_density <- function(data, estimates, prob, prob_outer = .99) {
  out <- add_averages(data, {{estimates}})
  groups <- dplyr::group_vars(out)
  probs <- c(prob, prob_outer)
  out <- left_join(
    add_hdi(out, {{estimates}}, probs),
    add_density(out, {{estimates}}, median, mean),
    by = groups,
    multiple = "all"
  )
  out <- map(probs, \(prob) filter_cred_interval(out, prob))
  out <- list_rbind(out, names_to = "ci_id")
  coords <- summarize(
    out,
    xmin = min(.data$x),
    xmax = max(.data$x),
    ymax = max(.data$y),
    .by = all_of(groups)
  )
  left_join(out, coords, by = groups)
}

add_averages <- function(data, var) {
  mutate(
    data,
    median = stats::median({{ var }}, na.rm = TRUE),
    mean = mean({{ var }}, na.rm = TRUE)
  )
}

# ... Variables to keep in the nested tibble.
add_density <- function(data, estimates, ...) {
  out <- group_by(data, ..., .add = TRUE)
  out <- tidyr::nest(out)
  out <- mutate(out, density = map(.data$data, \(.x) {
    this <- dplyr::pull(.x, {{ estimates }})
    this <- stats::density(this)
    tibble(x = this$x, y = this$y)
  }))
  out <- select(out, -.data$data)
  tidyr::unnest(out, .data$density)
}

add_hdi <- function(data, estimates, probs) {
  out <- summarize(
    data,
    ci = list(bayestestR::hdi({{ estimates }}, ci = probs)),
    .groups = "keep"
  )
  out <- tidyr::unnest(out, .data$ci)
  rename_with(out, to_snake_case)
}

filter_cred_interval <- function(data, cred_interval) {
  out <- rowwise(data)
  out <- filter(
    out,
    .data$ci == cred_interval,
    between(.data$x, .data$ci_low, .data$ci_high)
  )
  ungroup(out)
}
