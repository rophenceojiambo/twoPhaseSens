# Create a publication-ready sensitivity-analysis table

Formats method-comparison results from
[`twophase_sensitivity()`](https://rophenceojiambo.github.io/twoPhaseSens/reference/twophase_sensitivity.md)
with methods in rows and one group of columns per outcome. By default,
the function returns a `gtsummary` object with outcome spanning headers.
A plain data frame can be requested for downstream custom formatting.

## Usage

``` r
tbl_sensitivity(
  x,
  estimate_digits = 3L,
  p_digits = 3L,
  include_se = FALSE,
  method_labels = NULL,
  outcome_labels = NULL,
  caption = NULL,
  output = c("gtsummary", "data.frame")
)
```

## Arguments

- x:

  A `twophase_sensitivity` object.

- estimate_digits:

  Number of digits for estimates and confidence limits. The default is
  3.

- p_digits:

  Number of digits for p values.

- include_se:

  Logical; include a separate standard-error column for each outcome.

- method_labels:

  Optional named character vector used to relabel methods. Names should
  be package method labels such as `"FCS-MI"` or `"AIPW"`.

- outcome_labels:

  Optional character vector used to relabel outcomes. Supply either a
  named vector whose names are the outcome variable names or an unnamed
  vector in the same order as `x$specification$outcome`.

- caption:

  Optional table caption. Markdown is supported for
  `output = "gtsummary"`.

- output:

  Output type: `"gtsummary"` (default) or `"data.frame"`.

## Value

A `gtsummary` object by default, or a formatted data frame when
`output = "data.frame"`.

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
tbl_sensitivity(fit, output = "data.frame")
#>   Method outcome1 Coefficient (95% CI) outcome1 P value
#> 1  Naive        0.407 (0.271 to 0.544)           <0.001
#> 2    CCA        0.235 (0.019 to 0.451)            0.033
#> 3    IPW        0.233 (0.023 to 0.444)            0.029
```
