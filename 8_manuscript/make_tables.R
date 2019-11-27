balance_results <- 
  read_rds("__data/results/balance_results.rds")

primary_outcome_results <-
  read_rds("__data/results/primary_outcome_results.rds")

secondary_outcome_results <-
  read_rds("__data/results/secondary_outcome_results.rds")


# table 1 -----------------------------------------------------------------

bottom_rows <-
  tibble(
    covariate = c(
      "Observations ($N$)",
      "Clusters ($M$)",
      "$F$-statistic",
      "$p$-value"
    ),
    Z_1_bl = c(nrow(filter(bl, Z == 1)),
               20,
               NA,
               NA),
    Z_0_bl = c(nrow(filter(bl, Z == 0)),
               20,
               NA,
               NA),
    bal_p_bl = c(NA,
                 NA,
                 balance_results$joint_F_bl[[1]],
                 balance_results$joint_F_p_bl[[1]]),
    Z_1_el = c(nrow(filter(el, Z == 1)),
               20,
               NA,
               NA),
    Z_0_el = c(nrow(filter(el, Z == 0)),
               20,
               NA,
               NA),
    bal_p_el = c(NA,
                 NA,
                 balance_results$joint_F_el[[1]],
                 balance_results$joint_F_p_el[[1]])
  )

bottom_rows <-
  bottom_rows %>%
  mutate_at(vars(Z_1_bl, Z_0_bl, Z_1_el, Z_0_el), ~ as.character(.x)) %>%
  mutate_at(vars(bal_p_bl, bal_p_el), ~ as.character(ifelse(is.na(.x), .x, specd(.x, 3))))


table1 <-
  balance_results %>%
  unnest(bal_p_bl) %>%
  unnest(bal_p_el) %>%
  ungroup() %>%
  mutate(covariate = variable_labels) %>%
  select(covariate, Z_1_bl, Z_0_bl, bal_p_bl, Z_1_el, Z_0_el, bal_p_el) %>%
  mutate_at(vars(Z_1_bl, Z_0_bl, bal_p_bl, Z_1_el, Z_0_el, bal_p_el),
            ~ as.character(ifelse(is.na(.x), .x, specd(.x, 3)))) %>%
  bind_rows(bottom_rows)

write_rds(table1, "__data/results/table1.rds")

# table 2 -----------------------------------------------------------------

get_nice_ci <- function(model, treat = "Z") {
  model %>%
    tidy() %>%
    filter(term %in% treat) %>%
    mutate(ci = paste0("(", specd(conf.low, 3), ", ", specd(conf.high, 3), ")")) %>%
    pull(ci)
}

table2 <-
  bind_rows(primary_outcome_results, secondary_outcome_results) %>%
  ungroup() %>%
  mutate(
    outcome_labels = outcome_labels,
    unadj_effects = map(unadj_model, ~ get_estimate(.x)),
    adj_effects = map(adj_model, ~ get_estimate(.x)),
    unadj_ci = map(unadj_model, ~ get_nice_ci(.x)),
    adj_ci = map(adj_model, ~ get_nice_ci(.x))
  ) %>%
  unnest(c(unadj_effects, unadj_ci, unadj_p, adj_effects, adj_ci, adj_p)) %>%
  select(outcome_labels,
         unadj_effects,
         unadj_ci,
         unadj_p,
         adj_effects,
         adj_ci,
         adj_p)

write_rds(table2, "__data/results/table2.rds")


# table 3 -----------------------------------------------------------------

cace_iv_results <- read_rds("__data/results/cace_iv_results.rds")
cace_ipw_results <- read_rds("__data/results/cace_ipw_results.rds")

table3 <-
  left_join(
    cace_iv_results,
    cace_ipw_results,
    by = "outcome"
  ) %>%
  ungroup() %>%
  mutate(
    outcome_labels = outcome_labels,
    iv_effects = map(adj_model, get_estimate, treatment = "treated"),
    iv_ci = map(adj_model, get_nice_ci, treat = "treated"),
    ipw_effects = map(ipw_model, get_estimate, treatment = "ipc_attend"),
    ipw_ci = map(ipw_model, get_nice_ci, treat = "ipc_attend")
  ) %>%
  unnest(c(iv_effects, iv_ci, ipw_effects, ipw_ci)) %>%
  select(outcome_labels,
         iv_effects,
         iv_ci,
         ipw_effects,
         ipw_ci)
  
write_rds(table3, "__data/results/table3.rds")


# table s2 ----------------------------------------------------------------

pooled_outcome_results <- 
  read_rds("__data/results/pooled_outcome_results.rds")

