test_that("forest plot returns a ggplot for one outcome", {
  dat <- .make_synthetic_twophase_data(n = 400L, seed = 201L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca", "ipw"),
    seed = 1201L
  )

  p <- plot_sensitivity(fit)

  expect_s3_class(p, "ggplot")
  expect_equal(levels(p$data$method_display), rev(c("Naive", "CCA", "IPW")))
})

test_that("forest plot supports multiple outcomes and custom labels", {
  dat <- .make_synthetic_twophase_data(n = 400L, seed = 202L)
  dat$y2 <- dat$y + rnorm(nrow(dat), sd = 0.2)

  fit <- twophase_sensitivity(
    dat,
    outcome = c("y", "y2"),
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca"),
    seed = c(y = 1301L, y2 = 1302L)
  )

  p <- plot_sensitivity(
    fit,
    outcome_labels = c(y = "Outcome Y", y2 = "Outcome Y2"),
    method_labels = c(Naive = "Naive model", CCA = "Complete case"),
    facet_scales = "fixed"
  )

  expect_s3_class(p, "ggplot")
  expect_equal(levels(p$data$outcome_display), c("Outcome Y", "Outcome Y2"))
  expect_equal(levels(p$data$method_display), rev(c("Naive model", "Complete case")))
})

test_that("plot method delegates to plot_sensitivity", {
  dat <- .make_synthetic_twophase_data(n = 350L, seed = 203L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  p <- plot(fit, reference_line = NULL)

  expect_s3_class(p, "ggplot")
})

test_that("forest plot validates requested filters", {
  dat <- .make_synthetic_twophase_data(n = 300L, seed = 204L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  expect_error(plot_sensitivity(fit, outcome = "missing"), "Unknown outcome")
  expect_error(plot_sensitivity(fit, method = "ipw"), "were not run")
})
