el <- read_stata("__data/md_endline.dta")

el <- el %>%
  select(
    -treatment,
    -endline,
    -educ,
    -starts_with("ward_"),
    -starts_with("ipc_attendance"),
    -starts_with("ipc_sessions"),
    -block
  )

el <- el %>%
  mutate(
    any_use_ever = mc_use_ever == 1 | fc_use_ever == 1,
    any_use_6mo = mc_use_6mo == 1 | fc_use_6mo == 1,
    any_use_last = mc_use_last == 1 | fc_use_last == 1
  ) %>%
  mutate_at(vars(starts_with("any_use")), as.numeric)