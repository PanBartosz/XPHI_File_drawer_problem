#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1) {
  stop("Run this validator with Rscript.")
}

script_path <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
repo_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
data_dir <- file.path(repo_root, "02_RESULTS", "data_public")

read_public_csv <- function(filename) {
  path <- file.path(data_dir, filename)
  if (!file.exists(path)) stop("Missing public dataset: ", path)
  read.csv(path, check.names = FALSE, stringsAsFactors = FALSE, na.strings = "")
}

assert <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}

main <- read_public_csv("public_main.csv")
geo <- read_public_csv("public_geo_spec.csv")
text <- read_public_csv("public_text.csv")

expected_n <- 50L
datasets <- list(main = main, geo = geo, text = text)
for (label in names(datasets)) {
  data <- datasets[[label]]
  assert(nrow(data) == expected_n, sprintf("%s must contain %d rows.", label, expected_n))
}

assert(identical(main$id, seq_len(expected_n)), "public_main.csv must have sequential IDs 1..50.")
assert(!"id" %in% names(geo), "public_geo_spec.csv must not contain an ID.")
assert(!"id" %in% names(text), "public_text.csv must not contain an ID.")

metadata_cols <- c(
  "seed", "submitdate", "lastpage", "startlanguage", "startdate",
  "datestamp", "interviewtime"
)
timing_cols <- names(main)[
  grepl("(^groupTime)|Time$", names(main), ignore.case = TRUE, perl = TRUE)
]
assert(
  length(intersect(names(main), metadata_cols)) == 0,
  "public_main.csv contains raw LimeSurvey metadata."
)
assert(
  length(timing_cols) == 0,
  paste("public_main.csv contains timing columns:", paste(timing_cols, collapse = ", "))
)

geo_cols <- c("D4", "D6", paste0("D8[SQ", sprintf("%03d", 1:11), "]"), "D8[other]")
assert(
  setequal(names(geo), geo_cols),
  "public_geo_spec.csv does not contain the expected geo/specialization fields."
)
assert(
  length(intersect(names(main), geo_cols)) == 0,
  "Geo/specialization fields are linked to public_main.csv."
)

text_cols <- c(
  "D7[other]", "D9text", paste0("S3[SQ", sprintf("%03d", 1:6), "comment]"),
  "S5part2other", "M2[other]", "H1[other]", "H2[other]", "H5"
)
assert(
  setequal(names(text), text_cols),
  "public_text.csv does not contain the expected open-text fields."
)
assert(
  length(intersect(names(main), c(text_cols, "D12"))) == 0,
  "Open-text fields are linked to public_main.csv."
)
assert(!"D12" %in% names(text), "The excluded D12 field is present in public_text.csv.")

assert("data_shared_ever" %in% names(main), "Missing derived data_shared_ever field.")
sharing_counts <- table(main$data_shared_ever, useNA = "ifany")
assert(
  identical(as.integer(sharing_counts[c("No", "Yes")]), c(7L, 43L)) &&
    !anyNA(main$data_shared_ever),
  "data_shared_ever must contain 7 No and 43 Yes responses with no missing values."
)

scan_data <- c(unlist(geo["D8[other]"], use.names = FALSE), unlist(text, use.names = FALSE))
scan_data <- paste(scan_data[!is.na(scan_data)], collapse = "\n")
pii_patterns <- c(
  email = "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}",
  orcid = "\\b\\d{4}-\\d{4}-\\d{4}-\\d{3}[\\dX]\\b"
)
for (label in names(pii_patterns)) {
  assert(
    !grepl(pii_patterns[[label]], scan_data, ignore.case = TRUE, perl = TRUE),
    sprintf("Potential %s found in public open-text data; review manually.", label)
  )
}

cat("Public-release validation passed.\n")
cat(sprintf("  public_main.csv: %d rows, %d columns\n", nrow(main), ncol(main)))
cat(sprintf("  public_geo_spec.csv: %d rows, %d columns\n", nrow(geo), ncol(geo)))
cat(sprintf("  public_text.csv: %d rows, %d columns\n", nrow(text), ncol(text)))
cat("  data_shared_ever: 7 No, 43 Yes\n")
