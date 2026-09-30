# Extract diagnostics from a twoPhaseSens analysis

Returns method-level information from a
[`twophase_sensitivity()`](https://rophenceojiambo.github.io/twoPhaseSens/reference/twophase_sensitivity.md)
fit. The default view contains analysis status, sample-size information,
stochastic settings, multiple-imputation settings, and available
IPW/AIPW weight diagnostics. More focused views can be requested with
`type`.

## Usage

``` r
diagnostics(x, ...)

# S3 method for class 'twophase_sensitivity'
diagnostics(
  x,
  type = c("all", "status", "weights", "mi"),
  outcome = NULL,
  method = NULL,
  ...
)
```

## Arguments

- x:

  An object.

- ...:

  Additional arguments passed to methods.

- type:

  Diagnostic view. One of `"all"`, `"status"`, `"weights"`, or `"mi"`.

- outcome:

  Optional character vector selecting one or more outcomes.

- method:

  Optional character vector selecting one or more methods. Method names
  are normalized in the same way as in
  [`twophase_sensitivity()`](https://rophenceojiambo.github.io/twoPhaseSens/reference/twophase_sensitivity.md).

## Value

A data frame with one row per selected outcome-method combination.

## Details

The function reports diagnostics but does not automatically label values
as acceptable or unacceptable. Interpretation of weight variability,
effective sample size, imputation behavior, and method failures should
be based on the study design and scientific context.

## Examples

``` r
dat <- twophase_example_data(n = 200, seed = 2026)
fit <- twophase_sensitivity(
  data = dat,
  outcome = "outcome1",
  exposure = "exposure",
  covariates = c("age", "sex"),
  phase2_covariates = c("marker1", "marker2", "marker3"),
  phase2 = "phase2",
  methods = c("naive", "cca", "ipw"),
  seed = 1001
)
diagnostics(fit)
#>    outcome method status message N_phase1 N_phase2 phase2_fraction
#> 1 outcome1  Naive     ok    <NA>      200      126            0.63
#> 2 outcome1    CCA     ok    <NA>      200      126            0.63
#> 3 outcome1    IPW     ok    <NA>      200      126            0.63
#>   analysis_seed n_imputations mice_maxit jomo_nburn jomo_nbetween
#> 1          1001            NA         NA         NA            NA
#> 2          1001            NA         NA         NA            NA
#> 3          1001            NA         NA         NA            NA
#>   mi_logged_events weight_min weight_p99 weight_max weight_cv weight_ess
#> 1               NA         NA         NA         NA        NA         NA
#> 2               NA         NA         NA         NA        NA         NA
#> 3               NA   1.293361    2.14367   2.262247 0.1068651   124.5885
#>   weight_ess_fraction
#> 1                  NA
#> 2                  NA
#> 3           0.9887974
```
