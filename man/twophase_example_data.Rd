\name{twophase_example_data}
\alias{twophase_example_data}
\title{Generate a synthetic two-phase example dataset}
\usage{
twophase_example_data(n = 300L, seed = 2026L)
}
\arguments{
  \item{n}{Number of observations. Must be an integer greater than or equal to 80.}
  \item{seed}{Non-negative integer seed used only while generating the example data. The caller's pre-existing global random-number state is restored.}
}
\value{
A data frame containing two continuous outcomes, one continuous exposure, two
Phase-1 covariates, three continuous Phase-2 covariates, and a binary Phase-2
indicator.
}
\description{
Creates a small reproducible dataset for examples, teaching, and package
documentation. Phase-1 variables are fully observed, while the continuous
Phase-2 covariates are observed as a complete block only when \code{phase2 = 1}.
The generated data are synthetic and are not derived from MIDUS or any other
participant-level study data.
}
\examples{
dat <- twophase_example_data(n = 200, seed = 2026)
head(dat)
table(dat$phase2)
}
