test_that("example data have the required two-phase structure", {
  dat <- twophase_example_data(n = 200L, seed = 123L)

  expect_s3_class(dat, "data.frame")
  expect_equal(nrow(dat), 200L)
  expect_true(all(c(
    "outcome1", "outcome2", "exposure", "age", "sex",
    "marker1", "marker2", "marker3", "phase2"
  ) %in% names(dat)))

  expect_true(all(dat$phase2 %in% c(0L, 1L)))
  expect_true(any(dat$phase2 == 0L))
  expect_true(any(dat$phase2 == 1L))

  marker_complete <- rowSums(!is.na(dat[c("marker1", "marker2", "marker3")]))
  expect_true(all(marker_complete %in% c(0L, 3L)))
  expect_true(all(marker_complete[dat$phase2 == 1L] == 3L))
  expect_true(all(marker_complete[dat$phase2 == 0L] == 0L))
})

test_that("example data generation is reproducible and preserves RNG state", {
  set.seed(999L)
  before <- .Random.seed

  dat1 <- twophase_example_data(n = 150L, seed = 321L)
  after <- .Random.seed
  dat2 <- twophase_example_data(n = 150L, seed = 321L)

  expect_equal(before, after)
  expect_equal(dat1, dat2)
})

test_that("invalid example-data sizes are rejected", {
  expect_error(twophase_example_data(n = 20L), "greater than or equal to 80")
  expect_error(twophase_example_data(n = 100.5), "greater than or equal to 80")
})
