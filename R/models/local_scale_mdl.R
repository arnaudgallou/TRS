####  Model  ####
  {
    mdl <- function() {
      # priors ----------------
      for (i in 1:n_location) {
        alpha[i]~ dnorm(0, 1E-6)
        beta[i]~ dnorm(0, 1E-6)
      }
      tau ~ dgamma(.001, .001)

      # likelihood ------------
      for (i in 1:n) {
        sp_range[i] ~ dnorm(mu[i], tau)
        mu[i] <- alpha[location[i]] + beta[location[i]] * bioclim[i]

        # simulated data for posterior predictive check
        # sp_range_rep[i] ~ dnorm(mu[i], tau)
      }
    }
  }

####  Parameters  ####
  {
    mdl_params <- c(
      # "sp_range_rep",
      "alpha",
      "beta",
      "tau"
    )
  }
