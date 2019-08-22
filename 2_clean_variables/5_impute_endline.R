set.seed(463598)

el_dont_impute <- grepl("_c$", names(el)) | names(el) == "Z"
tmp <- mice(el[, -el_dont_impute])
el[, -el_dont_impute] <- complete(tmp)