####  Init  ####
  {
    source("R/init.R")

    fls_srtm <- list_files("gis/srtm", names = extract_file_name)
  }

####  Bioclim (present)  ####
  {
    bioclim <- "gis/clim/data/present" %>%
      list_files(TIF, names = ~ {
        .x %>%
          basename() %>%
          str_remove("10_0?") %>%
          str_extract("bio\\d+")
      }) %>%
      rs_read()

    fls_srtm %>%
      map(~ {
        location <- extract_file_name(.x, to_snake_case = TRUE)

        .x %>%
          list_files(TIF, names = ~ str_extract(dirname(.x), "[^/]+$")) %>%
          map(
            ~ rs_read(.x) %>%
              rs_set_range() %>%
              rs_filter(. > 0) %>%
              rs_reclass_dem(binwidth = ELEV_BIN_WIDTH)
          ) %>%
          map_df(
            ~ bioclim %>%
              rs_crop(.x, snap = "out") %>%
              rs_project(y = .x) %>%
              rs_zonal(.x, fun = "mean", na.rm = TRUE) %>%
              as_tibble(),
            .id = "location"
          ) %>%
          rename(elev_band = zone) %>%
          group_by(elev_band) %>%
          mutate(across(
            starts_with("bio"),
            mean
          )) %>%
          ungroup() %>%
          distinct(elev_band, .keep_all = TRUE) %>%
          write_csv(glue("gis/clim/extracted/present/{location}-bioclim.csv"))

        gc()
      })
  }

####  Bioclim (past)  ####
  {
    polygons <- fls_srtm %>%
      map(
        ~ list_files(.x, TIF) %>%
          map(~ rs_read(.x) %>% rs_ext_to_polygon())
      ) %>%
      map(rs_vect)

    "gis/clim/data/past/var" %>%
      list_files("mean", names = partial(extract_file_name, to_snake_case = TRUE)) %>%
      map(
        ~ list_files(.x, ASC, recursive = TRUE, names = ~ {
            parse_number(basename(.x))
          }) %>%
          rs_read() %>%
          rs_set_crs()
      ) %>%
      imap(~ {
        clim <- .x
        name <- .y
        map_df(
          polygons,
          ~ clim %>%
            rs_extract(.x, fun = mean) %>%
            summarise(across(-ID, mean)) %>%
            pivot_longer(everything(), names_to = "time", values_to = name),
          .id = "location"
        )
      }) %>%
      reduce(left_join, by = c("location", "time")) %>%
      group_by(location) %>%
      summarise(
        past_dmat = max(mean_temperature) - min(mean_temperature),
        past_map = mean(mean_precipitation)
      ) %>%
      arrange(location) %>%
      write_csv("gis/clim/extracted/past/bioclim_0-1980.csv")
  }
