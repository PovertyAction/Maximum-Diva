
# unadjusted models -------------------------------------------------------

cat("  Running unadjusted models...\n\n")
secondary_outcome_results <-
  nested_el %>%
  filter(outcome %in% secondary_outcomes) %>%
  mutate(
    # unadjusted model
    unadj_model = map(
      data, 
      function (x) {
        main_estimator(data = x, outcome = "value")
      }),
    # null distribution under permutted Z 
    unadj_null = map2(
      data,
      outcome,
      function(x, y) {
        ri(data = x, outcome = "value", print = y, sims = sims)
      }),
    # randomization inference p-value
    unadj_p = map2(
      unadj_model,
      unadj_null,
      function(x, y) {
        get_p(get_estimate(x), y)
      }),
    unadj_ci = map2(
      unadj_model,
      unadj_null,
      function(x, y) {
        get_ci(get_estimate(x), y)
      })
  )


# adjusted models ---------------------------------------------------------

cat("  Running adjusted models...\n\n")
secondary_outcome_results <-
  secondary_outcome_results %>%
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
          )
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
          sims = sims
        )
      }),
    # randomization inference p-value
    adj_p = map2(
      adj_model,
      adj_null,
      function(x, y) {
        get_p(get_estimate(x), y)
      }),
    adj_ci = map2(
      adj_model,
      adj_null,
      function(x, y) {
        get_ci(get_estimate(x), y)
      })
  )

write_rds(secondary_outcome_results, "__data/results/secondary_outcome_results.rds")

