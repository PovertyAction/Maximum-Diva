bl_pool <-
  bl %>%
  select(-id) %>%
  group_by(ward) %>%
  summarise_all(mean, na.rm = TRUE)