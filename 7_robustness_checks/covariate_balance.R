# baseline balance --------------------------------------------------------

if (rerun_robustness_checks) {
  
  bl_balance_means <-
    bl %>%
    select(balance_covariates, Z) %>%
    group_by(Z) %>%
    summarise_all(mean, na.rm = T) %>%
    gather(covariate, mean, -Z) %>%
    spread(Z, mean, sep = "_")
  
  bl_balance_results <-
    bl %>%
    group_by(ward) %>%
    add_count() %>%
    mutate(ipw = 1 / n) %>%
    ungroup() %>%
    gather(covariate, value, balance_covariates) %>%
    group_by(covariate) %>%
    nest() %>%
    mutate(
      # balance model
      bal_model = map(data,
                      function (x) {
                        main_estimator(data = x, outcome = "value")
                      }),
      # null distribution under permutted Z
      bal_null = map2(data,
                      covariate,
                      function(x, y) {
                        ri(
                          data = x,
                          outcome = "value",
                          print = y,
                          sims = sims
                        )
                      }),
      # randomization inference p-value
      bal_p = map2(bal_model,
                   bal_null,
                   function(x, y) {
                     get_p(get_estimate(x), y)
                   })
    )
  
  bl_balance_results <-
    bl_balance_results %>%
    left_join(bl_balance_means, by = "covariate")
  
  bl_balance_F_null <-
    bl %>%
    group_by(ward) %>%
    add_count() %>%
    mutate(ipw = 1 / n) %>%
    ungroup() %>%
    ri(
      outcome = "Z",
      treatment = balance_covariates,
      sims = 1000,
      se_type = "stata",
      extract = get_F
    )
  
  bl_balance_joint_model <-
    bl %>%
    select(balance_covariates, Z, ward, block) %>%
    group_by(ward) %>%
    add_count() %>%
    mutate(ipw = 1 / n) %>%
    ungroup() %>%
    main_estimator(
      outcome = "Z",
      treatment = balance_covariates,
      data = .,
      se_type = "stata"
    )
  
  bl_balance_results$joint_F <- get_F(bl_balance_joint_model)
  bl_balance_results$joint_F_p <- get_p(get_F(bl_balance_joint_model), bl_balance_F_null)
}


# endline balance ---------------------------------------------------------

if (rerun_robustness_checks) {
  
  el_balance_means <-
    el %>%
    select(balance_covariates[1:15], Z) %>%
    group_by(Z) %>%
    summarise_all(mean, na.rm = T) %>%
    gather(covariate, mean, -Z) %>%
    spread(Z, mean, sep = "_")
  
  el_balance_results <-
    el %>%
    group_by(ward) %>%
    add_count() %>%
    mutate(ipw = 1 / n) %>%
    ungroup() %>%
    gather(covariate, value, balance_covariates[1:15]) %>%
    group_by(covariate) %>%
    nest() %>%
    mutate(
      # balance model
      bal_model = map(data,
                      function (x) {
                        main_estimator(data = x, outcome = "value")
                      }),
      # null distribution under permutted Z
      bal_null = map2(data,
                      covariate,
                      function(x, y) {
                        ri(
                          data = x,
                          outcome = "value",
                          print = y,
                          sims = sims
                        )
                      }),
      # randomization inference p-value
      bal_p = map2(bal_model,
                   bal_null,
                   function(x, y) {
                     get_p(get_estimate(x), y)
                   })
    )
  
  el_balance_results <-
    el_balance_results %>%
    left_join(el_balance_means, by = "covariate")
  
  el_balance_F_null <-
    el %>%
    group_by(ward) %>%
    add_count() %>%
    mutate(ipw = 1 / n) %>%
    ungroup() %>%
    ri(
      outcome = "Z",
      treatment = balance_covariates[1:15],
      sims = 1000,
      se_type = "stata",
      extract = get_F
    )
  
  el_balance_joint_model <-
    bl %>%
    select(balance_covariates[1:15], Z, ward, block) %>%
    group_by(ward) %>%
    add_count() %>%
    mutate(ipw = 1 / n) %>%
    ungroup() %>%
    main_estimator(
      outcome = "Z",
      treatment = balance_covariates[1:15],
      data = .,
      se_type = "stata"
    )
  
  el_balance_results$joint_F <- get_F(el_balance_joint_model)
  el_balance_results$joint_F_p <- get_p(get_F(el_balance_joint_model), el_balance_F_null)
}

if (rerun_robustness_checks) {
  
  balance_results <-
    bl_balance_results %>%
    left_join(el_balance_results, by = "covariate", suffix = c("_bl", "_el"))
  
  balance_results <- 
    balance_results %>%
    mutate(bal_p_el = map(bal_p_el, ~ifelse(is.null(.x), NA, .x)))
  
  write_rds(balance_results, "__data/results/balance_results.rds")
  
} else {
  balance_results <- read_rds("__data/results/balance_results.rds")
}


  

