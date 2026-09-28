.fit_fcs_mi <- function(dat, phase1_names, marker_names, nimp=20L, maxit=10L,
                        method="norm", conf_level=0.95) {
  cols <- c(".A", ".Y", phase1_names, marker_names)
  imp_data <- dat[, cols, drop=FALSE]
  ini <- mice::mice(imp_data, maxit=0, printFlag=FALSE)
  meth <- ini$method; pred <- ini$predictorMatrix
  meth[] <- ""; meth[marker_names] <- method; pred[,] <- 0
  for (mvar in marker_names) pred[mvar, setdiff(cols, mvar)] <- 1
  imp <- mice::mice(imp_data, m=as.integer(nimp), maxit=as.integer(maxit),
                    method=meth, predictorMatrix=pred, printFlag=FALSE)
  fits <- lapply(seq_len(nimp), function(j) {
    completed <- mice::complete(imp, action=j)
    stats::lm(.full_formula(phase1_names, marker_names), data=completed)
  })
  pooled <- .pool_A_from_lm_list(fits, nrow(dat), conf_level)
  logged_events <- if (is.null(imp$loggedEvents)) 0L else nrow(imp$loggedEvents)

  data.frame(
    method="FCS-MI",
    estimate=pooled["estimate"],
    se=pooled["se"],
    df=pooled["df"],
    p_value=pooled["p_value"],
    conf_low=pooled["conf_low"],
    conf_high=pooled["conf_high"],
    status="ok",
    message=if (logged_events > 0L) paste("mice logged events:", logged_events) else NA_character_,
    mi_logged_events=as.integer(logged_events),
    stringsAsFactors=FALSE
  )
}
