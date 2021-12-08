
%let username=Huong.Chu.CTR; /*update with username*/
%let todate=%sysfunc(today(), MMDDYYN6.);

/*/*/*/*/*/*/*/*/*/*/* STEP 1: IMPORT DATASETS */*/*/*/*/*/*/*/*/*/*/

*Vaccine administration by doses;
proc import datafile ="C:\Users\Huong.Chu.CTR\Desktop\20210216_01_RIA-INTERNAL.xlsx"
 out = vaccine_overall_file replace
 dbms = xlsx
 ;
run;

proc format;
	value agegroup
	1 = "75+"
	2 = "<75"
	;
	value raceethnicity
	0 = "Hispanic or Latino (any race)"
	1 = "American Indian or Alaska Native (non-Hispanic or ethnicity unknown or declined)"
	2 = "Asian (non-Hispanic or ethnicity unknown or declined)"
	3 = "Black or African American (non-Hispanic or ethnicity unknown or declined)"
	4 = "Native Hawaiian or Other Pacific Islander"
	5 = "White (non-Hispanic or ethnicity unknown or declined)"
	6 = "Other race (non-Hispanic or ethnicity unknown or declined)"
	9 = "Unknown, pending further information, or missing";

	value weekMMWR
                  51="12/13/20-12/19/20 (Week 51)"
                  52="12/20/20-12/26/20 (Week 52)"
                  53="12/27/20-1/2/21 (Week 53)"
                  54="1/3/21-1/9/21 (Week 1)"
                  55="1/10/21-1/16/21 (Week 2)"
                  56="1/17/21-1/23/21 (Week 3)"
                  57="1/24/21-1/30/21 (Week 4)"
                  58="1/31/21-2/6/21 (Week 5)"
                  59="2/7/21-2/13/21 (Week 6)"
                  60="2/14/21-2/20/21 (Week 7)"
                  ;

run;

proc contents data = vaccine_overall_file;
run;

data vacc;
	set vaccine_overall_file;
	format series_complete $10.;

	if dose_num = 1 then series_complete = "N";
		else if dose_num = 2 then series_complete = "Y";

/* Create age group variables */
     age_at_vacc_date = INT(YRDIF(recip_dob, admin_date,'ACTUAL'));

	 if age_at_vacc_date ge 75 then agegroup=1;
	 else agegroup = 2;
*Create tier variable;
	 if recip_address_zip in (02860, 02863, 02904, 02905, 02907, 02908, 02909) then tier = 1;
	
*Race/Ethnicity combined;
	if recip_ethnicity = "2135-2" then race_eth = 0;/*Hispanic or Latino (any race)*/
		else if (recip_race_1 = "1002-5" and recip_ethnicity = "2186-5") then race_eth = 1; /*1.American Indian or Alaska Native (non-Hispanic or ethnicity unknown or declined)*/
		else if (recip_race_1 = "1002-5" and recip_ethnicity = "") then race_eth = 1;

		else if (recip_race_1 = "2028-9" and recip_ethnicity = "2186-5") then race_eth = 2;/*2.Asian (non-Hispanic or ethnicity unknown or declined)*/
		else if (recip_race_1 = "2028-9" and recip_ethnicity = "") then race_eth = 2;

		else if (recip_race_1 = "2054-5" and recip_ethnicity = "2186-5") then race_eth = 3; /*3.Black or African American (non-Hispanic or ethnicity unknown or declined)*/
		else if (recip_race_1 = "2054-5" and recip_ethnicity = .) then race_eth = 3;

		else if (recip_race_1 = "2076-8" and recip_ethnicity = "2186-5") then race_eth = 4;/*4.Native Hawaiian or Other Pacific Islander*/
		else if (recip_race_1 = "2076-8" and recip_ethnicity = "") then race_eth = 4;

		else if (recip_race_1 = "2106-3" and recip_ethnicity = "2186-5") then race_eth = 5;/*5.White (non-Hispanic or ethnicity unknown or declined)*/
		else if (recip_race_1 = "2106-3" and recip_ethnicity = "") then race_eth = 5;

		else if (recip_race_1 = "2131-1" and recip_ethnicity = "2186-5") then race_eth = 6; /*6.Other race (non-Hispanic or ethnicity unknown or declined)*/
		else if (recip_race_1 = "2131-1" and recip_ethnicity = "") then race_eth = 6;

		else if (recip_race_1 in("UNK", "POL") and recip_ethnicity = "2186-5") then race_eth = 9;/*9.Unknown, pending further information, or missing*/
		else if (recip_race_1 in("UNK", "POL") and recip_ethnicity = .) then race_eth = 9;

	week_mmwr=intck('week', mdy(01,01,2020),admin_date)+1;
format agegroup agegroup. race_eth raceethnicity. week_mmwr weekMMWR.;
run;

**** Mean and Median for Tier 1;
data tier1;
set vacc;
where tier=1;
num_dose =1;
run;

proc sort data=tier1;
	by admin_date;
run;

proc summary data=tier1;
	var num_dose;
	by admin_date;  
	output out=mean_tier1 sum=;
run;

data tier1_mean;
set mean_tier1;
week_mmwr=intck('week', mdy(01,01,2020),admin_date)+1;
format week_mmwr weekMMWR.;
run;

**** Mean and Median for Central Falls;
data central_falls;
set vacc;
where recip_official_city_town ="CENTRAL FALLS";
num_dose =1;
run;

proc sort data=central_falls;
	by admin_date;
run;

proc summary data=central_falls;
	var num_dose;
	by admin_date; 
	output out=mean_median sum=;
run;

data cf;
set mean_median;
week_mmwr=intck('week', mdy(01,01,2020),admin_date)+1;
format week_mmwr weekMMWR.;
run;

/*/*/*/*/*/* SAVE THE OUTPUTS */*/*/*/*/*/;

ods excel file="C:\Users\&username.\Desktop\Agnes project &todate..xlsx" options(sheet_name="1");
proc freq data=vacc;
where dose_num=1 and tier=1;
table week_mmwr/nocum norow nocol nopercent sparse;
run;

ods excel options(sheet_name="2");
proc freq data=vacc;
where dose_num=2 and tier=1;
table week_mmwr/nocum norow nocol nopercent sparse;
run;

ods excel options(sheet_name="3");
proc freq data=vacc;
where dose_num=1 and tier=1;
table week_mmwr*race_eth/nocum norow nocol nopercent sparse;
run;

ods excel options(sheet_name="4");
proc freq data=vacc;
where dose_num=2 and tier=1;
table week_mmwr*race_eth/nocum norow nocol nopercent sparse;
run;

ods excel options(sheet_name="5");
proc freq data=vacc;
where dose_num=1 and tier=1;
table week_mmwr*agegroup/nocum norow nocol nopercent sparse;
run;

ods excel options(sheet_name="6");
proc freq data=vacc;
where dose_num=2 and tier=1;
table week_mmwr*agegroup/nocum norow nocol nopercent sparse;
run;

ods excel options(sheet_name="7");
proc freq data=vacc;
where dose_num=1 and recip_official_city_town ="CENTRAL FALLS";
table week_mmwr/nocum norow nocol nopercent sparse;
run;

ods excel options(sheet_name="8");
proc freq data=vacc;
where dose_num=2 and recip_official_city_town ="CENTRAL FALLS";
table week_mmwr/nocum norow nocol nopercent sparse;
run;

ods excel options(sheet_name="9");
proc freq data=vacc;
where dose_num=1 and recip_official_city_town ="CENTRAL FALLS";
table week_mmwr*agegroup/nocum norow nocol nopercent sparse;
run;

ods excel options(sheet_name="10");
proc freq data=vacc;
where dose_num=2 and recip_official_city_town ="CENTRAL FALLS";
table week_mmwr*agegroup/nocum norow nocol nopercent sparse;
run;

ods excel options(sheet_name="11");
proc means data = tier1_mean median mean;
            var num_dose;
            class week_mmwr;
      run;

ods excel options(sheet_name="12");
proc means data = cf median mean;
            var num_dose;
            class week_mmwr;
      run;
ods excel close;

