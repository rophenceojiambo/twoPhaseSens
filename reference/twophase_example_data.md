# Generate a synthetic two-phase example dataset

Creates a small reproducible dataset for examples, teaching, and package
documentation. Phase-1 variables are fully observed, while the
continuous Phase-2 covariates are observed as a complete block only when
`phase2 = 1`.

## Usage

``` r
twophase_example_data(n = 300L, seed = 2026L)
```

## Arguments

- n:

  Number of observations.

- seed:

  Non-negative integer seed used only while generating the example data.
  The caller's pre-existing global random-number state is restored.

## Value

A data frame containing two continuous outcomes, one continuous
exposure, two Phase-1 covariates, three continuous Phase-2 covariates,
and a binary Phase-2 indicator.

## Details

The generated data are synthetic and are not derived from MIDUS or any
other participant-level study data.

## Examples

``` r
dat <- twophase_example_data(n = 200, seed = 2026)
head(dat)
#>     outcome1   outcome2   exposure         age    sex    marker1   marker2
#> 1  1.0809044 -1.2127139 -0.1485921  0.52058907 Female  1.0616969 1.4032274
#> 2  0.5368305 -1.8684702 -0.1829528 -1.07969076 Female         NA        NA
#> 3 -1.7443100  1.5099704 -0.8581478  0.13923812 Female -0.5965252 0.4332663
#> 4 -0.2190353  0.5948272  0.9581592 -0.08474878   Male  1.6333122 0.1232512
#> 5 -1.2190707 -0.6202255 -0.8390769 -0.66663962   Male -0.4828975 0.3933460
#> 6 -0.4671825 -0.5664140 -0.7597243 -2.51608903   Male         NA        NA
#>      marker3 phase2
#> 1  0.4124320      1
#> 2         NA      0
#> 3 -0.7204078      1
#> 4  1.3222128      1
#> 5  0.6419675      1
#> 6         NA      0
table(dat$phase2)
#> 
#>   0   1 
#>  74 126 
```
