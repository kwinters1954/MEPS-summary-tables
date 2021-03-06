
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

/* Rating for care (children) */
data MEPS; set MEPS;
  child_rating = CHHECR42;
  domain = (CHAPPT42 >= 1 & AGELAST < 18);
run;

proc format;
  value child_rating
  9-10 = "9-10 rating"
  7-8 = "7-8 rating"
  0-6 = "0-6 rating"
  -9 - -7 = "Don't know/Non-response"
  -1 = "Inapplicable";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT child_rating child_rating. ind ind.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*ind*child_rating / row;
run;

proc print data = out;
  where domain = 1 and child_rating ne . and ind ne .;
  var child_rating ind WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

