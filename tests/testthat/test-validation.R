test_that("partial Phase-2 blocks are rejected", {
  dat <- .make_synthetic_twophase_data()
  i <- which(dat$phase2 == 0)[1]
  dat$m1[i] <- 0

  expect_error(
    twophase_sensitivity(
      dat,
      outcome = "y",
      exposure = "a",
      covariates = c("age", "sex"),
      phase2_covariates = c("m1", "m2"),
      phase2 = "phase2",
      methods = c("naive", "cca")
    ),
    "complete block"
  )
})

test_that("missing Phase-1 covariates are rejected", {
  dat <- .make_synthetic_twophase_data()
  dat$age[1] <- NA_real_

  expect_error(
    twophase_sensitivity(
      dat,
      outcome = "y",
      exposure = "a",
      covariates = c("age", "sex"),
      phase2_covariates = c("m1", "m2"),
      phase2 = "phase2",
      methods = c("naive", "cca")
    ),
    "contains missing"
  )
})


test_that("scalar seeds expand sequentially across outcomes", {
  dat <- .make_synthetic_twophase_data(n = 350L, seed = 77L)
  dat$y2 <- dat$y + rnorm(nrow(dat), sd = 0.2)

  ans <- twophase_sensitivity(
    dat,
    outcome = c("y", "y2"),
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca"),
    seed = 100L
  )

  expect_equal(unique(ans$results$analysis_seed[ans$results$outcome == "y"]), 100L)
  expect_equal(unique(ans$results$analysis_seed[ans$results$outcome == "y2"]), 101L)
  expect_equal(ans$settings$seed, c(100L, 101L))
})

test_that("outcome-specific seeds can be supplied explicitly", {
  dat <- .make_synthetic_twophase_data(n = 350L, seed = 88L)
  dat$y2 <- dat$y + rnorm(nrow(dat), sd = 0.2)

  ans <- twophase_sensitivity(
    dat,
    outcome = c("y", "y2"),
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca"),
    seed = c(y2 = 250L, y = 150L)
  )

  expect_equal(unique(ans$results$analysis_seed[ans$results$outcome == "y"]), 150L)
  expect_equal(unique(ans$results$analysis_seed[ans$results$outcome == "y2"]), 250L)
  expect_equal(ans$settings$seed, c(150L, 250L))
})

test_that("invalid seed specifications are rejected", {
  dat <- .make_synthetic_twophase_data(n = 350L, seed = 99L)
  dat$y2 <- dat$y + rnorm(nrow(dat), sd = 0.2)

  expect_error(
    twophase_sensitivity(
      dat,
      outcome = c("y", "y2"),
      exposure = "a",
      covariates = c("age", "sex"),
      phase2_covariates = c("m1", "m2"),
      phase2 = "phase2",
      methods = c("naive", "cca"),
      seed = c(1L, 2L, 3L)
    ),
    "exactly one value per outcome"
  )

  expect_error(
    twophase_sensitivity(
      dat,
      outcome = c("y", "y2"),
      exposure = "a",
      covariates = c("age", "sex"),
      phase2_covariates = c("m1", "m2"),
      phase2 = "phase2",
      methods = c("naive", "cca"),
      seed = c(foo = 1L, bar = 2L)
    ),
    "each outcome name exactly once"
  )
})

test_that("duplicate method requests are rejected", {
  dat <- .make_synthetic_twophase_data()

  expect_error(
    twophase_sensitivity(
      dat,
      outcome = "y",
      exposure = "a",
      covariates = c("age", "sex"),
      phase2_covariates = c("m1", "m2"),
      phase2 = "phase2",
      methods = c("cca", "CCA")
    ),
    "must not contain duplicate methods"
  )
})
