#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

usage <- function() {
  cat(
    paste0(
      "\nUsage:\n",
      "  Rscript scripts/make_public_datasets.R <raw_full_answers.csv> [out_dir] [seed]\n\n",
      "Outputs (written to out_dir; default: 02_RESULTS/data_public):\n",
      "  - public_main.csv      (analysis-ready; no D4/D6/D8, no D12, no open text)\n",
      "  - public_geo_spec.csv  (decoupled + shuffled; D4/D6/D8 only)\n",
      "  - public_text.csv      (unlinked + shuffled; open-text fields except D12)\n\n",
      "Notes:\n",
      "  - Rows are shuffled independently across outputs to prevent record linkage.\n",
      "  - A fresh sequential id (1..N) is assigned in public_main.csv.\n"
    )
  )
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  usage()
  stop("Missing required argument: <raw_full_answers.csv>")
}

in_path <- args[[1]]
out_dir <- if (length(args) >= 2) args[[2]] else file.path("02_RESULTS", "data_public")
seed <- if (length(args) >= 3) as.integer(args[[3]]) else 20260209L

if (is.na(seed)) stop("Seed must be an integer.")

set.seed(seed)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

raw <- readr::read_csv(in_path, show_col_types = FALSE)

if (!"id" %in% names(raw)) {
  stop("Expected an 'id' column in the raw export (LimeSurvey-style export).")
}

meta_cols <- intersect(
  names(raw),
  c("id", "seed", "submitdate", "lastpage", "startlanguage", "startdate", "datestamp", "interviewtime")
)
time_cols <- names(raw)[str_detect(names(raw), "Time$")]

# Geo/spec columns (released separately, shuffled)
geo_cols <- intersect(names(raw), c("D4", "D6"))
d8_cols <- names(raw)[str_detect(names(raw), "^D8\\[")]
geo_spec_cols <- unique(c(geo_cols, d8_cols))

# Open-text columns (released separately, shuffled)
explicit_text_cols <- c(
  "D7[other]",
  "D9text",
  "D12",
  "S5part2other",
  "M2",
  "M2[other]",
  "H1[other]",
  "H2[other]",
  "H5",
  "S3[SQ001comment]",
  "S3[SQ002comment]",
  "S3[SQ003comment]",
  "S3[SQ004comment]",
  "S3[SQ005comment]",
  "S3[SQ006comment]"
)

pattern_text_cols <- names(raw)[
  str_detect(names(raw), "comment\\]$") |
    str_detect(names(raw), "\\[other\\]$") |
    str_detect(names(raw), "\\[Other\\]$")
]

text_cols <- unique(intersect(names(raw), c(explicit_text_cols, pattern_text_cols)))

# Redact D12 everywhere (public release)
text_cols <- setdiff(text_cols, "D12")

# Keep D8[other] only in the geo/spec file (so it does not sit next to H5 and other open text)
text_cols <- setdiff(text_cols, "D8[other]")

# ----- Build outputs -----
shuffle_rows <- function(df) df[sample.int(nrow(df)), , drop = FALSE]

public_geo_spec <- raw %>%
  select(any_of(geo_spec_cols)) %>%
  shuffle_rows()

public_text <- raw %>%
  select(any_of(text_cols)) %>%
  shuffle_rows()

drop_from_main <- unique(c(meta_cols, time_cols, geo_spec_cols, text_cols, "D12", "H5"))

public_main <- raw %>%
  select(-any_of(drop_from_main)) %>%
  shuffle_rows() %>%
  mutate(id = seq_len(n())) %>%
  select(id, everything())

# ----- Sanity checks -----
stop_if_present <- function(df, cols, where) {
  present <- intersect(names(df), cols)
  if (length(present) > 0) {
    stop(paste0("Unexpected columns present in ", where, ": ", paste(present, collapse = ", ")))
  }
}

stop_if_present(public_main, c("D4", "D6"), "public_main.csv")
stop_if_present(public_main, names(raw)[str_detect(names(raw), "^D8\\[")], "public_main.csv")
stop_if_present(public_main, c("D12", "H5"), "public_main.csv")

if ("id" %in% names(public_geo_spec)) stop("public_geo_spec.csv should not include 'id'.")
if ("id" %in% names(public_text)) stop("public_text.csv should not include 'id'.")

# ----- Light PII-ish scan (console only) -----
scan_patterns <- list(
  email = "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}",
  url = "https?://|www\\.",
  orcid = "\\b\\d{4}-\\d{4}-\\d{4}-\\d{3}[\\dX]\\b"
)

scan_text_cols <- intersect(names(raw), c(text_cols, "D8[other]"))
scan_blob <- raw %>%
  select(any_of(scan_text_cols)) %>%
  mutate(across(everything(), ~ if_else(is.na(.x), "", as.character(.x)))) %>%
  unite("all", everything(), sep = "\n", remove = TRUE) %>%
  pull(all) %>%
  paste(collapse = "\n")

cat("\nOpen-text scan (raw export; for your review):\n")
for (nm in names(scan_patterns)) {
  n_hits <- length(str_extract_all(scan_blob, regex(scan_patterns[[nm]], ignore_case = TRUE))[[1]])
  cat(sprintf("  - %s: %d\n", nm, n_hits))
}
cat("\n")

# ----- Write outputs -----
readr::write_csv(public_main, file.path(out_dir, "public_main.csv"), na = "")
readr::write_csv(public_geo_spec, file.path(out_dir, "public_geo_spec.csv"), na = "")
readr::write_csv(public_text, file.path(out_dir, "public_text.csv"), na = "")

cat("Wrote:\n")
cat("  - ", file.path(out_dir, "public_main.csv"), "\n", sep = "")
cat("  - ", file.path(out_dir, "public_geo_spec.csv"), "\n", sep = "")
cat("  - ", file.path(out_dir, "public_text.csv"), "\n", sep = "")
