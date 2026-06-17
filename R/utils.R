#' @title Round up or down a number to the nearest value
#' @description Round up or down a number to the nearest value.
#' @param x A numeric vector.
#' @param nearest A numeric value indicating the nearest value to round by. If
#'   negative, will round down to the nearest value. If positive, will round up
#'   to the nearest value.
#' @export
round_nearest <- function(x, nearest = -10) {
  nearest <- -nearest
  (x %/% nearest) * nearest
}

#' @title Compute proportion
#' @description Context dependent expression that returns the current proportion
#'   of values that sastify a condition. See [`dplyr::context()`] for details.
#' @param condition Logical vectors.
#' @export
proportion <- function(condition) {
  sum(condition, na.rm = TRUE) * 100 / dplyr::n()
}

#' @title Center and standardize data
#' @description Center and standardize data.
#' @param x A numeric vector.
#' @export
standardize <- function(x) {
  (x - mean(x, na.rm = TRUE)) / (2 * stats::sd(x, na.rm = TRUE))
}

#' @title Compute the difference between consecutive values
#' @description Compute the difference between the first element of a numeric vector and all consecutive values.
#' @param x Numeric vector.
#' @export
delta <- function(x) {
  x - dplyr::lag(x, n = length(x), default = x[1])
}

#' @export
extract_file_name <- function(x) {
  remove_file_ext(basename(x))
}

#' @title Calculate the maximum difference
#' @description Calculate the difference between the two most extreme values in
#'   a numeric vector.
#' @param x A numeric vector.
#' @export
calc_max_diff <- function(x) {
  max(x, na.rm = TRUE) - min(x, na.rm = TRUE)
}

remove_file_ext <- function(file) {
  stringr::str_remove(file, "\\.[^.]+$")
}

name_suffix <- function(x) {
  replace(seq(x), 1, "")
}

parse_formula <- function(x) {
  stringr::str_extract_all(as.character(x)[[2]], "\\w+")[[1]]
}

make_dir <- function(path, ...) {
  dir.create(path, recursive = TRUE, ...)
}

make_list <- function(...) {
  rlang::dots_list(..., .named = TRUE)
}

get_mdl_settings <- function(x) {
  settings <- x$settings
  tibble(
    model = as.character(settings$formula)[[2]],
    elevation_span = settings$elevation_span,
    exclusion_zone = settings$exclusion_zone,
    std_from = settings$std_from
  )
}

discard <- function(x, y) {
  x[!x %in% y]
}
