# Render publications.bib as grouped HTML for publications.qmd.
#
# BibTeX conventions (see .scratch/website-v1/issues/05-export-bibtex.md):
#   @article          -> Journal articles
#   @inproceedings    -> Conference papers
#   @incollection / @inbook -> Book chapters
#   @unpublished / @misc    -> Preprints & working papers
#   pubstate = {underreview}  any entry: shown as "Under review", venue hidden
#   selected = {true}         highlighted with a "Selected" badge
#   pdf / code / data / url / doi   become link buttons

library(bibtex)
library(htmltools)

.groups <- list(
  "Journal articles"            = c("article"),
  "Preprints & working papers"  = c("unpublished", "misc", "techreport"),
  "Conference papers"           = c("inproceedings", "conference"),
  "Book chapters"               = c("incollection", "inbook", "book")
)

.clean <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x[1])) return(NULL)
  x <- gsub("[{}]", "", x[1])
  x <- gsub("\\&", "&", x, fixed = TRUE)
  x <- gsub("--", "–", x, fixed = TRUE)
  trimws(gsub("\\s+", " ", x))
}

.field <- function(e, name) .clean(unclass(e)[[1]][[name]])

.authors <- function(e, me_family, me_given_initial) {
  ps <- e$author
  if (is.null(ps)) return("")
  out <- vapply(seq_along(ps), function(i) {
    p <- ps[i]
    given  <- .clean(paste(p$given, collapse = " ")) %||% ""
    family <- .clean(paste(p$family, collapse = " ")) %||% ""
    nm <- htmlEscape(trimws(paste(given, family)))
    is_me <- tolower(family) == tolower(me_family) &&
      startsWith(toupper(given), toupper(me_given_initial))
    if (is_me) paste0("<strong>", nm, "</strong>") else nm
  }, character(1))
  if (length(out) > 2) paste0(paste(out[-length(out)], collapse = ", "), ", and ", out[length(out)])
  else paste(out, collapse = " and ")
}

`%||%` <- function(a, b) if (is.null(a)) b else a

.venue <- function(e, type) {
  v <- switch(type,
    article       = .field(e, "journal"),
    inproceedings = , conference = .field(e, "booktitle"),
    incollection  = , inbook = .field(e, "booktitle"),
    book          = .field(e, "publisher"),
    .field(e, "howpublished") %||% .field(e, "institution") %||% .field(e, "note")
  )
  if (is.null(v)) return("")
  extra <- c(
    if (!is.null(.field(e, "volume"))) paste0(.field(e, "volume"),
      if (!is.null(.field(e, "number"))) paste0("(", .field(e, "number"), ")") else ""),
    .field(e, "pages")
  )
  paste0("<em>", htmlEscape(v), "</em>", if (length(extra)) paste0(", ", paste(extra, collapse = ", ")) else "")
}

.links <- function(e) {
  doi <- .field(e, "doi")
  l <- list(
    PDF  = .field(e, "pdf"),
    DOI  = if (!is.null(doi)) paste0("https://doi.org/", doi),
    Code = .field(e, "code"),
    Data = .field(e, "data"),
    Link = if (is.null(doi)) .field(e, "url")
  )
  l <- Filter(Negate(is.null), l)
  if (!length(l)) return("")
  paste0('<span class="pub-links">',
    paste0('<a class="btn btn-sm btn-outline-primary" href="', vapply(l, htmlEscape, "", attribute = TRUE),
           '">', names(l), "</a>", collapse = " "),
    "</span>")
}

.entry_html <- function(e, me_family, me_given_initial) {
  type     <- tolower(attr(unclass(e)[[1]], "bibtype"))
  review   <- identical(tolower(.field(e, "pubstate") %||% ""), "underreview")
  selected <- identical(tolower(.field(e, "selected") %||% ""), "true")
  year     <- .field(e, "year") %||% ""
  venue    <- if (review) "<em>Under review</em>" else .venue(e, type)
  # pubstate = {inpress}  -> ", in press";  addendum = {...} -> free-text suffix
  if (identical(tolower(.field(e, "pubstate") %||% ""), "inpress")) venue <- paste0(venue, ", in press")
  if (!is.null(.field(e, "addendum"))) venue <- paste0(venue, ". ", htmlEscape(.field(e, "addendum")))
  paste0(
    '<li class="pub', if (selected) " pub-selected", '">',
    if (selected) '<span class="badge bg-primary pub-badge">Selected</span> ' else "",
    .authors(e, me_family, me_given_initial),
    if (review || !nzchar(year)) ". " else paste0(" (", htmlEscape(year), "). "),
    '<span class="pub-title">', htmlEscape(.field(e, "title") %||% ""), ".</span> ",
    venue, if (nzchar(venue)) ". " else "",
    .links(e),
    "</li>"
  )
}

render_publications <- function(bib = "publications.bib",
                                me_family = "Peng", me_given_initial = "Z") {
  if (!file.exists(bib)) {
    cat("*Publication list coming soon.*\n")
    return(invisible())
  }
  entries <- bibtex::read.bib(bib)
  types   <- vapply(entries, function(e) tolower(attr(unclass(e)[[1]], "bibtype")), "")
  review  <- vapply(entries, function(e) identical(tolower(.field(e, "pubstate") %||% ""), "underreview"), TRUE)
  years   <- suppressWarnings(as.numeric(vapply(entries, function(e) .field(e, "year") %||% "0", "")))

  for (g in names(.groups)) {
    # under-review items always go to the preprints/working-papers group
    in_g <- if (g == "Preprints & working papers") (types %in% .groups[[g]]) | review
            else (types %in% .groups[[g]]) & !review
    idx <- which(in_g)
    if (!length(idx)) next
    idx <- idx[order(-review[idx], -years[idx])]   # under review first, then newest
    cat("\n## ", g, "\n\n", sep = "")
    cat('<ol class="pub-list" reversed>\n')
    for (i in idx) cat(.entry_html(entries[i], me_family, me_given_initial), "\n")
    cat("</ol>\n")
  }
}
