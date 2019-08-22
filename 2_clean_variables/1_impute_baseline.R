set.seed(18807)

tmp <- mice(bl)
bl <- complete(tmp)

# tmp <- mice(el)
# el <- complete(tmp)