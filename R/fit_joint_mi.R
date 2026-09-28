.fit_joint_mi <- function(dat, phase1_names, marker_names, nimp=20L,
                          nburn=1000L, nbetween=1000L, conf_level=0.95) {
  Yimp <- as.data.frame(dat[, marker_names, drop=FALSE])
  Ximp <- .marker_predictor_matrix(dat, phase1_names, include_y=TRUE)
  imp_long <- jomo::jomo(Y=Yimp, X=Ximp, nburn=as.integer(nburn),
                         nbetween=as.integer(nbetween), nimp=as.integer(nimp), output=0)
  if (!("Imputation" %in% names(imp_long))) stop("jomo output does not contain the Imputation index.")
  fits <- vector("list", nimp)
  for (j in seq_len(nimp)) {
    mj <- imp_long[imp_long$Imputation == j, marker_names, drop=FALSE]
    if (nrow(mj) != nrow(dat)) stop("Unexpected jomo output size for imputation ", j, ".")
    completed <- dat[, c(".A", ".Y", phase1_names), drop=FALSE]
    completed[marker_names] <- mj
    fits[[j]] <- stats::lm(.full_formula(phase1_names, marker_names), data=completed)
  }
  pooled <- .pool_A_from_lm_list(fits, nrow(dat), conf_level)
  data.frame(method="JM-MI", estimate=pooled["estimate"], se=pooled["se"],
    df=pooled["df"], p_value=pooled["p_value"], conf_low=pooled["conf_low"],
    conf_high=pooled["conf_high"], status="ok", message=NA_character_,
    stringsAsFactors=FALSE)
}
