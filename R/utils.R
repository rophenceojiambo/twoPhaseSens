.failed_result <- function(method_name, msg) {
  data.frame(
    method = method_name,
    estimate = NA_real_,
    se = NA_real_,
    df = NA_real_,
    p_value = NA_real_,
    conf_low = NA_real_,
    conf_high = NA_real_,
    status = "failed",
    message = as.character(msg),
    stringsAsFactors = FALSE
  )
}

.rbind_fill <- function(x) {
  if (length(x) == 0L) return(data.frame())
  all_names <- unique(unlist(lapply(x, names), use.names = FALSE))
  x2 <- lapply(x, function(d) {
    missing <- setdiff(all_names, names(d))
    for (nm in missing) d[[nm]] <- NA
    d[, all_names, drop = FALSE]
  })
  out <- do.call(rbind, x2)
  rownames(out) <- NULL
  out
}

.with_preserved_seed <- function(seed, code) {
  if (is.null(seed)) return(force(code))

  if (
    length(seed) != 1L ||
      !is.numeric(seed) ||
      is.na(seed) ||
      !is.finite(seed) ||
      seed < 0 ||
      seed != floor(seed) ||
      seed > .Machine$integer.max
  ) {
    stop(
      "`seed` must resolve to one non-negative integer no larger than ",
      ".Machine$integer.max.",
      call. = FALSE
    )
  }

  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)

  on.exit({
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)

  set.seed(as.integer(seed))
  force(code)
}

.resolve_analysis_seeds <- function(seed, outcomes) {
  n_outcomes <- length(outcomes)

  if (is.null(seed)) {
    return(rep(NA_integer_, n_outcomes))
  }

  if (!is.numeric(seed) || anyNA(seed) || any(!is.finite(seed))) {
    stop(
      "`seed` must be NULL or a numeric vector of finite, non-missing values.",
      call. = FALSE
    )
  }

  if (
    any(seed < 0) ||
      any(seed != floor(seed)) ||
      any(seed > .Machine$integer.max)
  ) {
    stop(
      "Every supplied seed must be a non-negative integer no larger than ",
      ".Machine$integer.max.",
      call. = FALSE
    )
  }

  if (length(seed) == 1L) {
    last_seed <- seed + n_outcomes - 1L
    if (last_seed > .Machine$integer.max) {
      stop(
        "The scalar `seed` is too large to generate one sequential seed per outcome.",
        call. = FALSE
      )
    }
    return(as.integer(seed + seq_len(n_outcomes) - 1L))
  }

  if (length(seed) != n_outcomes) {
    stop(
      "When `seed` has more than one value, it must have exactly one value ",
      "per outcome.",
      call. = FALSE
    )
  }

  if (!is.null(names(seed))) {
    if (
      any(!nzchar(names(seed))) ||
        anyDuplicated(names(seed)) ||
        !setequal(names(seed), outcomes)
    ) {
      stop(
        "Named `seed` vectors must contain each outcome name exactly once.",
        call. = FALSE
      )
    }
    seed <- seed[match(outcomes, names(seed))]
  }

  as.integer(seed)
}

.normalize_methods <- function(methods) {
  if (is.null(methods) || length(methods) == 0L) {
    stop("`methods` must contain at least one method.", call. = FALSE)
  }

  if (!is.character(methods) || anyNA(methods) || any(!nzchar(methods))) {
    stop(
      "`methods` must be a non-missing character vector.",
      call. = FALSE
    )
  }

  key <- tolower(gsub("[- ]", "_", methods))
  lookup <- c(
    naive = "Naive",
    cca = "CCA",
    fcs_mi = "FCS-MI",
    jm_mi = "JM-MI",
    ipw = "IPW",
    aipw = "AIPW"
  )

  bad <- setdiff(key, names(lookup))
  if (length(bad) > 0L) {
    stop(
      "Unknown method(s): ",
      paste(methods[key %in% bad], collapse = ", "),
      ". Allowed methods are naive, cca, fcs_mi, jm_mi, ipw, aipw.",
      call. = FALSE
    )
  }

  resolved <- unname(lookup[key])

  if (anyDuplicated(resolved)) {
    stop(
      "`methods` must not contain duplicate methods.",
      call. = FALSE
    )
  }

  resolved
}

.format_p <- function(p, digits = 3L) {
  cutoff <- 10^(-digits)
  ifelse(
    is.na(p),
    "",
    ifelse(
      p < cutoff,
      paste0("<", formatC(cutoff, format = "f", digits = digits)),
      formatC(p, format = "f", digits = digits)
    )
  )
}
