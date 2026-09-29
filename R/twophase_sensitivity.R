#' Compare methods for Phase-2 covariates missing by design
#'
#' Runs a prespecified set of analytic approaches for a linear-regression
#' exposure coefficient when a block of continuous adjustment covariates is
#' observed only in a Phase-2 subsample.
#'
#' @param data A data frame.
#' @param outcome Character vector naming one or more continuous outcomes. A
#'   single outcome is fully supported. Multiple outcomes are analyzed
#'   separately using the same exposure, covariates, Phase-2 variables, and
#'   requested methods.
#' @param exposure Character scalar naming the numeric primary exposure.
#' @param covariates Character vector naming fully observed Phase-1 covariates.
#' @param phase2_covariates Character vector naming continuous Phase-2 covariates.
#' @param phase2 Character scalar naming the 0/1 Phase-2 indicator.
#' @param methods Methods to run. Defaults to all six validated approaches.
#' @param n_imputations Number of imputations for FCS-MI and JM-MI.
#' @param mice_maxit Maximum FCS iterations.
#' @param jomo_nburn JM-MI burn-in iterations.
#' @param jomo_nbetween JM-MI iterations between saved imputations.
#' @param seed Optional random-number seed. Supply either one non-negative
#'   integer, which is expanded sequentially across outcomes, or one integer
#'   per outcome. A named vector may be supplied using the outcome names. The
#'   previous global RNG state is restored after each outcome analysis.
#' @param conf_level Confidence level for intervals.
#' @return An object of class `twophase_sensitivity`.
#'
#' @examples
#' dat <- twophase_example_data(n = 200, seed = 2026)
#' fit <- twophase_sensitivity(
#'   data = dat,
#'   outcome = "outcome1",
#'   exposure = "exposure",
#'   covariates = c("age", "sex"),
#'   phase2_covariates = c("marker1", "marker2", "marker3"),
#'   phase2 = "phase2",
#'   methods = c("naive", "cca", "ipw"),
#'   seed = 1001
#' )
#' fit
#'
#' @export
twophase_sensitivity <- function(
  data,
  outcome,
  exposure,
  covariates = character(),
  phase2_covariates,
  phase2,
  methods = c("naive", "cca", "fcs_mi", "jm_mi", "ipw", "aipw"),
  n_imputations = .twophasesens_defaults$n_imputations,
  mice_maxit = .twophasesens_defaults$mice_maxit,
  jomo_nburn = .twophasesens_defaults$jomo_nburn,
  jomo_nbetween = .twophasesens_defaults$jomo_nbetween,
  seed = NULL,
  conf_level = .twophasesens_defaults$conf_level
) {
  validated <- .validate_twophase_inputs(
    data=data, outcome=outcome, exposure=exposure, covariates=covariates,
    phase2_covariates=phase2_covariates, phase2=phase2
  )

  if (!is.numeric(conf_level) || length(conf_level)!=1L ||
      !is.finite(conf_level) || conf_level<=0 || conf_level>=1) {
    stop("`conf_level` must be one number strictly between 0 and 1.", call.=FALSE)
  }

  integer_settings <- c(
    n_imputations=n_imputations, mice_maxit=mice_maxit,
    jomo_nburn=jomo_nburn, jomo_nbetween=jomo_nbetween
  )
  if (any(!is.finite(integer_settings)) || any(integer_settings<1) ||
      any(integer_settings != floor(integer_settings))) {
    stop("MI iteration settings must be positive integers.", call.=FALSE)
  }

  method_labels <- .normalize_methods(methods)
  analysis_seeds <- .resolve_analysis_seeds(seed, outcome)

  results <- vector("list",length(outcome))
  internal_maps <- vector("list",length(outcome))

  for (i in seq_along(outcome)) {
    yy <- outcome[[i]]
    prepared <- .prepare_internal_data(
      data=data, outcome=yy, exposure=exposure, covariates=covariates,
      phase2_covariates=phase2_covariates, phase2=phase2
    )
    seed_i <- if (is.na(analysis_seeds[[i]])) NULL else analysis_seeds[[i]]

    method_results <- .with_preserved_seed(
      seed_i,
      .run_requested_methods(
        dat=prepared$data,
        phase1_names=prepared$phase1_names,
        marker_names=prepared$marker_names,
        methods=method_labels,
        nimp=as.integer(n_imputations),
        mice_maxit=as.integer(mice_maxit),
        jomo_nburn=as.integer(jomo_nburn),
        jomo_nbetween=as.integer(jomo_nbetween),
        probability_floor=.twophasesens_defaults$probability_floor,
        matrix_tolerance=.twophasesens_defaults$matrix_tolerance,
        conf_level=conf_level
      )
    )

    method_results$outcome <- yy
    method_results$exposure <- exposure
    method_results$N_phase1 <- nrow(data)
    method_results$N_phase2 <- sum(validated$phase2==1L)
    method_results$phase2_fraction <- mean(validated$phase2)
    method_results$analysis_seed <- if (is.null(seed_i)) NA_integer_ else seed_i

    core <- c("outcome","exposure","method","estimate","se","conf_low",
      "conf_high","p_value","df","status","message","N_phase1",
      "N_phase2","phase2_fraction","analysis_seed")
    extras <- setdiff(names(method_results),core)
    method_results <- method_results[,c(core,extras),drop=FALSE]

    results[[i]] <- method_results
    internal_maps[[i]] <- list(
      outcome=yy,
      phase1_map=prepared$phase1_map,
      marker_map=prepared$marker_map
    )
  }

  result_df <- do.call(rbind,results)
  rownames(result_df) <- NULL
  result_df$method <- factor(result_df$method,levels=.twophasesens_method_order)
  result_df <- result_df[order(match(result_df$outcome,outcome),result_df$method),,drop=FALSE]
  result_df$method <- as.character(result_df$method)

  out <- list(
    results=result_df,
    call=match.call(),
    specification=list(
      outcome=outcome,
      exposure=exposure,
      covariates=covariates,
      phase2_covariates=phase2_covariates,
      phase2=phase2,
      methods=method_labels
    ),
    settings=list(
      n_imputations=as.integer(n_imputations),
      mice_maxit=as.integer(mice_maxit),
      jomo_nburn=as.integer(jomo_nburn),
      jomo_nbetween=as.integer(jomo_nbetween),
      seed=if (all(is.na(analysis_seeds))) NULL else analysis_seeds,
      conf_level=conf_level,
      probability_floor=.twophasesens_defaults$probability_floor,
      matrix_tolerance=.twophasesens_defaults$matrix_tolerance
    ),
    internal_maps=internal_maps
  )
  class(out) <- "twophase_sensitivity"
  out
}
