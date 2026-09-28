#' Create a publication-ready sensitivity-analysis table
#'
#' Formats method-comparison results from [twophase_sensitivity()] with methods
#' in rows and one group of columns per outcome. By default, the function
#' returns a `gtsummary` object with outcome spanning headers. A plain data
#' frame can be requested for downstream custom formatting.
#'
#' @param x A `twophase_sensitivity` object.
#' @param estimate_digits Number of digits for estimates and confidence limits.
#' @param p_digits Number of digits for p values.
#' @param include_se Logical; include a separate standard-error column for each
#'   outcome.
#' @param method_labels Optional named character vector used to relabel methods.
#'   Names should be package method labels such as `"FCS-MI"` or `"AIPW"`.
#' @param outcome_labels Optional character vector used to relabel outcomes.
#'   Supply either a named vector whose names are the outcome variable names or
#'   an unnamed vector in the same order as `x$specification$outcome`.
#' @param caption Optional table caption. Markdown is supported for
#'   `output = "gtsummary"`.
#' @param output Output type: `"gtsummary"` (default) or `"data.frame"`.
#'
#' @return A `gtsummary` object by default, or a formatted data frame when
#'   `output = "data.frame"`.
#'
#' @export
tbl_sensitivity <- function(
  x,
  estimate_digits = 4L,
  p_digits = 3L,
  include_se = FALSE,
  method_labels = NULL,
  outcome_labels = NULL,
  caption = NULL,
  output = c("gtsummary", "data.frame")
) {
  if (!inherits(x, "twophase_sensitivity")) {
    stop("`x` must be a twophase_sensitivity object.", call. = FALSE)
  }

  output <- match.arg(output)

  .validate_table_digits(estimate_digits, "estimate_digits")
  .validate_table_digits(p_digits, "p_digits")

  results <- x$results
  methods <- x$specification$methods
  outcomes <- x$specification$outcome

  if (length(methods) == 0L || length(outcomes) == 0L) {
    stop("The analysis object contains no methods or outcomes.", call. = FALSE)
  }

  method_display <- .resolve_method_labels(methods, method_labels)
  outcome_display <- .resolve_outcome_labels(outcomes, outcome_labels)

  body <- data.frame(
    variable = rep("method", length(methods)),
    row_type = rep("level", length(methods)),
    label = unname(method_display),
    stringsAsFactors = FALSE
  )

  fmt <- paste0("%.", estimate_digits, "f")

  for (j in seq_along(outcomes)) {
    yy <- outcomes[[j]]
    d <- results[results$outcome == yy, , drop = FALSE]
    d <- d[match(methods, d$method), , drop = FALSE]

    if (nrow(d) != length(methods) || anyNA(d$method)) {
      stop(
        "The analysis object is missing one or more method results for outcome `",
        yy, "`.",
        call. = FALSE
      )
    }

    est_col <- paste0("estimate_", j)
    p_col <- paste0("p_", j)

    body[[est_col]] <- ifelse(
      d$status == "ok",
      sprintf(
        paste0(fmt, " (", fmt, " to ", fmt, ")"),
        d$estimate,
        d$conf_low,
        d$conf_high
      ),
      paste0("Failed: ", d$message)
    )

    if (isTRUE(include_se)) {
      se_col <- paste0("se_", j)
      body[[se_col]] <- ifelse(
        d$status == "ok",
        formatC(d$se, format = "f", digits = estimate_digits),
        ""
      )
    }

    body[[p_col]] <- ifelse(
      d$status == "ok",
      .format_p(d$p_value, digits = p_digits),
      ""
    )
  }

  if (identical(output, "data.frame")) {
    out <- data.frame(Method = body$label, stringsAsFactors = FALSE)

    for (j in seq_along(outcomes)) {
      label <- outcome_display[[j]]
      out[[paste0(label, " Coefficient (95% CI)")]] <- body[[paste0("estimate_", j)]]

      if (isTRUE(include_se)) {
        out[[paste0(label, " SE")]] <- body[[paste0("se_", j)]]
      }

      out[[paste0(label, " P value")]] <- body[[paste0("p_", j)]]
    }

    return(out)
  }

  tbl <- gtsummary::as_gtsummary(body)

  # Hide internal gtsummary bookkeeping columns and format the method column.
  tbl <- gtsummary::modify_table_styling(
    tbl,
    columns = c(1L, 2L),
    hide = TRUE
  )
  tbl <- gtsummary::modify_table_styling(
    tbl,
    columns = 3L,
    label = "**Method**",
    align = "left"
  )

  for (j in seq_along(outcomes)) {
    spanning <- paste0("**", outcome_display[[j]], "**")
    est_name <- paste0("estimate_", j)
    p_name <- paste0("p_", j)

    est_pos <- match(est_name, names(body))
    p_pos <- match(p_name, names(body))

    tbl <- gtsummary::modify_table_styling(
      tbl,
      columns = est_pos,
      label = "**Coefficient (95% CI)**",
      spanning_header = spanning,
      align = "center"
    )

    if (isTRUE(include_se)) {
      se_name <- paste0("se_", j)
      se_pos <- match(se_name, names(body))
      tbl <- gtsummary::modify_table_styling(
        tbl,
        columns = se_pos,
        label = "**SE**",
        spanning_header = spanning,
        align = "center"
      )
    }

    tbl <- gtsummary::modify_table_styling(
      tbl,
      columns = p_pos,
      label = "**P value**",
      spanning_header = spanning,
      align = "center"
    )
  }

  if (!is.null(caption)) {
    if (!is.character(caption) || length(caption) != 1L || is.na(caption)) {
      stop("`caption` must be NULL or one non-missing character string.", call. = FALSE)
    }
    tbl <- gtsummary::modify_caption(tbl, caption)
  }

  tbl
}

.validate_table_digits <- function(x, arg) {
  if (
    length(x) != 1L ||
      !is.numeric(x) ||
      is.na(x) ||
      !is.finite(x) ||
      x < 0 ||
      x != floor(x)
  ) {
    stop("`", arg, "` must be one non-negative integer.", call. = FALSE)
  }
  invisible(TRUE)
}

.resolve_method_labels <- function(methods, method_labels) {
  display <- methods

  if (is.null(method_labels)) {
    return(display)
  }

  if (!is.character(method_labels) || anyNA(method_labels)) {
    stop("`method_labels` must be NULL or a character vector.", call. = FALSE)
  }

  if (is.null(names(method_labels)) || any(!nzchar(names(method_labels)))) {
    stop(
      "`method_labels` must be a named character vector keyed by method name.",
      call. = FALSE
    )
  }

  unknown <- setdiff(names(method_labels), methods)
  if (length(unknown) > 0L) {
    stop(
      "Unknown method label name(s): ",
      paste(unknown, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  idx <- match(names(method_labels), methods)
  display[idx] <- unname(method_labels)
  display
}

.resolve_outcome_labels <- function(outcomes, outcome_labels) {
  if (is.null(outcome_labels)) {
    return(outcomes)
  }

  if (
    !is.character(outcome_labels) ||
      anyNA(outcome_labels) ||
      any(!nzchar(outcome_labels))
  ) {
    stop("`outcome_labels` must be NULL or a non-missing character vector.", call. = FALSE)
  }

  if (is.null(names(outcome_labels))) {
    if (length(outcome_labels) != length(outcomes)) {
      stop(
        "Unnamed `outcome_labels` must have the same length as the outcomes.",
        call. = FALSE
      )
    }
    display <- unname(outcome_labels)
  } else {
    if (any(!nzchar(names(outcome_labels)))) {
      stop("Named `outcome_labels` cannot contain empty names.", call. = FALSE)
    }

    unknown <- setdiff(names(outcome_labels), outcomes)
    if (length(unknown) > 0L) {
      stop(
        "Unknown outcome label name(s): ",
        paste(unknown, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    display <- outcomes
    idx <- match(names(outcome_labels), outcomes)
    display[idx] <- unname(outcome_labels)
  }

  if (anyDuplicated(display)) {
    stop("Outcome display labels must be unique.", call. = FALSE)
  }

  display
}
