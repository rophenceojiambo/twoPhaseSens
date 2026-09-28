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


test_that("publication forest plot uses manuscript method aesthetics", {
  dat <- .make_synthetic_twophase_data(n = 400L, seed = 205L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca", "ipw"),
    seed = 1205L
  )

  p <- plot_sensitivity(fit)

  expect_s3_class(p, "ggplot")
  expect_equal(
    unname(p$scales$get_scales("colour")$palette(3L)),
    unname(.twophasesens_method_colors[c("Naive", "CCA", "IPW")])
  )
  expect_equal(
    unname(p$scales$get_scales("shape")$palette(3L)),
    unname(.twophasesens_method_shapes[c("Naive", "CCA", "IPW")])
  )
  expect_true(any(vapply(p$layers, function(z) inherits(z$geom, "GeomText"), logical(1))))
})

test_that("publication forest plot annotations can be disabled", {
  dat <- .make_synthetic_twophase_data(n = 350L, seed = 206L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  p <- plot_sensitivity(fit, annotate = FALSE)

  expect_s3_class(p, "ggplot")
  expect_false(any(vapply(p$layers, function(z) inherits(z$geom, "GeomText"), logical(1))))
})

test_that("publication forest plot validates annotation formatting arguments", {
  dat <- .make_synthetic_twophase_data(n = 300L, seed = 207L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  expect_error(plot_sensitivity(fit, annotate = NA), "must be TRUE or FALSE")
  expect_error(plot_sensitivity(fit, estimate_digits = -1), "non-negative integer")
  expect_error(plot_sensitivity(fit, p_digits = 1.5), "non-negative integer")
})
