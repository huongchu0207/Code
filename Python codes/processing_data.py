import pandas as pd
import numpy as np


def rename_col(data):
    """
    Lowercase the column names and then rename them.
    Return the updated dataset.
    """
    data.columns = map(str.lower, data.columns)
    data.rename(columns={'_state': 'state', '_age_g': 'age',
                         '_racegr3': 'race',
                         '_educag': 'education', '_incomg': 'income',
                         'sex1': 'sex',
                         'flushot6': 'flushot', 'genhlth': 'health_status',
                         'hlthpln1': 'insurance',
                         'persdoc2': 'mul_doc', 'checkup1': 'checkup',
                         '_rfsmok3': 'smoke', "marital": "marital_status",
                         '_rfbing5': 'alcohol'}, inplace=True)
    return data


def recode_missing(data):
    """
    Recode 7 (“Don’t know/Not sure”) and 9 values
    to missing values. Return a updated dataset.
    """
    variables = ("race", "income", "education", "sex", "marital_status",
                 "health_status", "insurance", "mul_doc",
                 "medcost", "checkup", "smoke", "alcohol",
                 "flushot")
    code_7 = ("sex", "health_status", "insurance", "mul_doc",
              "medcost", "checkup", "flushot")
    for variable in variables:
        data.loc[data[variable] == 9, variable] = np.nan
        if variable in code_7:
            data.loc[data[variable] == 7, variable] = np.nan
    return data


def rename_age(data):
    """
    Recode the values for age.
    """
    data.loc[data["age"] == 1, "age"] = "18-24"
    data.loc[data["age"] == 2, "age"] = "25-34"
    data.loc[data["age"] == 3, "age"] = "35-44"
    data.loc[data["age"] == 4, "age"] = "45-54"
    data.loc[data["age"] == 5, "age"] = "55-64"
    data.loc[data["age"] == 6, "age"] = "65+"
    return data


def rename_race(data):
    """
    Recode the values for race.
    """
    data.loc[data["race"] == 1, "race"] = "White American"
    data.loc[data["race"] == 2, "race"] = "Black American"
    data.loc[data["race"] == 3, "race"] = "Other races"
    data.loc[data["race"] == 4, "race"] = "Multiracial"
    data.loc[data["race"] == 5, "race"] = "Hispanic"
    return data


def rename_education(data):
    """
    Recode the values for education.
    """
    data.loc[data["education"] == 1, "education"] = "Less than high school"
    data.loc[data["education"] == 2, "education"] = "High school"
    data.loc[data["education"] == 3, "education"] = "Some college"
    data.loc[data["education"] == 4, "education"] = "College graduate"
    return data


def rename_income(data):
    """
    Recode the values for income.
    """
    data.loc[data["income"] == 1, "income"] = "<$15,000"
    data.loc[data["income"] == 2, "income"] = "$15,000-$24,999"
    data.loc[data["income"] == 3, "income"] = "$25,000-$34,999"
    data.loc[data["income"] == 4, "income"] = "$35,000-$49,999"
    data.loc[data["income"] == 5, "income"] = "$50,000+"
    return data


def rename_sex(data):
    """
    Recode the values for sex.
    """
    data.loc[data["sex"] == 1, "sex"] = "Male"
    data.loc[data["sex"] == 2, "sex"] = "Female"
    return data


def rename_flushot(data):
    """
    Recode the values for flu shot.
    """
    data.loc[data["flushot"] == 1, "flushot"] = "Yes"
    data.loc[data["flushot"] == 2, "flushot"] = "No"
    return data


def rename_health_status(data):
    """
    Recode the values for health status.
    """
    data.loc[data["health_status"] == 1, "health_status"] = "Excellent"
    data.loc[data["health_status"] == 2, "health_status"] = "Very good"
    data.loc[data["health_status"] == 3, "health_status"] = "Good"
    data.loc[data["health_status"] == 4, "health_status"] = "Fair"
    data.loc[data["health_status"] == 5, "health_status"] = "Poor"
    return data


def rename_insurance(data):
    """
    Recode the values for health care coverage.
    """
    data.loc[data["insurance"] == 1, "insurance"] = "Yes"
    data.loc[data["insurance"] == 2, "insurance"] = "No"
    return data


def rename_mul_doc(data):
    """
    Recode the values for having multiple health care professionals.
    """
    data.loc[data["mul_doc"] == 1, "mul_doc"] = "Only one"
    data.loc[data["mul_doc"] == 2, "mul_doc"] = "More than one"
    data.loc[data["mul_doc"] == 3, "mul_doc"] = "No"
    return data


def rename_checkup(data):
    """
    Recode for the length of time since last routine checkup.
    """
    data.loc[data["checkup"] == 1, "checkup"] = "Within past year"
    data.loc[data["checkup"] == 2, "checkup"] = "Within past 2 years"
    data.loc[data["checkup"] == 3, "checkup"] = "Within past 5 years"
    data.loc[data["checkup"] == 4, "checkup"] = "5 or more years ago"
    data.loc[data["checkup"] == 8, "checkup"] = "Never"
    return data


def rename_marital(data):
    """
    Recode the values for marital status.
    """
    data.loc[data["marital_status"] == 1, "marital_status"] = "Married"
    data.loc[data["marital_status"] == 2, "marital_status"] = "Divorced"
    data.loc[data["marital_status"] == 3, "marital_status"] = "Widowed"
    data.loc[data["marital_status"] == 4, "marital_status"] = "Separated"
    data.loc[data["marital_status"] == 5, "marital_status"] = "Never married"
    data.loc[data["marital_status"] == 6,
             "marital_status"] = "Unmarried couple"
    return data


def rename_smoke(data):
    """
    Recode the values for sex.
    """
    data.loc[data["smoke"] == 1, "smoke"] = "No"
    data.loc[data["smoke"] == 2, "smoke"] = "Yes"
    return data


def rename_alcohol(data):
    """
    Recode the values for sex.
    """
    data.loc[data["alcohol"] == 1, "alcohol"] = "No"
    data.loc[data["alcohol"] == 2, "alcohol"] = "Yes"
    return data


def rename_medcost(data):
    """
    Recode for could not see doctor because of the cost.
    """
    data.loc[data["medcost"] == 1, "medcost"] = "Yes"
    data.loc[data["medcost"] == 2, "medcost"] = "No"
    return data


def region_colum(data):
    """
    Create another column for regions.
    """
    northeast = [9, 23, 25, 33, 34, 36, 42, 44, 50]
    midwest = [18, 17, 26, 39, 55, 19, 20, 27, 29, 31, 38, 46]
    south = [10, 11, 12, 13, 24, 37, 45, 51, 54, 1, 21, 28, 47, 5, 22, 40, 48]
    west = [4, 8, 16, 35, 30, 49, 32, 56, 2, 6, 15, 41, 53]
    for state in data["state"].unique():
        if state in northeast:
            data.loc[data['state'] == state, "region"] = "Northeast"
        elif state in midwest:
            data.loc[data['state'] == state, "region"] = "Midwest"
        elif state in south:
            data.loc[data['state'] == state, "region"] = "South"
        elif state in west:
            data.loc[data['state'] == state, "region"] = "West"
    return data


def main():
    data = pd.read_csv('~/Desktop/CSE163/project/data.csv')
    data = data.dropna()
    data = rename_col(data)
    # Convert the values from floats to integers
    data = data.astype(int)
    # Recode all the values
    data = recode_missing(data)
    data = rename_age(data)
    data = rename_race(data)
    data = rename_education(data)
    data = rename_income(data)
    data = rename_sex(data)
    data = rename_flushot(data)
    data = rename_health_status(data)
    data = rename_insurance(data)
    data = rename_mul_doc(data)
    data = rename_checkup(data)
    data = rename_marital(data)
    data = rename_smoke(data)
    data = rename_alcohol(data)
    data = region_colum(data)
    data = rename_medcost(data)
    data.to_csv('~/Desktop/CSE163/project/clean_data.csv')


if __name__ == '__main__':
    main()
