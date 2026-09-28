#' Plot sensitivity-analysis estimates and confidence intervals
#'
#' Creates a publication-style forest plot from a [twophase_sensitivity()]
#' object. Each method is shown with a method-specific color and symbol,
#' horizontal confidence interval, and optional right-side text columns for the
#' formatted coefficient/CI and p value. With multiple outcomes, outcomes are
#' shown in separate facets.
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
#' @param annotate Logical; if `TRUE` (default), add manuscript-style
#'   right-side columns for the coefficient with confidence interval and p
#'   value.
#' @param estimate_digits Number of digits used in the coefficient and
#'   confidence-interval annotation.
#' @param p_digits Number of digits used in the p-value annotation.
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
  title = NULL,
  annotate = TRUE,
  estimate_digits = 3L,
  p_digits = 3L
) {
  if (!inherits(x, "twophase_sensitivity")) {
    stop("`x` must be a twophase_sensitivity object.", call. = FALSE)
  }

  facet_scales <- match.arg(facet_scales)
  .validate_plot_flag(annotate, "annotate")
  .validate_table_digits(estimate_digits, "estimate_digits")
  .validate_table_digits(p_digits, "p_digits")

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

  d$estimate_text <- sprintf(
    paste0("%.", estimate_digits, "f (%.", estimate_digits, "f to %.", estimate_digits, "f)"),
    d$estimate,
    d$conf_low,
    d$conf_high
  )
  d$p_text <- .format_p(d$p_value, digits = p_digits)

  method_colors <- .twophasesens_method_colors[methods]
  method_shapes <- .twophasesens_method_shapes[methods]
  method_linetypes <- .twophasesens_method_linetypes[methods]

  p <- ggplot2::ggplot(
    d,
    ggplot2::aes(
      x = estimate,
      y = method_display,
      color = method,
      shape = method
    )
  )

  if (!is.null(reference_line)) {
    p <- p + ggplot2::geom_vline(
      xintercept = reference_line,
      linetype = 3,
      linewidth = 0.55,
      color = "grey45"
    )
  }

  p <- p +
    ggplot2::geom_segment(
      ggplot2::aes(
        x = conf_low,
        xend = conf_high,
        y = method_display,
        yend = method_display,
        linetype = method
      ),
      linewidth = 0.8,
      show.legend = FALSE
    ) +
    ggplot2::geom_point(
      size = 3.0,
      stroke = 0.95,
      fill = "white"
    ) +
    ggplot2::scale_color_manual(
      values = method_colors,
      breaks = methods,
      labels = unname(method_display)
    ) +
    ggplot2::scale_shape_manual(
      values = method_shapes,
      breaks = methods,
      labels = unname(method_display)
    ) +
    ggplot2::scale_linetype_manual(values = method_linetypes) +
    ggplot2::labs(
      x = x_label,
      y = NULL,
      title = title,
      color = NULL,
      shape = NULL
    ) +
    ggplot2::theme_classic(base_size = 11) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(color = "black"),
      axis.text.x = ggplot2::element_text(color = "black"),
      axis.title.x = ggplot2::element_text(color = "black"),
      plot.title = ggplot2::element_text(face = "bold", hjust = 0),
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold", color = "black"),
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.box = "horizontal",
      legend.text = ggplot2::element_text(color = "black"),
      plot.margin = ggplot2::margin(5.5, 12, 5.5, 5.5)
    )

  if (isTRUE(annotate)) {
    ranges <- lapply(split(d, d$outcome_display), function(z) {
      vals <- c(z$conf_low, z$conf_high)
      span <- diff(range(vals, finite = TRUE))
      if (!is.finite(span) || span <= 0) {
        span <- max(abs(vals), na.rm = TRUE)
      }
      if (!is.finite(span) || span <= 0) {
        span <- 1
      }

      xmax <- max(vals, finite = TRUE)
      c(
        estimate_x = xmax + 0.22 * span,
        p_x = xmax + 0.86 * span,
        header_y = length(methods) + 0.55
      )
    })

    d$estimate_x <- vapply(
      as.character(d$outcome_display),
      function(z) ranges[[z]][["estimate_x"]],
      numeric(1)
    )
    d$p_x <- vapply(
      as.character(d$outcome_display),
      function(z) ranges[[z]][["p_x"]],
      numeric(1)
    )

    header <- data.frame(
      outcome_display = factor(unname(outcome_display), levels = unname(outcome_display)),
      method_display = factor(rep(NA_character_, length(outcomes)), levels = levels(d$method_display)),
      estimate_x = vapply(unname(outcome_display), function(z) ranges[[z]][["estimate_x"]], numeric(1)),
      p_x = vapply(unname(outcome_display), function(z) ranges[[z]][["p_x"]], numeric(1)),
      header_y = vapply(unname(outcome_display), function(z) ranges[[z]][["header_y"]], numeric(1)),
      stringsAsFactors = FALSE
    )

    p <- p +
      ggplot2::geom_text(
        data = d,
        ggplot2::aes(x = estimate_x, label = estimate_text),
        hjust = 0,
        color = "black",
        size = 3.25,
        inherit.aes = FALSE
      ) +
      ggplot2::geom_text(
        data = d,
        ggplot2::aes(x = p_x, label = p_text),
        hjust = 0,
        color = "black",
        size = 3.25,
        inherit.aes = FALSE
      ) +
      ggplot2::geom_text(
        data = header,
        ggplot2::aes(x = estimate_x, y = header_y, label = "Coefficient (95% CI)"),
        hjust = 0,
        vjust = 0,
        fontface = "bold",
        color = "black",
        size = 3.35,
        inherit.aes = FALSE
      ) +
      ggplot2::geom_text(
        data = header,
        ggplot2::aes(x = p_x, y = header_y, label = "P value"),
        hjust = 0,
        vjust = 0,
        fontface = "bold",
        color = "black",
        size = 3.35,
        inherit.aes = FALSE
      ) +
      ggplot2::coord_cartesian(clip = "off")
  }

  if (length(outcomes) > 1L) {
    p <- p + ggplot2::facet_wrap(
      ~ outcome_display,
      scales = facet_scales
    )
  }

  p
}

.validate_plot_flag <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop("`", arg, "` must be TRUE or FALSE.", call. = FALSE)
  }
  invisible(TRUE)
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
