options(knitr.kable.NA = '')
options(kableExtra.auto_format = FALSE)


# Table 1 -----------------------------------------------------------------

sink("8_manuscript/tables/table1.tex")
kable(
  table1,
  digits = 3,
  format = "latex",
  col.names = c(
    "Variable",
    "Treatment",
    "Control",
    "$p$-value",
    "Treatment",
    "Control",
    "$p$-value"
  ),
  align = c("l", "c", "c", "c", "c", "c", "c"),
  caption = "Baseline balance",
  booktabs = TRUE,
  escape = FALSE
) %>%
  kable_styling(font_size = 9, latex_options = "striped") %>%
  group_rows("Socio-demographic controls",
             1,
             15,
             italic = TRUE,
             bold = FALSE) %>%
  group_rows("Primary outcomes", 16, 22, italic = TRUE, bold = FALSE) %>%
  group_rows("Secondary outcomes",
             23,
             27,
             italic = TRUE,
             bold = FALSE) %>%
  group_rows("", 28, 32, indent = FALSE, hline_before = TRUE) %>%
  add_header_above(c(
    " ",
    "($N = 2364$; $M = 40$)" = 3,
    "($N = 2430$; $M = 40$)" = 3
  ), escape = FALSE) %>%
  add_header_above(c(" ", "Baseline" = 3, "Endline" = 3),
                   escape = FALSE,
                   line = FALSE)
sink()


# Table 2 -----------------------------------------------------------------

sink("8_manuscript/tables/table2.tex")
kable(
  table2,
  digits = 3,
  format = "latex",
  col.names = c(
    "",
    "$\\widehat{\\tau}$",
    "95\\% CI",
    "$p$-value",
    "$\\widehat{\\tau}$",
    "95\\% CI",
    "$p$-value"
  ),
  align = c("l", "c", "c", "c", "c", "c", "c"),
  caption = "Intention-to-treat effects",
  booktabs = TRUE,
  escape = FALSE
) %>%
  kable_styling(font_size = 9, latex_options = "striped") %>%
  group_rows("Primary outcomes", 1, 7, italic = TRUE, bold = FALSE) %>%
  group_rows("Secondary outcomes", 8, 12, italic = TRUE, bold = FALSE) %>%
  add_header_above(c(" ", "Unadjusted" = 3, "Adjusted" = 3))
sink()


# Table 3 -----------------------------------------------------------------

sink("8_manuscript/tables/table3.tex")
kable(
  table3,
  digits = 3,
  format = "latex",
  col.names = c(
    "",
    "$\\widehat{\\tau}$",
    "95\\% CI",
    "$\\widehat{\\tau}$",
    "95\\% CI"
  ),
  align = c("l", "c", "c", "c", "c"),
  caption = "Compliance effects",
  booktabs = TRUE,
  escape = FALSE
) %>%
  kable_styling(font_size = 9, latex_options = "striped") %>%
  group_rows("Primary outcomes", 1, 7, italic = TRUE, bold = FALSE) %>%
  group_rows("Secondary outcomes", 8, 12, italic = TRUE, bold = FALSE) %>%
  add_header_above(c(" ", "IV" = 2, "IPW" = 2))
sink()