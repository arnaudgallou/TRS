#' @title List files in a directory
#' @description A wrapper around [`list.files()`] that gives the possibility to
#'   name each file directly.
#' @param path A character vector of full path names.
#' @param target An optional [`regular expression`][regex()] to return only file
#'   names that match the regular expression.
#' @param names A vector of names to assign to each file, a function, formula or
#'   regular expression to extract names from file names.
#' @param full.names Should the full path be returned?
#' @param ... Other arguments passed on to [`list.files()`].
#' @return A character vector of class `collection`.
#' @export
list_files <- function(path = ".", target = NULL, names = NULL, ...) {
  if (!is.null(names)) {
    if (!(is.function(names) || is.character(names))) {
      rlang::abort("`names` must be a function or character vector.")
    }
  }
  out <- list.files(path, target, full.names = TRUE, ...)
  if (is_empty(out)) {
    rlang::abort("Target files could not be found.")
  }
  if (!is.null(names)) {
    nms <- if (is.function(names)) names(out) else names
    out <- rlang::set_names(out, nms)
  }
  structure(out, class = c("collection", "character"))
}

#' @export
print.collection <- function(x, ...) {
  print(x[seq_along(x)], ...)
}
