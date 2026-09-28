test_that("Naive and CCA reproduce direct lm fits", {
  dat <- .make_synthetic_twophase_data(n = 500L, seed = 25L)

  ans <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  naive_ref <- coef(lm(y ~ a + age + sex, data = dat))["a"]
  cca_ref <- coef(lm(y ~ a + age + sex + m1 + m2, data = dat[dat$phase2 == 1, ]))["a"]

  expect_equal(ans$results$estimate[ans$results$method == "Naive"], unname(naive_ref), tolerance = 1e-10)
  expect_equal(ans$results$estimate[ans$results$method == "CCA"], unname(cca_ref), tolerance = 1e-10)
})

test_that("main result object has expected class and metadata", {
  dat <- .make_synthetic_twophase_data()
  ans <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("naive", "cca")
  )

  expect_s3_class(ans, "twophase_sensitivity")
  expect_equal(ans$specification$exposure, "a")
  expect_equal(ans$results$N_phase1[1], nrow(dat))
  expect_equal(ans$results$N_phase2[1], sum(dat$phase2 == 1))
})
