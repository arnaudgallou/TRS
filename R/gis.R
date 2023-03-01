####  Init  ####
  {
    source("R/init.R")

    dem_folders <- list_files("gis/srtm", names = extract_file_name)
  }

####  Bioclim (present)  ####
  {
    bioclim <- "gis/clim/data/present" |>
      list_files(TIF, names = \(file) {
        out <- basename(file)
        out <- str_remove(out, "10_0?")
        str_extract(out, "bio\\d+")
      }) |>
      rs_read()

    walk(dem_folders, \(folder) {
      location <- extract_file_name(folder, to_snake_case = TRUE)

      folder |>
        list_files(TIF, names = \(file) {
          str_extract(dirname(file), "[^/]+$")
        }) |>
        map(\(file) {
          dem <- rs_read(file)
          dem <- rs_set_range(dem)
          dem <- rs_filter(dem, dem > 0)
          rs_reclass(dem, binwidth = ELEV_BIN_WIDTH, col_name = "elev_band")
        }) |>
        map(\(dem) {
          clim <- rs_crop(bioclim, dem, snap = "out")
          clim <- rs_project(clim, dem)
          clim <- rs_zonal(clim, dem, fun = "mean", na.rm = TRUE)
          as_tibble(clim)
        }) |>
        list_rbind(names_to = "location") |>
        mutate(
          across(starts_with("bio"), mean),
          .by = elev_band
        ) |>
        distinct(elev_band, .keep_all = TRUE) |>
        write_csv(glue("gis/clim/extracted/present/{location}-bioclim.csv"))

      gc()
    }, .progress = TRUE)
  }

####  Bioclim (past)  ####
  {
    polygons <- dem_folders |>
      map(\(folder) {
        fls <- list_files(folder, TIF)
        map(fls, \(file) {
          out <- rs_read(file)
          rs_ext_to_polygon(out)
        })
      }) |>
      map(rs_vect)

    "gis/clim/data/past/var" |>
      list_files(
        target = "mean",
        names = partial(extract_file_name, to_snake_case = TRUE)
      ) |>
      map(\(folder) {
        out <- list_files(folder, ASC, recursive = TRUE, names = \(file) {
          parse_number(basename(file))
        })
        out <- rs_read(out)
        rs_set_crs(out)
      }) |>
      imap(\(raster, name) {
        clim <- map(polygons, \(polygon) {
          out <- rs_extract(raster, polygon, fun = mean)
          out <- summarise(out, across(-ID, mean))
          pivot_longer(out, everything(), names_to = "time", values_to = name)
        })
        list_rbind(clim, names_to = "location")
      }) |>
      reduce(left_join, by = c("location", "time")) |>
      summarise(
        past_dmat = max(mean_temperature) - min(mean_temperature),
        past_map = mean(mean_precipitation),
        .by = location
      ) |>
      arrange(location) |>
      write_csv("gis/clim/extracted/past/bioclim_0-1980.csv")
  }
