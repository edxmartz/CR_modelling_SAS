/*
SAS LABORATORY 2.6.1 GLM ANALYSIS
Let us consider Example 2.3.1. As a starting point, one needs to upload the same data file, then
the following SAS code replicates the analysis by means of the next steps:
1. Create default flag,
2. Train and test samples,
3. Define binning and compute WOE,
4. Perform correlation analysis, and
5. Fit logit regression.
/*

/* 1. Create default flag */
data default_flag;
set oneypd;
if arrears_event=1 or term_expiry_event=1 or bankrupt_Event=1
then default_flag=1;
else default_flag=0;
run;
/* 2. Train and test Samples */
proc sort data=default_flag;
by default_flag vintage_year;
run;
proc surveyselect data=default_flag
out=stratified_data method=srs rate=0.7 outall;
strata default_flag;run;
data train test;
set stratified_data;
if selected=1 then output train;
else output test;
run;
/* 3. Define binning and compute WOE */
proc hpbin data=train numbin=5;
bureau_score num_ccj max_arrears_12m
max_arrears_bal_6m cc_util annual_income
emp_length months_since_recent_cc_delinq;
ods output mapping=mapping;
run;
ods trace on;
ods output woe=WOE infovalue=IV;
proc hpbin data=train WOE bins_meta=mapping output=binned_dataset;
id _all_;
target default_flag/level=interval;
run;
proc sql;
create table appending_woe as select distinct
b.*,
c1.woe as woe_bureau_score,
c2.woe as woe_cc_util,
c3.woe as woe_num_ccj,
c4.woe as woe_max_arrears_12m,
c5.woe as woe_max_arrears_bal_6m,
c6.woe as woe_emp_length,
c7.woe as woe_months_since_recent_cc_delin,
c8.woe as woe_annual_income
from binned_dataset as b
left join woe as c1 on b.bin_bureau_Score=c1.bin and
c1.variable=’bureau_score’
left join woe as c2 on b.bin_cc_util=c2.bin and
c2.variable=’cc_util’
left join woe as c3 on b.bin_num_ccj=c3.bin and
c3.variable=’num_ccj’ left join woe as c4
on b.bin_max_arrears_12m=c4.bin and c4.variable=’max_arrears_12m’
left join woe as c5 on b.bin_max_arrears_bal_6m=c5.bin and
c5.variable=’max_arrears_bal_6m’
left join woe as c6 on b.bin_emp_length=c6.bin and
c6.variable=’emp_length’
left join woe as c7 on b.bin_months_since_recent_cc_delin=c7.bin and
c7.variable=’months_since_recent_cc_delinq’
left join woe as c8 on b.bin_annual_income=c8.bin and
c8.variable=’annual_income’;
quit;
/* 4. Perform correlation analysis */
proc corr data=appending_woe outs=spear_corr spearman;
var woe_:;
run;
/* 5. Fit logit regression */
ods output fitsummary=out_fit parameterEstimates=Params;
ods graphics on;
proc logistic data=appending_woe plots=roc ;
model default_flag(event=’1’) =
woe_bureau_score
woe_cc_util
woe_num_ccj
woe_max_arrears_12m
woe_emp_length
woe_months_since_recent_cc_delin
woe_annual_income
/selection=stepwise ;
quit;
ods graphics on;
proc hpsplit data=default_flag leafsize=50 maxdepth=8
plots=zoomedtree;
target default_flag / level=interval;
input bureau_Score cc_util annual_income emp_length
months_since_recent_cc_delinq /level=interval;
input num_ccj max_Arrears_12m /level=ordinal;
output growthsubtree=growth importance=factor_imp
nodestats=node_stats;
run;
quit;
