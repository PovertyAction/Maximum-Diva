# add pooled values of centered baseline covariates to endline 
el <- left_join(el, bl_pool_c, by = "ward", suffix = c("", "_bl"))

# add random assignment
el <- left_join(el, ra, by = "ward")
bl <- left_join(bl, ra, by = "ward")

# confirm correct sample size
stopifnot(nrow(el) == 2430)
