
ods graphics off;

/* Read in dataset and initialize year */
  FILENAME &FYC. "C:\MEPS\&FYC..ssp";
  proc xcopy in = &FYC. out = WORK IMPORT;
  run;

  data MEPS;
    SET &FYC.;
    year = &year.;
    ind = 1;
    count = 1;

    /* Create AGELAST variable */
    if AGE&yy.X >= 0 then AGELAST=AGE&yy.x;
    else if AGE42X >= 0 then AGELAST=AGE42X;
    else if AGE31X >= 0 then AGELAST=AGE31X;
  run;

  proc format;
    value ind 1 = "Total";
  run;

/* Marital Status */
  data MEPS; set MEPS;
    ARRAY OLDMAR(2) MARRY1X MARRY2X;
    if year = 1996 then do;
      if MARRY2X <= 6 then MARRY42X = MARRY2X;
      else MARRY42X = MARRY2X-6;

      if MARRY1X <= 6 then MARRY31X = MARRY1X;
      else MARRY31X = MARRY1X-6;
    end;

    if MARRY&yy.X >= 0 then married = MARRY&yy.X;
    else if MARRY42X >= 0 then married = MARRY42X;
    else if MARRY31X >= 0 then married = MARRY31X;
    else married = .;
  run;

  proc format;
    value married
    1 = "Married"
    2 = "Widowed"
    3 = "Divorced"
    4 = "Separated"
    5 = "Never married"
    6 = "Inapplicable (age < 16)"
    . = "Missing";
  run;

/* Reason for difficulty receiving needed dental care */
data MEPS; set MEPS;
  delay_DN  = (DNUNAB42=1|DNDLAY42=1);
  afford_DN = (DNDLRS42=1|DNUNRS42=1);
  insure_DN = (DNDLRS42 in (2,3)|DNUNRS42 in (2,3));
  other_DN  = (DNDLRS42 > 3|DNUNRS42 > 3);
  domain = (ACCELI42 = 1 & delay_DN=1);
run;

proc format;
  value afford 1 = "Couldn't afford";
  value insure 1 = "Insurance related";
  value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT afford_DN afford. insure_DN insure. other_DN other. married married.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*married*(afford_DN insure_DN other_DN) / row;
run;

proc print data = out;
  where domain = 1 and (afford_DN > 0 or insure_DN > 0 or other_DN > 0) and married ne .;
  var afford_DN insure_DN other_DN married WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

