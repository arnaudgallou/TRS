#' @title Load model
#' @description Load the global- or local-analyses model file.
#' @param scope Scope of the model to load. One of `c("global", "local")`.
#' @export
load_model <- function(scope = c("global", "local")) {
  scope <- match.arg(scope)
  path <- glue::glue("scripts/models/{scope}-scale.R")
  mdl <- mdl_params <- NULL
  source(path, local = TRUE)
  list(
    model = mdl,
    params = mdl_params,
    name = remove_file_ext(basename(path)),
    scope = scope
  )
}
