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

# Usual source of care
  FYC <- FYC %>%
    mutate(usc = ifelse(HAVEUS42 == 2, 0, LOCATN42)) %>%
    mutate(usc = recode_factor(usc, .default = "Missing", .missing = "Missing", 
      "0" = "No usual source of health care",
      "1" = "Office-based",
      "2" = "Hospital (not ER)",
      "3" = "Emergency room"))

# Insurance coverage
# To compute for all insurance categories, replace 'insurance' in the 'svyby' function with 'insurance_v2X'
  if(year == 1996){
    FYC <- FYC %>%
      mutate(MCDEV96 = MCDEVER, MCREV96 = MCREVER,
             OPAEV96 = OPAEVER, OPBEV96 = OPBEVER)
  }

  if(year < 2011){
    FYC <- FYC %>%
      mutate(
        public   = (MCDEV.yy.==1|OPAEV.yy.==1|OPBEV.yy.==1),
        medicare = (MCREV.yy.==1),
        private  = (INSCOV.yy.==1),

        mcr_priv = (medicare &  private),
        mcr_pub  = (medicare & !private & public),
        mcr_only = (medicare & !private & !public),
        no_mcr   = (!medicare),

        ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr,
        INSURC.yy. = ifelse(AGELAST < 65, INSCOV.yy., ins_gt65)
      )
  }

  FYC <- FYC %>%
    mutate(insurance = recode_factor(INSCOV.yy., .default = "Missing", .missing = "Missing", 
      "1" = "Any private, all ages",
      "2" = "Public only, all ages",
      "3" = "Uninsured, all ages")) %>%
    mutate(insurance_v2X = recode_factor(INSURC.yy., .default = "Missing", .missing = "Missing",
      "1" = "<65, Any private",
      "2" = "<65, Public only",
      "3" = "<65, Uninsured",
      "4" = "65+, Medicare only",
      "5" = "65+, Medicare and private",
      "6" = "65+, Medicare and other public",
      "7" = "65+, No medicare",
      "8" = "65+, No medicare"))

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~usc, FUN = svytotal, by = ~insurance, design = subset(FYCdsgn, ACCELI42==1 & HAVEUS42 >= 0 & LOCATN42 >= -1))
print(results)
