import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
from sklearn.tree import DecisionTreeClassifier
sns.set()


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
        sns.catplot(x=variable, y="Yes", kind="bar", data=rate)
        plt.title("2018 Immunization Rate in the United States")
        if variable == "alcohol":
            plt.xlabel("Current drinker")
        elif variable == "age":
            plt.xlabel("Age group")
        elif variable == "income":
            plt.xlabel("Household income")
            plt.xticks(rotation=45)
        elif variable == "education":
            plt.xlabel("Education")
            plt.xticks(rotation=45)
        elif variable == "race":
            plt.xlabel("Race/Ethnicity")
            plt.xticks(rotation=45)
        elif variable == "sex":
            plt.xlabel("Gender")
        elif variable == "health_status":
            plt.xlabel("Health status")
        elif variable == "marital_status":
            plt.xlabel("Marital status")
            plt.xticks(rotation=45)
        elif variable == "mul_doc":
            plt.xlabel("Having multiple health care professionals")
        elif variable == "medcost":
            plt.xlabel("Could not see doctor because of the cost")
        elif variable == "insurance":
            plt.xlabel("Having health care coverage")
        elif variable == "checkup":
            plt.xlabel("The length of time since last routine checkup")
            plt.xticks(rotation=45)
        elif variable == "smoke":
            plt.xlabel("Smoking status")
        else:
            plt.xlabel(variable)
        plt.ylabel('Immunization Rate')
        plt.savefig("immunization_rate_" + variable + ".png",
                    bbox_inches='tight')
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
    sns.catplot(x="region", y="Yes", kind="bar", data=rate)
    plt.title("Immunization Rates among 4 U.S Regions in 2018")
    plt.xlabel('Region')
    plt.ylabel('Immunization Rate')
    plt.savefig('immunization_rate_region.png', bbox_inches='tight')


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
    sns.catplot(x="state", y="Yes", kind="bar", data=rate,
                legend_out=True)
    plt.legend(title='State', labels=['2: Alaska', '4: Arizona',
                                      '6: California', '8: Colorado',
                                      '15: Hawaii', '16: Idaho', '30: Montana',
                                      '32: Nevada', '35: New Mexico',
                                      '41: Oregon', '49: Utah',
                                      '53: Washington', '56: Wyoming'],
               bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.)
    plt.title("2018 Immunization Rates among 13 States in West Region")
    plt.xlabel('State')
    plt.ylabel('Immunization rate')
    plt.savefig('immunization_rate_west.png', bbox_inches='tight')


def fit_and_predict_immunization(data):
    """
    Takes the data as a parameter and returns the train and test
    accuracy score as a float. Also plot all these accuracy
    scores with different attempted options for splitting the
    data including 50:50, 60:40, 70:30, 80:20 ratios, and for
    different max depth for the DecissionTree from 1 to 24.
    """
    df = data.copy()
    df = df.dropna()
    features = df[["race", "income", "education", "sex", "marital_status",
                   "health_status", "insurance", "mul_doc",
                   "medcost", "checkup", "smoke", "alcohol", "age"]]
    labels = df['flushot']
    features = pd.get_dummies(features)
    split_size = [0.2, 0.3, 0.4, 0.5]
    for test_sample_size in split_size:
        features_train, features_test, labels_train, labels_test = \
            train_test_split(features, labels, test_size=test_sample_size)
        accuracies = []
        for i in range(1, 26):
            model = DecisionTreeClassifier(max_depth=i)
            model.fit(features_train, labels_train)
            pred_train = model.predict(features_train)
            train_acc = accuracy_score(labels_train, pred_train)
            accuracies.append({'max depth': i, 'accuracy score': train_acc,
                               'Predict Type': "Training"})
            pred_test = model.predict(features_test)
            test_acc = accuracy_score(labels_test, pred_test)
            accuracies.append({'max depth': i, 'accuracy score': test_acc,
                               'Predict Type': "Testing"})
        accuracies = pd.DataFrame(accuracies)
        print(accuracies)
        # Plot
        sns.relplot(kind='line', x='max depth', y='accuracy score',
                    hue="Predict Type", data=accuracies)
        plt.title('Accuracy Score as Max Depth Changes' + " (test_size: " +
                  str(test_sample_size) + ")")
        plt.ylim(0.6, 0.75)
        plt.xlabel('Max Depth')
        plt.ylabel('Accuracy Score')
        plt.legend()
        plt.savefig('accuracy_score_' + str(test_sample_size) + '.png',
                    bbox_inches='tight')


def main():
    data = pd.read_csv('~/Desktop/CSE163/project/clean_data.csv')
    immunization_rate(data)
    immunization_region(data)
    immunization_west(data)
    fit_and_predict_immunization(data)


if __name__ == '__main__':
    main()
