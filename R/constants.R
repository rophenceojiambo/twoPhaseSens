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

# Publication-style method aesthetics used consistently across package figures.
.twophasesens_method_colors <- c(
  "Naive" = "#1B9E77",
  "CCA" = "#D95F02",
  "FCS-MI" = "#7570B3",
  "JM-MI" = "#E7298A",
  "IPW" = "#66A61E",
  "AIPW" = "#E6AB02"
)

.twophasesens_method_shapes <- c(
  "Naive" = 21L,
  "CCA" = 24L,
  "FCS-MI" = 22L,
  "JM-MI" = 23L,
  "IPW" = 25L,
  "AIPW" = 10L
)

.twophasesens_method_linetypes <- c(
  "Naive" = "solid",
  "CCA" = "dashed",
  "FCS-MI" = "dotted",
  "JM-MI" = "dotdash",
  "IPW" = "longdash",
  "AIPW" = "twodash"
)
