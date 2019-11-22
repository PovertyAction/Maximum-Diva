primary_outcomes <- c(
  "fc_use_ever",
  "fc_use_6mo",
  "fc_use_last",
  "any_use_ever",
  "any_use_6mo",
  "any_use_last",
  "fc_try"
)

secondary_outcomes <- c(
  "cont_z_know",
  "fc_recognize",
  "mc_z_opinion",
  "fc_z_opinion",
  "cont_discussed"
)

outcomes <- c(
  primary_outcomes,
  secondary_outcomes
)

balance_covariates <- c(
  "female",
  "age",
  "edu_secondary",
  "edu_higher",
  "literacy",
  "married",
  "children",
  "employed",
  "sex_age",
  "sex_partners_ever",
  "sex_partners_6mo",
  "sex_freq_1mo",
  "sex_sti_test",
  "mc_broke",
  "cont_travel_30min",
  "fc_use_ever",
  "fc_use_6mo",
  "fc_use_last",
  "any_use_ever",
  "any_use_6mo",
  "any_use_last",
  "fc_try",
  "cont_z_know",
  "mc_z_opinion",
  "fc_z_opinion",
  "fc_recognize",
  "cont_discussed"
)

outcome_labels <- c(
  "Ever used female condom [0,1]",
  "Used female condom in last 6 months [0,1]",
  "Used female condom at most recent sex [0,1]",
  "Ever used any condom [0,1]",
  "Used any condom in last 6 months [0,1]",
  "Used any condom at most recent sex [0,1]",
  "Would be willing to try a female condom [0,1]",
  "Contraceptive knowledge index, z-score",
  "Correctly identifies a female condom [0,1]",
  "Male condoms attitudes index, z-score",
  "Female condoms attitudes index, z-score",
  "Discussed contraceptive use, [0,1]"
)

variable_labels <- c(
  "Female [0,1]",
  "Age",
  "Completed some secondary school [0,1]",
  "Completed some post secondary school [0,1]",
  "Can read and write [0,1]",
  "Married [0,1]",
  "Has children [0,1]",
  "Is currently employed [0,1]",
  "Age at first sex",
  "Lifetime sex partners (n)",
  "Sex partners in last 6 months (n)",
  "Frequency of sex in last month (n)",
  "Has been tested for STIs [0,1]",
  "Has experienced a male condom break [0,1]",
  "Travels at least 30 min to buy contraception [0,1]",
  "Ever used female condom [0,1]",
  "Used female condom in last 6 months [0,1]",
  "Used female condom at most recent sex [0,1]",
  "Ever used any condom [0,1]",
  "Used any condom in last 6 months [0,1]",
  "Used any condom at most recent sex [0,1]",
  "Would be willing to try a female condom [0,1]",
  "Contraceptive knowledge index, z-score",
  "Correctly identifies a female condom [0,1]",
  "Male condoms attitudes index, z-score",
  "Female condoms attitudes index, z-score",
  "Discussed contraceptive use, [0,1]"
)
