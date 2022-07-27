####  Init  ####
  {
    source("R/init.R")
  }

####  Diagnostics  ####
  {
    # · Init ----
      {
        mdl_output <- "data/jags/global-scale/dtr-span_2500-excl_250-top.rds"
      }

    # · Traceplots ----
      {
        mdl_output %>%
          read_jags("sims") %>%
          pivot_longer(matches("beta")) %>%
          traceplot(aes(x = iter, y = value, color = chain), vars(name))
      }

    # · Rhat ----
      {
        mdl_output %>%
          read_jags("summary") %>%
          pull("rhat") %>%
          bayesplot::mcmc_rhat()
      }

    # · Autocorrelation ----
      {
        mdl_output %>%
          read_jags("sims") %>%
          select(matches("beta")) %>%
          bayesplot::mcmc_acf_bar(lags = 20)
      }

    # · Posterior predictive check ----
      {
        # 'rep' data not saved in the .rds
        # uncomment parameters ending with '_rep' in the model files
        # use run_jags() with default_output=TRUE

        ppc_(mdl_data, mdl_output, all = FALSE)
      }
  }
