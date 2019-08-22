rm(list = ls())


# global parameters -------------------------------------------------------

lasso_sims <- 10
lasso_folds <- 30

sims <- 1000


# Packages and helper functions -------------------------------------------

source("0_packages_and_helpers/0_load_packages.R")

source("0_packages_and_helpers/1_load_helpers.R")


# Load data ---------------------------------------------------------------

source("1_load_data/1_load_baseline.R")

source("1_load_data/2_load_randomization.R")

source("1_load_data/3_load_intervention.R")

source("1_load_data/4_load_endline.R")


# Data cleaning and preparation -------------------------------------------

source("2_clean_variables/0_make_replacements.R")

source("2_clean_variables/1_impute_baseline.R")

source("2_clean_variables/2_pool_baseline.R")

source("2_clean_variables/3_center_covariates.R")

source("2_clean_variables/4_merge_datasets.R")

source("2_clean_variables/5_impute_endline.R")

source("2_clean_variables/6_create_outcomes.R")

source("2_clean_variables/7_create_variable_lists.R")


# Select covariates -------------------------------------------------------

source("3_covariate_selection/1_covariate_lists.R")

source("3_covariate_selection/2_select_covariates.R")


# Main analyses -----------------------------------------------------------

source("4_main_analyses/primary_outcomes.R")

# source("4_main_analyses/primary_outcomes_plots.R")


# Secondary analyses ------------------------------------------------------

source("5_secondary_analyses/secondary_outcomes.R")

source("5_secondary_analyses/pre_post_analysis.R")

source("5_secondary_analyses/complier_average_effects.R")


# Subgroup analyses -------------------------------------------------------

source("6_subgroup_analyses/heterogeneous_effects_gender.R")

source("6_subgroup_analyses/heterogeneous_effects_married.R")


# Robustness checks -------------------------------------------------------

source("7_robustness_checks/covariate_balance.R")

source("7_robustness_checks/alternative_specifications.R")

source("7_robustness_checks/pooled_results.R")

source("7_robustness_checks/leave_one_out.R")


