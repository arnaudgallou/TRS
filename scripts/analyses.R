# ---- model ----

model <- load_model(scope = "global")

# ---- compile data ----

if (model$scope == "global") {
  mdl_data <- compile_mdl_data(
    load_data(),
    clim_data = load_bioclim(),
    elevation_span = ELEV_SPAN_DEFAULT,
    exclusion_zone = EXCL_DEFAULT,
    singleton_thr = SINGLETON_THR,
    std_elev_grad = TRUE,
    average = TRUE,
    std_from = "top",
    cols = c("location", "sp_range", "land_type"),
    expr = ~ dtr * land_type
  )
} else {
  mdl_data <- compile_mdl_data(
    load_data(),
    elevation_span = 1500,
    exclusion_zone = EXCL_DEFAULT,
    singleton_thr = SINGLETON_THR,
    cols = c("location", "sp_range"),
    expr = "dtr"
  )
}

# ---- run model ----

run_jags(
  mdl_data,
  model = model,
  n.iter = JAGS_ITER,
  n.thin = JAGS_THIN,
  n.chains = JAGS_CHAINS,
  n.burnin = JAGS_BURN_IN,
  save = TRUE,
  path = glue("data/jags/{model$scope}-scale/")
)
