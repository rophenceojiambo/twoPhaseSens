.vech_pairs <- function(k) {
  out <- vector("list", k * (k + 1) / 2)
  z <- 1L
  for (b in seq_len(k)) {
    for (a in b:k) {
      out[[z]] <- c(a, b)
      z <- z + 1L
    }
  }
  out
}

.fit_aipw <- function(
  dat,
  phase1_names,
  marker_names,
  selection_include_y = TRUE,
  marker_include_y = TRUE,
  method_label = "AIPW",
  prob_floor = 1e-8,
  matrix_tolerance = 1e-10,
  conf_level = 0.95
) {
  S <- dat$.phase2
  N <- nrow(dat)
  obs <- which(S == 1L)

  if (length(obs) <= length(marker_names) + 10L) {
    stop("Too few Phase-2 observations for AIPW.")
  }

  Zs <- .selection_matrix(dat, phase1_names, include_y = selection_include_y)
  sel_fit <- stats::glm.fit(x = Zs, y = S, family = stats::binomial())
  alpha <- sel_fit$coefficients
  if (any(!is.finite(alpha))) stop("Non-finite coefficient in AIPW selection model.")

  pi_hat <- as.vector(stats::plogis(Zs %*% alpha))
  if (any(pi_hat < prob_floor | pi_hat > 1 - prob_floor)) {
    stop("Estimated Phase-2 probabilities too close to 0/1 for stable AIPW.")
  }
  h <- S / pi_hat

  Zm <- .marker_predictor_matrix(dat, phase1_names, include_y = marker_include_y)
  M_obs <- as.matrix(dat[obs, marker_names, drop = FALSE])
  Zm_obs <- Zm[obs, , drop = FALSE]

  Bhat <- qr.solve(Zm_obs, M_obs)
  mu <- Zm %*% Bhat
  colnames(mu) <- marker_names
  E_obs <- M_obs - Zm_obs %*% Bhat
  Sigma_hat <- crossprod(E_obs) / length(obs)

  if (min(eigen(Sigma_hat, symmetric = TRUE, only.values = TRUE)$values) <= matrix_tolerance) {
    stop("Estimated AIPW marker covariance is singular/near-singular.")
  }

  W <- .target_w_matrix(dat, phase1_names)
  r <- ncol(W)
  k <- length(marker_names)
  d <- r + k
  Cbar <- cbind(W, mu)
  Cobs <- Cbar
  Cobs[obs, (r + 1):d] <- M_obs

  Vsig <- matrix(0, nrow = d, ncol = d)
  Vsig[(r + 1):d, (r + 1):d] <- Sigma_hat
  sqrt_h <- sqrt(h)

  A_sum <- crossprod(Cbar) +
    N * Vsig +
    crossprod(Cobs * sqrt_h) -
    crossprod(Cbar * sqrt_h) -
    sum(h) * Vsig

  b_sum <- colSums(Cbar * dat$.Y) +
    colSums((Cobs - Cbar) * (h * dat$.Y))

  beta <- as.vector(solve(A_sum, b_sum))
  names(beta) <- colnames(Cbar)

  beta_w <- beta[seq_len(r)]
  beta_m <- beta[(r + 1):d]
  resid_bar <- dat$.Y - as.vector(W %*% beta_w) - as.vector(mu %*% beta_m)
  m_top <- W * resid_bar
  sigma_beta_m <- as.vector(Sigma_hat %*% beta_m)
  m_bottom <- sweep(mu * resid_bar, 2, sigma_beta_m, FUN = "-")
  m_psi <- cbind(m_top, m_bottom)

  resid_complete <- dat$.Y - as.vector(Cobs %*% beta)
  u_psi <- Cobs * resid_complete
  psi_beta <- m_psi + (u_psi - m_psi) * h
  psi_alpha <- Zs * (S - pi_hat)

  qm <- ncol(Zm)
  E_all <- matrix(0, nrow = N, ncol = k)
  E_all[obs, ] <- E_obs
  psi_B_blocks <- lapply(seq_len(k), function(j) Zm * (S * E_all[, j]))
  psi_B <- do.call(cbind, psi_B_blocks)

  pairs <- .vech_pairs(k)
  hs <- length(pairs)
  psi_Sigma <- matrix(0, nrow = N, ncol = hs)
  for (j in seq_along(pairs)) {
    a <- pairs[[j]][1]
    b <- pairs[[j]][2]
    psi_Sigma[, j] <- S * (E_all[, a] * E_all[, b] - Sigma_hat[a, b])
  }

  qs <- ncol(Zs)
  pB <- qm * k
  J_aa <- -crossprod(Zs, Zs * (pi_hat * (1 - pi_hat)))
  J_BB <- -kronecker(diag(k), crossprod(Zm_obs))
  J_SS <- -length(obs) * diag(hs)

  dh_dalpha <- Zs * (-S * (1 - pi_hat) / pi_hat)
  J_beta_alpha <- crossprod(u_psi - m_psi, dh_dalpha)

  J_beta_B <- matrix(0, nrow = d, ncol = pB)
  one_minus_h <- 1 - h
  for (j in seq_len(k)) {
    Dcol <- matrix(0, nrow = N, ncol = d)
    Dcol[, seq_len(r)] <- -W * beta_m[j]
    bottom <- -mu * beta_m[j]
    bottom[, j] <- bottom[, j] + resid_bar
    Dcol[, (r + 1):d] <- bottom
    cols_j <- ((j - 1) * qm + 1):(j * qm)
    J_beta_B[, cols_j] <- crossprod(Dcol * one_minus_h, Zm)
  }

  Dsig <- matrix(0, nrow = d, ncol = hs)
  for (j in seq_along(pairs)) {
    a <- pairs[[j]][1]
    b <- pairs[[j]][2]
    deriv_bottom <- rep(0, k)
    if (a == b) {
      deriv_bottom[a] <- -beta_m[a]
    } else {
      deriv_bottom[a] <- -beta_m[b]
      deriv_bottom[b] <- -beta_m[a]
    }
    Dsig[(r + 1):d, j] <- deriv_bottom
  }

  J_beta_Sigma <- sum(one_minus_h) * Dsig
  J_beta_beta <- -A_sum

  total_p <- qs + pB + hs + d
  J <- matrix(0, nrow = total_p, ncol = total_p)
  i_alpha <- seq_len(qs)
  i_B <- qs + seq_len(pB)
  i_Sigma <- qs + pB + seq_len(hs)
  i_beta <- qs + pB + hs + seq_len(d)

  J[i_alpha, i_alpha] <- J_aa
  J[i_B, i_B] <- J_BB
  J[i_Sigma, i_Sigma] <- J_SS
  J[i_beta, i_alpha] <- J_beta_alpha
  J[i_beta, i_B] <- J_beta_B
  J[i_beta, i_Sigma] <- J_beta_Sigma
  J[i_beta, i_beta] <- J_beta_beta

  Psi <- cbind(psi_alpha, psi_B, psi_Sigma, psi_beta)
  meat <- crossprod(Psi)
  J_inv <- solve(J)
  V_stack <- J_inv %*% meat %*% t(J_inv)
  V_beta <- V_stack[i_beta, i_beta, drop = FALSE]

  A_index <- match(".A", names(beta))
  if (is.na(A_index)) stop("Primary exposure coefficient not found in AIPW target design.")

  est <- beta[A_index]
  se <- sqrt(V_beta[A_index, A_index])
  p <- 2 * stats::pnorm(-abs(est / se))
  crit <- stats::qnorm(1 - (1 - conf_level) / 2)
  w_obs <- 1 / pi_hat[obs]

  data.frame(
    method = method_label, estimate = est, se = se, df = Inf, p_value = p,
    conf_low = est - crit * se, conf_high = est + crit * se,
    status = "ok", message = NA_character_,
    weight_min = min(w_obs),
    weight_p99 = unname(stats::quantile(w_obs, 0.99)),
    weight_max = max(w_obs),
    weight_cv = stats::sd(w_obs) / mean(w_obs),
    weight_ess = sum(w_obs)^2 / sum(w_obs^2),
    stringsAsFactors = FALSE
  )
}
