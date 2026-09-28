#' Extract method diagnostics
#'
#' @param x An object.
#' @param ... Additional arguments.
#' @export
diagnostics <- function(x, ...) {
  UseMethod("diagnostics")
}

#' @export
diagnostics.twophase_sensitivity <- function(x, ...) {
  diagnostic_cols <- intersect(
    c(
      "outcome", "method", "status", "message", "N_phase1", "N_phase2",
      "phase2_fraction", "weight_min", "weight_p99", "weight_max",
      "weight_cv", "weight_ess"
    ),
    names(x$results)
  )
  x$results[, diagnostic_cols, drop = FALSE]
}
