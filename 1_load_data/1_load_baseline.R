bl <- read_stata("__data/md_baseline.dta",)

bl <- bl %>%
  select(
    -educ,
    -treatment,
    -endline,
    -starts_with("ward_"),
    -block
  )

bl <- bl %>%
  mutate(
    any_use_ever = mc_use_ever == 1 | fc_use_ever == 1,
    any_use_6mo = mc_use_6mo == 1 | fc_use_6mo == 1,
    any_use_last = mc_use_last == 1 | fc_use_last == 1
  ) %>%
  mutate_at(vars(starts_with("any_use")), as.numeric)

bl <- zap_labels(bl)