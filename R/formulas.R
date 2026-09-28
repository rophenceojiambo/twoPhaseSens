.make_formula <- function(response, terms) {
  stats::reformulate(termlabels = terms, response = response)
}

.full_formula <- function(phase1_names, marker_names) {
  .make_formula(".Y", c(".A", phase1_names, marker_names))
}

.naive_formula <- function(phase1_names) {
  .make_formula(".Y", c(".A", phase1_names))
}

.selection_matrix <- function(dat, phase1_names, include_y = TRUE) {
  terms <- c(".A", if (include_y) ".Y", phase1_names)
  stats::model.matrix(.make_formula(NULL, terms), data = dat)
}

.marker_predictor_matrix <- function(dat, phase1_names, include_y = TRUE) {
  terms <- c(".A", if (include_y) ".Y", phase1_names)
  stats::model.matrix(.make_formula(NULL, terms), data = dat)
}

.target_w_matrix <- function(dat, phase1_names) {
  stats::model.matrix(.make_formula(NULL, c(".A", phase1_names)), data = dat)
}
