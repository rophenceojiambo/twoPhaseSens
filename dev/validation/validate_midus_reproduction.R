################################################################################
# validate_midus_reproduction.R
#
# Developer-only numerical validation of twoPhaseSens against the validated
# MIDUS manuscript application.
#
# IMPORTANT:
#   - Run from the twoPhaseSens repository root.
#   - Do not commit restricted MIDUS data.
#   - The script does not modify the analytic data.
################################################################################

# ------------------------------------------------------------------------------
# 1. REQUIREMENTS
# ------------------------------------------------------------------------------

if (!requireNamespace("devtools", quietly = TRUE)) {
  stop("Install devtools before running this validation: install.packages('devtools')")
}

if (!requireNamespace("readr", quietly = TRUE)) {
  stop("Install readr before running this validation: install.packages('readr')")
}

if (!file.exists("DESCRIPTION")) {
  stop("Run this script from the twoPhaseSens repository root.")
}

devtools::load_all(".", quiet = TRUE)

# ------------------------------------------------------------------------------
# 2. INPUT PATHS
# ------------------------------------------------------------------------------

analytic_file <- Sys.getenv("TWOPHASESENS_MIDUS_RDS", unset = "")

if (!nzchar(analytic_file)) {
  stop(
    "Set TWOPHASESENS_MIDUS_RDS to the local path of ",
    "MIDUS_discrimination_analysis.rds before running validation."
  )
}

if (!file.exists(analytic_file)) {
  stop("MIDUS analytic RDS not found: ", analytic_file)
}

full_reference_file <- Sys.getenv("TWOPHASESENS_REFERENCE_CSV", unset = "")

frozen_reference_file <- file.path(
  "dev", "validation", "reference", "midus_manuscript_core_reference.csv"
)

if (nzchar(full_reference_file)) {
  if (!file.exists(full_reference_file)) {
    stop("TWOPHASESENS_REFERENCE_CSV does not exist: ", full_reference_file)
  }
  reference_file <- full_reference_file
  reference_source <- "original manuscript result CSV"
} else {
  reference_file <- frozen_reference_file
  reference_source <- "frozen core manuscript reference"
}

if (!file.exists(reference_file)) {
  stop("Reference result file not found: ", reference_file)
}

# ------------------------------------------------------------------------------
# 3. READ AND PREPARE THE MIDUS DATA EXACTLY AS IN THE MANUSCRIPT APPLICATION
# ------------------------------------------------------------------------------

dat <- readRDS(analytic_file)

marker_names <- c(
  "log2_cd19_STD",
  "log2_cd3d_STD",
  "log2_cd3e_STD",
  "log2_cd4_STD",
  "log2_cd8a_STD",
  "log2_cd14_STD",
  "log2_fcgr3a_STD",
  "log2_ncam1_STD"
)

required_columns <- c(
  "discrimination_STD",
  "grimage2_STD",
  "dunedinpace_STD",
  "age_STD",
  "sex",
  "race_eth",
  marker_names,
  "phase2"
)

missing_columns <- setdiff(required_columns, names(dat))
if (length(missing_columns) > 0L) {
  stop(
    "Analytic data are missing required variable(s): ",
    paste(missing_columns, collapse = ", ")
  )
}

# Match Script 44 factor handling exactly.
dat$sex <- droplevels(factor(dat$sex))
dat$race_eth <- factor(
  dat$race_eth,
  levels = c(
    "non-Hispanic White",
    "non-Hispanic Black",
    "Other"
  )
)
dat$phase2 <- as.integer(dat$phase2)

# Structural checks from the manuscript workflow.
phase1_vars <- c(
  "discrimination_STD",
  "grimage2_STD",
  "dunedinpace_STD",
  "age_STD",
  "sex",
  "race_eth"
)

if (any(vapply(dat[phase1_vars], anyNA, logical(1)))) {
  stop("Unexpected missingness remains in Phase-1 variables.")
}

n_marker_observed <- rowSums(!is.na(dat[marker_names]))
if (any(!(n_marker_observed %in% c(0L, length(marker_names))))) {
  stop("Partially observed Phase-2 marker blocks were found.")
}

marker_complete <- as.integer(n_marker_observed == length(marker_names))
if (any(dat$phase2 != marker_complete)) {
  stop("phase2 disagrees with complete observation of the eight marker variables.")
}

if (nrow(dat) != 786L) {
  warning("Expected manuscript Phase-1 N = 786; observed N = ", nrow(dat), ".")
}

if (sum(dat$phase2 == 1L) != 518L) {
  warning(
    "Expected manuscript Phase-2 N = 518; observed N = ",
    sum(dat$phase2 == 1L), "."
  )
}

# ------------------------------------------------------------------------------
# 4. RUN THE GENERALIZED PACKAGE WITH THE MANUSCRIPT SETTINGS
# ------------------------------------------------------------------------------

cat("\nRunning twoPhaseSens manuscript reproduction...\n")
cat("This can take several minutes because both MI procedures are rerun.\n\n")

fit <- twophase_sensitivity(
  data = dat,
  outcome = c("grimage2_STD", "dunedinpace_STD"),
  exposure = "discrimination_STD",
  covariates = c("age_STD", "sex", "race_eth"),
  phase2_covariates = marker_names,
  phase2 = "phase2",
  methods = c("naive", "cca", "fcs_mi", "jm_mi", "ipw", "aipw"),
  n_imputations = 20L,
  mice_maxit = 10L,
  jomo_nburn = 1000L,
  jomo_nbetween = 1000L,
  seed = 20260901L,
  conf_level = 0.95
)

package_results <- fit$results

# Map package outcome variable names to manuscript labels.
outcome_label <- c(
  grimage2_STD = "GrimAge2",
  dunedinpace_STD = "DunedinPACE"
)

package_results$outcome_variable <- package_results$outcome
package_results$outcome <- unname(outcome_label[package_results$outcome_variable])

if (anyNA(package_results$outcome)) {
  stop("Failed to map one or more package outcome names to manuscript labels.")
}

# ------------------------------------------------------------------------------
# 5. READ THE VALIDATED REFERENCE RESULTS
# ------------------------------------------------------------------------------

reference <- readr::read_csv(reference_file, show_col_types = FALSE)

required_reference_columns <- c(
  "outcome", "method", "estimate", "se", "conf_low", "conf_high", "p_value"
)

missing_reference <- setdiff(required_reference_columns, names(reference))
if (length(missing_reference) > 0L) {
  stop(
    "Reference file is missing required column(s): ",
    paste(missing_reference, collapse = ", ")
  )
}

reference$method <- as.character(reference$method)

expected_methods <- c("Naive", "CCA", "FCS-MI", "JM-MI", "IPW", "AIPW")
expected_outcomes <- c("GrimAge2", "DunedinPACE")

expected_keys <- expand.grid(
  outcome = expected_outcomes,
  method = expected_methods,
  stringsAsFactors = FALSE
)

key <- function(d) paste(d$outcome, d$method, sep = "||")

if (!setequal(key(package_results), key(expected_keys))) {
  stop("Package results do not contain exactly the expected 12 outcome-method combinations.")
}

if (!setequal(key(reference), key(expected_keys))) {
  stop("Reference results do not contain exactly the expected 12 outcome-method combinations.")
}

# ------------------------------------------------------------------------------
# 6. ALIGN AND COMPARE
# ------------------------------------------------------------------------------

package_results <- package_results[match(key(expected_keys), key(package_results)), , drop = FALSE]
reference <- reference[match(key(expected_keys), key(reference)), , drop = FALSE]

if (any(package_results$status != "ok")) {
  failed <- package_results[package_results$status != "ok", c("outcome", "method", "message")]
  print(failed)
  stop("One or more package methods failed.")
}

metrics <- c("estimate", "se", "conf_low", "conf_high", "p_value")

comparison <- data.frame(
  outcome = expected_keys$outcome,
  method = expected_keys$method,
  stringsAsFactors = FALSE
)

for (metric in metrics) {
  comparison[[paste0("reference_", metric)]] <- reference[[metric]]
  comparison[[paste0("package_", metric)]] <- package_results[[metric]]
  comparison[[paste0("abs_diff_", metric)]] <- abs(
    package_results[[metric]] - reference[[metric]]
  )
}

# Full-precision original CSV should permit a very strict comparison.
# The frozen fallback CSV was reconstructed from printed full-precision output
# and therefore uses a slightly looser tolerance.
core_tolerance <- if (identical(reference_source, "original manuscript result CSV")) {
  1e-10
} else {
  5e-7
}

comparison$core_pass <- apply(
  comparison[paste0("abs_diff_", metrics)],
  1,
  function(z) all(is.finite(z) & z <= core_tolerance)
)

# Compare weight diagnostics only when they exist in the reference file.
weight_metrics <- c(
  "weight_min", "weight_p99", "weight_max", "weight_cv", "weight_ess"
)

available_weight_metrics <- intersect(
  weight_metrics,
  intersect(names(reference), names(package_results))
)

if (length(available_weight_metrics) > 0L) {
  for (metric in available_weight_metrics) {
    comparison[[paste0("reference_", metric)]] <- reference[[metric]]
    comparison[[paste0("package_", metric)]] <- package_results[[metric]]
    comparison[[paste0("abs_diff_", metric)]] <- abs(
      package_results[[metric]] - reference[[metric]]
    )
  }

  weight_rows <- comparison$method %in% c("IPW", "AIPW")
  weight_diff_cols <- paste0("abs_diff_", available_weight_metrics)

  comparison$weight_pass <- NA
  comparison$weight_pass[weight_rows] <- apply(
    comparison[weight_rows, weight_diff_cols, drop = FALSE],
    1,
    function(z) all(is.finite(z) & z <= core_tolerance)
  )
} else {
  comparison$weight_pass <- NA
}

# ------------------------------------------------------------------------------
# 7. SAVE LOCAL VALIDATION OUTPUTS
# ------------------------------------------------------------------------------

output_dir <- file.path("dev", "validation", "output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

readr::write_csv(
  comparison,
  file.path(output_dir, "midus_reference_vs_package.csv")
)

saveRDS(
  fit,
  file.path(output_dir, "midus_twophasesens_fit.rds")
)

# ------------------------------------------------------------------------------
# 8. REPORT
# ------------------------------------------------------------------------------

display_cols <- c(
  "outcome",
  "method",
  "reference_estimate",
  "package_estimate",
  "abs_diff_estimate",
  "reference_se",
  "package_se",
  "abs_diff_se",
  "core_pass"
)

cat("\n============================================================\n")
cat("twoPhaseSens MIDUS NUMERICAL VALIDATION\n")
cat("============================================================\n")
cat("Reference source: ", reference_source, "\n", sep = "")
cat("Core tolerance: ", format(core_tolerance, scientific = TRUE), "\n", sep = "")
cat("Phase-1 N: ", nrow(dat), "\n", sep = "")
cat("Phase-2 N: ", sum(dat$phase2 == 1L), "\n\n", sep = "")

print(comparison[, display_cols, drop = FALSE], row.names = FALSE)

all_core_pass <- all(comparison$core_pass)

if (length(available_weight_metrics) > 0L) {
  all_weight_pass <- all(
    comparison$weight_pass[comparison$method %in% c("IPW", "AIPW")],
    na.rm = TRUE
  )
} else {
  all_weight_pass <- NA
}

cat("\nCore numerical agreement: ", if (all_core_pass) "PASS" else "FAIL", "\n", sep = "")

if (!is.na(all_weight_pass)) {
  cat(
    "IPW/AIPW weight-diagnostic agreement: ",
    if (all_weight_pass) "PASS" else "FAIL",
    "\n",
    sep = ""
  )
} else {
  cat(
    "IPW/AIPW weight-diagnostic agreement: NOT ASSESSED ",
    "(full reference CSV not supplied)\n",
    sep = ""
  )
}

cat(
  "Comparison file: ",
  file.path(output_dir, "midus_reference_vs_package.csv"),
  "\n",
  sep = ""
)
cat("============================================================\n")

if (!all_core_pass || identical(all_weight_pass, FALSE)) {
  stop("Numerical validation failed. Inspect the comparison CSV before proceeding.")
}

cat("\nNumerical validation PASSED.\n")
