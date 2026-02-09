# The file drawer problem in experimental philosophy: what is not published and why?

This repository contains materials for the project *"The file drawer problem in experimental philosophy: what is not published and why?"* (OSF: https://osf.io/6xn27/).

## Repository structure

- `01_SURVEY/` – survey materials (LimeSurvey export + PDFs).
- `02_RESULTS/` – analysis code + rendered reports.
  - `file_drawer_analysis.Rmd` (+ `file_drawer_analysis.html` / `file_drawer_analysis.pdf`)
  - `file_drawer_exploratory_analysis.Rmd` (+ `file_drawer_exploratory_analysis.html` / `file_drawer_exploratory_analysis.pdf`)
  - `data_public/` – public datasets used by the Rmds (see below).
- `scripts/` – helper scripts to regenerate the public datasets from the raw export.

## Public datasets (and why there are three)

The public data release is split into three CSV files to reduce re-identification risk and prevent record linkage across sensitive fields:

- `02_RESULTS/data_public/public_main.csv`
  - analysis-ready survey responses (no raw timestamps/metadata),
  - **excludes** `D4`, `D6`, and all `D8[...]` columns (geo/specialization),
  - **excludes** all open-text fields (including `H5`),
  - includes a fresh sequential `id` (1..N) for convenience **within this file only**.
- `02_RESULTS/data_public/public_geo_spec.csv`
  - **decoupled and shuffled** file containing only `D4`, `D6`, and `D8[...]` (including `D8[other]`),
  - contains **no** `id` (and must not be merged back to `public_main.csv`).
- `02_RESULTS/data_public/public_text.csv`
  - **unlinked and shuffled** file containing open-text responses (e.g., `S3[...comment]`, `S5part2other`, `H5`, etc.),
  - contains **no** `id` (and must not be merged back to `public_main.csv`),
  - the free-text item `D12` is **not included** in the public release.

Rows are shuffled independently across the three files; treat them as three separate anonymized releases rather than three “tables to join”.

## Reproducing the public data release

To regenerate `public_*.csv` from a private LimeSurvey “full answers” export:

```bash
Rscript scripts/make_public_datasets.R <raw_full_answers.csv> 02_RESULTS/data_public 20260209
```

The script prints a lightweight scan of open-text fields for patterns like emails/URLs/ORCIDs (counts only).

## Reproducing the reports

From the `02_RESULTS/` directory:

```bash
Rscript -e 'rmarkdown::render("file_drawer_analysis.Rmd")'
Rscript -e 'rmarkdown::render("file_drawer_exploratory_analysis.Rmd")'
```
