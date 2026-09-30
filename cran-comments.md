## Test environments

* GitHub Actions:
  * Ubuntu, R release
  * Windows, R release
  * macOS, R release
  * Ubuntu, R-devel
  * Ubuntu, R-oldrel-1
* Full source-package check on Ubuntu with R-devel:
  * `R CMD check --as-cran twoPhaseSens_0.1.0.tar.gz`
  * 0 errors | 0 warnings | 0 notes
* Win-builder:
  * R-devel (Windows): 0 errors | 0 warnings | 1 note
  * R-release 4.6.1 (Windows): 0 errors | 0 warnings | 1 note
  * R-oldrelease 4.5.3 (Windows): 0 errors | 0 warnings | 1 note

The Win-builder NOTE in all three environments is the expected incoming-feasibility
message for a new submission:

```
New submission
```

## R CMD check results

There were no ERRORs or WARNINGs.

The only NOTE observed on Win-builder was the expected "New submission" NOTE
reported by CRAN incoming-feasibility checks.

## Downstream dependencies

This is a new submission, so there are no reverse dependencies to check.
