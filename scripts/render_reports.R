#!/usr/bin/env Rscript

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("Package 'rmarkdown' is required. Restore the project environment first.")
}

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1) {
  stop("Run this renderer with Rscript.")
}

script_path <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
repo_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
analysis_dir <- file.path(repo_root, "02_RESULTS")
reports <- c(
  "file_drawer_analysis.Rmd",
  "file_drawer_exploratory_analysis.Rmd",
  "likert_sensitivity_analysis.Rmd"
)

missing_reports <- reports[!file.exists(file.path(analysis_dir, reports))]
if (length(missing_reports) > 0) {
  stop("Missing report source(s): ", paste(missing_reports, collapse = ", "))
}

old_dir <- setwd(analysis_dir)
on.exit(setwd(old_dir), add = TRUE)

for (report in reports) {
  message("Rendering ", report)
  rmarkdown::render(
    input = report,
    output_format = "all",
    clean = TRUE,
    envir = new.env(parent = globalenv())
  )
}

message("Rendered all reports.")
