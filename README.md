# twoPhaseSens

`twoPhaseSens` is an R package under development for method-comparison sensitivity analyses when important continuous adjustment covariates are observed only in a Phase-2 subsample.

The planned first release compares six approaches for a linear-regression exposure coefficient:

1. Naive Phase-1 analysis
2. Complete-case analysis (CCA)
3. Fully conditional specification multiple imputation (FCS-MI)
4. Joint-model multiple imputation (JM-MI)
5. Inverse probability weighting (IPW)
6. Augmented inverse probability weighting (AIPW)

## Development status

Current version: `0.0.0.9000`. This scaffold has not yet been validated as an installable package. The next milestone is numerical reproduction of the validated manuscript implementation and MIDUS application.

## Planned interface

```r
fit <- twophase_sensitivity(
  data = dat,
  outcome = c("outcome1", "outcome2"),
  exposure = "exposure",
  covariates = c("age", "sex"),
  phase2_covariates = c("marker1", "marker2"),
  phase2 = "phase2",
  seed = 20260928
)

tbl_sensitivity(fit)
diagnostics(fit)
```

See `README_STEP3.md` for development notes and validation requirements.
