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

# Race / ethnicity
  # Starting in 2012, RACETHX replaced RACEX;
  if(year >= 2012){
    FYC <- FYC %>%
      mutate(white_oth=F,
        hisp   = (RACETHX == 1),
        white  = (RACETHX == 2),
        black  = (RACETHX == 3),
        native = (RACETHX > 3 & RACEV1X %in% c(3,6)),
        asian  = (RACETHX > 3 & RACEV1X %in% c(4,5)))

  }else if(year >= 2002){
    FYC <- FYC %>%
      mutate(white_oth=0,
        hisp   = (RACETHNX == 1),
        white  = (RACETHNX == 4 & RACEX == 1),
        black  = (RACETHNX == 2),
        native = (RACETHNX >= 3 & RACEX %in% c(3,6)),
        asian  = (RACETHNX >= 3 & RACEX %in% c(4,5)))

  }else{
    FYC <- FYC %>%
      mutate(
        hisp = (RACETHNX == 1),
        black = (RACETHNX == 2),
        white_oth = (RACETHNX == 3),
        white = 0,native=0,asian=0)
  }

  FYC <- FYC %>% mutate(
    race = 1*hisp + 2*white + 3*black + 4*native + 5*asian + 9*white_oth,
    race = recode_factor(race, .default = "Missing", .missing = "Missing", 
      "1" = "Hispanic",
      "2" = "White",
      "3" = "Black",
      "4" = "Amer. Indian, AK Native, or mult. races",
      "5" = "Asian, Hawaiian, or Pacific Islander",
      "9" = "White and other"))

# Education
  if(year <= 1998){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYR.yy.)
  }else if(year <= 2004){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYEAR)
  }

  if(year >= 2012 & year < 2016){
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDRECODE & EDRECODE < 13),
        high_school  = (EDRECODE == 13),
        some_college = (EDRECODE > 13))

  }else{
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDUCYR & EDUCYR < 12),
        high_school  = (EDUCYR == 12),
        some_college = (EDUCYR > 12))
  }

  FYC <- FYC %>% mutate(
    education = 1*less_than_hs + 2*high_school + 3*some_college,
    education = replace(education, AGELAST < 18, 9),
    education = recode_factor(education, .default = "Missing", .missing = "Missing",
      "1" = "Less than high school",
      "2" = "High school",
      "3" = "Some college",
      "9" = "Inapplicable (age < 18)",
      "0" = "Missing"))

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~TOTEXP.yy., FUN=svymean, by = ~education + race, design = FYCdsgn)
print(results)
