pre_post_df <-
  el %>%
  bind_rows(bl, .id = "dataset") %>%
  mutate(post = as.numeric(dataset == 1))

pre_post_df[, paste0(el_to_center, "_c")] <- 
  scale(
    pre_post_df[, el_to_center],
    center = TRUE,
    scale = FALSE
  )

# create nested data frame 
nested_pre_post_df <-
  pre_post_df %>%
  group_by(dataset, ward) %>%
  add_count() %>%
  mutate(ipw = 1 / n) %>%
  ungroup() %>% 
  gather(outcome, value, outcomes) %>%
  group_by(outcome) %>%
  nest() 


# run models --------------------------------------------------------------

pre_post_results <-
  nested_pre_post_df %>%
  mutate(
    # pre-post model
    unadj_model = map(
      data, 
      function (x) {
        lm_robust(
          formula = value ~ post,
          data = x,
          clusters = ward,
          weights = ipw
        )
      }),
    # pre-post model
    adj_model = map2(
      data, 
      outcomes,
      function (x, y) {
        lm_robust(
          formula = reformulate(
            termlabels = c(
              "post", 
              get_covariates(y, selected_endline_covariates),
              paste0("post", ":", get_covariates(y, selected_endline_covariates))
            ),
            response = "value"
          ),
          data = x,
          clusters = ward,
          weights = ipw
        )      
      })
  )

write_rds(pre_post_results, "__data/results/pre_post_results.rds")
