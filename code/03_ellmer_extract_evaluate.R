# Medicine x LLM x R -- Showcase 4: extraction with ellmer, then evaluation
# Wan Nor Arifin, R Conference Malaysia 2026
# Run with the working directory set to the code/ folder.
# For demonstration only -- not for clinical use.
#
# Requirements: Ollama running locally; install.packages("ellmer")
#   ollama pull medgemma1.5:4b

library(ellmer)
source("../functions.R")   # extract_num()

model = "medgemma1.5:4b"
notes = read.csv("../data/clinical_notes.csv")   # 8 synthetic notes + gold standard

# --- Schema: numeric variables as text copied from the note -----------------------
type_patient = type_object(
  age = type_number("Age in years, as written in the note"),
  sex = type_enum(values = c("male", "female"),
                  description = "Sex of the patient, from words such as man, lady, Encik, Puan"),
  bp_text = type_string("Blood pressure value and unit only, copied exactly from the note, e.g. '150/95 mmHg'. Empty string if not reported."),
  hba1c_text = type_string("HbA1c value and unit only, copied exactly from the note, e.g. '8.9%'. Empty string if not reported."),
  creatinine_text = type_string("Serum creatinine value and unit only, copied exactly from the note, e.g. '132 umol/L'. Empty string if not reported."),
  smoker = type_enum(values = c("yes", "no", "unknown"),
                     description = "Is the patient a CURRENT smoker? Ex-smokers and never-smokers are 'no'. 'unknown' if smoking is not mentioned.")
)

chat = chat_ollama(
  model = model,
  system_prompt = "You extract data from clinical notes. Do not guess values that are not stated.",
  params = params(temperature = 0, seed = 2026)
)

extracted = parallel_chat_structured(chat, as.list(notes$note), type = type_patient)
extracted

# --- The LLM locates the text; R extracts the numbers ------------------------------
extracted$sbp        = extract_num(extracted$bp_text, 1)
extracted$dbp        = extract_num(extracted$bp_text, 2)
extracted$hba1c      = extract_num(extracted$hba1c_text)
extracted$creatinine = extract_num(extracted$creatinine_text)
extracted

# --- Evaluation against the gold standard ------------------------------------------
gold = notes[, c("age", "sex", "sbp", "dbp", "hba1c", "creatinine", "smoker")]

# Agreement: equal values, or missing in both
agree = function(x, y) (is.na(x) & is.na(y)) | (!is.na(x) & !is.na(y) & x == y)

# Field-level accuracy (%)
acc = sapply(names(gold), function(x) mean(agree(extracted[[x]], gold[[x]])))
round(acc * 100, 2)
