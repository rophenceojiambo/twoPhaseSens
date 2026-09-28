.fit_ipw <- function(dat, phase1_names, marker_names, prob_floor=1e-8, conf_level=0.95) {
  S <- dat$.phase2; N <- nrow(dat)
  Z <- .selection_matrix(dat, phase1_names, include_y=TRUE)
  sel_fit <- stats::glm.fit(x=Z, y=S, family=stats::binomial())
  alpha <- sel_fit$coefficients
  if (any(!is.finite(alpha))) stop("Non-finite coefficient in IPW selection model.")
  pi_hat <- as.vector(stats::plogis(Z %*% alpha))
  if (any(pi_hat < prob_floor | pi_hat > 1-prob_floor))
    stop("Estimated Phase-2 probabilities too close to 0/1 for stable IPW.")
  obs <- which(S==1L)
  C_obs <- stats::model.matrix(.full_formula(phase1_names, marker_names), data=dat[obs,,drop=FALSE])
  Y_obs <- dat$.Y[obs]; pi_obs <- pi_hat[obs]; w <- 1/pi_obs
  beta <- as.vector(solve(crossprod(C_obs, C_obs*w), crossprod(C_obs, Y_obs*w)))
  names(beta) <- colnames(C_obs)
  q <- ncol(Z); d <- ncol(C_obs)
  psi_alpha <- Z * (S-pi_hat)
  psi_beta <- matrix(0, nrow=N, ncol=d); colnames(psi_beta) <- colnames(C_obs)
  resid_obs <- Y_obs - as.vector(C_obs %*% beta); G_obs <- C_obs * resid_obs
  psi_beta[obs,] <- G_obs/pi_obs
  J_aa <- -crossprod(Z, Z*(pi_hat*(1-pi_hat)))
  J_bb <- -crossprod(C_obs, C_obs*(1/pi_obs))
  J_ba <- -crossprod(G_obs, Z[obs,,drop=FALSE]*((1-pi_obs)/pi_obs))
  J <- rbind(cbind(J_aa, matrix(0,q,d)), cbind(J_ba,J_bb))
  Psi <- cbind(psi_alpha, psi_beta); meat <- crossprod(Psi)
  J_inv <- solve(J); V_stack <- J_inv %*% meat %*% t(J_inv)
  V_beta <- V_stack[q+seq_len(d), q+seq_len(d), drop=FALSE]
  A_index <- match(".A", names(beta)); if (is.na(A_index)) stop("Primary exposure coefficient not found in IPW outcome design.")
  est <- beta[A_index]; se <- sqrt(V_beta[A_index,A_index])
  p <- 2*stats::pnorm(-abs(est/se)); crit <- stats::qnorm(1-(1-conf_level)/2)
  data.frame(method="IPW", estimate=est, se=se, df=Inf, p_value=p,
    conf_low=est-crit*se, conf_high=est+crit*se, status="ok", message=NA_character_,
    weight_min=min(w), weight_p99=unname(stats::quantile(w,0.99)), weight_max=max(w),
    weight_cv=stats::sd(w)/mean(w), weight_ess=sum(w)^2/sum(w^2),
    stringsAsFactors=FALSE)
}
