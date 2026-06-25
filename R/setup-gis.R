#' @title Create directories for GIS analyses
#' @description Create the required directories to run the GIS analyses.
#' @export
setup_gis <- function() {
  proj <- "TRS.Rproj"
  if (!file.exists(proj)) {
    stop("function `setup_gis` must be executed in ", proj, ".")
  }
  trs <- "data/trs.csv"
  if (!file.exists(trs)) {
    stop(basename(trs), " could not be found in the `data` directory.")
  }
  gis_make_paths()
}

gis_dir_paths <- c(
  file.path("extracted", c("past", "present")),
  "data/present",
  file.path(
    "data",
    "past",
    c(
      "base",
      file.path("var", c("mean precipitation", "mean temperature"))
    )
  )
)

gis_make_paths <- function() {
  for (i in gis_dir_paths) {
    make_dir(file.path("gis", "clim", i))
  }
  x <- read_csv(trs, col_select = "location")
  mountains <- unique(x$location)
  for (i in mountains) {
    make_dir(file.path("gis", "srtm", i))
  }
}
