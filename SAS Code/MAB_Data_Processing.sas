

****************************************************************/
/***     STEP 1: IMPORT MASTER FILE - CREATE LINKING KEYS     ***/
/****************************************************************/;

proc import datafile="C:\Users\Huong.Chu.ctr\OneDrive - State of Rhode Island\Analytics_dataset\MAB\merged_cases_mab_07282021.xlsx"
dbms=xlsx out=sf_treatment replace;
run;

data sf_treatment1;
set sf_treatment;
length full_nameA $ 80 id_A_tm $ 80;
   
    first_idl=UPCASE(firstname);
    last_idl=UPCASE(lastname);
    name1_idl=UPCASE(scan(first_idl,1," "));
* combine first and last;
    full_name=CATS(first_idl,last_idl);
    full_nameA=CATS(name1_idl,last_idl);
* remove non alpha characters;
    full_name=COMPRESS(full_name,'ak');
    full_nameA=COMPRESS(full_nameA,'ak');
* identifier #1: full_name_IDl + DOB;   
    id_A_tm=CATX('_', full_nameA, datebirth);
run; 		

proc sort data=sf_treatment1;
by idl_person_id resultdate_updated;
run;

*Keep the last pos lab for the merge with deaths;
data part1;
set sf_treatment1;
by idl_person_id;
if last.idl_person_id then output;
run;

data part1;
set part1;
last_pos = 1;
run;

*Merge back with deaths later;
data part2;
set sf_treatment1;
by idl_person_id;
if last.idl_person_id then delete;
last_pos = 0;
run;

proc print data = part1(obs=2);
var id_A_tm;
run;
****************************************************************/
/***                   STEP 2: DEATHS MERGED                 ***/
/****************************************************************/;

*1. Import daily death spreadsheet;
proc import datafile="C:\Users\Huong.Chu.ctr\OneDrive - State of Rhode Island\Analytics_dataset\IDL_Death\death_w_IDL_20210726.xlsx"
dbms=xlsx out=DeathsDemo replace;
run;

data DeathsDemo;
set DeathsDemo;
keep idl_person_id date_of_death case;
run;

proc sort data=part1; by idl_person_id; run;

proc sort data=DeathsDemo; 
by idl_person_id; run;

data want;
merge part1(in=inA) DeathsDemo(in=inB);
	by idl_person_id;
       if inA;
	length data_source $ 20;
  if inA = 1 and inB = 0 then data_source = "sf-tx only";
  else if inA = 1 and inB = 1 then data_source = "both";
  else if inA = 0 and inB = 1 then data_source = "death only";
run;

data death_all;
	set want;
	run;

proc freq data=want;
table data_source;
run;

proc print data=want;
where data_source = "death only";
run;
/****************************************************************/
/*** STEP 3: IMPORT HOSPITALIZATION DATA - MERGED ALL AND HIRS ***/
/****************************************************************/


%let todate=%sysfunc(today(), MMDDYYN6.);
%let username=Huong.Chu.CTR; /*update with username*/


proc import datafile="C:\Users\Huong.Chu.ctr\OneDrive - State of Rhode Island\Analytics_dataset\Hospitalization data\removed_transfers_072821.xlsx"
dbms=xlsx out=hirs replace;
run;

data hirs2;
set hirs;

length full_nameA_idl $ 80 id_A_idl $ 80;
   
    first_idl=UPCASE(IDL_FirstName);
    last_idl=UPCASE(IDL_LastName);
    name1_idl=UPCASE(scan(first_idl,1," "));
* combine first and last;
    full_name_idl=CATS(first_idl,last_idl);
    full_nameA_idl=CATS(name1_idl,last_idl);
* remove non alpha characters;
    full_name_idl=COMPRESS(full_name_idl,,'ak');
    full_nameA_idl=COMPRESS(full_nameA_idl,,'ak');
* identifier #1: full_name_IDl + DOB;   
    id_A_idl=CATX('_', full_nameA_idl, IDL_DOB);
run;

proc sort data=hirs2; *Sort the data;
by id_A_idl new_admission_date;
run;

data hirs_new2; *Make a variable for admission count;
set hirs2;
by id_A_idl;
if first.id_A_idl then admission_count = 1;
else  admission_count + 1;
hosp=1;
run;

/*proc sort data=hirs_new2 out=hirs_new3 dupout=duplicates nodupkey;*/
/*	by  id_A new_admission_date facility; run;*/
proc freq data=hirs_new2;
table symptomatic;
run;

data hirs3;
set hirs_new2 (rename = (id_A = hirs_id_A));
keep  full_nameA_idl full_nameA hirs_id_A IDL_DOB new_admission_date discharge_date disposition admission_count other_condition condition
date_moved_icu last_date_icu date_placed_on_vent date_off_vent hosp facility id_A_idl IDL_person_id symptomatic;
run;

proc sort data=hirs3; 		by idl_person_id; run;

proc sort data=death_all; 	by idl_person_id; run;

data sf_tx_death;
merge death_all(in=inA) hirs3(in=inB);
	by idl_person_id;
       if inA;
	length data_source2 $ 20;
  if inA = 1 and inB = 0 then data_source2 = "sf-tx only";
  else if inA = 1 and inB = 1 then data_source2 = "both";
  else if inA = 0 and inB = 1 then data_source2 = "hirs only";
run;

data final;
	set sf_tx_death;
	run;

proc freq data=sf_tx_death;
table data_source2;
run;

proc sort data=final out=final2 dupout=duplicates nodupkey;
	by  idl_person_id resultdate_updated IDL_Date_SF_Specimen_Collection_ new_admission_date date_of_death investigation_num facility; run;


/****************************************************************/
/***          STEP 4: Formatting/Selecting Variables          ***/
/****************************************************************/

/*CLEANING DEATH VARIABLES IN SF*/
DATA brown1;
SET final2;
	*DEATH VARIABLE - merge with death spreadsheet?;
	if data_source = "both" then casedeath = "Y"; else casedeath = "N";
	if data_source = "both" then statenew_ll = "RI";

	IF disposition="Morgue" and casedeath = "N" THEN casedeath = "Y";
	if disposition = "Morgue" then date_of_death = discharge_date;

zcta1 = CATX('0',ZCTA);
if ZCTA1 in ("2860","2863","2904","2905","2907","2908","2909") then tier = 1;
    else if ZCTA1 in ("2861","2893","2895","2906","2910","2911","2914","2919","2920") then tier = 2;
    else if ZCTA1 in ("2802","2804","2806","2807","2808","2809","2812","2813","2814","2815",
        "2816","2817","2818","2822","2825","2826","2827","2828","2830","2831","2832","2833",
        "2835","2836","2837","2838","2839","2840","2841","2842","2852","2857","2858","2859",
        "2864","2865","2871","2872","2873","2874","2875","2876","2878","2879","2881","2882",
        "2885","2886","2888","2889","2891","2892","2894","2896","2898","2903","2912","2915",
        "2916","2917","2921") then tier = 3;
if  (statenew_ll = "RI" and tier not in (1,2,3)) then tier = 4;
if tier in (1,2,3) then statenew_ll = "RI";
RUN;

proc sort data=brown1;
by id_A_tm new_admission_date;
run;

data brown2; *Remove duplicated deaths - clean death variable;
set brown1;
by id_A_tm;
if last.id_A_tm and casedeath = "Y" then died = 1;
else died = 0;
run;

proc freq data=brown2;
table died;
run;

data brown3;
set brown2;
            hypertension =0;
            obesity =0;
            diabetes=0;
            cvd=0;
            lung=0;
            hypercholesterol=0;
            renal=0;
            immunocompromised=0;
			ASTHMA=0;
			STROKE_DEMENTIA=0;
			RA=0;
			hypertension1 =0;
			cardiac =0;
			pregnancy =0;
	

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

    total_conditions = hypertension + obesity + diabetes + cvd + lung + hypercholesterol + renal + immunocompromised + stroke_dementia;

run;




data brown33;
set brown3;
length mab_dosage mab_eligibility_age65 mab_eligibility_comorbidity mab_eligibility_other $ 500;

mab_drug = Monoclonal_antibody_therapy_drug ;
mab_dosage = Bamlanivimab_treatment_dosage;
mab_treatment_date = Treatment_start_date;

if mab_dosage = "" then mab_dosage = Casirivimab___imdevimab_treatmen;
if mab_dosage = "" and mab_drug = "Bamlanivimab" then mab_dosage = "700mg IV infusion once over 60 minutes";
if mab_dosage = "" and mab_drug = "Bamlanivimab & etesevimab" then 
mab_dosage = "700mg of bamlanivimab & 1,400mg of etesevimab in a single IV infusion once over 60 minutes";

/*diff = Treatment_end_date - Treatment_start_date;*/

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
drop casedeath symptom_status;
run;

proc freq data=brown33;
where mab_dosage = "" and mab_drug ne "";
table mab_drug;
run;

data brown55;
set brown33;
/*drop age;*/
if hosp ne 1 then hypertension = .; 
if hosp ne 1 then obesity = .;
if hosp ne 1 then diabetes = .;
if hosp ne 1 then cvd = .;
if hosp ne 1 then lung = .;
if hosp ne 1 then hypercholesterol =.;
if hosp ne 1 then renal =. ;
if hosp ne 1 then immunocompromised = .;
if hosp ne 1 then stroke_dementia =.;
if hosp ne 1 then pregnancy =.;

if mab_drug = "" then mab_eligibility_comorbidity = ".";
if mab_drug = "" then mab_eligibility_age65 = ".";
if mab_drug = "" then mab_eligibility_other = ".";

new_uniqueID = IDL_person_id;
if died = 1 then casedeath = "Y";
else casedeath = "N";
if died = 0 then date_of_death = .;

symptom_status = Symptom_Status__c_case;
if symptom_status = "" then symptom_status = "Not interview";
run;

proc freq data=brown55; table last_pos; run;
proc freq data=brown55; table age; run;

data brown6;
  set brown55 (rename = ( date_of_death = datedeath));
  KEEP new_uniqueID age sex_new race_eth_final congregatetype Congregate_RorE zipnew5 ZCTA tier casedeath datedeath HOSP admission_count pregnancy hypertension obesity
	diabetes cvd lung hypercholesterol renal immunocompromised stroke_dementia new_admission_date discharge_date disposition date_moved_icu
	last_date_icu date_placed_on_vent date_off_vent resultdate_updated statenew_ll symptom_status symptom_status_YesNo symptomatic investigation_num last_pos
mab_dosage mab_eligibility_age65 mab_eligibility_comorbidity mab_eligibility_other mab_treatment_date mab_drug;

  run;

/*save to cvs*/
%ds2csv (
   data=brown6, 
   runmode=b, 
   csvfile=X:\COVID Analytic\Data Requests\Raw data\Tom T modeling\Mab files\Brown_&todate..csv
 );
