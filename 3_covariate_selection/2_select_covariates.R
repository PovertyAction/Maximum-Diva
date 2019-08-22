
selected_baseline_covariates <-
  tibble(
    outcome = outcomes,
    term = paste0(outcomes, "_bl")
  )

selected_endline_covariates <-
  tibble(
    outcome = rep(outcomes, each = length(endline_covariates)),
    term = rep(endline_covariates, length(outcomes))
  )
  # outcomes %>%
  # map(function (name) {
  #   select_covariates(
  #     outcome_name = name,
  #     covariates = endline_covariates,
  #     data = el,
  #     sims = lasso_sims,
  #     N_folds = lasso_folds
  #   )
  # }) %>% bind_rows()

write.csv(
  selected_endline_covariates,
  "__data/results/couple_outcome_covariates.csv",
  na = ""
)
