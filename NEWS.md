# twoPhaseSens 0.1.0

* Initialized package development scaffold.
* Generalized the validated six-method engine to use internal canonical variable roles rather than MIDUS-specific variable names.
* Added initial input validation, S3 result object, diagnostics, and a provisional sensitivity-table formatter.
* Added initial tests for input structure and Naive/CCA equivalence.

* Finalized the initial public API for analysis settings: users can analyze one or multiple outcomes, choose a subset of methods, set the confidence level, control FCS/JM-MI computation, and supply either one reproducible seed or outcome-specific seeds.
* Polished `tbl_sensitivity()` with user-controlled decimal places, outcome/method labels, optional standard-error columns, captions, and gtsummary/data-frame output modes.
* Added `plot_sensitivity()` and `plot()` support for forest plots of method-specific estimates and confidence intervals, including outcome/method filtering, custom labels, configurable reference lines, and fixed or free facet scales.

* Upgraded `plot_sensitivity()` to the manuscript publication style, including the validated six-method palette, open method-specific symbols, horizontal confidence intervals, a dotted null line, and right-side coefficient/CI and p-value annotations.

* Completed numerical validation against the manuscript implementation for both MIDUS outcomes across all six methods.
* Added a synthetic example-data generator and a full Getting Started vignette.
* Refined publication forest plots for single- and multiple-outcome analyses, including portable font handling, outcome facet strips, customizable estimate labels, and manuscript-size export guidance.
* Updated README and package metadata for release-readiness review.
* Added runnable examples for the public API and focused regression tests for FCS-MI, JM-MI, IPW, and AIPW.
* Expanded R CMD check to Ubuntu, Windows, and macOS on current R, plus R-devel and R-oldrel-1 on Ubuntu.
* Verified installation and end-to-end execution from the built source tarball in a fresh R library and process.

* Prepared version 0.1.0 for public release, including the public GitHub repository, pkgdown documentation website, full R-devel source-package checks, and Windows checks on R-devel, R-release, and R-oldrelease.
