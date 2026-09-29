#' twoPhaseSens: sensitivity analysis for covariates observed in two-phase samples
#'
#' `twoPhaseSens` provides a standardized workflow for comparing analytic
#' approaches when important continuous adjustment covariates are observed only
#' in a Phase-2 subsample.
#'
#' The current validated scope is a continuous outcome with a linear-regression
#' target model, a numeric primary exposure, fully observed Phase-1 covariates,
#' and a block of continuous Phase-2 covariates observed only when the Phase-2
#' indicator equals 1.
#'
#' Six methods are available: Naive, complete-case analysis (CCA), fully
#' conditional specification multiple imputation (FCS-MI), joint-model multiple
#' imputation (JM-MI), inverse probability weighting (IPW), and augmented
#' inverse probability weighting (AIPW).
#'
#' The main entry point is [twophase_sensitivity()]. Results can be summarized
#' with [tbl_sensitivity()], inspected with [diagnostics()], and visualized with
#' [plot_sensitivity()].
#'
#' @importFrom rlang .data
#' @keywords internal
"_PACKAGE"
