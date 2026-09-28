.extract_lm_A <- function(fit, method_name, conf_level = 0.95) {
  sm <- summary(fit)$coefficients
  if (!(".A" %in% rownames(sm))) stop("Primary exposure coefficient not found in fitted model.")
  est <- sm[".A", "Estimate"]; se <- sm[".A", "Std. Error"]; df <- stats::df.residual(fit)
  stat <- est / se; p <- 2 * stats::pt(-abs(stat), df = df)
  crit <- stats::qt(1 - (1 - conf_level) / 2, df = df)
  data.frame(method=method_name, estimate=est, se=se, df=df, p_value=p,
    conf_low=est-crit*se, conf_high=est+crit*se, status="ok",
    message=NA_character_, stringsAsFactors=FALSE)
}

.pool_A_from_lm_list <- function(fits, N_complete, conf_level = 0.95) {
  q <- vapply(fits, function(f) stats::coef(f)[".A"], numeric(1))
  u <- vapply(fits, function(f) stats::vcov(f)[".A", ".A"], numeric(1))
  k <- length(stats::coef(fits[[1]]))
  pooled <- mice::pool.scalar(Q=q, U=u, n=N_complete, k=k, rule="rubin1987")
  est <- pooled$qbar; se <- sqrt(pooled$t); df <- pooled$df
  stat <- est / se; p <- 2 * stats::pt(-abs(stat), df=df)
  crit <- stats::qt(1 - (1 - conf_level)/2, df=df)
  c(estimate=est, se=se, df=df, p_value=p,
    conf_low=est-crit*se, conf_high=est+crit*se)
}
