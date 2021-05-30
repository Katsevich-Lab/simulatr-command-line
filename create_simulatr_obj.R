library(simulatr)

generate_lm_data <- function(beta_0, beta_1, sigma, n) {
  x <- rnorm(n)
  ep <- rnorm(n, sd = sigma)
  y <- beta_0 + beta_1 * x + ep
  data.frame(y = y, x = x)
}

data_generator <- simulatr_function(f = generate_lm_data,
                                    arg_names = c("beta_0", "beta_1", "sigma", "n"),
                                    loop = TRUE)

fit_lm <- function(df) {
  fit <- lm(y ~ x, data = df)
  s <- summary(fit)$coefficients
  row.names(s) <- NULL
  out <- data.frame(
    parameter = c("beta_0", "beta_1"),
    Estimate = s[, "Estimate"],
    p_val = s[, "Pr(>|t|)"] ) %>% pivot_longer(
      cols = c("Estimate", "p_val"),
      names_to = "target")
  return(out)
}
method <- simulatr_function(f = fit_lm, packages = "tidyr", loop = TRUE)

silly_competitor <- function(df, sigma) {
  out <- data.frame(parameter = c("beta_1", "beta_1"),
                    target = c("Estimate", "p_val"),
                    value = c(rnorm(1, sd = sigma), runif(1)))
  return(out)
}
competitor <- simulatr_function(f = silly_competitor, arg_names = "sigma", loop = TRUE)

parameter_grid <- expand.grid(beta_0 = seq(-2, 2, 2), beta_1 = seq(-2, 2, 2))
fixed_parameters <- list(n = 100, sigma = 1, n_processors = 2, seed = 4, B = 100)

simulatr_specifier_object <- simulatr_specifier(
  parameter_grid = parameter_grid,
  fixed_parameters = fixed_parameters,
  generate_data_function = data_generator,
  run_method_functions = list(lm = method, silly = competitor)
)

saveRDS(simulatr_specifier_object, "~/research_code/simulatr-project/ex_sim_obj.rds")
