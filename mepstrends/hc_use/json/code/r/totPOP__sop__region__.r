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

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU.yy., VARSTR=VARSTR.yy.)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT.yy.F = WTDPER.yy.)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE.yy.X, AGE42X, AGE31X))

  FYC$ind = 1  

# Census region
  if(year == 1996)
    FYC <- FYC %>% mutate(REGION42 = REGION2, REGION31 = REGION1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("REGION")), funs(replace(., .< 0, NA))) %>%
    mutate(region = coalesce(REGION.yy., REGION42, REGION31)) %>%
    mutate(region = recode_factor(region, .default = "Missing", .missing = "Missing", 
      "1" = "Northeast",
      "2" = "Midwest",
      "3" = "South",
      "4" = "West"))

# Add aggregate sources of payment
  if(year <= 1999)
    FYC <- FYC %>% mutate(TOTTRI.yy. = TOTCHM.yy.)

  FYC <- FYC %>% mutate(
    TOTOTH.yy. = TOTOFD.yy. + TOTSTL.yy. + TOTOPR.yy. + TOTOPU.yy. + TOTOSR.yy.,
    TOTOTZ.yy. = TOTOTH.yy. + TOTWCP.yy. + TOTVA.yy.,
    TOTPTR.yy. = TOTPRV.yy. + TOTTRI.yy.)

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = FYC,
  nest = TRUE)

# Loop over sources of payment
  sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")
  results <- list()

  for(sp in sops) {
    key <- paste0("TOT", sp)
    formula <- as.formula(sprintf("~(%s.yy. > 0)", key))
    results[[key]] <- svyby(formula, FUN = svytotal, by = ~region, design = FYCdsgn)
  }

print(results)
