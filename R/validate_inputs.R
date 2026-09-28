.validate_character_names <- function(x, arg, allow_empty = FALSE) {
  if (!is.character(x) || anyNA(x)) stop("`", arg, "` must be a character vector with no missing values.", call.=FALSE)
  if (!allow_empty && length(x)==0L) stop("`", arg, "` must not be empty.", call.=FALSE)
  if (any(!nzchar(x))) stop("`", arg, "` contains an empty variable name.", call.=FALSE)
  if (anyDuplicated(x)) stop("`", arg, "` contains duplicate variable names.", call.=FALSE)
  invisible(TRUE)
}

.validate_twophase_inputs <- function(data, outcome, exposure, covariates, phase2_covariates, phase2) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call.=FALSE)
  if (nrow(data)<2L) stop("`data` must contain at least two rows.", call.=FALSE)

  .validate_character_names(outcome,"outcome")
  .validate_character_names(exposure,"exposure")
  .validate_character_names(covariates,"covariates",allow_empty=TRUE)
  .validate_character_names(phase2_covariates,"phase2_covariates")
  .validate_character_names(phase2,"phase2")

  if (length(exposure)!=1L) stop("Version 0.1.0 supports exactly one primary exposure.", call.=FALSE)
  if (length(phase2)!=1L) stop("`phase2` must identify exactly one binary indicator variable.", call.=FALSE)

  roles <- c(outcome, exposure, covariates, phase2_covariates, phase2)
  if (anyDuplicated(roles)) stop("A variable cannot be assigned to more than one analysis role.", call.=FALSE)
  missing_names <- setdiff(roles,names(data))
  if (length(missing_names)>0L) stop("Missing variable(s): ",paste(missing_names,collapse=", "),call.=FALSE)

  if (!is.numeric(data[[exposure]])) stop("Version 0.1.0 requires a numeric primary exposure.",call.=FALSE)
  if (anyNA(data[[exposure]]) || any(!is.finite(data[[exposure]]))) stop("The primary exposure must be complete and finite.",call.=FALSE)

  for (yy in outcome) {
    if (!is.numeric(data[[yy]])) stop("Outcome `",yy,"` must be numeric.",call.=FALSE)
    if (anyNA(data[[yy]]) || any(!is.finite(data[[yy]]))) stop("Outcome `",yy,"` must be complete and finite.",call.=FALSE)
  }

  for (xx in covariates) {
    if (anyNA(data[[xx]])) stop("Phase-1 covariate `",xx,"` contains missing values.",call.=FALSE)
    if (is.numeric(data[[xx]]) && any(!is.finite(data[[xx]]))) stop("Numeric Phase-1 covariate `",xx,"` contains non-finite values.",call.=FALSE)
  }

  for (mm in phase2_covariates) {
    if (!is.numeric(data[[mm]])) stop("Phase-2 covariate `",mm,"` must be numeric in version 0.1.0.",call.=FALSE)
    obs <- !is.na(data[[mm]])
    if (any(!is.finite(data[[mm]][obs]))) stop("Phase-2 covariate `",mm,"` contains non-finite observed values.",call.=FALSE)
  }

  s_raw <- data[[phase2]]
  if (is.logical(s_raw)) s <- as.integer(s_raw)
  else if (is.numeric(s_raw) || is.integer(s_raw)) {
    if (anyNA(s_raw) || !all(s_raw %in% c(0,1))) stop("`phase2` must be complete and coded 0/1 (or logical).",call.=FALSE)
    s <- as.integer(s_raw)
  } else stop("`phase2` must be numeric/integer 0/1 or logical.",call.=FALSE)

  marker_obs <- !is.na(data[,phase2_covariates,drop=FALSE])
  n_obs <- rowSums(marker_obs); k <- length(phase2_covariates)
  if (any(!(n_obs %in% c(0L,k)))) stop("Version 0.1.0 requires the Phase-2 covariates to be observed/missing as a complete block; partially observed rows were found.",call.=FALSE)
  if (any(s==1L & n_obs!=k) || any(s==0L & n_obs!=0L)) stop("The Phase-2 indicator does not agree with observation of the Phase-2 covariate block.",call.=FALSE)
  if (sum(s==1L)==0L || sum(s==0L)==0L) stop("Both Phase-1-only and Phase-2 observations are required.",call.=FALSE)
  invisible(list(phase2=s))
}

.prepare_internal_data <- function(data, outcome, exposure, covariates, phase2_covariates, phase2) {
  out <- data.frame(.Y=data[[outcome]], .A=data[[exposure]], .phase2=as.integer(data[[phase2]]), check.names=FALSE)
  x_names <- paste0(".X",seq_along(covariates))
  if (length(covariates)>0L) for (j in seq_along(covariates)) out[[x_names[[j]]]] <- data[[covariates[[j]]]]
  m_names <- paste0(".M",seq_along(phase2_covariates))
  for (j in seq_along(phase2_covariates)) out[[m_names[[j]]]] <- data[[phase2_covariates[[j]]]]
  list(data=out, phase1_names=x_names, marker_names=m_names,
       phase1_map=stats::setNames(covariates,x_names),
       marker_map=stats::setNames(phase2_covariates,m_names))
}
