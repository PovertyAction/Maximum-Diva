# create list of pooled baseline covariates to run through lasso
baseline_covariates <- names(el)[grepl("_bl\\b", names(el))]

# create list of invariant endline covariates to run through lasso
endline_covariates <- names(el)[grepl("_c\\b", names(el))]