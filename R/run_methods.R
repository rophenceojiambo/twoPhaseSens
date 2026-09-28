.run_requested_methods <- function(
  dat,
  phase1_names,
  marker_names,
  methods,
  nimp,
  mice_maxit,
  jomo_nburn,
  jomo_nbetween,
  probability_floor,
  matrix_tolerance,
  conf_level
) {
  out <- list()

  add <- function(label, expr) {
    out[[length(out) + 1L]] <<- tryCatch(
      expr,
      error = function(e) .failed_result(label, conditionMessage(e))
    )
  }

  if ("Naive" %in% methods) {
    add("Naive", .fit_naive(dat, phase1_names, conf_level = conf_level))
  }
  if ("CCA" %in% methods) {
    add("CCA", .fit_cca(dat, phase1_names, marker_names, conf_level = conf_level))
  }
  if ("FCS-MI" %in% methods) {
    add("FCS-MI", .fit_fcs_mi(
      dat, phase1_names, marker_names,
      nimp = nimp, maxit = mice_maxit, method = "norm",
      conf_level = conf_level
    ))
  }
  if ("JM-MI" %in% methods) {
    add("JM-MI", .fit_joint_mi(
      dat, phase1_names, marker_names,
      nimp = nimp, nburn = jomo_nburn, nbetween = jomo_nbetween,
      conf_level = conf_level
    ))
  }
  if ("IPW" %in% methods) {
    add("IPW", .fit_ipw(
      dat, phase1_names, marker_names,
      prob_floor = probability_floor,
      conf_level = conf_level
    ))
  }
  if ("AIPW" %in% methods) {
    add("AIPW", .fit_aipw(
      dat, phase1_names, marker_names,
      selection_include_y = TRUE,
      marker_include_y = TRUE,
      method_label = "AIPW",
      prob_floor = probability_floor,
      matrix_tolerance = matrix_tolerance,
      conf_level = conf_level
    ))
  }

  .rbind_fill(out)
}
