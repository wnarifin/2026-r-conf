# Medicine x LLM x R -- Showcase 7: a patient-education chat app with RAG
# Wan Nor Arifin, R Conference Malaysia 2026
# Run with the working directory set to the code/ folder.
# For demonstration only -- not for clinical use.
# Build the store first with 05_ragnar_store.R.
#
# Requirements: install.packages(c("shiny", "shinychat", "ellmer", "ragnar", "bslib"))
# shinychat >= 0.5.0 (for chat_server())

library(shiny)
library(shinychat)
library(ellmer)
library(ragnar)

store_location = path.expand("~/ragnar_store/kencing_manis.duckdb")   # as in 05_ragnar_store.R
store = ragnar_store_connect(store_location, read_only = TRUE)

ui = bslib::page_fillable(
  bslib::card(
    bslib::card_header("Pembantu pendidikan pesakit: kencing manis (demo)"),
    chat_ui("chat")
  )
)

# Using local model
# model_my = "hf.co/aisingapore/Apertus-SEA-LION-v4-8B-IT-GGUF:Q8_0"
# server = function(input, output, session) {
#   chat = chat_ollama(
#     model = model_my,
#     system_prompt = "You explain diabetes to patients in simple Malay or English.
#       Search the knowledge store before answering and cite it.
#       You do not diagnose. Always advise seeing a doctor."
#   )
#   ragnar_register_tool_retrieve(chat, store, top_k = 5)
#   chat_server("chat", chat, history = FALSE)   # history = FALSE: do not save chats
# }

# Using Gemini
Sys.setenv(GOOGLE_API_KEY = readLines("api")) # your own api key
model_my = "gemini-3.1-flash-lite"
server = function(input, output, session) {
  chat = chat_google_gemini(
    model = model_my,
    system_prompt = "You explain diabetes to patients in simple Malay or English.
      Search the knowledge store before answering and cite it.
      You do not diagnose. Always advise seeing a doctor."
  )
  ragnar_register_tool_retrieve(chat, store, top_k = 5)
  chat_server("chat", chat, history = FALSE)
}

shinyApp(ui, server)

# Quick personal chat in the browser, without an app:
# chat = chat_ollama(model = model_my)
# ragnar_register_tool_retrieve(chat, store)
# live_browser(chat)
