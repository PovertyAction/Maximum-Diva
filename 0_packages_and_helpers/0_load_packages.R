# Load packages -----------------------------------------------------------

library(tidyverse)
library(haven)
library(stringr)
library(DeclareDesign)
library(mice)
library(crayon)
library(knitr)
library(kableExtra)
library(texreg)
library(broom)
library(randomizr)

# Check file path ---------------------------------------------------------

# if(!grepl("boxcryptor", getwd(), TRUE))
#   stop(crayon::bgRed(white("You have not opened the Rproject on the Boxcryptor file path. Try again!")))
