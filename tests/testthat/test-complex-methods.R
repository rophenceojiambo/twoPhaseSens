test_that("FCS-MI is reproducible with a fixed analysis seed", {
  dat <- .make_synthetic_twophase_data(n = 240L, seed = 301L)

  fit1 <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = "fcs_mi",
    n_imputations = 3L,
    mice_maxit = 3L,
    seed = 7301L
  )

  fit2 <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = "fcs_mi",
    n_imputations = 3L,
    mice_maxit = 3L,
    seed = 7301L
  )

  r1 <- fit1$results[1, c("estimate", "se", "df", "p_value", "conf_low", "conf_high")]
  r2 <- fit2$results[1, c("estimate", "se", "df", "p_value", "conf_low", "conf_high")]

  expect_equal(fit1$results$status, "ok")
  expect_true(all(is.finite(unlist(r1))))
  expect_equal(r1, r2, tolerance = 1e-12)
})


test_that("JM-MI is reproducible with a fixed analysis seed", {
  dat <- .make_synthetic_twophase_data(n = 220L, seed = 302L)

  fit1 <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = "jm_mi",
    n_imputations = 2L,
    jomo_nburn = 30L,
    jomo_nbetween = 30L,
    seed = 7302L
  )

  fit2 <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = "jm_mi",
    n_imputations = 2L,
    jomo_nburn = 30L,
    jomo_nbetween = 30L,
    seed = 7302L
  )

  r1 <- fit1$results[1, c("estimate", "se", "df", "p_value", "conf_low", "conf_high")]
  r2 <- fit2$results[1, c("estimate", "se", "df", "p_value", "conf_low", "conf_high")]

  expect_equal(fit1$results$status, "ok")
  expect_true(all(is.finite(unlist(r1))))
  expect_equal(r1, r2, tolerance = 1e-10)
})


test_that("IPW point estimate agrees with an independent weighted lm fit", {
  dat <- .make_synthetic_twophase_data(n = 420L, seed = 303L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = "ipw"
  )

  selection_fit <- stats::glm(
    phase2 ~ a + y + age + sex,
    family = stats::binomial(),
    data = dat
  )
  pi_hat <- stats::predict(selection_fit, type = "response")
  observed <- dat$phase2 == 1L

  direct_fit <- stats::lm(
    y ~ a + age + sex + m1 + m2,
    data = dat[observed, , drop = FALSE],
    weights = 1 / pi_hat[observed]
  )

  expect_equal(fit$results$status, "ok")
  expect_equal(
    unname(fit$results$estimate),
    unname(stats::coef(direct_fit)[["a"]]),
    tolerance = 1e-10
  )
  expect_gt(fit$results$se, 0)
  expect_lt(fit$results$conf_low, fit$results$estimate)
  expect_gt(fit$results$conf_high, fit$results$estimate)
})


test_that("IPW and AIPW retain the same selection-weight diagnostics", {
  dat <- .make_synthetic_twophase_data(n = 420L, seed = 304L)

  fit <- twophase_sensitivity(
    dat,
    outcome = "y",
    exposure = "a",
    covariates = c("age", "sex"),
    phase2_covariates = c("m1", "m2"),
    phase2 = "phase2",
    methods = c("ipw", "aipw")
  )

  ipw <- fit$results[fit$results$method == "IPW", , drop = FALSE]
  aipw <- fit$results[fit$results$method == "AIPW", , drop = FALSE]
  weight_fields <- c(
    "weight_min",
    "weight_p99",
    "weight_max",
    "weight_cv",
    "weight_ess"
  )

  expect_equal(ipw$status, "ok")
  expect_equal(aipw$status, "ok")
  expect_true(is.finite(aipw$estimate))
  expect_gt(aipw$se, 0)
  expect_lt(aipw$conf_low, aipw$estimate)
  expect_gt(aipw$conf_high, aipw$estimate)
  expect_equal(
    unname(as.numeric(ipw[1, weight_fields])),
    unname(as.numeric(aipw[1, weight_fields])),
    tolerance = 1e-12
  )
})
