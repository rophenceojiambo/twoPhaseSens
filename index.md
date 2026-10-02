# twoPhaseSens

`twoPhaseSens` is an R package for method-comparison sensitivity
analyses when important continuous adjustment covariates are observed
only in a Phase-2 subsample.

Version 0.1.0 compares six approaches for a linear-regression exposure
coefficient:

1.  Naive Phase-1 analysis
2.  Complete-case analysis (CCA)
3.  Fully conditional specification multiple imputation (FCS-MI)
4.  Joint-model multiple imputation (JM-MI)
5.  Inverse probability weighting (IPW)
6.  Augmented inverse probability weighting (AIPW)

## Release status

Version `0.1.0` is the first public release of `twoPhaseSens`. The six
analytic methods have been generalized into the package interface and
numerically checked against the validated manuscript implementation for
both MIDUS outcomes. Automated tests, cross-platform R CMD checks,
source-package checks, Win-builder checks, and a clean source-install
smoke test are passing.

## Installation

Install version `0.1.0` from GitHub with:

``` r

# install.packages("remotes")
remotes::install_github("rophenceojiambo/twoPhaseSens")
```

By default, `remotes` may ask whether to update older installed
dependencies. Users who specifically want to avoid upgrading
already-installed packages can instead use `upgrade = "never"`.

After the package is available on CRAN, it can also be installed with
`install.packages("twoPhaseSens")`.

## Basic workflow

``` r

library(twoPhaseSens)

dat <- twophase_example_data(
  n = 300,
  seed = 2026
)

fit <- twophase_sensitivity(
  data = dat,
  outcome = c("outcome1", "outcome2"),
  exposure = "exposure",
  covariates = c("age", "sex"),
  phase2_covariates = c("marker1", "marker2", "marker3"),
  phase2 = "phase2",
  methods = c("naive", "cca", "ipw"),
  seed = 20260928
)

tbl_sensitivity(fit)
diagnostics(fit)
plot_sensitivity(fit)
```

The example above uses three fast methods for a quick first run. Omit
the `methods` argument to run all six methods in version 0.1.0.

## Plot display and export

[`plot_sensitivity()`](https://rophenceojiambo.github.io/twoPhaseSens/reference/plot_sensitivity.md)
returns a publication-style `ggplot` object. Annotated plots can look
compressed in a small RStudio Plots pane, especially with two outcomes.
Use **Zoom**, enlarge the pane, or set `annotate = FALSE` for a compact
interactive preview.

For exported output, specify the graphics size explicitly. As practical
starting points, use approximately 9.5 x 6 inches for one annotated
outcome and 14 x 6 inches for two annotated outcomes.

``` r

p <- plot_sensitivity(
  fit,
  estimate_label = "Adjusted beta"
)

ggplot2::ggsave(
  "sensitivity_plot.png",
  p,
  width = 9.5,
  height = 6,
  dpi = 320,
  bg = "white"
)
```

See the Getting Started vignette for single- and multiple-outcome
examples, fixed versus free x-axis scales, custom labels, and export
guidance.
