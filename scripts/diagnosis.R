fl <- fetch_jags(
  "data/jags/global-scale",
  vars = "dtr",
  elevation_span = 2500,
  exclusion_zone = 250,
  std_from = "top"
)

# ---- traceplots ----

fl |>
  read_jags("sims") |>
  pivot_longer(matches("beta")) |>
  traceplot(aes(x = iter, y = value, color = chain), vars(name))

# ---- r-hat ----

fl |>
  read_jags("summary") |>
  pull("rhat") |>
  bayesplot::mcmc_rhat()

# ---- autocorrelation ----

fl |>
  read_jags("sims") |>
  select(matches("beta")) |>
  bayesplot::mcmc_acf_bar(lags = 20)

# ---- posterior predictive check ----

# 'rep' data not saved in the .rds
# uncomment parameters ending with '_rep' in the model files
# use run_jags() with `default_output = TRUE`

ppc_(mdl_data, fl, all = FALSE)
