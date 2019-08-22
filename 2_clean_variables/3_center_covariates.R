# Center pooled baseline covariates ---------------------------------------

bl_to_center <-
  bl_pool %>% select(-ward) %>% names()

bl_pool_c <- bl_pool

bl_pool_c[, bl_to_center] <-
  scale(
    bl_pool[, bl_to_center], 
    center = TRUE, 
    scale = FALSE
  )


# Center invariant endline covariates -------------------------------------

el_to_center <- c(
  "female",
  "age",
  "edu_secondary",
  "edu_higher",
  "married",
  "literacy",
  "employed"
)

el[, paste0(el_to_center, "_c")] <- 
  scale(
    el[, el_to_center],
    center = TRUE,
    scale = FALSE
  )
