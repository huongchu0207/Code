import pandas as pd


def immunization_rate(data):
    """
    Calculate the immunization rate for each
    demographic and health characteristic. Print
    out and plot the immunization rates.
    """
    variables = ("race", "income", "education", "sex", "marital_status",
                 "health_status", "insurance", "mul_doc",
                 "medcost", "checkup", "smoke", "alcohol", "age")
    for variable in variables:
        subset = data[["flushot", variable]]
        subset.dropna()
        rate = pd.crosstab(subset[variable], subset["flushot"],
                           normalize='index')*100
        rate = rate.round(decimals=0)
        rate.index.name = variable
        rate.reset_index(inplace=True)
        print(rate)
    return rate


def immunization_region(data):
    """
    Calculate the immunization rate for each region
    in the US. Print out and plot the immunization rates.
    """
    subset = data[['flushot', 'region']]
    subset = subset.dropna()
    rate = pd.crosstab(subset["region"], subset["flushot"],
                       normalize='index')*100
    rate = rate.round(decimals=0)
    rate.index.name = "region"
    rate.reset_index(inplace=True)
    print(rate)
    return rate


def immunization_west(data):
    """
    Calculate the immunization rate for the West region.
    Print out and plot the immunization rates.
    """
    subset = data[['flushot', 'region', 'state']]
    subset = subset[subset["region"] == "West"]
    subset = subset.dropna()
    rate = pd.crosstab(subset["state"], subset["flushot"],
                       normalize='index')*100
    rate = rate.round(decimals=0)
    rate.index.name = "state"
    rate.reset_index(inplace=True)
    print(rate)
    return rate


def main():
    data = pd.read_csv('~/Desktop/CSE163/project_work/clean_testing_data.csv')
    immunization_rate(data)
    immunization_region(data)
    immunization_west(data)


if __name__ == '__main__':
    main()
