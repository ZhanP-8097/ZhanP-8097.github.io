# Personal website

Quarto site published to <https://zhanp-8097.github.io> by GitHub Actions on every push to `main`.

## Everyday workflow

```powershell
quarto preview                      # live local preview
quarto render publications.qmd      # re-run R after editing publications.bib
git add -A; git commit -m "..."; git push
```

R code runs **only on your machine**. Its results are stored in `_freeze/`, which must be committed. The online build has no R.

- `quarto render` (whole site) reuses frozen results, so it will not pick up a changed `publications.bib`.
- Rendering a single file (`quarto render publications.qmd`) always re-runs its R code.

Quarto is bundled with RStudio at `C:\Program Files\RStudio\resources\app\bin\quarto\bin\quarto.exe`. Add that folder to PATH, or use the RStudio terminal / Render button.

## Publications

`publications.bib` is the master list and is read by `R/publications.R`. Use these conventions:

| BibTeX | Shown as |
|---|---|
| `@article` | Journal articles |
| `@unpublished`, `@misc`, `@techreport` | Preprints & working papers |
| `@inproceedings` | Conference papers |
| `@incollection`, `@inbook`, `@book` | Book chapters |
| `pubstate = {underreview}` | "Under review", journal hidden, listed with working papers |
| `selected = {true}` | Highlighted with a "Selected" badge |
| `pdf`, `code`, `data`, `doi`, `url` | Link buttons |

The R package `bibtex` is required (`install.packages("bibtex")`).

## Layout

| Path | Purpose |
|---|---|
| `_quarto.yml` | Site config, navbar, theme |
| `index.qmd`, `publications.qmd`, `software.qmd`, `cv.qmd` | Pages |
| `research.qmd` | v2, a draft that is not published yet |
| `assets/` | SCSS themes, images |
| `files/` | Downloadable files (CV PDF, papers) |
| `R/` | Helper R code |
