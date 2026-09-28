# twoPhaseSens (development version 0.0.0.9000)

* Initialized package development scaffold.
* Generalized the validated six-method engine to use internal canonical variable roles rather than MIDUS-specific variable names.
* Added initial input validation, S3 result object, diagnostics, and a provisional sensitivity-table formatter.
* Added initial tests for input structure and Naive/CCA equivalence.

* Finalized the initial public API for analysis settings: users can analyze one or multiple outcomes, choose a subset of methods, set the confidence level, control FCS/JM-MI computation, and supply either one reproducible seed or outcome-specific seeds.
* Polished `tbl_sensitivity()` with user-controlled decimal places, outcome/method labels, optional standard-error columns, captions, and gtsummary/data-frame output modes.
* Added `plot_sensitivity()` and `plot()` support for forest plots of method-specific estimates and confidence intervals, including outcome/method filtering, custom labels, configurable reference lines, and fixed or free facet scales.
