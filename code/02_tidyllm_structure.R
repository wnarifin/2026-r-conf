# Medicine x LLM x R -- Showcase 3: structuring clinical notes with tidyllm
# Wan Nor Arifin, R Conference Malaysia 2026
# Run with the working directory set to the code/ folder.
# For demonstration only -- not for clinical use.
#
# Requirements: Ollama running locally; install.packages(c("tidyllm", "jsonlite"))
#   ollama pull medgemma1.5:4b
# MJMSTable is used for the descriptive table.

library(tidyllm)
library(jsonlite)

model = "medgemma1.5:4b"

patient_schema = tidyllm_schema(
  name = "PatientHistory",
  patient_name = field_chr("Patient's name; empty if not stated"),
  age = field_dbl("Age in years. If given in months, convert to a fraction of a year."),
  gender = field_fct("Gender of the patient", .levels = c("male", "female")),
  symptoms = field_chr("Current symptoms reported by the patient", .vector = TRUE)
)

# --- One note ---------------------------------------------------------------------
raw_text = "Mrs. Amy, a 35-year-old lady came to the outpatient clinic with the
            complaint of fever for three days and cough."

result = llm_message(paste("Extract the patient's note according to the schema.", raw_text)) |>
  chat(.provider = ollama(), .model = model, .json_schema = patient_schema,
       .temperature = 0, .seed = 2026)
# Cloud alternative (API key in a local file "api", listed in .gitignore):
# Sys.setenv(GOOGLE_API_KEY = readLines("api"))
# chat(.provider = gemini(), .model = "gemini-3.1-flash-lite", .json_schema = patient_schema)

get_reply(result) |> minify()

# --- Several notes -> JSON Lines -> data frame --------------------------------------
notes = read.csv("../data/clinical_notes.csv")
output_file = "pt_data.jsonl"
if (file.exists(output_file)) file.remove(output_file)   # start a new file on each run

for (note in notes$note) {
  tryCatch({
    llm_message(paste("Extract the patient's note according to the schema.", note)) |>
      chat(.provider = ollama(), .model = model, .json_schema = patient_schema,
           .temperature = 0, .seed = 2026) |>
      get_reply() |> minify() |>
      cat("\n", file = output_file, append = TRUE, sep = "")
  }, error = function(e) cat("Error:", conditionMessage(e), "\n"))
}

patient_data = stream_in(file(output_file), verbose = FALSE)   # read the JSON Lines file
patient_data

MJMSTable::descriptive_tbl(patient_data, included_var = c("age", "gender"))
