  
# create nested data frame 
nested_pooled_el <-
  el %>%
  select(Z,
         block,
         ward,
         outcomes,
         baseline_covariates,
         endline_covariates) %>%
  group_by(ward) %>%
  add_count() %>%
  mutate(ipw = 1 / n) %>%
  ungroup() %>% 
  group_by(Z, block, ward) %>%
  summarise_all(mean) %>%
  gather(outcome, value, outcomes) %>%
  group_by(outcome) %>%
  nest() 

if (rerun_robustness_checks) {
  
  cat("  Running adjusted models...\n\n")
  pooled_outcome_results <-
    nested_pooled_el %>%
    mutate(
      # adjusted model
      adj_model = map2(
        data, 
        outcome, 
        function (x, y) {
          main_estimator(
            data = x,
            outcome = "value",
            covariates = c(
              get_covariates(y, selected_endline_covariates),
              get_covariates(y, selected_baseline_covariates)
            ),
            clusters = NULL,
            se_type = "HC2"
          )
        }),
      # null distribution under permutted Z 
      adj_null = map2(
        data,
        outcome,
        function(x, y) {
          ri(
            data = x,
            outcome = "value",
            covariates = c(
              get_covariates(y, selected_endline_covariates),
              get_covariates(y, selected_baseline_covariates)
            ),
            print = y,
            sims = sims,
            clusters = NULL,
            se_type = "HC2"
          )
        }),
      # randomization inference p-value
      adj_p = map2(
        adj_model,
        adj_null,
        function(x, y) {
          get_p(get_estimate(x), y)
        }),
      # randomization inference confidence interval
      adj_ci = map2(
        adj_model,
        adj_null,
        function(x, y) {
          get_ci(get_estimate(x), y)
        })
    )
  write_rds(pooled_outcome_results, "__data/results/pooled_outcome_results.rds")

} else {
  pooled_outcome_results <- read_rds("__data/results/pooled_outcome_results.rds")
}