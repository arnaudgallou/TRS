#' @title Read multiple delimited files
#' @description Wrapper around [`data.table::fread()`] to read multiple files.
#' @param files A list of files, connections, or literal data.
#' @param rename A named vector of regex and replacements used to rename columns
#'   in each file.
#' @param ... One or more arguments separated with a comma to pass on to
#'   [`data.table::fread()`].
#' @param merge Should the data be merged in a single data frame?
#' @param clean_names Should the column names be cleaned?
#' @param ignore_case Should letter case be ignored?
#' @param names_to Either a string or NULL. See [`purrr::map_df()`] for details.
#' @export
read_auto <- function(files, rename = NULL, ..., names_to = rlang::zap()) {
  out <- purrr::map(files, function(file) {
    data <- as_tibble(data.table::fread(file, ...))
    if (!is.null(rename)) {
      data <- rename_with(data, \(var) string_replace_all(var, rename, TRUE))
    }
    rename_with(data, to_snake_case)
  })
  list_rbind(out, names_to = names_to)
}
