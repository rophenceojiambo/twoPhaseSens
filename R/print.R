#' @export
print.twophase_sensitivity <- function(x, ...) {
  cat("twoPhaseSens analysis\n")
  cat("  Outcomes: ", paste(x$specification$outcome, collapse = ", "), "\n", sep = "")
  cat("  Exposure: ", x$specification$exposure, "\n", sep = "")
  cat("  Methods: ", paste(x$specification$methods, collapse = ", "), "\n", sep = "")
  cat("  Phase-1 N: ", unique(x$results$N_phase1), "\n", sep = "")
  cat("  Phase-2 N: ", unique(x$results$N_phase2), "\n\n", sep = "")

  keep <- c("outcome", "method", "estimate", "se", "conf_low", "conf_high", "p_value", "status")
  print(x$results[, keep, drop = FALSE], row.names = FALSE)
  invisible(x)
}

#' @export
summary.twophase_sensitivity <- function(object, ...) {
  object$results
}
