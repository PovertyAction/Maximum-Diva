pooled_df <-
  el %>%
  group_by(block, Z, ward) %>%
  add_count() %>%
  summarise_at(c(primary_outcomes, "n"), mean) %>%
  gather(outcome, value, primary_outcomes)

get_marginal_mean <- function(model, terms) {
  mean(model$fixed_effects)
}

pooled_estimates <-
  map(primary_outcomes,
      function(x) {
        fit <- lm_robust(
          formula = reformulate(
            termlabels = c(
              "Z",
              get_covariates(x, selected_baseline_covariates),
              get_covariates(x, selected_endline_covariates),
              paste0("Z", ":", get_covariates(x, selected_baseline_covariates)),
              paste0("Z", ":", get_covariates(x, selected_endline_covariates))
            ),
            response = x
          ),
          data = el %>% group_by(ward) %>% add_count() %>% mutate(ipw = 1 / n) %>% ungroup(),
          clusters = ward,
          weights = ipw,
          se_type = "stata"
        )
        
        newdata <-
          el %>%
          group_by(Z) %>%
          summarise_at(c(paste0(
            get_covariates(x, selected_baseline_covariates)
          ),
          paste0(
            get_covariates(x, selected_endline_covariates)
          )),
          function (x) {
            x = 0
          })
        cis <-
          predict(fit,
                  newdata = newdata,
                  interval = "confidence",
                  alpha = 0.05)
        data.frame(
          estimate_0 = cis$fit[1, 1],
          estimate_1 = cis$fit[2, 1],
          conf.low_0 = cis$fit[1, 2],
          conf.high_0 = cis$fit[1, 3],
          conf.low_1 = cis$fit[2, 2],
          conf.high_1 = cis$fit[2, 3]
        )
      }) %>%
  bind_rows()


pooled_estimates$outcome <- primary_outcomes


pooled_estimates <-
  pooled_estimates %>%
  gather(variable, value, -outcome) %>%
  separate(variable, c("variable", "Z"), sep = "_") %>%
  spread(variable, value)


pooled_estimates <-
  filter(pooled_estimates, str_detect(outcome, "fc_use"))
pooled_df <- filter(pooled_df, str_detect(outcome, "fc_use"))

pooled_estimates <- pooled_estimates %>%
  mutate(
    outcome_labels = case_when(
      outcome == "fc_use_ever" ~ "Ever used female condom [0,1]",
      outcome == "fc_use_6mo" ~ "Used female condom\nin last 6 months [0,1]",
      outcome == "fc_use_last" ~ "Used female condom\nat most recent sex [0,1]"
    )
  )

pooled_df <- pooled_df %>%
  mutate(
    outcome_labels = case_when(
      outcome == "fc_use_ever" ~ "Ever used female condom [0,1]",
      outcome == "fc_use_6mo" ~ "Used female condom\nin last 6 months [0,1]",
      outcome == "fc_use_last" ~ "Used female condom\nat most recent sex [0,1]"
    )
  )


p <-
  ggplot(pooled_estimates,
         aes(x = factor(Z, labels = c(
           "Control", "Treatment"
         )),
         y = estimate)) +
  geom_jitter(
    aes(
      x = factor(Z, labels = c("Control", "Treatment")),
      y = value,
      size = n
    ),
    data = pooled_df,
    width = 0.35,
    height = 0.001,
    alpha = 0.15,
    stroke = 0
  ) +
  geom_point() +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0) +
  geom_text(aes(label = specd(estimate, 3)), size = 2.5, nudge_x = 0.175, family = "Palatino") +
  facet_grid(~ fct_relevel(
    outcome_labels,
    c(
      "Ever used female condom [0,1]",
      "Used female condom\nin last 6 months [0,1]"
    )
  )) +
  labs(x = "",
       y = "Proportion answering 'Yes'") +
  scale_size_continuous(name = "N per ward") +
  md_theme()

pdf(
  "8_manuscript/figures/primary_outcomes_plot.pdf",
  width = 8,
  height = 5
)
p %>% print()
dev.off()
