# Medicine x LLM x R -- Showcase 5: tool calling with ellmer (eGFR calculator)
# Wan Nor Arifin, R Conference Malaysia 2026
# Run with the working directory set to the code/ folder.
# For demonstration only -- not for clinical use.
#
# The LLM decides WHEN to call the tool; R does the arithmetic exactly.
# Equation: race-free CKD-EPI 2021 creatinine equation (Inker et al., NEJM 2021);
# GFR categories: KDIGO 2012 CKD guideline.
# Requirements: Ollama running locally; install.packages("ellmer")
#   ollama pull qwen3.5:4b   (medgemma1.5 does not support tool calling)

library(ellmer)

egfr_ckdepi2021 = function(creatinine_umol, age, sex) {
  scr = creatinine_umol / 88.4                 # umol/L -> mg/dL
  female = sex == "female"
  k = ifelse(female, 0.7, 0.9)
  a = ifelse(female, -0.241, -0.302)
  142 * pmin(scr / k, 1)^a * pmax(scr / k, 1)^-1.200 *
    0.9938^age * ifelse(female, 1.012, 1)
}

egfr_ckdepi2021(132, age = 64, sex = "female") |> round(1)   # 38.9: KDIGO G3b (30-44)

tool_egfr = tool(
  egfr_ckdepi2021,
  name = "egfr_ckdepi2021",
  description = "Estimate GFR (mL/min/1.73 m2) using the race-free CKD-EPI 2021 creatinine equation.",
  arguments = list(
    creatinine_umol = type_number("Serum creatinine in umol/L"),
    age = type_number("Age in years"),
    sex = type_enum(values = c("male", "female"), description = "Sex of the patient")
  )
)

model_tool = "qwen3.5:4b"

# --- With the tool --------------------------------------------------------------------
# temperature > 0 for a thinking model: at temperature = 0 it can get stuck in a
# thinking loop; the fixed seed keeps the run reproducible
chat = chat_ollama(model = model_tool, params = params(temperature = 0.5, seed = 2026))
chat$register_tool(tool_egfr)

t0 = Sys.time()
res_tool = chat$chat("Puan Aminah is a 64-year-old woman with serum creatinine 132 umol/L.
                     What is her eGFR, which KDIGO CKD GFR category and
                     which clinical term is it?", echo = "none")
time_tool = as.numeric(difftime(Sys.time(), t0, units = "secs"))
res_tool

# --- Without the tool (takes much longer: the model reasons through the maths) -----
chat_no_tool = chat_ollama(model = model_tool, params = params(temperature = 0.5, seed = 2026))

t0 = Sys.time()
res_no_tool = chat_no_tool$chat("Puan Aminah is a 64-year-old woman with serum creatinine 132 umol/L.
                                Calculate her eGFR with CKD-EPI 2021 creatinine equation.
                                Which KDIGO CKD GFR category and which clinical term is it?",
                                echo = "none")
time_no_tool = as.numeric(difftime(Sys.time(), t0, units = "secs"))
res_no_tool

# --- Time and tokens ----------------------------------------------------------------
tok_tool = chat$get_tokens()
tok_no_tool = chat_no_tool$get_tokens()

data.frame(
  run = c("With tool", "Without tool"),
  seconds = round(c(time_tool, time_no_tool), 1),
  assistant_turns = c(nrow(tok_tool), nrow(tok_no_tool)),
  input_tokens = c(sum(tok_tool$input, na.rm = TRUE), sum(tok_no_tool$input, na.rm = TRUE)),
  output_tokens = c(sum(tok_tool$output, na.rm = TRUE), sum(tok_no_tool$output, na.rm = TRUE))
)
