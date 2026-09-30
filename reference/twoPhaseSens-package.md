# twoPhaseSens: sensitivity analysis for covariates observed in two-phase samples

`twoPhaseSens` provides a standardized workflow for comparing analytic
approaches when important continuous adjustment covariates are observed
only in a Phase-2 subsample.

## Details

The current validated scope is a continuous outcome with a
linear-regression target model, a numeric primary exposure, fully
observed Phase-1 covariates, and a block of continuous Phase-2
covariates observed only when the Phase-2 indicator equals 1.

Six methods are available: Naive, complete-case analysis (CCA), fully
conditional specification multiple imputation (FCS-MI), joint-model
multiple imputation (JM-MI), inverse probability weighting (IPW), and
augmented inverse probability weighting (AIPW).

The main entry point is
[`twophase_sensitivity()`](https://rophenceojiambo.github.io/twoPhaseSens/reference/twophase_sensitivity.md).
Results can be summarized with
[`tbl_sensitivity()`](https://rophenceojiambo.github.io/twoPhaseSens/reference/tbl_sensitivity.md),
inspected with
[`diagnostics()`](https://rophenceojiambo.github.io/twoPhaseSens/reference/diagnostics.md),
and visualized with
[`plot_sensitivity()`](https://rophenceojiambo.github.io/twoPhaseSens/reference/plot_sensitivity.md).

## See also

Useful links:

- <https://github.com/rophenceojiambo/twoPhaseSens>

- Report bugs at
  <https://github.com/rophenceojiambo/twoPhaseSens/issues>

## Author

**Maintainer**: Rophence Ojiambo <rophence.ojiambo@nyu.edu>
([ORCID](https://orcid.org/0000-0002-6798-9066))

Authors:

- Jemar Bather <jemar.bather@nyu.edu>
  ([ORCID](https://orcid.org/0000-0002-0285-3678))
