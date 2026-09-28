.fit_cca <- function(dat, phase1_names, marker_names, conf_level = 0.95) {
  cc <- dat[dat$.phase2 == 1L, , drop = FALSE]

  if (nrow(cc) <= length(marker_names) + 10L) {
    stop("Too few Phase-2 observations for complete-case model.")
  }

  fit <- stats::lm(.full_formula(phase1_names, marker_names), data = cc)
  .extract_lm_A(fit, "CCA", conf_level = conf_level)
}
