#' Plot sensitivity-analysis estimates and confidence intervals
#'
#' Creates a forest plot from a [twophase_sensitivity()] object. Each method is
#' displayed as a point estimate with its stored confidence interval. With
#' multiple outcomes, outcomes are shown in separate facets.
#'
#' @param x A `twophase_sensitivity` object.
#' @param outcome Optional character vector selecting one or more outcomes.
#' @param method Optional character vector selecting one or more methods.
#' @param outcome_labels Optional character vector used to relabel outcomes.
#'   Supply either a named vector whose names are the outcome variable names or
#'   an unnamed vector in the same order as the selected outcomes.
#' @param method_labels Optional named character vector used to relabel methods.
#' @param reference_line Numeric scalar giving the vertical reference line.
#'   Use `NULL` to omit the line. The default is 0.
#' @param facet_scales Facet x-axis scaling for multiple outcomes:
#'   `"free_x"` (default) or `"fixed"`.
#' @param x_label Optional x-axis label. If `NULL`, a label is generated from
#'   the confidence level stored in the analysis object.
#' @param title Optional plot title.
#'
#' @return A `ggplot` object.
#'
#' @export
plot_sensitivity <- function(
  x,
  outcome = NULL,
  method = NULL,
  outcome_labels = NULL,
  method_labels = NULL,
  reference_line = 0,
  facet_scales = c("free_x", "fixed"),
  x_label = NULL,
  title = NULL
) {
  if (!inherits(x, "twophase_sensitivity")) {
    stop("`x` must be a twophase_sensitivity object.", call. = FALSE)
  }

  facet_scales <- match.arg(facet_scales)

  outcomes <- x$specification$outcome
  methods <- x$specification$methods

  if (!is.null(outcome)) {
    if (!is.character(outcome) || anyNA(outcome) || any(!nzchar(outcome))) {
      stop("`outcome` must be NULL or a non-missing character vector.", call. = FALSE)
    }

    unknown_outcomes <- setdiff(outcome, outcomes)
    if (length(unknown_outcomes) > 0L) {
      stop(
        "Unknown outcome(s): ",
        paste(unknown_outcomes, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    outcomes <- outcomes[outcomes %in% outcome]
  }

  if (!is.null(method)) {
    method_resolved <- .normalize_methods(method)

    unavailable <- setdiff(method_resolved, methods)
    if (length(unavailable) > 0L) {
      stop(
        "Requested method(s) were not run in this analysis: ",
        paste(unavailable, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    methods <- methods[methods %in% method_resolved]
  }

  if (length(outcomes) == 0L || length(methods) == 0L) {
    stop("No outcomes or methods remain after filtering.", call. = FALSE)
  }

  if (!is.null(reference_line)) {
    if (
      length(reference_line) != 1L ||
        !is.numeric(reference_line) ||
        is.na(reference_line) ||
        !is.finite(reference_line)
    ) {
      stop("`reference_line` must be NULL or one finite numeric value.", call. = FALSE)
    }
  }

  if (!is.null(x_label) && (
    !is.character(x_label) ||
      length(x_label) != 1L ||
      is.na(x_label)
  )) {
    stop("`x_label` must be NULL or one non-missing character string.", call. = FALSE)
  }

  if (!is.null(title) && (
    !is.character(title) ||
      length(title) != 1L ||
      is.na(title)
  )) {
    stop("`title` must be NULL or one non-missing character string.", call. = FALSE)
  }

  d <- x$results[
    x$results$outcome %in% outcomes &
      x$results$method %in% methods,
    ,
    drop = FALSE
  ]

  failed <- d$status != "ok"
  if (any(failed)) {
    warning(
      sum(failed),
      " failed method result(s) were omitted from the forest plot.",
      call. = FALSE
    )
    d <- d[!failed, , drop = FALSE]
  }

  if (nrow(d) == 0L) {
    stop("No successful method results are available to plot.", call. = FALSE)
  }

  outcome_display <- .resolve_outcome_labels(outcomes, outcome_labels)
  method_display <- .resolve_method_labels(methods, method_labels)

  outcome_map <- stats::setNames(outcome_display, outcomes)
  method_map <- stats::setNames(method_display, methods)

  d$outcome_display <- unname(outcome_map[d$outcome])
  d$method_display <- unname(method_map[d$method])

  # Reverse factor levels so the first requested method appears at the top.
  d$method_display <- factor(
    d$method_display,
    levels = rev(unname(method_display))
  )

  d$outcome_display <- factor(
    d$outcome_display,
    levels = unname(outcome_display)
  )

  if (is.null(x_label)) {
    conf_pct <- 100 * x$settings$conf_level
    conf_text <- if (abs(conf_pct - round(conf_pct)) < sqrt(.Machine$double.eps)) {
      format(round(conf_pct), trim = TRUE, scientific = FALSE)
    } else {
      format(conf_pct, trim = TRUE, scientific = FALSE)
    }

    x_label <- paste0("Coefficient (", conf_text, "% CI)")
  }

  p <- ggplot2::ggplot(
    d,
    ggplot2::aes(
      x = estimate,
      y = method_display
    )
  )

  if (!is.null(reference_line)) {
    p <- p + ggplot2::geom_vline(
      xintercept = reference_line,
      linetype = 2
    )
  }

  p <- p +
    ggplot2::geom_segment(
      ggplot2::aes(
        x = conf_low,
        xend = conf_high,
        y = method_display,
        yend = method_display
      ),
      linewidth = 0.7
    ) +
    ggplot2::geom_point(size = 2.4) +
    ggplot2::labs(
      x = x_label,
      y = NULL,
      title = title
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(),
      strip.text = ggplot2::element_text(face = "bold")
    )

  if (length(outcomes) > 1L) {
    p <- p + ggplot2::facet_wrap(
      ~ outcome_display,
      scales = facet_scales
    )
  }

  p
}

#' Plot a twophase_sensitivity object
#'
#' @param x A `twophase_sensitivity` object.
#' @param ... Arguments passed to [plot_sensitivity()].
#'
#' @return A `ggplot` object.
#' @export
plot.twophase_sensitivity <- function(x, ...) {
  plot_sensitivity(x, ...)
}
