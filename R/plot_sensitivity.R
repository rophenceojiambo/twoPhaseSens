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
#'   `estimate_label` and the confidence level stored in the analysis object.
#' @param estimate_label Label used for the numeric estimate column. The default
#'   is `"Coefficient"`. For a manuscript that reports adjusted betas, for
#'   example, use `estimate_label = "Adjusted beta"`.
#' @param title Optional overall plot title. Outcome labels are shown in facet
#'   strips, including when a single outcome is plotted.
#' @param annotate Logical; if `TRUE` (default), add manuscript-style
#'   right-side columns for the coefficient with confidence interval and p
#'   value.
#' @param estimate_digits Number of digits used in the coefficient and
#'   confidence-interval annotation.
#' @param p_digits Number of digits used in the p-value annotation.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' dat <- twophase_example_data(n = 200, seed = 2026)
#' fit <- twophase_sensitivity(
#'   data = dat,
#'   outcome = "outcome1",
#'   exposure = "exposure",
#'   covariates = c("age", "sex"),
#'   phase2_covariates = c("marker1", "marker2", "marker3"),
#'   phase2 = "phase2",
#'   methods = c("naive", "cca", "ipw"),
#'   seed = 1001
#' )
#' plot_sensitivity(fit, outcome_labels = c(outcome1 = "Outcome 1"))
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
  estimate_label = "Coefficient",
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

  if (
    !is.character(estimate_label) ||
      length(estimate_label) != 1L ||
      is.na(estimate_label) ||
      !nzchar(estimate_label)
  ) {
    stop("`estimate_label` must be one non-empty character string.", call. = FALSE)
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

  conf_pct <- 100 * x$settings$conf_level
  conf_text <- if (abs(conf_pct - round(conf_pct)) < sqrt(.Machine$double.eps)) {
    format(round(conf_pct), trim = TRUE, scientific = FALSE)
  } else {
    format(conf_pct, trim = TRUE, scientific = FALSE)
  }

  if (is.null(x_label)) {
    x_label <- paste0(estimate_label, " (", conf_text, "% CI)")
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

  base_data <- d[d$method != "AIPW", , drop = FALSE]
  aipw_data <- d[d$method == "AIPW", , drop = FALSE]

  p <- ggplot2::ggplot(
    d,
    ggplot2::aes(
      x = .data$estimate,
      y = .data$method_display,
      color = .data$method
    )
  )

  if (!is.null(reference_line)) {
    p <- p + ggplot2::geom_vline(
      xintercept = reference_line,
      linetype = "dotted",
      linewidth = 0.65,
      color = "grey20"
    )
  }

  p <- p +
    ggplot2::geom_segment(
      ggplot2::aes(
        x = .data$conf_low,
        xend = .data$conf_high,
        y = .data$method_display,
        yend = .data$method_display
      ),
      linewidth = 0.85
    ) +
    ggplot2::geom_point(
      data = base_data,
      ggplot2::aes(
        shape = .data$method,
        fill = .data$method
      ),
      size = 3.4,
      stroke = 1.15
    )

  if (nrow(aipw_data) > 0L) {
    p <- p +
      ggplot2::geom_point(
        data = aipw_data,
        shape = 21,
        color = "white",
        fill = "white",
        size = 4.5,
        stroke = 0,
        show.legend = FALSE
      ) +
      ggplot2::geom_point(
        data = aipw_data,
        ggplot2::aes(shape = .data$method),
        size = 3.6,
        stroke = 1.20,
        show.legend = TRUE
      )
  }

  p <- p +
    ggplot2::scale_color_manual(
      values = method_colors,
      breaks = methods,
      limits = methods,
      labels = unname(method_display),
      drop = FALSE
    ) +
    ggplot2::scale_fill_manual(
      values = stats::setNames(rep("white", length(methods)), methods),
      breaks = methods,
      limits = methods,
      drop = FALSE
    ) +
    ggplot2::scale_shape_manual(
      values = method_shapes,
      breaks = methods,
      limits = methods,
      labels = unname(method_display),
      drop = FALSE
    ) +
    ggplot2::guides(
      color = ggplot2::guide_legend(
        nrow = 1,
        byrow = TRUE,
        label.position = "right",
        override.aes = list(
          shape = unname(method_shapes),
          fill = rep("white", length(methods)),
          linewidth = rep(1.0, length(methods)),
          size = rep(3.8, length(methods))
        )
      ),
      fill = "none",
      shape = "none"
    ) +
    ggplot2::labs(
      x = x_label,
      y = NULL,
      title = title,
      color = NULL
    ) +
    ggplot2::theme_bw(
      base_size = 12
    ) +
    ggplot2::theme(
      text = ggplot2::element_text(
        colour = "black"
      ),
      plot.title = ggplot2::element_text(
        face = "bold",
        hjust = 0,
        colour = "black"
      ),
      strip.background = ggplot2::element_rect(
        fill = "grey94",
        color = "grey35",
        linewidth = 0.55
      ),
      strip.text = ggplot2::element_text(
        size = 10.4,
        colour = "black"
      ),
      panel.border = ggplot2::element_rect(
        color = "grey35",
        linewidth = 0.55
      ),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.title = ggplot2::element_text(
        size = 12.2,
        colour = "black"
      ),
      axis.text = ggplot2::element_text(
        size = 10.5,
        colour = "black"
      ),
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.box = "horizontal",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(
        size = 10.2,
        colour = "black"
      ),
      legend.key.width = grid::unit(1.45, "lines"),
      legend.spacing.x = grid::unit(0.20, "cm"),
      legend.margin = ggplot2::margin(t = 2, b = 0),
      panel.spacing.x = grid::unit(
        if (length(outcomes) > 1L) 1.25 else 0.5,
        "lines"
      ),
      plot.margin = ggplot2::margin(
        7,
        if (isTRUE(annotate) && length(outcomes) > 1L) 24 else 16,
        4,
        8
      )
    )


  graph_breaks <- pretty(
    range(c(d$conf_low, d$conf_high, reference_line), finite = TRUE),
    n = 5
  )

  if (isTRUE(annotate)) {
    make_panel_layout <- function(z, multi_panel = FALSE) {
      graph_min <- min(c(z$conf_low, reference_line), na.rm = TRUE)
      graph_max <- max(z$conf_high, na.rm = TRUE)
      graph_span <- graph_max - graph_min

      if (!is.finite(graph_span) || graph_span <= 0) {
        graph_span <- max(abs(c(graph_min, graph_max)), na.rm = TRUE)
      }
      if (!is.finite(graph_span) || graph_span <= 0) {
        graph_span <- 1
      }

      if (multi_panel) {
        # Multi-outcome panels need substantially more reserved x-space for
        # the estimate/CI and p-value columns. These offsets are deliberately
        # generous so annotation text stays inside its own facet rather than
        # colliding with the next facet.
        estimate_offset <- 0.18
        p_offset <- 1.65
        panel_offset <- 2.12
      } else {
        estimate_offset <- 0.22
        p_offset <- 0.72
        panel_offset <- 0.95
      }

      c(
        graph_min = graph_min - 0.05 * graph_span,
        graph_max = graph_max + 0.05 * graph_span,
        estimate_x = graph_max + estimate_offset * graph_span,
        p_x = graph_max + p_offset * graph_span,
        panel_max = graph_max + panel_offset * graph_span
      )
    }

    if (facet_scales == "fixed" && length(outcomes) > 1L) {
      common_layout <- make_panel_layout(d, multi_panel = TRUE)
      panel_layout <- stats::setNames(
        rep(list(common_layout), length(outcome_display)),
        unname(outcome_display)
      )
    } else {
      panel_layout <- lapply(
        split(d, d$outcome_display),
        make_panel_layout,
        multi_panel = length(outcomes) > 1L
      )
    }

    annotation_size <- if (length(outcomes) > 1L) 2.55 else 3.00
    header_size <- if (length(outcomes) > 1L) 2.65 else 3.05

    d$estimate_x <- vapply(
      as.character(d$outcome_display),
      function(z) panel_layout[[z]][["estimate_x"]],
      numeric(1)
    )
    d$p_x <- vapply(
      as.character(d$outcome_display),
      function(z) panel_layout[[z]][["p_x"]],
      numeric(1)
    )
    d$panel_max <- vapply(
      as.character(d$outcome_display),
      function(z) panel_layout[[z]][["panel_max"]],
      numeric(1)
    )

    blank_data <- data.frame(
      outcome_display = factor(
        unname(outcome_display),
        levels = unname(outcome_display)
      ),
      method_display = factor(
        rep(unname(method_display)[length(method_display)], length(outcomes)),
        levels = levels(d$method_display)
      ),
      x = vapply(
        unname(outcome_display),
        function(z) panel_layout[[z]][["panel_max"]],
        numeric(1)
      ),
      stringsAsFactors = FALSE
    )

    header <- data.frame(
      outcome_display = factor(
        unname(outcome_display),
        levels = unname(outcome_display)
      ),
      method_display = factor(
        rep(unname(method_display)[1L], length(outcomes)),
        levels = levels(d$method_display)
      ),
      estimate_x = vapply(
        unname(outcome_display),
        function(z) panel_layout[[z]][["estimate_x"]],
        numeric(1)
      ),
      p_x = vapply(
        unname(outcome_display),
        function(z) panel_layout[[z]][["p_x"]],
        numeric(1)
      ),
      stringsAsFactors = FALSE
    )

    p <- p +
      ggplot2::geom_blank(
        data = blank_data,
        ggplot2::aes(
          x = .data$x,
          y = .data$method_display
        ),
        inherit.aes = FALSE
      ) +
      ggplot2::geom_text(
        data = d,
        ggplot2::aes(
          x = .data$estimate_x,
          y = .data$method_display,
          label = .data$estimate_text
        ),
        hjust = 0,
        color = "black",
        size = annotation_size,
        inherit.aes = FALSE
      ) +
      ggplot2::geom_text(
        data = d,
        ggplot2::aes(
          x = .data$p_x,
          y = .data$method_display,
          label = .data$p_text
        ),
        hjust = 0,
        color = "black",
        size = annotation_size,
        inherit.aes = FALSE
      ) +
      ggplot2::geom_text(
        data = header,
        ggplot2::aes(
          x = .data$estimate_x,
          y = .data$method_display,
          label = paste0(estimate_label, " (", conf_text, "% CI)")
        ),
        hjust = 0,
        vjust = -1.55,
        fontface = "bold",
        color = "black",
        size = header_size,
        inherit.aes = FALSE
      ) +
      ggplot2::geom_text(
        data = header,
        ggplot2::aes(
          x = .data$p_x,
          y = .data$method_display,
          label = "P value"
        ),
        hjust = 0,
        vjust = -1.55,
        fontface = "bold",
        color = "black",
        size = header_size,
        inherit.aes = FALSE
      )
  }


  p <- p +
    ggplot2::scale_x_continuous(
      breaks = graph_breaks,
      labels = function(z) format(z, trim = TRUE, scientific = FALSE)
    )

  p <- p + ggplot2::facet_wrap(
    ~ outcome_display,
    scales = facet_scales,
    nrow = if (length(outcomes) <= 2L) 1L else NULL
  )

  if (isTRUE(annotate)) {
    p <- p + ggplot2::coord_cartesian(clip = "off")
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
#' @rdname plot_sensitivity
#' @param x A `twophase_sensitivity` object.
#' @param ... Arguments passed to [plot_sensitivity()].
#' @export
plot.twophase_sensitivity <- function(x, ...) {
  plot_sensitivity(x, ...)
}
