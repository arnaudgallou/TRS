string_clean <- function(string) {
  items <- c(
    r"{\B_\B|(?<!['\"])(?<=[\p{Pe}\p{Po}])(?=\p{L})|(?<=\p{L})(?=[\p{Ps}&])}" = " ",
    "(?!\\.)(?:^[^\\p{L}]+|[^\\p{L}]+$)|_" = "",
    "\\s+" = " "
  )
  stringr::str_replace_all(string, items)
}

#' @title Convert a string's first character to uppercase
#' @description Convert a string's first character to uppercase.
#' @param string A character vector.
#' @param to_lower Should other characters be converted to lowercase?
#' @return A character vector.
#' @export
uc_first <- function(string, to_lower = FALSE) {
  if (to_lower) {
    string <- tolower(string)
  }
  substr(string, 1L, 1L) <- toupper(string)
  string
}

first_word <- function(string) {
  out <- stringr::str_remove(string, "^\\P{L}+")
  stringr::str_extract(out, "^[\\p{L}-]+")
}

string_replace <- function(string, pattern, replacement) {
  sub(pattern, replacement, string, perl = TRUE)
}

string_replace_all <- function(string, pattern, ignore_case = FALSE) {
  for (i in seq_along(pattern)) {
    x <- pattern[i]
    string <- gsub(names(x), x, string, perl = TRUE, ignore.case = ignore_case)
  }
  string
}

string_extract_all <- function(string, pattern) {
  out <- regmatches(string, gregexpr(pattern, string, perl = TRUE))
  if (length(out) > 1L) {
    return(out)
  }
  unlist(out)
}

to_snake_case <- function(x) {
  x <- string_replace_all(x, c(
    r"{[^\pL\pN]+|(?<=\p{Lu})(?=\p{Lu}\p{Ll})|(?<=\p{Ll})(?=\p{Lu}|\pN)|(?<=\pN)(?!\pN)}" = "_",
    "^_|_$" = ""
  ))
  tolower(x)
}
