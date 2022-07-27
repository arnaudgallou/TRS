####  Model  ####
  {
    mdl <- function() {
      # priors ----------------
      for (j in 1:n_param) {
        beta[j] ~ dnorm(0, 1E-6)
      }
      tau_rs ~ dgamma(.001, .001)
      tau_site ~ dgamma(.001, .001)

      # likelihood ------------
      # to estimate the mean range size in each elevational gradient
      for (i in 1:n_obs) {
        sp_range_obs[i] ~ dnorm(mu_rs[i], tau_rs)
        mu_rs[i] <- alpha_site[location_obs[i]]

        # simulated data for posterior predictive check
        # sp_range_rep[i] ~ dnorm(mu_rs[i], tau_rs)
      }

      # to fit the response to the explanatory variables
      for (i in 1:n) {
        alpha_site[i] ~ dnorm(mu_site[i], tau_site)
        mu_site[i] <- inprod(beta, model_matrix[i, ])

        # simulated data for posterior predictive check
        # alpha_site_rep[i] ~ dnorm(mu_site[i], tau_site)

        # for model selection
        loglik[i] <- logdensity.norm(alpha_site[i], mu_site[i], tau_site)
      }
    }
  }

####  Parameters  ####
  {
    mdl_params <- c(
      # "alpha_site_rep",
      # "sp_range_rep",
      "beta",
      "tau_site",
      "alpha_site",
      "loglik"
    )
  }
