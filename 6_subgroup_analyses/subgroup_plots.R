gender_hetero_results <- read_rds("__data/results/gender_hetero_results.rds")
married_hetero_results <- read_rds("__data/results/married_hetero_results.rds")

get_asymp_ci <- function(model, treat = "Z") {
  model %>% 
    tidy() %>%
    filter(term %in% treat) %>%
    select(conf.low, conf.high)
}

hetx_plot_df <- 
  gender_hetero_results %>%
  mutate(
    type = ifelse(outcome %in% primary_outcomes,
                  "Primary Outcomes",
                  "Secondary Outcomes"),
    outcome = outcome_labels,
    male = map(hetx_models_0, get_asymp_ci),
    female = map(hetx_models_1, get_asymp_ci)
  ) %>%
  unnest(c("male", "female"), names_sep = "_") %>%
  unnest(c("hetx_effects", "hetx_p")) %>%
  mutate(subgroup = rep(c("Men", "Women", "Diff"), length(outcomes)))

gender_subgroup_plot <-
  ggplot(filter(hetx_plot_df, subgroup != "Diff"),
       aes(x = hetx_effects, y = fct_relevel(outcome, rev(outcome_labels)))) +
  geom_point() +
  geom_vline(xintercept = 0, linetype = "dotted") +
  geom_segment(
    aes(x = male_conf.low, xend = male_conf.high, yend = outcome),
    data = filter(hetx_plot_df, subgroup == "Men")
  ) +
  geom_segment(
    aes(x = female_conf.low, xend = female_conf.high, yend = outcome),
    data = filter(hetx_plot_df, subgroup == "Women")
  ) +
  facet_grid(type ~ subgroup, scales = "free_y", space = "free_y") +
  labs(x = "Effect of IPC intervention",
       y = "") +
  md_theme()

pdf("8_manuscript/figures/gender_subgroup_plot.pdf", width = 8, height = 5)
gender_subgroup_plot %>% print()
dev.off()

hetx_plot_df <- 
  married_hetero_results %>%
  mutate(
    type = ifelse(outcome %in% primary_outcomes,
                  "Primary Outcomes",
                  "Secondary Outcomes"),
    outcome = outcome_labels,
    unmarried = map(hetx_models_0, get_asymp_ci),
    married = map(hetx_models_1, get_asymp_ci)
  ) %>%
  unnest(c("unmarried", "married"), names_sep = "_") %>%
  unnest(c("hetx_effects", "hetx_p")) %>%
  mutate(subgroup = rep(c("Unmarried", "Married", "Diff"), length(outcomes)))

married_subgroup_plot <-
  ggplot(filter(hetx_plot_df, subgroup != "Diff"),
       aes(x = hetx_effects, y = fct_relevel(outcome, rev(outcome_labels)))) +
  geom_point() +
  geom_vline(xintercept = 0, linetype = "dotted") +
  geom_segment(
    aes(x = unmarried_conf.low, xend = unmarried_conf.high, yend = outcome),
    data = filter(hetx_plot_df, subgroup == "Unmarried")
  ) +
  geom_segment(
    aes(x = married_conf.low, xend = unmarried_conf.high, yend = outcome),
    data = filter(hetx_plot_df, subgroup == "Married")
  ) +
  facet_grid(type ~ subgroup, scales = "free_y", space = "free_y") +
  labs(x = "Effect of IPC intervention",
       y = "") +
  md_theme()

pdf("8_manuscript/figures/married_subgroup_plot.pdf", width = 8, height = 5)
married_subgroup_plot %>% print()
dev.off()

pdf("8_manuscript/figures/subgroup_plot.pdf", width = 8, height = 10, onefile = FALSE)
ggarrange(
  gender_subgroup_plot,
  married_subgroup_plot,
  nrow = 2,
  ncol = 1
) %>% print()
dev.off()
