# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/.FYC..ssp');
  year <- .year.
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE.yy.X, AGE42X, AGE31X))

  FYC$ind = 1

# Diabetes care: Hemoglobin A1c measurement
  FYC <- FYC %>%
    mutate(diab_a1c = ifelse(0 < DSA1C53 & DSA1C53 < 96, 1, DSA1C53)) %>%
    mutate(diab_a1c = replace(diab_a1c,DSA1C53==96,0)) %>%
    mutate(diab_a1c = recode_factor(diab_a1c, .default = "Missing", .missing = "Missing", 
      "1" = "Had measurement",
      "0" = "Did not have measurement",
      "-7" = "Don\'t know/Non-response",
      "-8" = "Don\'t know/Non-response",
      "-9" = "Don\'t know/Non-response",
      "-1" = "Inapplicable"))

# Sex
  FYC <- FYC %>%
    mutate(sex = recode_factor(SEX, .default = "Missing", .missing = "Missing", 
      "1" = "Male",
      "2" = "Female"))

DIABdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~DIABW.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~diab_a1c, FUN = svytotal, by = ~sex, design = DIABdsgn)
print(results)
