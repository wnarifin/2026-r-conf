# clean text since medgemma1.5 output <unused94></unused94> thinking tag
clean_thought <- function(x) {
  trimws(
    gsub("(?s)<unused94>.*?(?:<unused95>|</unused94>|$)", "", x, perl = TRUE)
  )
}

# Numbers in a text; skips digits inside words such as "HbA1c"
extract_num = function(x, which = 1) {
  m = regmatches(x, gregexpr("(?<![A-Za-z0-9.])[0-9]+(\\.[0-9]+)?", x, perl = TRUE))
  vapply(m, function(v) if (length(v) >= which) as.numeric(v[which]) else NA_real_, numeric(1))
}