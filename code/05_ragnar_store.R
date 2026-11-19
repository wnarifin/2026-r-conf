# Medicine x LLM x R -- Showcase 6: retrieval-augmented generation (RAG) with ragnar
# Wan Nor Arifin, R Conference Malaysia 2026
# Run with the working directory set to the code/ folder.
# For demonstration only -- not for clinical use.
#
# Requirements: Ollama running locally; install.packages(c("ragnar", "ellmer", "jsonlite"))
#   ollama pull bge-m3                                                  # embeddings
#   ollama pull hf.co/aisingapore/Apertus-SEA-LION-v4-8B-IT-GGUF:Q8_0   # chat model
# Source document: Malay Wikipedia, "Kencing manis" (CC BY-SA).

library(ragnar)
library(ellmer)

# --- 1. Plain-text article from the Wikipedia API (no menus or sidebars) -----------
# read_as_markdown() cannot read the Wikipedia URL directly (HTTP 403).
url = "https://ms.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&redirects=1&format=json&titles=Kencing_manis"
json_file = "kencing_manis.json"
md_file = "kencing_manis.md"
download.file(url, destfile = json_file, mode = "wb")
writeLines(jsonlite::fromJSON(json_file)$query$pages[[1]]$extract,
           md_file, useBytes = TRUE)

# --- 2. Build the store on a local disk -----------------------------------------------
# Cloud-synced folders (e.g. pCloud Drive) can break DuckDB's .wal file.
store_location = path.expand("~/ragnar_store/kencing_manis.duckdb")
dir.create(dirname(store_location), showWarnings = FALSE)

store = ragnar_store_create(
  store_location,
  embed = \(x) embed_ollama(x, model = "bge-m3"),   # multilingual embeddings
  overwrite = TRUE                                  # rebuild from scratch
)

chunks = read_as_markdown(md_file) |> markdown_chunk()
chunks

ragnar_store_insert(store, chunks)
ragnar_store_build_index(store)

# --- 3. Retrieve the most relevant chunks ----------------------------------------------
ragnar_retrieve(store, "Apakah tanda-tanda kencing manis?", top_k = 3)

# --- 4. The store as a tool for the LLM -------------------------------------------------
model_my = "hf.co/aisingapore/Apertus-SEA-LION-v4-8B-IT-GGUF:Q8_0"
chat = chat_ollama(
  model = model_my,
  system_prompt = paste(
    "You explain diabetes to patients in simple Malay or English.",
    "Search the knowledge store before answering and cite it.",
    "You do not diagnose. Always advise seeing a doctor."
  ),
  params = params(temperature = 0, seed = 2026)
)
ragnar_register_tool_retrieve(chat, store, top_k = 5)
chat$chat("Apakah tanda-tanda awal kencing manis?")
