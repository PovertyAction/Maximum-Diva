source("0_packages_and_helpers/__lasso_functions.R")
#source("0_packages_and_helpers/__analysis_functions.R")


# Load helper functions ---------------------------------------------------

get_covariates <- function(outcome_name, covariate_frame){
  if(!outcome_name %in% covariate_frame$outcome) {
    print(paste0("No covariates found for ",outcome_name,".\nDid you use the right lasso dataset?"))
    return(NULL)}
  covariate_frame %>% filter(outcome == outcome_name) %>% select(term) %>% 
    unlist()
}

get_data <- function(path) {
  paste0("../../../../", path)
}

specd <- function(x, k) trimws(format(round(x, k), nsmall=k))

# a ggplot theme for Stellar plots
md_theme <-
  function() {
    theme_bw() +
      theme(
        axis.ticks = element_blank(),
        axis.line = element_blank(),
        panel.border = element_blank(),
        panel.grid.major = element_line(color = '#eeeeee'),
        strip.background = element_blank(),
        legend.position = "bottom",
        text = element_text(family = "Palatino"),
        plot.title = element_text(hjust = 0.5)
      )
  }

plot_treatment_effects <- function(
    fit,
    outcome,
    data,
    type = "individual",
    color = NULL,
    color_name = NULL,
    color_values = NULL,
    color_labels = NULL,
    title = NULL,
    ylabel = outcome,
    xlabel = NULL
  ) {
  
    plot_df <-
      data %>%
      group_by(treatment) %>%
      summarise(n = n()) %>%
      ungroup()
  
    predictions <-
      predict(fit,
              newdata = plot_df,
              interval = "confidence",
              alpha = 0.05)
  
    plot_df <-
      plot_df %>%
      mutate(
        pred = predictions$fit[, 1],
        conf95_low = predictions$fit[, 2],
        conf95_high = predictions$fit[, 3],
        label = specd(pred, 3)
      )
  
    p <- ggplot(plot_df, aes(
      x = factor(treatment, labels = c("Control", "Treatment")),
      y = pred, 
    )) 
    
    if (type == "cluster") {
      if (is.null(color)) {
        p <- p + geom_jitter(
          aes(
            x = factor(treatment, labels = c("Control", "Treatment")),
            y = get(outcome),
            size = n
          ),
          data = data,
          alpha = 0.30,
          width = 0.2,
          height = 0
        ) 
      } else {
        p <- p + geom_jitter(
          aes(
            x = factor(treatment, labels = c("Control", "Treatment")),
            y = get(outcome),
            size = n,
            color = factor(get(color))
          ),
          data = data,
          alpha = 0.30,
          width = 0.2,
          height = 0
        ) 
      }
    } else {
      if (is.null(color)) {
        p <- p + geom_jitter(
          aes(
            x = factor(treatment, labels = c("Control", "Treatment")),
            y = get(outcome)
          ),
          data = data,
          alpha = 0.30,
          width = 0.2,
          height = 0.0
        ) 
      } else {
        p <- p + geom_jitter(
          aes(
            x = factor(treatment, labels = c("Control", "Treatment")),
            y = get(outcome),
            color = factor(get(color))
          ),
          data = data,
          alpha = 0.30,
          width = 0.2,
          height = 0.1
        ) 
      }
    }
    
    p <- p +
      geom_point() +
      geom_text(aes(label = label), nudge_x = 0.075, size = 3) +
      geom_errorbar(aes(ymin = conf95_low, ymax = conf95_high), width = 0) +
      labs(
        title = title,
        x = xlabel,
        y = ylabel
      ) +
      md_theme() +
      scale_color_manual(
        name = color_name,
        values = color_values,
        labels = color_labels
      ) + 
      theme(
        legend.position = "bottom",
        axis.title = element_text(size = 10), 
        plot.title = element_text(size = 10)
      )
    
    return(p)
}


plot_coefs <- function(plot_data, levels){
  plot_data$outcome <- factor(plot_data$outcome, levels = levels)
  ggplot(plot_data, aes(y = outcome, x = estimate)) +
    geom_point() +
    geom_vline(xintercept = 0, linetype = "dashed", size = .25) +
    geom_segment(aes(x = conf.low, xend = conf.high, y = outcome, yend = outcome), 
                 alpha = .3) + 
    facet_grid(adjusted~blocks) + 
    labs(
      x = "Treatment Effect",
      y = ""
    ) +
    mmc_theme()
}

plot_balance <- function(plot_data, levels){
  plot_data$outcome <- factor(plot_data$outcome, levels = levels)
  ggplot(plot_data, aes(y = outcome, x = estimate)) +
    geom_point() +
    geom_vline(xintercept = 0, linetype = "dashed", size = .25) +
    geom_segment(aes(x = conf.low, xend = conf.high, y = outcome, yend = outcome), 
                 alpha = .3) + 
    facet_grid(~blocks) + 
    labs(
      x = "Treatment Effect",
      y = ""
    ) +
    mmc_theme()
}

main_estimator <-
  function (outcome,
            covariates = NULL,
            treatment = "Z",
            data,
            fixed_effects = "block",
            clusters = "ward",
            weights = "ipw",
            se_type = "stata",   
            subgroup = NULL,
            ci = TRUE,
            return_vcov = FALSE,
            try_cholesky = FALSE) {
    if (is.null(covariates)) {
      f <- reformulate(treatment, outcome)
    } else {
      f <- reformulate(termlabels = c(treatment,
                                      covariates,
                                      paste0(treatment, ":", covariates)),
                       response = outcome)
    }
    if (!is.null(clusters)) {
      clusters <- sym(clusters)
    }
    if (!is.null(weights)) {
      weights <- sym(weights)
    }
    if (!is.null(fixed_effects)) {
      fixed_effects <- sym(fixed_effects)
    }
    if (!is.null(subgroup)) {
      if (!is.character(subgroup))
        stop("You must provide subgroup as a character string.")
      data <- subset(data, eval(parse(text = subgroup)))
    }
    
    lm_robust(
      formula = f,
      data = data,
      clusters = !!clusters,
      fixed_effects = !!fixed_effects,
      weights = !!weights,
      ci = ci,
      return_vcov = return_vcov,
      try_cholesky = try_cholesky,
      se_type = se_type
    )
  }


rerandomize <- function(data, sims) {
  declaration <- with(data,
                      declare_ra(
                        blocks = block,
                        clusters = ward,
                        prob = 0.5
                      ))
  
  permutation_matrix <- replicate(sims, conduct_ra(declaration))
  
  return(permutation_matrix)
}

ri <-
  function(data,
           outcome,
           treatment = "Z",
           covariates = NULL,
           fixed_effects = "block",
           clusters = "ward",
           weights = "ipw",
           se_type = "none",
           print = outcome,
           extract = get_estimate,
           term = treatment,
           sims) {
    
  cat(paste0("   outcome: ", print, "\n"))
  cat(paste0("   simulating ", sims, " assignments under the sharp null...\n"))
 
  Z_sims <- rerandomize(data, sims)
  
  pb <- txtProgressBar(min = 0, max = sims, style = 3)
  i <- 1
  
  reps <- apply(
    Z_sims, 
    2, 
    function(Z_sim) {
      i <<- i + 1
      
      if (outcome == "Z") {
        data[, outcome] <- Z_sim
      } else {
        data[, treatment] <- Z_sim
      }
      
      fit <-
        main_estimator(
          outcome = outcome,
          covariates = covariates,
          treatment = treatment,
          clusters = clusters,
          fixed_effects = fixed_effects,
          weights = weights,
          se_type = se_type,
          data = data,
          ci = FALSE,
          return_vcov = FALSE, 
          try_cholesky = TRUE
        )
      
      setTxtProgressBar(pb, i)
      
      extract(fit, term)
    })
 
  cat("\n")
  close(pb)
  return(reps)
}

ri_interaction <-
  function(data,
           outcome,
           sharp_null,
           subgroup,
           treatment = "Z",
           covariates = NULL,
           fixed_effects = "block",
           clusters = "ward",
           weights = "ipw",
           se_type = "none",
           print = outcome,
           extract = get_estimate,
           term = treatment,
           sims) {
    
    cat(paste0("   outcome: ", print, "\n"))
    cat(paste0("   subgroups: ", subgroup, "\n"))
    cat(paste0("   simulating ", sims, " assignments under the sharp null...\n"))
    
    if (!is.null(covariates)) {
      res_covs <- str_subset(covariates, subgroup, negate = TRUE)
    } else {
      res_covs <- NULL
    }
    
    Z_sims <- rerandomize(data, sims)
    
    pb <- txtProgressBar(min = 0, max = sims, style = 3)
    i <- 1
    
    reps <- apply(
      Z_sims, 
      2, 
      function(Z_sim) {
        i <<- i + 1
        
        if (outcome == "Z") {
          data[, outcome] <- Z_sim
        } else {
          data[, treatment] <- Z_sim
        }
        
        fit_0 <-
          main_estimator(
            outcome = outcome,
            covariates = res_covs,
            treatment = treatment,
            subgroup = paste0(subgroup, " == 0"),
            clusters = clusters,
            fixed_effects = fixed_effects,
            weights = weights,
            se_type = se_type,
            data = data,
            ci = FALSE,
            return_vcov = FALSE, 
            try_cholesky = TRUE
          )
        
        fit_1 <-
          main_estimator(
            outcome = outcome,
            covariates = res_covs,
            treatment = treatment,
            subgroup = paste0(subgroup, " == 1"),
            clusters = clusters,
            fixed_effects = fixed_effects,
            weights = weights,
            se_type = se_type,
            data = data,
            ci = FALSE,
            return_vcov = FALSE, 
            try_cholesky = TRUE
          )
        
        Y_0 <- data[, outcome] - sharp_null * Z_sim 
        Y_1 <- data[, outcome] + sharp_null * (1 - Z_sim)
        data[, "Y_sim"] <- Y_0 * (1 - Z_sim) + Y_1 * Z_sim
        
        fit_full <- 
          main_estimator(
            outcome = "Y_sim",
            covariates = c(subgroup, covariates),
            treatment = treatment,
            clusters = clusters,
            fixed_effects = fixed_effects,
            weights = weights,
            se_type = se_type,
            data = data,
            ci = FALSE,
            return_vcov = FALSE, 
            try_cholesky = TRUE
          )
        
        setTxtProgressBar(pb, i)
        
        c(
          extract(fit_0, term),
          extract(fit_1, term),
          extract(fit_full, paste0(term, ":", subgroup))
        )
      })
    
    cat("\n")
    close(pb)
    return(reps)
  }


get_p <- function(observed_effect, null_distribution, hypothesis = "two") {
  if (hypothesis == "two") {
    mean(abs(null_distribution) >= abs(observed_effect))
  } else if (hypothesis %in% c("upper", "positive")) {
    mean(null_distribution >= observed_effect)
  } else if (hypothesis %in% c("lower", "negative")) {
    mean(null_distribution <= observed_effect)
  } else {
    stop("You have not supplied a valid hypothesis direction. Please choose:\n two; 'upper' (alt: 'positive'); or 'lower' (alt: 'negative').")
  }
}

get_estimate <- function(model, treatment = "Z"){
  model %>% 
    tidy() %>% 
    filter(term == treatment) %>% 
    pull(estimate)
}

get_F <- function(model, term) {
  model$proj_fstatistic[1] %>% as.numeric()
}

get_ci <- function(observed_effect, null_distribution) {
  observed_effect + quantile(null_distribution, probs = c(0.025, 0.975))
}

get_interaction_terms <- function(model, terms) {
  model %>% 
    tidy() %>% 
    filter(term %in% terms) %>% 
    pull(estimate)
}
get_estimate_quick <- function(model, treatment = "Z"){
  coef_mat <- coef(model)
  coef_mat[, treatment_variable]
}

# source("00_packages_and_helpers/helpers_codebook.R")
# source("0_packages_and_helpers/__p_value_functions.R")
# source("00_packages_and_helpers/helpers_plot_functions.R")
# source("00_packages_and_helpers/helpers_table_functions.R")
