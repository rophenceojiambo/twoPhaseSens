test_that("provisional sensitivity table keeps methods in requested order", {
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

  tab <- tbl_sensitivity(ans)
  expect_equal(tab$Method, c("Naive", "CCA"))
  expect_true("y Coefficient (95% CI)" %in% names(tab))
  expect_true("y P value" %in% names(tab))
})
