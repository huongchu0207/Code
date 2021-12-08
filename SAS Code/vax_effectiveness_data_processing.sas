/****************************************************************/
/***              DO NOT USE: STEP 1: HOSPITALIZATION- MERGE              ***/
/****************************************************************/

%let username=Huong.Chu.CTR; /*update with username*/
%let todate=%sysfunc(today(), MMDDYYN6.);
*1. Import daily spreadsheet;
proc import datafile="X:\COVID Analytic\Hospitalization data\Hospital_SAS_Files\Claire\removed_transfers_082721.xlsx"
dbms=xlsx out=hirs replace;
run;

proc sort data=hirs;
by idl_person_id new_admission_date;
run;

data hirs2;
set hirs;
by idl_person_id;
if first.idl_person_id then admission_count = 1;
else  admission_count + 1;
if idl_person_id = "" then delete;

rename new_Admission_Date = admission_date
		symptomatic = hospitalization_symptom_status;
run;

proc freq data=hirs2;
table admission_count;
run;
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*~~~~~~~~~~~~~~~~~~~   CREATE A WIDE HIRS DATASET   ~~~~~~~~~~~~~~~~~~*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

proc sort data=hirs2;
by idl_person_id admission_date;
      run;

data hirs3;
	set hirs2;
	by idl_person_id admission_date;
	keep idl_person_id admission_count discharge_date admission_date condition other_condition disposition
		date_moved_icu last_date_icu date_placed_on_vent date_off_vent hospitalization_symptom_status;
		*adding indicator for Hosp because of COVID/With COVID here;
	run;

proc sort data=hirs3;
	by idl_person_id admission_count;
	run;

proc transpose data=hirs3 out=hirs4;
	by 	idl_person_id admission_count;
	var idl_person_id admission_count discharge_date admission_date condition other_condition disposition
		date_moved_icu last_date_icu date_placed_on_vent date_off_vent hospitalization_symptom_status;
		*adding indicator for Hosp because of COVID/With COVID here;
	run;

proc transpose data=hirs4 delimiter=_ out=hirs5 (drop=_name_);
by idl_person_id;
var col1;
id _name_ admission_count;
run;

	  proc print data=work.hirs5 (obs=10);
      run;

data hirs6 (keep= idl_person_id condition other_condition
admission_date_1 admission_date_2 admission_date_3 admission_date_4 admission_date_5 admission_date_6
discharge_date_1 discharge_date_2 discharge_date_3 discharge_date_4 discharge_date_5 discharge_date_6
disposition_1 disposition_2 disposition_3 disposition_4 disposition_5 disposition_6
date_moved_icu_1 date_moved_icu_2 date_moved_icu_3 date_moved_icu_4 date_moved_icu_5 date_moved_icu_6
last_date_icu_1 last_date_icu_2 last_date_icu_3 last_date_icu_4 last_date_icu_5 last_date_icu_6
date_placed_on_vent_1 date_placed_on_vent_2 date_placed_on_vent_3 date_placed_on_vent_4 date_placed_on_vent_5 date_placed_on_vent_6
date_off_vent_1 date_off_vent_2 date_off_vent_3 date_off_vent_4 date_off_vent_5 date_off_vent_6
hospitalization_symptom_status_1 hospitalization_symptom_status_2 hospitalization_symptom_status_3 hospitalization_symptom_status_4 hospitalization_symptom_status_5 hospitalization_symptom_status_6
);
*adding indicator for Hosp because of COVID/With COVID here from _1 to _6;
	set hirs5;
	rename 	condition_1 = condition
			other_condition_1 = other_condition
			;
run;

data hirs9;
length idl_person_id $ 100;
set hirs6;

            hospitalization_hypertension =0;
            hospitalization_obesity =0;
            hospitalization_diabetes=0;
            hospitalization_cvd=0;
            hospitalization_lung=0;
            hospitalization_hypercholesterol=0;
            hospitalization_renal=0;
            hospital_immunocompromised=0;
			hospitalization_STROKE_DEMENTIA=0;
			hospitalization_pregnancy =0;
	

		*CONDITIONS;
    if prxmatch('m/hypertension|high blood pressure|elevated blood pressure|tension/io', condition) then hospitalization_hypertension=1;
	if prxmatch('m/hypertension|high blood pressure|elevated blood pressure|tension/io', other_condition) then hospitalization_hypertension=1; 

    if prxmatch('m/obesity|obese/io', condition) then hospitalization_obesity=1;
	if prxmatch('m/obesity|obese/io', other_condition) then hospitalization_obesity=1; 

    if prxmatch('m/diabet/io', condition) then hospitalization_diabetes=1;
	if prxmatch('m/diabet/io', other_condition) then hospitalization_diabetes=1; 

    if prxmatch('m/cardiovascular disease|cardiac_disease|cvd|atrial|afib|cardiomyophathy|Heart|Cardia|CAD
	|Coronary|tachycardia|aortic|cardioversion|cardiomyopathy|Cardiopmegaly/io', condition) then hospitalization_cvd=1;
	if prxmatch('m/cardiovascular disease|cardiac_disease|cvd|atrial|afib|cardiomyophathy|Heart|Cardia|CAD
	|Coronary|tachycardia|aortic|cardioversion|cardiomyopathy|Cardiopmegaly/io', other_condition) then hospitalization_cvd=1;

    if prxmatch('m/lung|lung_disease|pneumonia|asthma|respiratory|COPD|pulmonary|bronchitis/io',condition) then hospitalization_lung=1;
	if prxmatch('m/lung|lung_disease|pneumonia|asthma|respiratory|COPD|pulmonary|bronchitis/io',other_condition) then hospitalization_lung=1; 

    if prxmatch('m/hypercholesterol|high cholester|hypercholesterolemia|cholestrol/io', condition) then hospitalization_hypercholesterol=1;
	if prxmatch('m/hypercholesterol|high cholester|hypercholesterolemia|cholestrol/io', other_condition) then hospitalization_hypercholesterol=1; 
 
    if prxmatch('m/renal_disease|RENAL_DISEASE|kidney|CKD|urolithiasis|stones|renal|bladder/io', condition) then hospitalization_renal=1;
	if prxmatch('m/renal_disease|RENAL_DISEASE|kidney|CKD|urolithiasis|stones|renal|bladder/io', other_condition) then hospitalization_renal=1;
 
    if prxmatch('m/immunocompr/io', condition) then hospital_immunocompromised=1;
	if prxmatch('m/immunocompr/io', other_condition) then hospital_immunocompromised=1;

	if prxmatch('m/pregnancy|pregnant/io', condition) then hospitalization_pregnancy=1;
	if prxmatch('m/pregnancy|pregnant/io', other_condition) then hospitalization_pregnancy=1;
	
	IF PRXMATCH('m/Dementia|Dementai|Stroke/io', condition) THEN hospitalization_stroke_dementia=1;
	IF PRXMATCH('m/Dementia|Dementai|Stroke/io', other_condition) THEN hospitalization_stroke_dementia=1; 
run;

proc print data=hirs9(obs=20); run;

proc print data=hirs9;
where idl_person_id = "a1A3h000000lJDpEAM";
run;

proc contents data=hirs9; run;

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*~~~~~~~~~~~~~~~~~~~      IMPORT MAB DATA FILE      ~~~~~~~~~~~~~~~~~~*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

proc import datafile="X:\COVID Analytic\Treatment\Data\merged patient level data\mab_merged_08272021.xlsx"
dbms=xlsx out=treatment replace;
run;

proc sort data=treatment;
by idl_person_id Treatment_start_date;
run;

data tx;
set treatment;
by idl_person_id;
if first.idl_person_id then tx_count = 1;
else  tx_count + 1;
if idl_person_id = "" then delete;

length mab_dosage mab_eligibility_age65 mab_eligibility_comorbidity mab_eligibility_other $ 500;

mab_drug = Monoclonal_antibody_therapy_drug ;
mab_dosage = Bamlanivimab_treatment_dosage;
mab_treatment_date = Treatment_start_date;

if mab_dosage = "" then mab_dosage = Casirivimab___imdevimab_treatmen;
if mab_dosage = "" and mab_drug = "Bamlanivimab" then mab_dosage = "700mg IV infusion once over 60 minutes";
if mab_dosage = "" and mab_drug = "Bamlanivimab & etesevimab" then 
mab_dosage = "700mg of bamlanivimab & 1,400mg of etesevimab in a single IV infusion once over 60 minutes";

if Age_65_years_or_older = "Checked" then mab_eligibility_age65 = "Yes";
else if Age_65_years_or_older = "Unchecked" then mab_eligibility_age65 = "No";
else mab_eligibility_age65 = "Unknown";

if Underlying_health_condition = "Checked" then mab_eligibility_comorbidity = "Yes";
else if Underlying_health_condition = "Unchecked" then mab_eligibility_comorbidity = "No";
else mab_eligibility_comorbidity = "Unknown";

if Other = "Checked" then mab_eligibility_other = "Yes";
else if Other = "Unchecked" then mab_eligibility_other = "No";
else mab_eligibility_other = "Unknown";
format mab_treatment_date MMDDYY10.;
run;

proc freq data=tx;
table tx_count;
run;

proc sort data=tx;
by idl_person_id mab_treatment_date;
run;

data tx2;
	set tx;
	by idl_person_id mab_treatment_date;
	keep idl_person_id mab_dosage mab_eligibility_age65 mab_eligibility_comorbidity mab_eligibility_other mab_treatment_date mab_drug tx_count;
	run;

proc sort data=tx2;
	by idl_person_id tx_count;
	run;

proc transpose data=tx2 out=tx3;
	by idl_person_id tx_count;
	var idl_person_id mab_dosage mab_eligibility_age65 mab_eligibility_comorbidity mab_eligibility_other mab_treatment_date mab_drug tx_count;
	run;

proc transpose data=tx3 delimiter=_ out=tx4 (drop=_name_);
by idl_person_id;
var col1;
id _name_ tx_count;
run;


data tx5 (keep= idl_person_id
mab_dosage_1 mab_dosage_2 mab_dosage_3
mab_eligibility_age65_1 mab_eligibility_age65_2 mab_eligibility_age65_3
mab_eligibility_comorbidity_1 mab_eligibility_comorbidity_2 mab_eligibility_comorbidity_3
mab_eligibility_other_1 mab_eligibility_other_2 mab_eligibility_other_3
mab_treatment_date_1 mab_treatment_date_2 mab_treatment_date_3
mab_drug_1 mab_drug_2 mab_drug_3
);
	set tx4;
/*format mab_treatment_date_1 mab_treatment_date_2 mab_treatment_date_3 mmddyy10.;*/
run;


	  proc print data=tx5 (obs=10);
	  where mab_treatment_date_1 ne "";
      run;
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*~~~~~~~~~~~~~~~~~~~    IMPORT IDL CASE DATA FILE   ~~~~~~~~~~~~~~~~~~*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
 proc format;
	value agevacc
			1='75+'
			2='65-74'
			3='60-64'
			4='50-59'
			5='40-49'
			6='30-39'
			7='20-29'
			8='0-19';
	value vaccdays
	0 = "91+ days before vax date"
	1 = " 61-90 days before vax date"
	2 = "41-60 days before vax date"
	3 = "29-40 days before vax date"
	4 = "22-28 days before vax date"
	5 = "15-21 days before vax date"
	6 = "8-14 days before vax date"
	7 = "0-7 days before vax date"
	8 = "1-7 days (1 weeks) AFTER vax date"
	9 = "8-13 days (2 weeks) AFTER vax date"
	10 = "14-21 days (3 weeks) AFTER vax date"
	11 = "22-28 days (4 weeks) AFTER vax date"
	12 = "29-40 days AFTER vax date"
	13 = "40-60 days AFTER vax date"
	14 = "2 months AFTER vax date"
	15 = "3 months AFTER vax date";
run;

libname w "X:\COVID Analytic\SalesForce\Case_VAX";

data salesforce_raw;
set w.case_vax_0827;
run;


data sf;
format IDL_Date_SF_Specimen_Collection_ IDL_Resulted_Date_v2 mmddyy10.;
set salesforce_raw;
by idl_person_id;
if first.idl_person_id then count = 1;
else count +1;
if idl_person_id = "" then delete;
rename IDL_Date_SF_Specimen_Collection_ = idl_collection_date
		vax_Date_3 = vax_booster_shot_date;

if cvx2 = 207 then vax_name_2 = "Moderna";
if cvx2 = 208 then vax_name_2 = "Pfizer";
if cvx2 = 212 then vax_name_2 = "Janssen";

if cvx3 = 207 then vax_booster_name = "Moderna";
if cvx3 = 208 then vax_booster_name = "Pfizer";
if cvx3 = 212 then vax_booster_name = "Janssen";

/*month = IDL_Resulted_Date_v2;*/
/*year = IDL_Resulted_Date_v2;*/
/*format month monname5. year year4.;*/
run;

proc freq data=sf;
table vax_name; run;

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*~~~~~~~~~~~~~~~~~~~   CREATE A WIDE HIRS DATASET   ~~~~~~~~~~~~~~~~~~*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
data sf1;
set sf (rename= (IDL_Resulted_Date_v2 = resulted_date_1
		idl_collection_date = idl_collection_date_1
		Symptom_Status__c_case = case_symptom_status_1
		vax_name = vax_name_1
		cvx = cvx1
		congregatetype = congregatetype_1
		congregate_RorE = congregate_RorE_1));
where investigation_num = 0;
keep idl_person_id resulted_date_1 idl_collection_date_1 ZCTA statenew_ll age race_eth_final vax_date_1 vax_Date_2 vax_booster_shot_date cvx1 cvx2 cvx3 
vax_name_1 vax_name_2 vax_booster_name  congregatetype_1 congregate_RorE_1
case_symptom_status_1 sex_new ; *RCS_First_Dose_Vaccine_Type_Manu  RCS_Date_of_First_Dose__c_case RCS_Date_of_Second_Dose__c_case;
*when the new IDL file has clean underlying conditions, add them in here (only those were associated with the first positive case), add case_ to rename the variables;
run;

data sf2;
set sf (rename= (IDL_Resulted_Date_v2 = resulted_date_2
		idl_collection_date = idl_collection_date_2
		Symptom_Status__c_case = case_symptom_status_2
		congregatetype = congregatetype_2
		congregate_RorE = congregate_RorE_2));
where investigation_num = 1;
keep idl_person_id resulted_date_2 idl_collection_date_2 case_symptom_status_2 congregatetype_2 congregate_RorE_2; *ZCTA statenew_ll congregate_rore age race_eth_final;
*Add congregatetype congregate_RorE and change the name to _2;
run;

data sf3;
set sf (rename= (IDL_Resulted_Date_v2 = resulted_date_3
		idl_collection_date = idl_collection_date_3
		Symptom_Status__c_case = case_symptom_status_3
		congregatetype = congregatetype_3
		congregate_RorE = congregate_RorE_3));
where investigation_num = 2;
keep idl_person_id resulted_date_3 idl_collection_date_3 case_symptom_status_3 congregatetype_3 congregate_RorE_3; *ZCTA statenew_ll congregate_rore age race_eth_final;
run;

*CHECKING;
data sf_check;
set sf (rename= (IDL_Resulted_Date_v2 = resulted_date_4
		idl_collection_date = idl_collection_date_4
		Symptom_Status__c_case = case_symptom_status_4
		congregatetype = congregatetype_4
		congregate_RorE = congregate_RorE_4));
where investigation_num = 3;
keep idl_person_id resulted_date_4 idl_collection_date_4 case_symptom_status_4 congregatetype_4 congregate_RorE_4; *ZCTA statenew_ll congregate_rore age race_eth_final;
run;
*********;

data sf4;
merge sf1 sf2 sf3;
by idl_person_id;
run;

proc print data=sf4 (obs=2);
run;

proc freq data=sf4;
table hcw congregate_RorE;
run;

proc contents data=sf4; run;
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

proc import datafile = "X:\COVID Analytic\SalesForce\IDL_Deaths\death_w_IDL_20210827.xlsx"
 out = death replace
 dbms = xlsx
 ;
run;

data death2;
set death;
keep date_of_death idl_person_id; *Edit here if Dr. Hogan requests more death variables;
if idl_person_id = "" then delete;
run;


/*proc contents data=death;run;*/

proc sort data=sf4;
by IDL_person_id;
run;
proc sort data=death2;
by IDL_person_id;
run;

data step2;
  merge sf4(in=inA) death2(in=inB);
  by IDL_person_id;
  length data_source2 $ 20;
  if inA = 1 and inB = 0 then data_source2 = "idl only";
  else if inA = 1 and inB = 1 then data_source2 = "both";
  else if inA = 0 and inB = 1 then data_source2 = "death only";
run;

data final;
set step2;
if data_source2 = "death only" then delete;
format date_of_Death mmddyy10.;
run;

proc sort data=final out=final2 dupout=duplicates nodupkey;
	by  IDL_person_id idl_collection_date_1 date_of_death; run;

/*proc freq data= step2;*/
/*table data_source2;*/
/*run;*/
/**/
/*proc print data=final2;*/
/*where date_of_Death ge '10dec2020'd and (resulted_date_1 lt '10Nov2020'd);*/
/*run;*/

proc sort data=final2;
by IDL_person_id;
run;
proc sort data=hirs9;
by IDL_person_id;
run;

data step3;
length IDL_person_id $ 200;
  merge final2(in=inA) hirs9(in=inB);
  by IDL_person_id;
  		if inA;
  length data_source3 $ 20;
  if inA = 1 and inB = 0 then data_source3 = "idl only";
  else if inA = 1 and inB = 1 then data_source3 = "both";
  else if inA = 0 and inB = 1 then data_source3 = "hirs only";
run;

/*proc freq data= step3;*/
/*table data_source3;*/
/*run;*/
/**/
/*proc print data=step3 (obs=2);*/
/*run;*/
/**/
/*proc freq data=sf4;*/
/*table RCS_First_Dose_Vaccine_Type_Manu ;*/
/*run;*/
 
proc sort data=step3;
by IDL_person_id;
run;
proc sort data=tx5;
by IDL_person_id;
run;

data step4;
length IDL_person_id $ 200;
  merge step3(in=inA) tx5(in=inB);
  by IDL_person_id;
  		if inA;
  length data_source3 $ 20;
  if inA = 1 and inB = 0 then data_source4 = "idl only";
  else if inA = 1 and inB = 1 then data_source4 = "both";
  else if inA = 0 and inB = 1 then data_source4 = "tx only";
run;

proc freq data= step4;
table data_source2 data_source3 data_source4;
run;

proc print data=step4 (obs=10); run;

proc contents data=step4; run;

data hogan;
length case_symptom_status_1 case_symptom_status_2 case_symptom_status_3 sex_new $ 20;
set step4;

T0 = '10Nov2020'd;
T1 = '10Dec2020'd;
T2 = '01jul2021'd;

/*test_date_1 = resulted_date_1;*/
/*test_date_2 = resulted_date_2;*/
/*test_date_3 = resulted_date_3;*/
/**/
/*if date_of_death ne . 	then days_to_event_1 = date_of_death - T1;*/
/*						else days_to_event_1 = T2 - T1;*/
/**/
/*if date_of_death ne .  and resulted_date_2 ne . 		then days_to_event_2 = date_of_death - resulted_date_2;*/
/*else if date_of_death = .  and resulted_date_2 ne . 	then days_to_event_2 = T2 - resulted_date_2;*/
/*else if date_of_death = .  and resulted_date_2 = . 		then days_to_event_2 = T2 - T1;*/
/**/
/*if date_of_death ne .  and resulted_date_3 ne . 		then days_to_event_3 = date_of_death - resulted_date_3;*/
/*else if date_of_death = .  and resulted_date_3 ne . 	then days_to_event_3 = T2 - resulted_date_3;*/
/*else if date_of_death = .  and resulted_date_3 = . 		then days_to_event_3 = T2 - T1;*/

/*if vax_date_1 = . and RCS_Date_of_First_Dose__c_case ne . then vax_Date_1 = RCS_Date_of_First_Dose__c_case;*/
/*if vax_date_2 = . and RCS_Date_of_Second_Dose__c_case ne . then vax_Date_2 = RCS_Date_of_Second_Dose__c_case;*/
/*if RCS_First_Dose_Vaccine_Type_Manu = "Johnson & Johnson" and cvx = . then cvx = 212;*/
/*if RCS_First_Dose_Vaccine_Type_Manu = "Moderna" and cvx = . then cvx = 207;*/
/*if RCS_First_Dose_Vaccine_Type_Manu = "Pfizer" and cvx = . then cvx = 208;*/
 
if vax_date_1 ne . and cvx1 = 212 	then full_vax_date = vax_date_1;
else if vax_date_2 ne . 			then full_vax_date = vax_date_2;

if full_vax_date ne . 						then vax_ind = 2;
if full_vax_date = . and vax_Date_1 ne . 	then vax_ind = 1;
if vax_ind = . 								then vax_ind = 0;

/*if vax_date_1 ne . and cvx = 212 						then V3 = 1; else V3 = 0;*/ 	/*v3 = 1 if one-single dose vax*/
/*if vax_date_2 ne . 									then V2 = 1; else V2 = 0;*/ 	/*V2 = 1 if they receive second dose of Mrna vax*/
/*if vax_date_1 ne . and vax_date_2 = . and cvx ~= 212 	then V1 = 1; else V1 = 0;*/		/*V1 = 1 if they receive first dose of Mrna vax*/

/*if V3 = 1 and V2 = 1 		then fully_vax = 1; 	else fully_vax = 0;*/
/*if V1 = 1 					then partially_vax = 1; else partially_vax = 0;*/

if admission_date_1 ne "" 	then min_admission_date = admission_date_1;
if admission_date_1 ne "" and admission_date_2 = "" then max_admission_date = admission_date_1;
if admission_date_2 ne "" and admission_date_3 = "" then max_admission_date = admission_date_2;
if admission_date_3 ne "" and admission_date_4 = "" then max_admission_date = admission_date_3;
if admission_date_4 ne "" and admission_date_5 = "" then max_admission_date = admission_date_4;
if admission_date_5 ne "" and admission_date_6 = "" then max_admission_date = admission_date_5;
if admission_date_6 ne ""  						  then max_admission_date = admission_date_6;

/*if max_admission_date > T1 then admitted_after_T1 = max_admission_date;*/

if date_of_death ne . 	then death = 1; else death = 0;
if date_of_death = . then death = 0;

/*if min_admission_date ne . and min_admission_date < T0  then hosp_before_T0 = 1; 	else hosp_before_T0 = 0;*/
/*if max_admission_date ne . and max_admission_date >= T1 then hosp_after_T1 = 1; 	else hosp_after_T1 = 0;*/

/*if vax_date_1 > T1 		then vax_after_T1 = 1; else vax_after_T1 = 0;*/
/*if date_of_death ne . and full_vax_date ne . and full_vax_date < date_of_death 	then full_vax_before_death = 1; 	else full_vax_before_death = 0;*/
/*if date_of_death ne . and vax_ind = 1 and full_vax_date < date_of_death 		then partial_vax_before_death = 1; 	else partial_vax_before_death = 0;*/
/**/
/*if full_vax_date ne . and test_date_2 > full_vax_date then pos_after_full_vax = 1; else pos_after_full_vax = 0;*/
/*if full_vax_date ne . and test_date_3 > full_vax_date then pos_after_full_vax = 1;*/
/**/
/*if date_of_death ne . 							then mmwr_week = intck('week', mdy(01,01,2021),date_of_death)+1;*/
/*else if date_of_Death = . and test_date_2 ne . 	then mmwr_week = intck('week', mdy(01,01,2021),test_date_2)+1;*/
/*else if date_of_Death = . and test_date_2 = . 	then mmwr_week = intck('week', mdy(01,01,2021),T2)+1;*/

if ZCTA in ("02860","02863","02904","02905","02907","02908","02909") then tier = 1;
    else if ZCTA in ("02861","02893","02895","02906","02910","02911","02914","02919","02920") then tier = 2;
    else if ZCTA in ("02802","02804","02806","02807","02808","02809","02812","02813","02814","02815",
        "02816","02817","02818","02822","02825","02826","02827","02828","02830","02831","02832","02833",
        "02835","02836","02837","02838","02839","02840","02841","02842","02852","02857","02858","02859",
        "02864","02865","02871","02872","02873","02874","02875","02876","02878","02879","02881","02882",
        "02885","02886","02888","02889","02891","02892","02894","02896","02898","02903","02912","02915",
        "02916","02917","02921") then tier = 3;
length state $ 10 ;

if case_symptom_status_1 = "" then case_symptom_status_1 = "Unknown";
if resulted_date_2 ne . and case_symptom_status_2 = "" then case_symptom_status_2 = "Unknown";
if resulted_date_3 ne . and case_symptom_status_3 = "" then case_symptom_status_3 = "Unknown";
if sex_new = "" then sex_new = "Unknown";

if tier ne . then state = "RI"; else state = "OOS";
if ZCTA = "" and statenew_ll = "RI" then state = "RI"; *Delete these two code line (state variable) once the clean one is produced;

if tier = . and state = "RI" and ZCTA = "" then tier = 4; *replace state with the new state variable on IDL;

if disposition_1 = "Morgue" then date_of_Death_clean = discharge_date_1;
if disposition_2 = "Morgue" then date_of_Death_clean = discharge_date_2;
if disposition_3 = "Morgue" then date_of_Death_clean = discharge_date_3;
if disposition_4 = "Morgue" then date_of_Death_clean = discharge_date_4;
if disposition_5 = "Morgue" then date_of_Death_clean = discharge_date_5;
if disposition_6 = "Morgue" then date_of_Death_clean = discharge_date_6;


/*format full_vax_date T0 T1 T2 test_date_1 test_date_2 test_date_3 min_admission_date max_admission_date admitted_after_T1 mmddyy10.;*/
format full_vax_date T0 T1 T2 mmddyy10.;
drop data_source2 data_source3 data_source4 idl_collection_date_1 idl_collection_date_2 idl_collection_date_3;
run;

proc print data=hogan (obs=10);
where date_of_Death_clean ne "";
var date_of_death date_of_Death_clean discharge_date_1 disposition_1;
run;


proc freq data=sf;
table Symptom_Status__c_case;
run;

/*proc export */
/*  data=hogan*/
/*  dbms=xlsx */
/*  outfile="X:\COVID Analytic\Data Requests\Raw data\Tom T modeling\Vaccination effectiveness\vax_effectiveness_V2_&todate..xlsx" */
/*  replace;*/
/*run;*/

proc export 
  data=hogan
  dbms=csv 
  outfile="X:\COVID Analytic\Data Requests\Raw data\Tom T modeling\Vaccination effectiveness\vax_effectiveness_MAB &todate..csv" 
  replace;
run;

*ONLY USE THE BELOW EXPORT CODES IF THE ABOVE CODE GIVES ERRORS;
%ds2csv (
   data=hogan, 
   runmode=b, 
   csvfile=C:\Users\Huong.Chu.ctr\Desktop\vax impact\vax_impact_&todate..csv
 );

/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/* END HERE */*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/;
/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/* END HERE */*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/;





* CASE-CONTROL SAS CODE - PRACTICE;


data case;
set test;
where first_or_full ne 0;
rename idl_person_id = SDYID;
run;

data control;
set test;
where first_or_full = 0;
rename idl_person_id = SDYID;
run;

DATA CTRL (KEEP=SDYID INDEX);
 SET control (KEEP=SDYID age sex2 tier CC_resident race_mod);
INDEX = age||sex2||tier||CC_resident||race_mod;
run;

DATA CASECN (KEEP=SDYID INDEX);
 SET case (KEEP=SDYID age sex2 tier CC_resident race_mod);
INDEX = age||sex2||tier||CC_resident||race_mod;
run;

PROC FREQ DATA= CTRL NOPRINT;
TABLES INDEX/LIST MISSING OUT=CTRLCNT (KEEP=INDEX COUNT
RENAME=(COUNT=CTRLCNT));
run;

proc print data= ALLCOUNT(obs=2);
run;

PROC FREQ DATA= CASECN NOPRINT;
TABLES INDEX/LIST MISSING OUT=CASECNT (KEEP=INDEX COUNT
RENAME=(COUNT=CASECNT));
run;

DATA ALLCOUNT;
 MERGE CASECNT (IN=A) CTRLCNT (IN=B);
 BY INDEX;
 IF CASECNT > 0;
 IF A AND NOT B THEN CTRLCNT = 0;
 _NSIZE_ = MIN(CASECNT,CTRLCNT);
 IF _NSIZE_ GT 0;
 run;

PROC SQL;
CREATE TABLE WORK.ELIGIBLE_CONTROLS AS
SELECT *
FROM CTRL
WHERE INDEX IN (SELECT INDEX FROM ALLCOUNT);
run;

proc print data= ELIGIBLE_CONTROLS(obs=2);
run;

PROC SQL;
CREATE TABLE WORK.ELIGIBLE_CASES AS
SELECT *
FROM CASECN
WHERE INDEX IN (SELECT INDEX FROM ALLCOUNT);
run;


PROC SORT DATA = WORK.ELIGIBLE_CONTROLS;
BY INDEX;
run;

PROC SORT DATA = WORK.ELIGIBLE_CASES;
BY INDEX;
run;

PROC SURVEYSELECT DATA = WORK.ELIGIBLE_CONTROLS
 SAMPSIZE = ALLCOUNT
 METHOD = SRS
 SEED=12345
 n=1
 OUT=WORK.SELECTED_CONTROLS;
 STRATA INDEX;
 run;

 proc print data=SELECTED_CONTROLS(obs=2);
 run;

 PROC SURVEYSELECT DATA = WORK.ELIGIBLE_CASES
 SAMPSIZE = ALLCOUNT
 METHOD = SRS
 SEED=12345
 n= 1
 OUT=WORK.SELECTED_CASES;
 STRATA INDEX;
 run;

 proc print data=SELECTED_CASES(obs=2);
 run;

 DATA CC (KEEP=SDYID INDEX CCID);
 SET WORK.SELECTED_CONTROLS (IN=A KEEP=SDYID INDEX)
 WORK.SELECTED_CASES (IN=B KEEP=SDYID INDEX);
IF A THEN CCID = 1; *CONTROLS;
ELSE IF B THEN CCID = 0;
run;

PROC SORT DATA= CC;
BY INDEX CCID;
run;

DATA CC (KEEP=SDYID INDEX CCID MATCHID);
 SET CC;
 BY INDEX CCID;
LENGTH CTKTR CAKTR IDXID 8 IDA $6 MATCHX $50 MATCHID 8;
ATTRIB MATCHID FORMAT =20.;
RETAIN CTKTR CAKTR IDXID;
IF CCID = 1 THEN CTKTR +1; * COUNTER FOR CONTROLS;
ELSE IF CCID = 0 THEN CAKTR +1; * COUNTER FOR CASES;
IF FIRST.INDEX THEN IDXID +1; * INCREASE INDEX COUNT;
IDA = COMPRESS(SUBSTR(INDEX,4,6),'*'); * RETAIN PART OF INDEX;
IDX= PUT(IDXID,$4.); * COUNTER (CHARACTER);
IF CCID = 1 THEN MATCHX = IDX||IDA||CTKTR; * MATCHID FOR CONTROLS;
ELSE IF CCID = 0 THEN MATCHX = IDX||IDA||CAKTR;* MATCHID FOR CASES;
MATCHX = COMPRESS(MATCHX,'');
MATCHID = INPUT(MATCHX, 20.); * NUMERIC MATCHID;
run;

proc print data=CC(obs=10);
 run;

data test_final;
set cc;
rename SDYID = idl_person_id;
run;

proc sort data=test_final;
by IDL_person_id;
run;
proc sort data=test;
by IDL_person_id;
run;

data test_model;
  merge test_final(in=inA) test(in=inB);
  by IDL_person_id;
  length data_source4 $ 20;
  if inA = 1 and inB = 0 then data_source4 = "test_final only";
  else if inA = 1 and inB = 1 then data_source4 = "both";
  else if inA = 0 and inB = 1 then data_source4 = "test only";
run;

proc freq data=test_model;
table data_source4/list missing;
run;

data keep;
set test_model;
where data_source4 = "both";
run;

proc sort data=keep out=keep2 dupout=duplicates nodupkey;
	by  IDL_person_id CCID MATCHID; run;

proc export 
  data=keep2
  dbms=xlsx 
  outfile="C:\Users\&username.\Desktop\case control study.xlsx" 
  replace;
run;

	proc print data=keep2 (obs=2); run;

proc tabulate data=keep2;
class CCID sex2 tier cc_resident race_mod first_or_full age_group die;
table first_or_full sex2 tier cc_resident race_mod die age_group, CCID;
run;

proc tabulate data=keep2;
class die sex2 tier cc_resident race_mod first_or_full age_group;
table first_or_full sex2 tier cc_resident race_mod age_group, die;
run;


proc freq daa=keep2;
table first_or_full*die/norow nocol nopercent;
run;

proc freq daa=keep2;
table race_mod*die/norow nocol nopercent;
run;

proc logistic DATA=keep2;
/*where race_mod ne 4;*/
CLASS first_or_full (ref = '0' ) sex2 (ref = '0' ) tier (ref = '3') CC_resident (ref = '0' ) race_mod (ref='1')/ PARAM=REF;
model die(event='1') = first_or_full sex2 age tier CC_resident race_mod;
/*exact first_or_full sex2 age tier CC_resident race_mod /estimate = both;*/
RUN;

/*proc logistic data = exlogit desc;*/
/*  freq num;*/
/*  model admit = female apcalc;*/
/*  exact female apcalc / estimate = both;*/
/*run;*/

proc freq data=keep2;
table die*first_or_full/missing norow nocol nopercent;
run;

proc freq data=keep2;
table die*first_or_full/missing norow nocol nopercent;
run;

proc freq data=keep2;
table die*vax_then_covid/list missing;
run;

proc freq data=keep2;
table die*investigation_num/list missing;
run;


data model;
set step3;
where (IDL_Date_SF_Specimen_Collection_ ge '1jan2021'd and IDL_Date_SF_Specimen_Collection_ le '19Apr2021'd and statenew_ll ne "OOS");
if age <18 then delete;
if first_or_full_vax = . then first_or_full_vax = 0;
if ci_flag=1 then first_or_full_vax =2;

if hosp ne 1 then hosp = 0;

******************************************;
length vax_status2 $ 50; 
vax_status2 = "";

if (days <14 and ci_flag=1) then do ; date_test = Specimen_Collection_Date; vax_date_2= Date_2nd_vaccine; 
days = Specimen_Collection_Date - Date_2nd_vaccine;end;

if date_test = . then date_test = IDL_Date_SF_Specimen_Collection_;
if date_test = . then date_test = IDL_Resulted_Date_v2;

if vax_date_1 = . then do; days_to_vax_1 = .; days_to_vax_2 = .;end;
if vax_date_1 ne . then days_to_vax_1 = date_test - vax_date_1;
if vax_date_2 ne . then days_to_vax_2 = date_test - vax_date_2;
if (ci_flag=1 and days_to_vax_2 <14 and Specimen_Collection_Date ne . and Date_2nd_vaccine ne .) then days_to_vax_2= Specimen_Collection_Date-Date_2nd_vaccine;


if days_to_vax_1 < 0 then vax_status2 = "Unvaccinated";
if days_to_vax_2 >= 14 then vax_status2 = "Fully vaccinated 14+ days";
if days_to_vax_1 >= 14 and cvx=212 then vax_status2 = "Fully vaccinated 14+ days";
if vax_status2 = "" then vax_status2 = "Partially vaccinated";

if (days_to_vax_2 >= 14 and first_or_full_vax =2) then first_or_full = 2;
if (days_to_vax_1 <= -14 and first_or_full_vax =2) then first_or_full = 2;
if (days_to_vax_1 >= 14 and cvx=212) then first_or_full = 2;
if (first_or_full= . and first_or_full_vax = 0) then first_or_full =0;
if first_or_full = . then first_or_full =1;
if first_or_full_vax =1 and days_to_vax_1 <14 then first_or_full =0;
if (investigation_num =0 and cvx=212 and -14 < days_to_vax_1 <14) then first_or_full =0;
if (cvx ne 212 and days_to_vax_2 <0 and -14< days_to_vax_1 <14) then first_or_full =0;
*****************************************************;
vax_then_covid = 0;*vax -> covid: No;
if (days_to_vax_1 >= 14) then vax_then_covid = 1; *vax -> covid: yes; 
if (investigation_num > 0 and days_to_vax_1>=45) then vax_then_covid = 0; *and first_or_full ne 0 ;
if (investigation_num > 0 and 14<days_to_vax_1<45) then vax_then_covid = 1;
/*if (investigation_num > 0 and days_to_vax_1<0 and days_to_vax_1 ne .) then vax_then_covid = 1;*/

*Fully vax/not fully vax;

if first_or_full = 2 then first_or_full2 = 1;
else first_or_full2 = 0;
vax_then_covid2 = 0;*vax -> covid: No;
if (days_to_vax_2 >= 14) then vax_then_covid2 = 1; *vax -> covid: yes; 
else vax_then_covid2 = 0;

if congregate_RorE = "Resident" then CC_resident = 1;
else CC_resident = 0;

if date_of_death ne . then casedeath = 1; else casedeath = 0;

if sex_new = "Female" then sex2 =1;
else if sex_new = "Male" then sex2=0;

if age<=39 then age_group=1; *"18-39";
      else if age>=40 and age<=49 then age_group=2; *"40-49";
      else if age>=50 and age<=59 then age_group=3; *"50-59";
      else if age>=60 and age<=69 then age_group=4; *"60-69";
      else if age>=70 and age<=79 then age_group=5; *"70-79";
      else if age>=80 and age<=89 then age_group=6; *"80-89";
      else if age>=90 then age_group=7; *"90+";
      else if age=. then age_group=.; *"zPending further info";

if ZCTA in ("02860","02863","02904","02905","02907","02908","02909") then tier = 1;
    else if ZCTA in ("02861","02893","02895","02906","02910","02911","02914","02919","02920") then tier = 2;
    else if ZCTA in ("02802","02804","02806","02807","02808","02809","02812","02813","02814","02815",
        "02816","02817","02818","02822","02825","02826","02827","02828","02830","02831","02832","02833",
        "02835","02836","02837","02838","02839","02840","02841","02842","02852","02857","02858","02859",
        "02864","02865","02871","02872","02873","02874","02875","02876","02878","02879","02881","02882",
        "02885","02886","02888","02889","02891","02892","02894","02896","02898","02903","02912","02915",
        "02916","02917","02921") then tier = 3;
/*	else if tier = . and statenew_ll ne "OOS" then tier = 4;*/
    else tier = .;
if tier =3 then tier2=0;
else tier2 = 1;

IF RACE_ETH_FINAL = "5.White (non-Hispanic or ethnicity unknown or declined)" THEN race_mod=1;
ELSE IF RACE_ETH_FINAL = "3.Black or African American (non-Hispanic or ethnicity unknown or declined)" THEN race_mod=3;
ELSE IF RACE_ETH_FINAL = "1.American Indian or Alaska Native (non-Hispanic or ethnicity unknown or declined)" THEN race_mod=3;
ELSE IF RACE_ETH_FINAL = "2.Asian (non-Hispanic or ethnicity unknown or declined)" THEN race_mod=3;
ELSE IF RACE_ETH_FINAL = "6.Other race (non-Hispanic or ethnicity unknown or declined)" THEN race_mod=3;
ELSE IF RACE_ETH_FINAL = "7.Multiple races (non-Hispanic or ethnicity unknown or declined)" THEN race_mod=3;
ELSE IF RACE_ETH_FINAL = "0.Hispanic or Latino (any race)" THEN race_mod=2;
ELSE IF RACE_ETH_FINAL = "8.Declined race (non-Hispanic or ethnicity unknown or declined)" THEN race_mod=4;
ELSE IF RACE_ETH_FINAL = "9.Unknown or pending further information" THEN race_mod=4;

if first_or_full = 0 then first_or_full_mod = 0;
if first_or_full = 1 and vax_then_covid = 0 then first_or_full_mod = 1;
else if first_or_full = 1 and vax_then_covid = 1 then first_or_full_mod = 2;
else if first_or_full = 2 and vax_then_covid = 0 then first_or_full_mod = 3;
else if first_or_full = 2 and vax_then_covid = 1 then first_or_full_mod = 4;

days60 = date_test + 60;
days90 = date_test + 90;
if vax_Date_1 > date_test then first_full = 0;
format days60 days90 mmddyy10.;

if date_of_death ne . and date_of_death <= days60 then casedeath2 = 1; else casedeath2 = 0;
if date_of_death ne . and date_of_death <= days90 then casedeath3 = 1; else casedeath3 = 0;

if (days_to_vax_2 >= 14 and first_or_full_vax =2) then first_or_full2 = 2;
if (days_to_vax_1 >= 14 and cvx =212) then first_or_full2 = 2;
if (days_to_vax_1 <= 13) then first_or_full2 = 0;
if (days_to_vax_1 >= 14 and first_or_full_vax =1) then first_or_full2 = 1;
if first_or_full = . then first_or_full2 = 0;
run;

proc print data=model;
where vax_then_covid = 1 and first_or_full = 2 and casedeath = 1;
var first_or_full vax_then_covid investigation_num casedeath vax_date_1 vax_date_2 cvx days_to_vax_1 days_to_vax_2 date_of_death date_test;
run;

proc print data=model;
where vax_then_covid = 1 and first_or_full = 0 and casedeath = 1;
var first_or_full vax_then_covid investigation_num casedeath vax_date_1 vax_date_2 cvx days_to_vax_1 days_to_vax_2 date_of_death date_test;
run;

proc print data=model;
where vax_then_covid = 1 and first_or_full = 1 and casedeath = 1;
var first_or_full vax_then_covid investigation_num casedeath vax_date_1 vax_date_2 cvx days_to_vax_1 days_to_vax_2 date_of_death date_test;
run;

proc print data=model;
where  cvx =212 and casedeath = 1;
var first_or_full vax_then_covid investigation_num casedeath vax_date_1 vax_date_2 cvx days_to_vax_1 days_to_vax_2 date_of_death date_test Specimen_Collection_Date ci_flag;
run;

proc print data=model;
where  vax_then_covid = 1 and cvx =208 and casedeath = 1;
var first_or_full vax_then_covid investigation_num casedeath vax_date_1 vax_date_2 cvx days_to_vax_1 days_to_vax_2 date_of_death date_test Specimen_Collection_Date ci_flag;
run;

proc print data=model;
where  vax_then_covid = 0 and first_or_full = 1;
var first_or_full vax_then_covid investigation_num casedeath vax_date_1 vax_date_2 cvx days_to_vax_1 days_to_vax_2 date_of_death date_test Specimen_Collection_Date ci_flag;
run;

proc print data=model (obs=50);
where 45>days_to_vax_1 >30 and investigation_num>0;
var first_or_full vax_then_covid investigation_num casedeath vax_date_1 vax_date_2 cvx days_to_vax_1 days_to_vax_2 date_of_death date_test Specimen_Collection_Date ci_flag;
run;

proc print data=model (obs=50);
where vax_then_covid=1 and first_or_full =0 and casedeath =1;
var first_or_full vax_then_covid investigation_num casedeath vax_date_1 vax_date_2 cvx days_to_vax_1 days_to_vax_2 date_of_death date_test Specimen_Collection_Date ci_flag;
run;

proc freq data=model;
table Date_2nd_vaccine;
run;

data model2;
set model;
keep first_or_full sex2 age tier hosp CC_resident vax_then_covid investigation_num casedeath;
run;

proc export 
  data=model2
  dbms=xlsx 
  outfile="C:\Users\&username.\Desktop\vax_impact_r.xlsx" 
  replace;
run;

proc print data=model (obs=50);
where (vax_then_covid = 0 and first_or_full = 2 and casedeath =1) and sex2 ne . and tier ne .;;
/*where (days <14 and ci_flag=1);*/
var age investigation_num days cvx ci_flag vax_date_1 vax_date_2 first_or_full date_test days60 days90 date_of_death casedeath casedeath2;
run;

proc tabulate data=model;
where sex2 ne . and tier ne .;
class first_or_full vax_then_covid casedeath;
table (first_or_full),(vax_then_covid*casedeath );
run;

proc tabulate data=model;
class vax_model age_group casedeath;
table (vax_model*age_group),(casedeath );
run;

proc freq data=model;
where sex2 ne . and tier ne .;
table first_or_full*casedeath/list;
run;

proc tabulate data=model;
where sex2 ne . and tier ne .;
class first_or_full casedeath;
table (first_or_full),(casedeath );
run;

*Age groups;
proc logistic DATA=model;
CLASS first_or_full_vax (ref = '0' ) sex2 (ref = '0' ) tier (ref = '3') age_group (ref = '4') hosp (ref = '0' ) CC_resident (ref = '0' )/ PARAM=REF;
model casedeath(event='1') = first_or_full_vax sex2 age_group tier hosp CC_resident;
RUN;


/*/*/*/*/*/*/*/*/*/*/*/* RUN THIS ONE */*/*/*/*/*/*/*/*/*/*/*/
*Age continuous;
proc logistic DATA=model;
CLASS first_or_full (ref = '0' ) sex2 (ref = '0' ) tier (ref = '3')  hosp (ref = '0' ) CC_resident (ref = '0' ) vax_then_covid(ref = '0' )/ PARAM=REF;
model casedeath(event='1') = first_or_full sex2 age tier hosp CC_resident vax_then_covid investigation_num;
RUN;

*Age continuous - sensitivity analysis;
proc logistic DATA=model;
where age >=75;
CLASS first_or_full (ref = '0' ) sex2 (ref = '0' ) tier (ref = '3')  hosp (ref = '0' ) CC_resident (ref = '0' ) vax_then_covid(ref = '0' )/ PARAM=REF;
model casedeath(event='1') = first_or_full sex2 age tier hosp CC_resident vax_then_covid investigation_num;
RUN;
*Checking EM;
proc logistic DATA=model descending;
CLASS first_or_full (ref = '0' ) vax_then_covid(ref = '0' )/ PARAM=REF;
model casedeath(event='1') = first_or_full vax_then_covid first_or_full*vax_then_covid;
RUN;


/*/*/*/*/*/*/*/*/*/*/*/* Not adjusted for vax then covid */*/*/*/*/*/*/*/*/*/*/*/;
*Unadjusted;
proc logistic DATA=model;
CLASS first_or_full (ref = '0' )/ PARAM=REF;
model casedeath(event='1') = first_or_full;
RUN;

proc logistic DATA=model;
CLASS sex2 (ref = '0' )/ PARAM=REF;
model casedeath(event='1') = sex2;
RUN;

proc logistic DATA=model;
model casedeath(event='1') = age;
RUN;

proc logistic DATA=model;
CLASS tier (ref = '3' )/ PARAM=REF;
model casedeath(event='1') = tier;
RUN;

proc logistic DATA=model;
CLASS hosp (ref = '0' )/ PARAM=REF;
model casedeath(event='1') = hosp;
RUN;

proc logistic DATA=model;
CLASS CC_resident (ref = '0' )/ PARAM=REF;
model casedeath(event='1') = CC_resident;
RUN;

proc logistic DATA=model;
model casedeath(event='1') = investigation_num;
RUN;

proc logistic DATA=model;
CLASS race_mod (ref = '1' )/ PARAM=REF;
model casedeath(event='1') = race_mod;
RUN;
*Age continuous;
proc logistic DATA=model;
CLASS first_or_full2 (ref = '0' ) sex2 (ref = '0' ) tier (ref = '3')  CC_resident (ref = '0' ) 
vax_then_covid(ref = '0' ) race_mod (ref='1')/ PARAM=REF;
model casedeath2(event='1') = first_or_full2 sex2 age tier  CC_resident investigation_num race_mod;
RUN;

************;
*Unadjusted;
proc logistic DATA=model;
where age >=75;
CLASS first_or_full (ref = '0' )/ PARAM=REF;
model casedeath(event='1') = first_or_full;
RUN;

proc logistic DATA=model;
where age >=75;
CLASS sex2 (ref = '0' )/ PARAM=REF;
model casedeath(event='1') = sex2;
RUN;

proc logistic DATA=model;
where age >=75;
model casedeath(event='1') = age;
RUN;

proc logistic DATA=model;
where age >=75;
CLASS tier (ref = '3' )/ PARAM=REF;
model casedeath(event='1') = tier;
RUN;

proc logistic DATA=model;
where age >=75;
CLASS hosp (ref = '0' )/ PARAM=REF;
model casedeath(event='1') = hosp;
RUN;

proc logistic DATA=model;
where age >=75;
CLASS CC_resident (ref = '0' )/ PARAM=REF;
model casedeath(event='1') = CC_resident;
RUN;

proc logistic DATA=model;
where age >=75;
model casedeath(event='1') = investigation_num;
RUN;

proc logistic DATA=model;
where age >=75;
CLASS race_mod (ref = '1' )/ PARAM=REF;
model casedeath(event='1') = race_mod;
RUN;

*Age continuous - sensitivity analysis;
proc logistic DATA=model;
where age >=75 and race_mod ne 4;
CLASS first_or_full2 (ref = '0' ) sex2 (ref = '0' ) tier (ref = '3') CC_resident (ref = '0' ) 
vax_then_covid(ref = '0' ) race_mod (ref='1')/ PARAM=REF;
model casedeath2(event='1') = first_or_full2 sex2 age tier CC_resident investigation_num race_mod;
RUN;

*Checking EM;
proc logistic DATA=model descending;
CLASS first_or_full (ref = '0' ) vax_then_covid(ref = '0' )/ PARAM=REF;
model casedeath(event='1') = first_or_full vax_then_covid first_or_full*vax_then_covid;
RUN;

*Descriptive analysis;
proc tabulate data=model;
class first_or_full sex2 age_group tier hosp CC_resident casedeath vax_then_covid;
table (first_or_full sex2 age_group tier hosp CC_resident vax_then_covid),(casedeath)*(n colPCTN='%'*F=6.1);;
run;

proc tabulate data=model;
class  first_or_full sex2 age_group tier hosp CC_resident casedeath vax_then_covid;
table ( sex2 age_group tier hosp CC_resident vax_then_covid),(first_or_full all)*(n colPCTN='%'*F=6.1);;
run;

proc freq data=model;
table (first_or_full sex2 age_group tier hosp CC_resident vax_then_covid)*(casedeath)/chisq;;
run;

proc freq data=test2;
table (first_or_full);
run;

data test;
set model;
where (sex2 ne .);
run;

data test2;
set test;
where (tier ne .);
run;

proc logistic DATA=test;
where age >=75;
CLASS first_or_full (ref = '0' ) sex2 (ref = '0' ) tier (ref = '3')  hosp (ref = '0' ) CC_resident (ref = '0' ) 
vax_then_covid(ref = '0' ) race_mod (ref='1')/ PARAM=REF;
model casedeath(event='1') = first_or_full sex2 age tier hosp CC_resident investigation_num race_mod;
RUN;
/*/*/*/*/*/*/* LAURA'S SUGGESTIONS*/*/*/*/*/*/*/;
*Age continuous - sensitivity analysis;
proc logistic DATA=model;
where age >=75;
CLASS first_or_full_mod (ref = '0' ) sex2 (ref = '0' ) tier (ref = '3')  hosp (ref = '0' ) CC_resident (ref = '0' ) 
vax_then_covid(ref = '0' ) race_mod (ref='1')/ PARAM=REF;
model casedeath(event='1') = first_or_full_mod sex2 age tier hosp CC_resident investigation_num race_mod;
RUN;

proc freq data=model;
table first_or_full_mod*casedeath/norow nocol nopercent;
run;


proc logistic DATA=model;
where age >=75;
CLASS first_or_full2 (ref = '0' ) sex2 (ref = '0' ) tier (ref = '3')  hosp (ref = '0' ) CC_resident (ref = '0' ) 
vax_then_covid(ref = '0' ) race_mod (ref='1') vax_then_covid2 (ref='0')/ PARAM=REF;
model casedeath(event='1') = first_or_full2 sex2 age tier hosp CC_resident investigation_num race_mod vax_then_covid2;
RUN;

proc logistic DATA=model;
where age >=75 and vax_then_covid2 = 1;
CLASS first_or_full (ref = '0' ) sex2 (ref = '0' ) tier (ref = '3')  hosp (ref = '0' ) CC_resident (ref = '0' ) 
vax_then_covid(ref = '0' ) race_mod (ref='1') vax_then_covid (ref='0')/ PARAM=REF;
model casedeath(event='1') = first_or_full sex2 age tier hosp CC_resident investigation_num race_mod;
RUN;

proc freq data=model;
where vax_then_covid2 =1;
table first_or_full*casedeath/norow nocol nopercent chisq;
run;









data test;
set model;
day1 = new_admission_date - vax_Date_1;
if day1 >0 then flag = 1;
else flag = 0;
run;



/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/**/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/;

 libname w "X:\COVID Analytic\SalesForce\IDL_VAX";

 proc format;
	value agevacc
			1='75+'
			2='65-74'
			3='60-64'
			4='50-59'
			5='40-49'
			6='30-39'
			7='20-29'
			8='0-19';
	value vaccdays
	0 = "91+ days before vax date"
	1 = " 61-90 days before vax date"
	2 = "41-60 days before vax date"
	3 = "29-40 days before vax date"
	4 = "22-28 days before vax date"
	5 = "15-21 days before vax date"
	6 = "8-14 days before vax date"
	7 = "0-7 days before vax date"
	8 = "1-7 days (1 weeks) AFTER vax date"
	9 = "8-13 days (2 weeks) AFTER vax date"
	10 = "14-21 days (3 weeks) AFTER vax date"
	11 = "22-28 days (4 weeks) AFTER vax date"
	12 = "29-40 days AFTER vax date"
	13 = "40-60 days AFTER vax date"
	14 = "2 months AFTER vax date"
	15 = "3 months AFTER vax date";
run;

data Zayid1;
set w.vax_impact_0609;
run;

/*data Zayid1;*/
/*set vax_impact;*/
/*run;*/

data Zayid2;
set Zayid1;
/*keep IDL_person_id first_or_full_vax ci_flag;*/
drop SF_Resulted_Date__c_intake SF_Date_of_Death__c_account SF_Date_of_Death__c_case;
run;

/*proc contents data=hirs3;run;*/
/**/
/*proc freq data=hirs3;*/
/*table SF_Primary_Language__c_case;*/
/*run;*/

proc sort data=Zayid2;
by IDL_person_id;
run;
proc sort data=hirs3;
by IDL_person_id;
run;

data step1;
  merge Zayid2(in=inA) hirs3(in=inB);
  by IDL_person_id;
  length data_source $ 20;
  if inA = 1 and inB = 0 then data_source = "vax only";
  else if inA = 1 and inB = 1 then data_source = "both";
  else if inA = 0 and inB = 1 then data_source = "hirs only";
run;

data clean;
set step1 part2;
if data_source = "vax only" then delete;
run;


proc freq data= step1;
table data_source;
run;

proc import datafile="C:\Users\&username.\Desktop\death.xlsx"
dbms=xlsx out=death replace;
run;

/*proc contents data=death;run;*/

proc sort data=clean;
by IDL_person_id;
run;
proc sort data=death;
by IDL_person_id;
run;

data step2;
  merge clean(in=inA) death(in=inB);
  by IDL_person_id;
  length data_source2 $ 20;
  if inA = 1 and inB = 0 then data_source2 = "hirs only";
  else if inA = 1 and inB = 1 then data_source2 = "both";
  else if inA = 0 and inB = 1 then data_source2 = "death only";
run;

data final;
set step2;
if data_source2 = "death only" then delete;
run;

proc sort data=final out=final2 dupout=duplicates nodupkey;
	by  IDL_person_id recip_id new_admission_date facility date_of_death; run;


proc freq data= step2;
table data_source2;
run;

data final3;
set final2;
where (new_admission_date ge '1jan2021'd and discharge_date ne . and symptomatic ne "N");
if first_or_full_vax = . then first_or_full_vax = 0;
if ci_flag=1 then first_or_full_vax =2;

if first_or_full_vax = 1 then days_to_hosp = new_admission_date - vax_date_1;
else if (first_or_full_vax = 2 and cvx ne 212) then days_to_hosp = new_admission_date - vax_date_2;
else if (first_or_full_vax = 2 and cvx = 212) then days_to_hosp = new_admission_date - vax_date_1;
else days_to_hosp = 9999;

/*if (days_to_hosp <14 and first_or_full_vax = 2) then first_or_full_vax = 1;*/


if days_to_hosp = 9999 then hosp_after_vax = 9999;
else if days_to_hosp <0 then hosp_after_vax = 0;
else if days_to_hosp ge 0 then hosp_after_vax = 1;

if (days >=14 and first_or_full_vax =2)|ci_flag=1 then vax_protected = 1;
else vax_protected = 0;

length vax_status vax_status2 $ 50;
vax_Status = "";
vax_status2 = "";

/*if vax_date_1 = . then do; days_to_vax_1 = .; days_to_vax_2 = .;end;*/
/*days_to_vax_1 = new_admission_date - vax_date_1;*/
/*days_to_vax_2 = new_admission_date - vax_date_2;*/

if vax_date_1 = . then do; days_to_vax_1 = .; days_to_vax_2 = .;end;
days_to_vax_1 = date_test - vax_date_1;
days_to_vax_2 = date_test - vax_date_2;

if days_to_vax_1 < 0 then vax_status = "Unvaccinated";
if days_to_vax_1 >= 0 and days_to_vax_2 <0 then vax_status = "Partially vaccinated";
if days_to_vax_1 > 0 and days_to_vax_2 >=0 then vax_status = "Fully vaccinated";
if days_to_vax_1 > 0 and cvx=212 then vax_status = "Fully vaccinated";

if days_to_vax_1 < 0 then vax_status2 = "Unvaccinated";
if days_to_vax_1 >= 0 and days_to_vax_2 <0 then vax_status2 = "Partially vaccinated";
/*if days_to_vax_1 > 0 and days_to_vax_2 >= 14 then vax_status2 = "Fully vaccinated 14+ days";*/
if days_to_vax_2 >= 14 then vax_status2 = "Fully vaccinated 14+ days";
if days_to_vax_1 > 0 and 0 <= days_to_vax_2 < 14 then vax_status2 = "Fully vaccinated <14 days";
if days_to_vax_1 >= 14 and cvx=212 then vax_status2 = "Fully vaccinated 14+ days";
if (0 =< days_to_vax_1 < 14 and cvx=212) then vax_status2 = "Fully vaccinated <14 days";

if vax_status = "Unvaccinated" then vax_model = 0;
else if vax_status = "Partially vaccinated" then vax_model = 1;
else if  vax_status = "Fully vaccinated" then vax_model =2;

if vax_status2 = "Unvaccinated" then vax_model2 = 0;
else if vax_status2 = "Partially vaccinated" then vax_model2 = 1;
else if  vax_status2 = "Fully vaccinated <14 days" then vax_model2 =2;
else if vax_status2 = "Fully vaccinated 14+ days" then vax_model2 = 3;

if vax_status = "Unvaccinated" then vax_model5 = 0;
else vax_model5 = 1;

if vax_model2 = 3 then vax_model3=1;
else vax_model3 = 0;

if vax_model2 = 3 then vax_model4=1;
else if vax_model2 = 0 then vax_model4=0;

if date_of_death ne . then casedeath = 1; else casedeath = 0;
if disposition="Morgue" and casedeath = 0 then casedeath = 1;

if sex_new = "Female" then sex2 =1;
else if sex_new = "Male" then sex2=0;

if age2<=39 then age_group=1; *"0-39";
      else if age2>=40 and age2<=49 then age_group=2; *"40-49";
      else if age2>=50 and age2<=59 then age_group=3; *"50-59";
      else if age2>=60 and age2<=69 then age_group=4; *"60-69";
      else if age2>=70 and age2<=79 then age_group=5; *"70-79";
      else if age2>=80 and age2<=89 then age_group=6; *"80-89";
      else if age2>=90 then age_group=7; *"90+";
      else if age2=. then age_group=.; *"zPending further info";


IF RACE_ETH_FINAL = "5.White (non-Hispanic or ethnicity unknown or declined)" THEN NEWRACEETH=1;
ELSE IF RACE_ETH_FINAL = "3.Black or African American (non-Hispanic or ethnicity unknown or declined)" THEN NEWRACEETH=2;
ELSE IF RACE_ETH_FINAL = "1.American Indian or Alaska Native (non-Hispanic or ethnicity unknown or declined)" THEN NEWRACEETH=3;
ELSE IF RACE_ETH_FINAL = "2.Asian (non-Hispanic or ethnicity unknown or declined)" THEN NEWRACEETH=3;
ELSE IF RACE_ETH_FINAL = "6.Other race (non-Hispanic or ethnicity unknown or declined)" THEN NEWRACEETH=3;
ELSE IF RACE_ETH_FINAL = "7.Multiple races (non-Hispanic or ethnicity unknown or declined)" THEN NEWRACEETH=3;
ELSE IF RACE_ETH_FINAL = "0.Hispanic or Latino (any race)" THEN NEWRACEETH=4;
ELSE IF RACE_ETH_FINAL = "8.Declined race (non-Hispanic or ethnicity unknown or declined)" THEN NEWRACEETH=5;
ELSE IF RACE_ETH_FINAL = "9.Unknown or pending further information" THEN NEWRACEETH=5;

if condition ne "" then cond=1; else cond =0;
if other_condition ne "" and cond = 0 then cond=1;

if ZCTA in ("02860","02863","02904","02905","02907","02908","02909") then tier = 1;
    else if ZCTA in ("02861","02893","02895","02906","02910","02911","02914","02919","02920") then tier = 2;
    else if ZCTA in ("02802","02804","02806","02807","02808","02809","02812","02813","02814","02815",
        "02816","02817","02818","02822","02825","02826","02827","02828","02830","02831","02832","02833",
        "02835","02836","02837","02838","02839","02840","02841","02842","02852","02857","02858","02859",
        "02864","02865","02871","02872","02873","02874","02875","02876","02878","02879","02881","02882",
        "02885","02886","02888","02889","02891","02892","02894","02896","02898","02903","02912","02915",
        "02916","02917","02921") then tier = 3;
    else tier = .;

	hypertension =0;
            obesity =0;
            diabetes=0;
            cvd=0;
            lung=0;
            hypercholesterol=0;
            renal=0;
            immunocompromised=0;
			STROKE_DEMENTIA=0;
			hypertension1 =0;
			cardiac =0;
			pregnancy=0;
			cancer =0;
			hep =0;

		*CONDITIONS;
    if prxmatch('m/hypertension|high blood pressure|elevated blood pressure|tension/io', condition) then hypertension=1;
	if prxmatch('m/hypertension|high blood pressure|elevated blood pressure|tension/io', other_condition) then hypertension=1; 
    if prxmatch('m/obesity|obese/io', condition) then obesity=1;
	if prxmatch('m/obesity|obese/io', other_condition) then obesity=1; 
    if prxmatch('m/diabet/io', condition) then diabetes=1;
	if prxmatch('m/diabet/io', other_condition) then diabetes=1; 
    if prxmatch('m/cardiovascular disease|cardiac_disease|cvd|atrial|afib|cardiomyophathy|Heart|Cardia|CAD
	|Coronary|tachycardia|aortic|cardioversion|cardiomyopathy|Cardiopmegaly/io', condition) then cvd=1;
	if prxmatch('m/cardiovascular disease|cardiac_disease|cvd|atrial|afib|cardiomyophathy|Heart|Cardia|CAD
	|Coronary|tachycardia|aortic|cardioversion|cardiomyopathy|Cardiopmegaly/io', other_condition) then cvd=1;
    if prxmatch('m/lung|lung_disease|pneumonia|asthma|respiratory|COPD|pulmonary|bronchitis/io',condition) then lung=1;
	if prxmatch('m/lung|lung_disease|pneumonia|asthma|respiratory|COPD|pulmonary|bronchitis/io',other_condition) then lung=1; 
    if prxmatch('m/hypercholesterol|high cholester|hypercholesterolemia|cholestrol/io', condition) then hypercholesterol=1; 
    if prxmatch('m/renal_disease|RENAL_DISEASE|kidney|CKD|urolithiasis|stones|renal|bladder/io', condition) then renal=1;
	if prxmatch('m/renal_disease|RENAL_DISEASE|kidney|CKD|urolithiasis|stones|renal|bladder/io', other_condition) then renal=1; 
    if prxmatch('m/immunocompr/io', condition) then immunocompromised=1;
	if prxmatch('m/pregnancy|pregnant/io', condition) then pregnancy=1;
	if prxmatch('m/pregnancy|pregnant/io', other_condition) then pregnancy=1;
	if prxmatch('m/cancer|tumor/io', condition) then cancer=1;
	if prxmatch('m/cancer|tumor/io', other_condition) then cancer=1;
	if prxmatch('m/liver|hep/io', condition) then hep=1;
	if prxmatch('m/liver|hep/io', other_condition) then hep=1;	
	IF PRXMATCH('m/Dementia|Dementai|Stroke/io', other_condition) THEN stroke_dementia=1; 
run;

/*proc freq data=final3;*/
/*table vax_status2;*/
/*run;*/

proc sort data=final3;
by hirs_id_A new_admission_date;
run;

data model;
set final3;
by hirs_id_A;
if last.hirs_id_A and casedeath = 1 then died = 1;
else died = 0;
run;


proc tabulate data=model;
class vax_status vax_status2 died hypertension obesity diabetes cvd lung hypercholesterol renal immunocompromised stroke_dementia;
table (vax_status vax_status2),(died hypertension obesity diabetes cvd lung hypercholesterol renal immunocompromised stroke_dementia);
run;

proc tabulate data=model;
class vax_model5 died cond;
table (vax_model5),(died *cond);
run;

proc freq data=model;
table vax_model5*died/norow nocol nopercent;
run;

proc logistic DATA=model;
CLASS first_or_full_vax (ref = '0' ) vax_protected (ref = '0' )/ PARAM=REF;
model died(event='1') = first_or_full_vax vax_protected;
RUN;

proc logistic DATA=model;
CLASS first_or_full_vax (ref = '0' ) sex2 (ref = '0' ) newraceeth (REF='1') age_group(REF='3')/ PARAM=REF;
model died(event='1') = first_or_full_vax sex2 newraceeth age_group;
RUN;

proc logistic DATA=model;
CLASS vax_model (ref = '0' ) sex2 (ref = '0' ) cond (ref = '0' ) tier (ref = '3')/ PARAM=REF;
model died(event='1') = vax_model sex2 age2 cond tier;
RUN;

proc logistic DATA=model;
CLASS vax_model2 (ref = '0' ) sex2 (ref = '0' ) cond (ref = '0' ) tier (ref = '3')/ PARAM=REF;
model died(event='1') = vax_model2 sex2 age2 cond tier;
RUN;

proc logistic DATA=model;
CLASS vax_model3 (ref = '0' ) sex2 (ref = '0' ) cond (ref = '0' ) tier (ref = '3')/ PARAM=REF;
model died(event='1') = vax_model3 sex2 age2 cond tier;
RUN;

proc logistic DATA=model;
CLASS vax_model4 (ref = '0' ) sex2 (ref = '0' ) cond (ref = '0' ) tier (ref = '3')/ PARAM=REF;
model died(event='1') = vax_model4 sex2 age2 cond tier;
RUN;

proc logistic DATA=model;
CLASS vax_model5 (ref = '0' ) sex2 (ref = '0' ) cond (ref = '0' ) tier (ref = '3')/ PARAM=REF;
model died(event='1') = vax_model5 sex2 age2 cond tier;
RUN;

proc logistic DATA=model;
CLASS vax_model5 (ref = '0' ) sex2 (ref = '0' ) lung (ref = '0' ) tier (ref = '3')/ PARAM=REF;
model died(event='1') = vax_model5 sex2 age2 lung tier;
RUN;

proc logistic DATA=model;
CLASS vax_model5 (ref = '0' )/ PARAM=REF;
model died(event='1') = vax_model5;
RUN;
