# Medicine x LLM x R -- Showcase 1 & 2: basic local inference with rollama
# Wan Nor Arifin, R Conference Malaysia 2026
# Run with the working directory set to the code/ folder.
# For demonstration only -- not for clinical use.
#
# Requirements: Ollama running locally; install.packages("rollama")
#   ollama pull medgemma1.5:4b

library(rollama)
source("../functions.R")   # clean_thought()

model = "medgemma1.5:4b"

ping_ollama()          # is Ollama running?
# pull_model(model)    # download once

# --- 1. Patient communication / translation --------------------------------------
finding = "HbA1c 8.9%, fasting glucose 11.2 mmol/L, BP 150/95 mmHg."

res = query(
  paste("Explain these results to a patient in simple Bahasa Melayu,",
        "in 3 sentences. Do not give a diagnosis.", finding),
  model = model,
  output = "data.frame", screen = FALSE,
  model_params = list(seed = 2026, temperature = 0)
)
clean_thought(res$response) |> cat()

# --- 2. Zero-shot triage classification ------------------------------------------
complaints = c(
  "Crushing chest pain radiating to the left arm, sweating, 30 minutes.",
  "Mild sore throat for two days, no fever, eating well.",
  "Sudden weakness of the right arm and slurred speech since this morning."
)

q = make_query(
  text   = complaints,
  prompt = "Classify the triage urgency: 'emergency', 'urgent' or 'non-urgent'.",
  system = "You are a triage assistant. Answer with one category only, in lowercase."
)

triage = query(q, model = model, output = "text", screen = FALSE,
               model_params = list(seed = 2026, temperature = 0)) |> clean_thought()

triage_df = data.frame(complaint = complaints, triage = triage)
triage_df

# Comparison with a reference classification (a hypothetical triage nurse)
nurse = c("emergency", "non-urgent", "emergency")
table(LLM = triage_df$triage, Nurse = nurse)
