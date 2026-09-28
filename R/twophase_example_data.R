#' Generate a synthetic two-phase example dataset
#'
#' Creates a small reproducible dataset for examples, teaching, and package
#' documentation. Phase-1 variables are fully observed, while the continuous
#' Phase-2 covariates are observed as a complete block only when `phase2 = 1`.
#'
#' The generated data are synthetic and are not derived from MIDUS or any other
#' participant-level study data.
#'
#' @param n Number of observations.
#' @param seed Non-negative integer seed used only while generating the example
#'   data. The caller's pre-existing global random-number state is restored.
#'
#' @return A data frame containing two continuous outcomes, one continuous
#'   exposure, two Phase-1 covariates, three continuous Phase-2 covariates, and
#'   a binary Phase-2 indicator.
#'
#' @examples
#' dat <- twophase_example_data(n = 200, seed = 2026)
#' head(dat)
#' table(dat$phase2)
#'
#' @export
twophase_example_data <- function(n = 300L, seed = 2026L) {
  if (
    length(n) != 1L ||
      !is.numeric(n) ||
      is.na(n) ||
      !is.finite(n) ||
      n < 80 ||
      n != floor(n)
  ) {
    stop("`n` must be one integer greater than or equal to 80.", call. = FALSE)
  }

  .with_preserved_seed(seed, {
    n <- as.integer(n)

    age <- stats::rnorm(n)
    sex <- factor(
      sample(c("Female", "Male"), size = n, replace = TRUE),
      levels = c("Female", "Male")
    )
    exposure <- stats::rnorm(n)

    marker1_full <- 0.45 * exposure + 0.25 * age +
      0.10 * (sex == "Male") + stats::rnorm(n, sd = 0.85)

    marker2_full <- -0.25 * exposure + 0.35 * age +
      0.15 * marker1_full + stats::rnorm(n, sd = 0.90)

    marker3_full <- 0.20 * exposure - 0.20 * age +
      0.20 * marker1_full + 0.10 * marker2_full +
      stats::rnorm(n, sd = 0.80)

    outcome1 <- 0.30 * exposure + 0.30 * age +
      0.15 * (sex == "Male") +
      0.20 * marker1_full - 0.10 * marker2_full +
      0.15 * marker3_full + stats::rnorm(n)

    outcome2 <- 0.20 * exposure + 0.15 * age -
      0.10 * (sex == "Male") +
      0.10 * marker1_full + 0.20 * marker2_full +
      0.10 * marker3_full + stats::rnorm(n, sd = 1.10)

    phase2_prob <- stats::plogis(
      0.70 + 0.20 * exposure + 0.15 * outcome1 + 0.10 * age
    )
    phase2 <- stats::rbinom(n, size = 1L, prob = phase2_prob)

    # Guarantee that both phases are represented in unusually small/random draws.
    if (all(phase2 == 1L)) phase2[which.min(phase2_prob)] <- 0L
    if (all(phase2 == 0L)) phase2[which.max(phase2_prob)] <- 1L

    marker1 <- marker1_full
    marker2 <- marker2_full
    marker3 <- marker3_full
    marker1[phase2 == 0L] <- NA_real_
    marker2[phase2 == 0L] <- NA_real_
    marker3[phase2 == 0L] <- NA_real_

    data.frame(
      outcome1 = outcome1,
      outcome2 = outcome2,
      exposure = exposure,
      age = age,
      sex = sex,
      marker1 = marker1,
      marker2 = marker2,
      marker3 = marker3,
      phase2 = phase2
    )
  })
}
