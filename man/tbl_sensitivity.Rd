\name{tbl_sensitivity}
\alias{tbl_sensitivity}
\title{Create a sensitivity-analysis comparison table}
\usage{
tbl_sensitivity(
  x,
  estimate_digits = 4L,
  p_digits = 3L,
  include_se = FALSE,
  method_labels = NULL
)
}
\arguments{
  \item{x}{A \code{twophase_sensitivity} object.}
  \item{estimate_digits}{Digits for estimates and confidence limits.}
  \item{p_digits}{Digits for p values.}
  \item{include_se}{Include a separate standard-error column for each outcome.}
  \item{method_labels}{Optional named character vector for method labels.}
}
\value{
A data frame with methods in rows and outcome-specific result columns.
}
\description{
Formats the results of a \code{twophase_sensitivity} analysis into a
method-comparison table.
}
