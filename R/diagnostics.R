#' Extract diagnostics from a twoPhaseSens analysis
#'
#' Returns method-level information from a [twophase_sensitivity()] fit. The
#' default view contains analysis status, sample-size information, stochastic
#' settings, multiple-imputation settings, and available IPW/AIPW weight
#' diagnostics. More focused views can be requested with `type`.
#'
#' The function reports diagnostics but does not automatically label values as
#' acceptable or unacceptable. Interpretation of weight variability,
#' effective sample size, imputation behavior, and method failures should be
#' based on the study design and scientific context.
#'
#' @param x An object.
#' @param ... Additional arguments passed to methods.
#' @export
diagnostics <- function(x, ...) {
  UseMethod("diagnostics")
}

#' @param type Diagnostic view. One of `"all"`, `"status"`,
#'   `"weights"`, or `"mi"`.
#' @param outcome Optional character vector selecting one or more outcomes.
#' @param method Optional character vector selecting one or more methods.
#'   Method names are normalized in the same way as in
#'   [twophase_sensitivity()].
#'
#' @return A data frame with one row per selected outcome-method combination.
#'
#' @export
diagnostics.twophase_sensitivity <- function(
  x,
  type = c("all", "status", "weights", "mi"),
  outcome = NULL,
  method = NULL,
  ...
) {
  type <- match.arg(type)

  r <- x$results

  if (!is.null(outcome)) {
    if (!is.character(outcome) || anyNA(outcome) || any(!nzchar(outcome))) {
      stop("`outcome` must be NULL or a non-missing character vector.", call. = FALSE)
    }

    unknown_outcomes <- setdiff(outcome, x$specification$outcome)
    if (length(unknown_outcomes) > 0L) {
      stop(
        "Unknown outcome(s): ",
        paste(unknown_outcomes, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    r <- r[r$outcome %in% outcome, , drop = FALSE]
  }

  if (!is.null(method)) {
    method_labels <- .normalize_methods(method)

    unavailable <- setdiff(method_labels, x$specification$methods)
    if (length(unavailable) > 0L) {
      stop(
        "Requested method(s) were not run in this analysis: ",
        paste(unavailable, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    r <- r[r$method %in% method_labels, , drop = FALSE]
  }

  if (nrow(r) == 0L) {
    return(data.frame())
  }

  base <- data.frame(
    outcome = r$outcome,
    method = r$method,
    status = r$status,
    message = r$message,
    N_phase1 = r$N_phase1,
    N_phase2 = r$N_phase2,
    phase2_fraction = r$phase2_fraction,
    analysis_seed = r$analysis_seed,
    stringsAsFactors = FALSE
  )

  if (type == "status") {
    return(base)
  }

  if (type == "weights") {
    keep <- r$method %in% c("IPW", "AIPW")
    if (!any(keep)) {
      return(data.frame())
    }

    out <- base[keep, , drop = FALSE]

    for (nm in c(
      "weight_min",
      "weight_p99",
      "weight_max",
      "weight_cv",
      "weight_ess"
    )) {
      out[[nm]] <- if (nm %in% names(r)) r[[nm]][keep] else NA_real_
    }

    out$weight_ess_fraction <- out$weight_ess / out$N_phase2
    rownames(out) <- NULL
    return(out)
  }

  if (type == "mi") {
    keep <- r$method %in% c("FCS-MI", "JM-MI")
    if (!any(keep)) {
      return(data.frame())
    }

    out <- base[keep, , drop = FALSE]
    out$n_imputations <- x$settings$n_imputations
    out$mice_maxit <- ifelse(out$method == "FCS-MI", x$settings$mice_maxit, NA_integer_)
    out$jomo_nburn <- ifelse(out$method == "JM-MI", x$settings$jomo_nburn, NA_integer_)
    out$jomo_nbetween <- ifelse(
      out$method == "JM-MI",
      x$settings$jomo_nbetween,
      NA_integer_
    )

    out$mi_logged_events <- if ("mi_logged_events" %in% names(r)) {
      r$mi_logged_events[keep]
    } else {
      NA_integer_
    }

    rownames(out) <- NULL
    return(out)
  }

  # type == "all"
  out <- base
  out$n_imputations <- ifelse(
    out$method %in% c("FCS-MI", "JM-MI"),
    x$settings$n_imputations,
    NA_integer_
  )
  out$mice_maxit <- ifelse(
    out$method == "FCS-MI",
    x$settings$mice_maxit,
    NA_integer_
  )
  out$jomo_nburn <- ifelse(
    out$method == "JM-MI",
    x$settings$jomo_nburn,
    NA_integer_
  )
  out$jomo_nbetween <- ifelse(
    out$method == "JM-MI",
    x$settings$jomo_nbetween,
    NA_integer_
  )

  out$mi_logged_events <- if ("mi_logged_events" %in% names(r)) {
    r$mi_logged_events
  } else {
    NA_integer_
  }

  for (nm in c(
    "weight_min",
    "weight_p99",
    "weight_max",
    "weight_cv",
    "weight_ess"
  )) {
    out[[nm]] <- if (nm %in% names(r)) r[[nm]] else NA_real_
  }

  out$weight_ess_fraction <- ifelse(
    out$method %in% c("IPW", "AIPW"),
    out$weight_ess / out$N_phase2,
    NA_real_
  )

  rownames(out) <- NULL
  out
}
