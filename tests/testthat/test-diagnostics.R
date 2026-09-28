test_that("diagnostics returns status information", {
  dat <- .make_synthetic_twophase_data(n = 400L, seed = 101L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca", "ipw"),
    seed = 1001L
  )

  d <- diagnostics(fit, type = "status")

  expect_equal(d$method, c("Naive", "CCA", "IPW"))
  expect_true(all(c(
    "outcome", "method", "status", "message", "N_phase1", "N_phase2",
    "phase2_fraction", "analysis_seed"
  ) %in% names(d)))
})

test_that("weight diagnostics are returned only for weighting methods", {
  dat <- .make_synthetic_twophase_data(n = 500L, seed = 102L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "ipw", "aipw"),
    seed = 1002L
  )

  d <- diagnostics(fit, type = "weights")

  expect_equal(d$method, c("IPW", "AIPW"))
  expect_true(all(c(
    "weight_min", "weight_p99", "weight_max", "weight_cv",
    "weight_ess", "weight_ess_fraction"
  ) %in% names(d)))
  expect_true(all(is.finite(d$weight_ess_fraction)))
})

test_that("MI diagnostics report settings and FCS logged events", {
  dat <- .make_synthetic_twophase_data(n = 350L, seed = 103L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("fcs_mi"),
    n_imputations = 3L,
    mice_maxit = 2L,
    seed = 1003L
  )

  d <- diagnostics(fit, type = "mi")

  expect_equal(d$method, "FCS-MI")
  expect_equal(d$n_imputations, 3L)
  expect_equal(d$mice_maxit, 2L)
  expect_true("mi_logged_events" %in% names(d))
  expect_true(is.integer(d$mi_logged_events) || is.numeric(d$mi_logged_events))
})

test_that("diagnostics can filter by outcome and method", {
  dat <- .make_synthetic_twophase_data(n = 350L, seed = 104L)
  dat$y2 <- dat$y + rnorm(nrow(dat), sd = 0.2)

  fit <- twophase_sensitivity(
    dat,
    outcome = c("y", "y2"),
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca"),
    seed = c(y = 1101L, y2 = 1102L)
  )

  d <- diagnostics(fit, outcome = "y2", method = "cca")

  expect_equal(nrow(d), 1L)
  expect_equal(d$outcome, "y2")
  expect_equal(d$method, "CCA")
})

test_that("diagnostics rejects unavailable filters", {
  dat <- .make_synthetic_twophase_data(n = 300L, seed = 105L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  expect_error(
    diagnostics(fit, outcome = "missing_outcome"),
    "Unknown outcome"
  )

  expect_error(
    diagnostics(fit, method = "ipw"),
    "were not run"
  )
})
