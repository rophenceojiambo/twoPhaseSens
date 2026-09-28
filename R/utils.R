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
  if (length(seed) != 1L || is.na(seed) || !is.finite(seed)) {
    stop("`seed` must be NULL or one finite numeric value.", call. = FALSE)
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

.normalize_methods <- function(methods) {
  if (is.null(methods) || length(methods) == 0L) {
    stop("`methods` must contain at least one method.", call. = FALSE)
  }
  key <- tolower(gsub("[- ]", "_", methods))
  lookup <- c(naive="Naive", cca="CCA", fcs_mi="FCS-MI", jm_mi="JM-MI", ipw="IPW", aipw="AIPW")
  bad <- setdiff(key, names(lookup))
  if (length(bad) > 0L) {
    stop("Unknown method(s): ", paste(methods[key %in% bad], collapse=", "),
         ". Allowed methods are naive, cca, fcs_mi, jm_mi, ipw, aipw.", call.=FALSE)
  }
  unname(lookup[key])
}

.format_p <- function(p, digits = 3L) {
  cutoff <- 10^(-digits)
  ifelse(is.na(p), "",
    ifelse(p < cutoff,
      paste0("<", formatC(cutoff, format="f", digits=digits)),
      formatC(p, format="f", digits=digits)))
}
