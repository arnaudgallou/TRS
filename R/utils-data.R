#' @export
load_data <- function() {
  file <- list.files(pattern = "trs\\.parquet$", recursive = TRUE)
  nanoparquet::read_parquet(file)
}

#' @export
load_bioclim <- function() {
  file <- list.files(pattern = "trs_bioclim\\.csv$", recursive = TRUE)
  readr::read_csv(file)
}
