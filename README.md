# Medicine × LLM × R

## R Conference Malaysia 2026 — Keynote

This repository hosts the slides, code and data for the keynote *Medicine × LLM × R*, delivered on 21 November 2026 at Sunway University.

- Slides: https://wnarifin.github.io/2026-r-conf/
- Demo document (compiled): https://wnarifin.github.io/workshop.html

### Contents

- `index.qmd` — Quarto (revealjs) source of the slides; `index.html` and `index_files/` are the rendered slides
- `demo.Rmd` — R Markdown source of the showcase demo document
- `functions.R` — helper functions used by the demo and the scripts: `clean_thought()` (removes MedGemma's thinking tags from the output) and `extract_num()` (extracts numbers from text)
- `custom.scss` — slide theme
- `references.bib` — bibliography
- `img/` — images
- `data/clinical_notes.csv` — eight **synthetic** clinical notes with gold-standard values, for the extraction and evaluation demo
- `api`, `code/api` — **placeholders** for your own API key (see below)
- `code/` — showcase scripts
  - `01_rollama_basic.R` — local inference and zero-shot triage classification with `rollama`
  - `02_tidyllm_structure.R` — structuring clinical notes with `tidyllm`
  - `03_ellmer_extract_evaluate.R` — extraction with `ellmer` (the LLM locates the text, R extracts the numbers), then evaluation against the gold standard
  - `04_ellmer_tool_egfr.R` — tool calling: an R eGFR (CKD-EPI 2021) function as an LLM tool, with time and tokens compared against no tool
  - `05_ragnar_store.R` — retrieval-augmented generation (RAG) over the Malay Wikipedia article *Kencing manis* with `ragnar`
  - `06_ellmer_shinychat_ragnar_app.R` — a patient-education chat app with `shinychat` (Gemini, or a local model), grounded in the `ragnar` store

### Requirements

R packages:

```r
install.packages(c("rollama", "tidyllm", "ellmer", "ragnar", "jsonlite",
                   "shiny", "shinychat", "bslib"))
# MJMSTable, for the descriptive table: https://github.com/wnarifin/MJMSTable
```

Models, with [Ollama](https://ollama.com/download) installed and running:

```
ollama pull medgemma1.5:4b    # demos 1-4
ollama pull qwen3.5:4b        # demo 5 (tool calling)
ollama pull bge-m3            # demos 6-7 (embeddings)
ollama pull hf.co/aisingapore/Apertus-SEA-LION-v4-8B-IT-GGUF:Q8_0   # demos 6-7
```

The `ragnar` store is created in `~/ragnar_store/`, outside the project folder, because cloud-synced folders can break DuckDB's temporary files.

### API key (cloud models)

The cloud examples (Google Gemini) read the key from the text file `api` (`code/api` for the scripts). These files are placeholders: replace the text with your own key from [Google AI Studio](https://aistudio.google.com).

If you work in your own clone or fork of this repository, stop Git from tracking your edits to these files before adding your key, so that it is never committed:

```
git update-index --skip-worktree api code/api
```

### Rendering

```r
quarto::quarto_render("index.qmd")   # slides; or, in a terminal: quarto render index.qmd
rmarkdown::render("demo.Rmd")        # demo; runs the LLM examples (needs Ollama and the models above)
# rmarkdown::render("demo.Rmd", params = list(run_llm = FALSE))  # code only, no LLM calls
```

Run the scripts in `code/` with `code/` as the working directory.

The code and the app are for demonstration only and are not intended for clinical use.
