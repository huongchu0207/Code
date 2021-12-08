import pandas as pd


def main():
    data = pd.read_sas('~/Desktop/CSE163/project/LLCP2018.XPT')
    subset = data[['_STATE', '_AGE_G', '_RACEGR3', '_EDUCAG',
                   '_INCOMG', 'SEX1', 'MARITAL', 'FLUSHOT6', 'GENHLTH',
                   'HLTHPLN1', 'PERSDOC2',
                   'MEDCOST', 'CHECKUP1', '_RFSMOK3', '_RFBING5']]
    subset.to_csv('~/Desktop/CSE163/project/data.csv')


if __name__ == '__main__':
    main()
