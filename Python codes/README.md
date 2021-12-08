## Summary:
This is a file to instruct you on how to run my project to produce the analyses. There are five different python files in this directory, and the following are instructions for running each file.
## Steps:
Before running any code, make sure that you download the right dataset file.
You can download the dataset by visiting this [link](https://www-cdc-gov.offcampus.lib.washington.edu/brfss/annual_data/annual_2018.html). The dataset is under `Data Files` section and named `2018 BRFSS Data (SAS Transport Format) [ZIP – 101 MB]`. <br/> Unzip the file and start following all the steps below.
* Step 1 - `subset_file.py`
<br/> *Description:* This file is used to subset a large, original dataset (962MB) into a smaller dataset (29.5MB) to use since we do not need to use all 275 variables existing in the original dataset.
<br/> - `main function`: in this function, it reads in the SAS file and only selects 15 variables needed for the analysis including _STATE, _AGE_G, _RACEGR3,_INCOMG, _EDUCAG, SEX1, MARITAL, GENHLTH, HLTHPLN1, PERSDOC2, MEDCOST, CHECKUP1, _RFSMOK3, _RFBING5, FLUSHOT6. After subseting the file, a new subset file will be saved as CSV file and will be used in the next step.

* Step 2 - `processing_data.py`
<br/> *Description:* This file has functions which are used to clean the dataset that was saved from Step 1:
<br/> - `rename_col` function is used to rename the columns with more interpretable names.
<br/> - `rename_age`, `rename_race`, `rename_education`, `rename_income`, `rename_sex`, `rename_flushot`, `rename_health_status`, `rename_insurance`, `rename_mul_doc`, `rename_checkup`, `rename_marital`, `rename_smoke`, `rename_alcohol`, `rename_medcost` functions are used to recode the values in each variable including age, race, education, income, sex, flushot, health_status, insurance, mul_doc, checkup, marital_status, smoke, alcohol, and medcost.
<br/> - `recode_missing` function is used to recode the missing values for the whole dataset.
<br/> - `region_column` function is used to create a new column named `region` which will be used for calculating the immunization rate per region in the next step.

* Step 3 - `analysis.py`
<br/> *Description:* This file has functions to analyze the data and produce the results for 3 research questions:
<br/> - `immunization_rate` function is used to calculate the immunization rate for each demographic and health characteristic. It also produces plots to present these rates as bar graphs.
<br/> - `immunization_region` function is used to calculate the immunization rate for each region in the US in 2018 and plot this rate into a bar graph as well. This function also produce the rates of all states in the West region and plot those rates as a bar graph in order to identify which state has the highest immunization rate in 2018.
<br/> - `fit_and_predict_immunization` function is used to split the dataset into training and test datasets with different attempted options including 50:50, 60:40, 70:30, 80:20 ratios, and then train the model with different max depths for the DecissionTree which are from 1 to 25. This function returns the training and testing accuracy scores as floats and plots all these accuracy scores into line graphs.

* Step 4: `Testing process`
<br/> *Description:* For this step, there are two python files that will be used, which are `test_processing_data.py` and `test_immunization_rate.py`. There is also a small csv file and an excel file that will be used.
<br/> - `test_processing_data.py` function is used to check if the cleaning processing will do the same with another dataset that has simmilar structure to the main file. This function will produce a clean csv dataset to use for the next python file below.
<br/> - `test_immunization_rate.py` function is used to calculate the immunization rates for the clean csv dataset. All the immunization rates calculated will be used to compare manually with an excel file that has all the immunization rates calculated by using excel.
<br/> - `testing_data.csv` is a csv file which is used when run the `test_processing_data.py` function.
<br/> - `clean_testing_data.xlsx` is an excel file which contains the cleaned data in the `clean_testing_data` sheet and all the immunization rates calculated for this data in the `immunization rates` sheet. This file is used to compare with the clean file produced from `test_processing_data.py` function and the immunization rates produced from `test_immunization_rate.py` function.