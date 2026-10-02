test_that("data-frame sensitivity table keeps methods in requested order", {
  dat <- .make_synthetic_twophase_data(n = 500L, seed = 33L)
  ans <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  tab <- tbl_sensitivity(ans, output = "data.frame")

  expect_equal(tab$Method, c("Naive", "CCA"))
  expect_true("y Coefficient (95% CI)" %in% names(tab))
  expect_true("y P value" %in% names(tab))
})

test_that("gtsummary sensitivity table is publication-ready", {
  dat <- .make_synthetic_twophase_data(n = 500L, seed = 44L)
  ans <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  tab <- tbl_sensitivity(
    ans,
    outcome_labels = c(y = "Outcome Y"),
    caption = "**Sensitivity analysis**"
  )

  expect_s3_class(tab, "gtsummary")
  expect_true("label" %in% names(tab$table_body))
  expect_equal(tab$table_body$label, c("Naive", "CCA"))
})

test_that("table labels and optional SE are handled correctly", {
  dat <- .make_synthetic_twophase_data(n = 500L, seed = 55L)
  ans <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  tab <- tbl_sensitivity(
    ans,
    output = "data.frame",
    include_se = TRUE,
    method_labels = c("Naive" = "Phase-1 naive", "CCA" = "Complete case"),
    outcome_labels = c(y = "Primary outcome")
  )

  expect_equal(tab$Method, c("Phase-1 naive", "Complete case"))
  expect_true("Primary outcome SE" %in% names(tab))
})

test_that("invalid table label specifications are rejected", {
  dat <- .make_synthetic_twophase_data(n = 500L, seed = 66L)
  ans <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  expect_error(
    tbl_sensitivity(ans, method_labels = c("Unknown" = "X")),
    "Unknown method"
  )

  expect_error(
    tbl_sensitivity(ans, outcome_labels = c(z = "Outcome Z")),
    "Unknown outcome"
  )
})


test_that("default sensitivity table displays estimates and confidence intervals to three decimals", {
  dat <- .make_synthetic_twophase_data(n = 500L, seed = 77L)
  ans <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  tab <- tbl_sensitivity(ans, output = "data.frame")
  vals <- tab[["y Coefficient (95% CI)"]]

  expect_true(all(grepl(
    "^-?[0-9]+\\.[0-9]{3} \\(-?[0-9]+\\.[0-9]{3} to -?[0-9]+\\.[0-9]{3}\\)$",
    vals
  )))
})
