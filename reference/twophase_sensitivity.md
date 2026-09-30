# Compare methods for Phase-2 covariates missing by design

Runs a prespecified set of analytic approaches for a linear-regression
exposure coefficient when a block of continuous adjustment covariates is
observed only in a Phase-2 subsample.

## Usage

``` r
twophase_sensitivity(
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
)
```

## Arguments

- data:

  A data frame.

- outcome:

  Character vector naming one or more continuous outcomes. A single
  outcome is fully supported. Multiple outcomes are analyzed separately
  using the same exposure, covariates, Phase-2 variables, and requested
  methods.

- exposure:

  Character scalar naming the numeric primary exposure.

- covariates:

  Character vector naming fully observed Phase-1 covariates.

- phase2_covariates:

  Character vector naming continuous Phase-2 covariates.

- phase2:

  Character scalar naming the 0/1 Phase-2 indicator.

- methods:

  Methods to run. Defaults to all six validated approaches.

- n_imputations:

  Number of imputations for FCS-MI and JM-MI.

- mice_maxit:

  Maximum FCS iterations.

- jomo_nburn:

  JM-MI burn-in iterations.

- jomo_nbetween:

  JM-MI iterations between saved imputations.

- seed:

  Optional random-number seed. Supply either one non-negative integer,
  which is expanded sequentially across outcomes, or one integer per
  outcome. A named vector may be supplied using the outcome names. The
  previous global RNG state is restored after each outcome analysis.

- conf_level:

  Confidence level for intervals.

## Value

An object of class `twophase_sensitivity`.

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
fit
#> twoPhaseSens analysis
#>   Outcomes: outcome1
#>   Exposure: exposure
#>   Methods: Naive, CCA, IPW
#>   Phase-1 N: 200
#>   Phase-2 N: 126
#> 
#>   outcome method  estimate         se   conf_low conf_high      p_value status
#>  outcome1  Naive 0.4073857 0.06924204 0.27083063 0.5439408 1.711697e-08     ok
#>  outcome1    CCA 0.2352489 0.10911253 0.01919515 0.4513026 3.309468e-02     ok
#>  outcome1    IPW 0.2334585 0.10717793 0.02339361 0.4435234 2.938870e-02     ok
```
