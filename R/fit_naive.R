.fit_naive <- function(dat, phase1_names, conf_level = 0.95) {
  fit <- stats::lm(.naive_formula(phase1_names), data = dat)
  .extract_lm_A(fit, "Naive", conf_level = conf_level)
}
