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

# Rating for care (children)
  FYC <- FYC %>%
    mutate(
      child_rating = as.factor(case_when(
        .$CHHECR42 >= 9 ~ "9-10 rating",
        .$CHHECR42 >= 7 ~ "7-8 rating",
        .$CHHECR42 >= 0 ~ "0-6 rating",
        .$CHHECR42 == -1 ~ "Inapplicable",
        .$CHHECR42 <= -7 ~ "Don\'t know/Non-response",
        TRUE ~ "Missing")))

# Poverty status
  if(year == 1996)
    FYC <- FYC %>% rename(POVCAT96 = POVCAT)

  FYC <- FYC %>%
    mutate(poverty = recode_factor(POVCAT.yy., .default = "Missing", .missing = "Missing", 
      "1" = "Negative or poor",
      "2" = "Near-poor",
      "3" = "Low income",
      "4" = "Middle income",
      "5" = "High income"))

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~child_rating, FUN=svymean, by = ~poverty, design = subset(FYCdsgn, CHAPPT42 >= 1 & AGELAST < 18))
print(results)
