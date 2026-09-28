# Numerical validation

This directory contains developer-only validation code for `twoPhaseSens`.
It is excluded from the built R package by `.Rbuildignore`.

The validation has two distinct goals:

1. **Manuscript reproduction:** run the generalized package on the restricted MIDUS analytic data and compare its output with the frozen results produced by the validated manuscript implementation.
2. **Refactor equivalence:** confirm that generalizing variable names and package structure did not change the numerical estimators.

## Restricted data

Do **not** commit the MIDUS analytic dataset to GitHub.

The local validation script expects the final analytic RDS through the environment variable:

```r
Sys.setenv(
  TWOPHASESENS_MIDUS_RDS = "path/to/MIDUS_discrimination_analysis.rds"
)
```

Optionally, point to the original full-precision manuscript result CSV:

```r
Sys.setenv(
  TWOPHASESENS_REFERENCE_CSV =
    "path/to/results/real_world_application/midus_real_world_method_results.csv"
)
```

If the original result CSV is not supplied, the script falls back to the frozen core reference values in
`dev/validation/reference/midus_manuscript_core_reference.csv`.

## Manuscript settings

The validated real-world application used:

- FCS method: normal linear regression (`norm`)
- imputations: 20
- MICE maximum iterations: 10
- JOMO burn-in: 1000
- JOMO iterations between imputations: 1000
- GrimAge2 seed: 20260901
- DunedinPACE seed: 20260902
- Phase-1 N: 786
- Phase-2 N: 518

Run from the repository root:

```r
source("dev/validation/validate_midus_reproduction.R")
```

The script writes local validation outputs to `dev/validation/output/`.
That output directory should not be committed.

## Acceptance rule

The package is not considered numerically validated until:

- all 12 outcome-method combinations are present;
- every method reports `status == "ok"`;
- deterministic methods agree with the validated implementation to a strict numerical tolerance;
- MI methods use identical seeds and tuning parameters and agree to the prespecified tolerance;
- IPW/AIPW weight diagnostics agree when the original full reference CSV is available.

A clean CRAN-style R CMD check is necessary, but it is not a substitute for this numerical validation.
