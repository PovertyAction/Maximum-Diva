ra <- read_csv(
  "__data/md_randomization.csv"
)

ra <- select(ra, ward, Z, block)