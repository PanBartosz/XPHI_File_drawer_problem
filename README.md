# Publication bias in experimental philosophy

Data, survey materials, analysis code, rendered reports, and publication figures for:

> Maćkiewicz, B., Kuś, K., & Krajewski, G. (2026). Publication bias in experimental philosophy: A survey on the file drawer problem, research attrition, and open science practices. *Synthese, 208*, Article 77. https://doi.org/10.1007/s11229-026-05727-2

- Published article: https://doi.org/10.1007/s11229-026-05727-2
- Archived project materials: https://doi.org/10.17605/OSF.IO/6XN27
- Prospective registration: https://doi.org/10.17605/OSF.IO/WDKNJ

## Repository contents

- `01_SURVEY/`: LimeSurvey source and PDF versions of the survey.
- `02_RESULTS/data_public/`: anonymized public datasets used by the reports.
- `02_RESULTS/file_drawer_analysis.Rmd`: main descriptive and comparative analyses.
- `02_RESULTS/file_drawer_exploratory_analysis.Rmd`: explicitly hypothesis-generating analyses.
- `02_RESULTS/likert_sensitivity_analysis.Rmd`: rank-based sensitivity analyses for Likert-type items.
- `02_RESULTS/*.html` and `02_RESULTS/*.pdf`: rendered reports.
- `figures/`: the four publication figures as 300 DPI, LZW-compressed TIFF files.
- `scripts/make_public_datasets.R`: regenerates the public datasets from the private LimeSurvey export.
- `scripts/validate_public_release.R`: checks the released datasets for structural and privacy regressions.
- `scripts/render_reports.R`: renders every analysis report.
- `renv.lock`: records the complete R package environment.

## Reproduce the analyses

The lockfile was created with R 4.6.1. From the repository root:

```bash
Rscript -e 'install.packages("renv")'
Rscript -e 'renv::restore()'
Rscript scripts/validate_public_release.R
Rscript scripts/render_reports.R
```

The full render command requires Pandoc and a LaTeX installation. Rendering the main report also regenerates the four TIFF files in `figures/`.

The public datasets and the two external comparison datasets needed by the reports are included. The private, identifiable LimeSurvey export is not required to reproduce the analyses.

## Public data release

The study data are split into three CSV files to reduce re-identification risk and prevent record linkage across sensitive fields:

- `public_main.csv` contains analysis-ready survey responses. It excludes raw survey metadata, response-time fields, geographic/specialization fields, and open text. Its sequential `id` is meaningful only within this file. It includes `data_shared_ever`, a non-sensitive indicator derived before open text was separated so that a valid "Other" sharing route is counted.
- `public_geo_spec.csv` contains only `D4`, `D6`, and `D8[...]` geographic/specialization fields. It has no identifier and its rows were shuffled independently.
- `public_text.csv` contains unlinked open-text responses, except the excluded `D12` field. It has no identifier and its rows were shuffled independently.

Do not attempt to merge or otherwise link these files. Their row orders are deliberately unrelated.

To validate the checked-in release:

```bash
Rscript scripts/validate_public_release.R
```

The validator checks row counts, the separation of sensitive fields, the absence of LimeSurvey metadata and response-time columns, the expected data-sharing group sizes, and common direct-identifier patterns. Automated screening does not replace responsible manual review of open text.

## Regenerate the public datasets

This maintainer-only step requires the private LimeSurvey "full answers" export:

```bash
Rscript scripts/make_public_datasets.R <raw_full_answers.csv> 02_RESULTS/data_public 20260209
Rscript scripts/validate_public_release.R
```

The fixed seed makes the independent row shuffles reproducible. The generator also prints counts from a lightweight email, URL, and ORCID scan of the raw open-text fields.

## External comparison data

The comparative analyses use data released by Borghi and Van Gulick:

- Borghi, J. A., & Van Gulick, A. E. (2018). Data management and sharing in neuroimaging: Practices and perceptions of MRI researchers. *PLOS ONE, 13*(7), e0200562. Data: https://doi.org/10.1184/R1/5845656.v1
- Borghi, J. A., & Van Gulick, A. E. (2021). Data management and sharing: Practices and perceptions of psychology researchers. *PLOS ONE, 16*(5), e0252047. Data: https://doi.org/10.5061/dryad.6wwpzgmw3

Those third-party files remain subject to the terms specified by their original repositories.

## Licensing

Except where a file states otherwise, the original contents of this repository
are dedicated to the public domain under
[CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/). See
`LICENSE` for the full legal text.

This dedication applies to the repository, not to the published Synthese
article. Third-party datasets and other third-party materials retain the terms
specified by their original sources.
