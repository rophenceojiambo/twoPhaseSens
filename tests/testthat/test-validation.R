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
