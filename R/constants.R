.twophasesens_defaults <- list(
  n_imputations = 20L,
  mice_maxit = 10L,
  jomo_nburn = 1000L,
  jomo_nbetween = 1000L,
  probability_floor = 1e-8,
  matrix_tolerance = 1e-10,
  conf_level = 0.95
)

.twophasesens_method_order <- c(
  "Naive", "CCA", "FCS-MI", "JM-MI", "IPW", "AIPW"
)
