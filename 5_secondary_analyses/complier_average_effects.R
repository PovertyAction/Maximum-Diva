# IV approach -------------------------------------------------------------

# mark as treated wards where at least one person reports attending an
# IPC session
treated_wards <-
  el %>%
  group_by(ward, Z) %>%
  summarise(
    treated = as.numeric(mean(ipc_attend) > 0)
  ) %>%
  ungroup() %>%
  select(-Z)

# merge compliance data with main data and nest
nested_iv_df <-
  el %>%
  left_join(treated_wards, by = "ward") %>%
  group_by(ward) %>%
  add_count() %>%
  mutate(ipw = 1 / n) %>%
  ungroup() %>% 
  gather(outcome, value, outcomes) %>%
  group_by(outcome) %>%
  nest() 

# run IV regressions
cace_iv_results <-
  nested_iv_df %>%
  mutate(
    # unadjusted models
    unadj_model = map(
      data,
      function (x) {
        iv_robust(
          formula = value ~ treated | Z,
          data = x,
          clusters = ward,
          fixed_effects = block,
          weights = ipw,
          se_type = "stata"
        )
      }),
    # adjusted models
    adj_model = map2(
      data,
      outcome,
      function (x, y) {
        iv_robust(
          formula = reformulate(
            termlabels = c(
              "treated", 
              get_covariates(y, selected_endline_covariates),
              get_covariates(y, selected_baseline_covariates),
              paste0("treated", ":", get_covariates(y, selected_endline_covariates)),
              paste0("treated", ":", get_covariates(y, selected_baseline_covariates)),
              "1 | Z",
              get_covariates(y, selected_endline_covariates),
              get_covariates(y, selected_baseline_covariates),
              paste0("Z", ":", get_covariates(y, selected_endline_covariates)),
              paste0("Z", ":", get_covariates(y, selected_baseline_covariates))
            ), 
            response = "value"
          ),
          data = x,
          clusters = ward,
          fixed_effects = block,
          weights = ipw,
          se_type = "stata"
        )
      })
  )


# inverse probability weighting approach ----------------------------------

ipw_model <-
  glm(
    formula = ipc_attend ~ female + age + edu_secondary + edu_higher +
      married + literacy + employed + factor(ward),
    family = binomial("logit"),
    data = select(el, ipc_attend, el_to_center, ward)
  )

stab_model <-
  glm(
    formula = ipc_attend ~ 1,
    family = binomial("logit"),
    data = select(el, ipc_attend, el_to_center, ward)
  )

# add inverse probability weights to dataset and estimate MSM
nested_ipw_df <-
  el %>%
  mutate(
    pr_num = predict(stab_model, type = "response"),
    pr_ipc_attend = predict(ipw_model, type = "response"),
    ipw = ifelse(ipc_attend == 1,
                 pr_num / pr_ipc_attend,
                 (1 - pr_num) / (1 - pr_ipc_attend))
  ) %>%
  gather(outcome, value, outcomes) %>%
  group_by(outcome) %>%
  nest() 


cace_ipw_results <-
  nested_ipw_df %>%
  mutate(
    # unadjusted models
    ipw_model = map(
      data,
      function (x) {
        lm_robust(
          formula = value ~ ipc_attend,
          data = x,
          clusters = ward,
          fixed_effects = block,
          weights = ipw,
          se_type = "stata"
        )
      })
  )

write_rds(cace_iv_results, "__data/results/cace_iv_results.rds")
write_rds(cace_ipw_results, "__data/results/cace_ipw_results.rds")

