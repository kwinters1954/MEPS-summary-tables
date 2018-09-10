
ods graphics off;

/* Read in FYC dataset and initialize year */
  FILENAME &FYC. "C:\MEPS\&FYC..ssp";
  proc xcopy in = &FYC. out = WORK IMPORT;
  run;

  data MEPS;
    SET &FYC.;
    ARRAY OLDVAR(5) VARPSU&yy. VARSTR&yy. WTDPER&yy. AGE2X AGE1X;
    year = &year.;
    ind = 1;
    count = 1;

    if year <= 2001 then do;
      VARPSU = VARPSU&yy.;
      VARSTR = VARSTR&yy.;
    end;

    if year <= 1998 then do;
      PERWT&yy.F = WTDPER&yy.;
    end;

    /* Create AGELAST variable */
    if year = 1996 then do;
      AGE42X = AGE2X;
      AGE31X = AGE1X;
    end;

    if AGE&yy.X >= 0 then AGELAST = AGE&yy.x;
    else if AGE42X >= 0 then AGELAST = AGE42X;
    else if AGE31X >= 0 then AGELAST = AGE31X;
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

/* Education */
  data MEPS; set MEPS;
    ARRAY EDUVARS(4) EDUCYR&yy. EDUCYR EDUCYEAR EDRECODE;
    if year <= 1998 then EDUCYR = EDUCYR&yy.;
    else if year <= 2004 then EDUCYR = EDUCYEAR;

    if 2012 <= year < 2016 then do;
      less_than_hs = (0 <= EDRECODE and EDRECODE < 13);
      high_school  = (EDRECODE = 13);
      some_college = (EDRECODE > 13);
    end;

    else do;
      less_than_hs = (0 <= EDUCYR and EDUCYR < 12);
      high_school  = (EDUCYR = 12);
      some_college = (EDUCYR > 12);
    end;

    education = 1*less_than_hs + 2*high_school + 3*some_college;

    if AGELAST < 18 then education = 9;
  run;

  proc format;
    value education
    1 = "Less than high school"
    2 = "High school"
    3 = "Some college"
    9 = "Inapplicable (age < 18)"
    0 = "Missing"
    . = "Missing";
  run;

ods output Domain = out;
proc surveymeans data = MEPS sum missing nobs;
  FORMAT education education. married married.;
  VAR TOTEXP&yy.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN education*married;
run;

proc print data = out;
run;

