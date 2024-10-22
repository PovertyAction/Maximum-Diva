
# adjusted models ---------------------------------------------------------

cat("  Running heterogeneous effects models for educational attainment... \n\n")
edu_hetero_results <-
  nested_el %>%
  mutate(
    hetx_models_0 = map2(
      data, 
      outcome, 
      function (x, y) {
        main_estimator(
          data = subset(x, edu_higher == 0),
          outcome = "value",
        )
      }),
    hetx_models_1 = map2(
      data, 
      outcome, 
      function (x, y) {
        main_estimator(
          data = subset(x, edu_higher == 1),
          outcome = "value",
        )
      }),
    hetx_effects = map2(
      hetx_models_0,
      hetx_models_1,
      function(x,y) {
        c(
          male_only = get_estimate(x),
          female_only = get_estimate(y),
          diff = get_estimate(y) - get_estimate(x)
        )
      }),
    # null distribution under permutted Z 
    hetx_null = pmap(
      list(
        data,
        outcome,
        c(primary_outcome_results$adj_model %>% map(get_estimate), 
          secondary_outcome_results$adj_model %>% map(get_estimate))
      ),
      function(x, y, z) {
        ri_interaction(
          data = x,
          outcome = "value",
          print = y,
          subgroup = "edu_higher",
          sharp_null = z,
          sims = sims
        )
      }),
    # randomization inference p-value
    hetx_p = map2(
      hetx_effects,
      hetx_null,
      function (effect, null) {
        apply(X = null,
              MARGIN =  2,
              FUN = function(null_distribution) {
                abs(null_distribution) >= abs(effect)
              }) %>%
          rowMeans()
      }),
    # randomization inference confidence interval
    hetx_ci = map2(
      hetx_effects,
      hetx_null,
      function (effect, null) {
        apply(X = null,
              MARGIN =  1,
              FUN = function(null_distribution) {
                quantile(null_distribution, probs = c(0.025, 0.975))
              }) + effect 
      })
  )

write_rds(edu_hetero_results, "__data/results/edu_hetero_results.rds")
