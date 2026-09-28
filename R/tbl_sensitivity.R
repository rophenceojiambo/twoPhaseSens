#' Create a sensitivity-analysis comparison table
#'
#' @param x A `twophase_sensitivity` object.
#' @param estimate_digits Digits for estimates and confidence limits.
#' @param p_digits Digits for p values.
#' @param include_se Include a separate standard-error column for each outcome.
#' @param method_labels Optional named character vector for method labels.
#' @return A data frame with methods in rows and outcome-specific result columns.
#' @export
tbl_sensitivity <- function(x, estimate_digits=4L, p_digits=3L, include_se=FALSE, method_labels=NULL) {
  if (!inherits(x,"twophase_sensitivity")) stop("`x` must be a twophase_sensitivity object.",call.=FALSE)
  r <- x$results; methods <- x$specification$methods; outcomes <- x$specification$outcome
  out <- data.frame(Method=methods,stringsAsFactors=FALSE)
  if (!is.null(method_labels)) {
    repl <- method_labels[out$Method]
    out$Method[!is.na(repl)] <- unname(repl[!is.na(repl)])
  }
  fmt <- paste0("%.",estimate_digits,"f")
  for (yy in outcomes) {
    d <- r[r$outcome==yy,,drop=FALSE]
    d <- d[match(methods,d$method),,drop=FALSE]
    est_ci <- ifelse(d$status=="ok",
      sprintf(paste0(fmt," (",fmt," to ",fmt,")"),d$estimate,d$conf_low,d$conf_high),
      paste0("Failed: ",d$message))
    out[[paste0(yy," Coefficient (95% CI)")]] <- est_ci
    if (isTRUE(include_se)) out[[paste0(yy," SE")]] <- ifelse(d$status=="ok",formatC(d$se,format="f",digits=estimate_digits),"")
    out[[paste0(yy," P value")]] <- ifelse(d$status=="ok",.format_p(d$p_value,digits=p_digits),"")
  }
  out
}
