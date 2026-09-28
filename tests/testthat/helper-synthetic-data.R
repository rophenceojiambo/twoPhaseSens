.make_synthetic_twophase_data <- function(n = 300L, seed = 11L) {
  set.seed(seed)
  age <- rnorm(n)
  sex <- factor(sample(c("Female", "Male"), n, replace = TRUE))
  a <- rnorm(n)
  m1_full <- 0.4 * a + 0.2 * age + rnorm(n)
  m2_full <- -0.2 * a + 0.3 * age + rnorm(n)
  y <- 0.25 * a + 0.30 * age + 0.15 * (sex == "Male") +
    0.20 * m1_full - 0.10 * m2_full + rnorm(n)
  p2 <- plogis(0.4 + 0.15 * a + 0.1 * y + 0.1 * age)
  s <- rbinom(n, 1, p2)

  m1 <- m1_full
  m2 <- m2_full
  m1[s == 0] <- NA_real_
  m2[s == 0] <- NA_real_

  data.frame(y = y, a = a, age = age, sex = sex, m1 = m1, m2 = m2, phase2 = s)
}
