#' @export
round_num <- function(data, digits = 2L) {
  mutate(data, across(\(x) is.double(x), round, digits))
}

#' @export
clean_taxa <- function(col) {
  data <- pick(everything())
  col <- as.character(substitute(col))
  class(data) <- c(col, class(data))
  clean_taxa_(data, data[[col]])
}

clean_taxa_ <- function(data, x) {
  UseMethod("clean_taxa_")
}

clean_taxa_.subspecies <- function(data, x) {
  out <- if_else(
    !is.na(x) & mean(str_detect(data$original_name, coll(x))) == 1L,
    NA,
    x
  )
  str_remove(out, "^(?:ssp|subsp)\\.\\s*")
}

clean_taxa_.variety <- function(data, x) {
  str_remove(data$variety, "^var\\.\\s*")
}

clean_taxa_.infraspecies <- function(data, x) {
  out <- case_when(
    !is.na(x) & str_detect(x, coll(data$original_name)) ~ NA,
    !is.na(data$subspecies) ~ paste("subsp.", data$subspecies),
    !is.na(data$variety) ~ paste("var.", data$variety),
    .default = x
  )
  str_replace(out, "^\\w+\\.(?!\\s)\\K", " ")
}

clean_taxa_.original_name <- function(data, x) {
  out <- paste(
    if_else(
      !is.na(data$genus) & mean(data$genus != first_word(x)) > .5,
      data$genus,
      ""
    ),
    x,
    replace_na(data$infraspecies, ""),
    replace_na(data$authority, "")
  )
  out <- string_clean(out)
  uc_first(out)
}
