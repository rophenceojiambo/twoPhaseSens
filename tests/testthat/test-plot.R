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


test_that("publication forest plot keeps solid confidence intervals and one-row legend", {
  dat <- .make_synthetic_twophase_data(n = 400L, seed = 208L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca", "fcs_mi", "jm_mi", "ipw", "aipw"),
    n_imputations = 2L,
    mice_maxit = 2L,
    jomo_nburn = 20L,
    jomo_nbetween = 20L,
    seed = 1208L
  )

  p <- plot_sensitivity(fit)

  expect_s3_class(p, "ggplot")
  expect_null(p$scales$get_scales("linetype"))
  expect_equal(
    unname(p$scales$get_scales("shape")$palette(6L)),
    unname(.twophasesens_method_shapes)
  )
  expect_equal(p$guides$guides$colour$params$nrow, 1L)
})


test_that("annotated publication plot reserves separate numeric columns", {
  dat <- .make_synthetic_twophase_data(n = 350L, seed = 209L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca", "ipw"),
    seed = 1209L
  )

  p <- plot_sensitivity(fit)
  text_layers <- Filter(
    function(z) inherits(z$geom, "GeomText"),
    p$layers
  )

  expect_true(length(text_layers) >= 4L)
  expect_true(all(vapply(
    text_layers,
    function(z) is.null(z$aes_params$family),
    logical(1)
  )))
})


test_that("forest plot supports manuscript estimate labels and single-outcome strip", {
  dat <- .make_synthetic_twophase_data(n = 320L, seed = 210L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca", "ipw"),
    seed = 1210L
  )

  p <- plot_sensitivity(
    fit,
    outcome_labels = c(y = "Primary outcome"),
    estimate_label = "Adjusted beta"
  )

  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Adjusted beta (95% CI)")
  expect_true(inherits(p$facet, "FacetWrap"))
})

test_that("forest plot validates estimate_label", {
  dat <- .make_synthetic_twophase_data(n = 300L, seed = 211L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  expect_error(plot_sensitivity(fit, estimate_label = ""), "non-empty character")
})
