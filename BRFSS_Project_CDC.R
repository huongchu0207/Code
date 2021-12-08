## EMPTY THE ENVIRONMENT
rm(list = ls())

## LOAD PACKAGES
library(epiR)
library(data.table)
library(survey)
library(epitools)

#############################################################################################
###                                    PROCESSING DATA                                    ###
#############################################################################################

## LOAD DATA
setwd("~/Desktop/EPI514/analysis")
data <- fread("data.csv")

## RENAME COLUMNS
setnames(data, old=names(data), new=gsub("X.", "", names(data)))
setnames(data, old=names(data), new=tolower(names(data)))

## RECODE RACE
data[race == 9, race := NA]
data[race %in% c(3, 5, 6, 7), race := 5] # other races
data[race == 4, race := 3] # Asian
data[race == 8, race := 4]

## RECODE REFUSALS AS NA
data[educag == 9, educag := NA]
data[incomg == 9, incomg := NA]
data[sex == 9, sex := NA]
data[marital == 9, marital := NA]

## SUFFICIENT FUNDS
data[sdhmeals %in% c(7,9), sdhmeals := NA]
data[sdhmeals ==3, sdhmeals := 0] # "never true" is recoded as "no" - 0
data[sdhmeals %in% c(1,2), sdhmeals := 1] # "Often true" & "Sometimes true" are combined  "yes" - 1

## TOBACO USE
data[, smoke := rfsmok3]
data[smoke == 9, smoke := NA]

## ALCOHOL CONSUMPTION
data[, alcohol := rfbing5]
data[alcohol == 9, alcohol := NA]

# RENAME SOME COLUMNS
setnames(data, old=c("age.g", "educag", "incomg"), new=c("age", "education", "income"))

## FIX THE EXPOSURE
data[, move := sdhmove]
data[move == 88, move := 0]
data[move %in% c(77, 99), move:= NA]
data[move > 12, move:= NA]
data[move > 1, move:= 2]

## Select data
dt <- data[, .(age, race, education, income, sex, sdhmeals, move, smoke, alcohol, marital)]

#############################################################################################
###                                  DESCRIPTIVE STATS                                    ###
#############################################################################################

table(dt$move, useNA = "ifany") # denominator
# RACE
round(prop.table(table(dt$race, useNA = "ifany"))*100, 1)
round(prop.table(table(dt$race, dt$move, useNA = "ifany"), 2)*100, 1)

# EDUCATION
round(prop.table(table(dt$education, useNA = "ifany"))*100, 1)
round(prop.table(table(dt$education, dt$move, useNA = "ifany"), 2)*100, 1)

# INCOME
round(prop.table(table(dt$income, useNA = "ifany"))*100, 1)
round(prop.table(table(dt$income, dt$move, useNA = "ifany"), 2)*100, 1)

# MARITAL STATUS
round(prop.table(table(dt$marital, useNA = "ifany"))*100, 1)
round(prop.table(table(dt$marital, dt$move, useNA = "ifany"), 2)*100, 1)

# SEX
round(prop.table(table(dt$sex, useNA = "ifany"))*100, 1)
round(prop.table(table(dt$sex, dt$move, useNA = "ifany"), 2)*100, 1)

# SUFFICIENT FUNDS FOR HEALTHY FOOD
round(prop.table(table(dt$sdhmeals, useNA = "ifany"))*100, 1)
round(prop.table(table(dt$sdhmeals, dt$move, useNA = "ifany"), 2)*100, 1)

# TOBACCO USE
round(prop.table(table(dt$smoke, useNA = "ifany"))*100, 1)
round(prop.table(table(dt$smoke, dt$move, useNA = "ifany"), 2)*100, 1)

# ALCOHOL CONSUMPTION
round(prop.table(table(dt$alcohol, useNA = "ifany"))*100, 1)
round(prop.table(table(dt$alcohol, dt$move, useNA = "ifany"), 2)*100, 1)

# FRUIT CONSUMPTION
#table(dt$fruit_cat, dt$move, useNA = "ifany")

#############################################################################################
###                                 SURVEY WEIGHTED STATS                                 ###
#############################################################################################

options(survey.lonely.psu="adjust")
sd <- svydesign(data=data, id=~psu, strata=~ststr, weight=~finalwt, nest=T)

## MOBILITY
round(prop.table(svytable(~move, sd))*100, 1)
## SEX
round(prop.table(svytable(~sex, sd))*100, 1)
round(prop.table(svytable(~sex+move, sd),2)*100, 1)

## AGE
round(prop.table(svytable(~age, sd))*100, 1)
round(prop.table(svytable(~age+move, sd),2)*100, 1)

## RACE
round(prop.table(svytable(~race, sd))*100, 1)
round(prop.table(svytable(~race+move, sd),2)*100, 1)

## EDUCATION
round(prop.table(svytable(~education, sd))*100, 1)
round(prop.table(svytable(~education+move, sd),2)*100, 1)

## INCOME
round(prop.table(svytable(~income, sd))*100, 1)
round(prop.table(svytable(~income+move, sd),2)*100, 1)

## MARITAL STATUS
round(prop.table(svytable(~marital, sd))*100, 1)
round(prop.table(svytable(~marital+move, sd),2)*100, 1)

## SUFFICIENT FUNDS FOR HEALTHY FOOD
round(prop.table(svytable(~sdhmeals, sd))*100, 1)
round(prop.table(svytable(~sdhmeals+move, sd),2)*100, 1)

## TOBACCO USE
round(prop.table(svytable(~smoke, sd))*100, 1)
round(prop.table(svytable(~smoke+move, sd),2)*100, 1)

## ALCOHOL CONSUMPTION
round(prop.table(svytable(~alcohol, sd))*100, 1)
round(prop.table(svytable(~alcohol+move, sd),2)*100, 1)

## FRUIT CONSUMPTION
round(prop.table(svytable(~fruit_cat, sd))*100, 1)
round(prop.table(svytable(~fruit_cat+move, sd),2)*100, 1)

## VEGETABLE CONSUMPTION
round(prop.table(svytable(~veg_cat, sd))*100, 1)
round(prop.table(svytable(~veg_cat+move, sd),2)*100, 1)

## PHYSICAL ACTIVITY
round(prop.table(svytable(~pa, sd))*100, 1)
round(prop.table(svytable(~pa+move, sd),2)*100, 1)

#############################################################################################
###                                 PROCESSES OUTCOME                                     ###
#############################################################################################

## RECODE TO FRUIT PER DAY
data[fruit2 == 300, fruit_day := 0.02]
data[fruit2 %in% c(777, 999), fruit_day := NA]
data[fruit2 == 555, fruit_day := 0]
data[(fruit2 > 100) & (fruit2 < 200), fruit_day := fruit2-100]
data[(fruit2 > 200) & (fruit2 < 300), fruit_day := (fruit2-200)/7]
data[(fruit2 > 300) & (fruit2 < 400), fruit_day := (fruit2-300)/30]

## BINARY FRUIT VARIABLE
data[fruit_day > 16, fruit_day := NA]
data[fruit_day >= 2, fruit_cat := 1]
data[fruit_day < 2, fruit_cat := 0]

## RECODE TO VEGETABLES PER DAY
data[fvgreen1 == 300, veg_day := 0.02]
data[fvgreen1 %in% c(777, 999), veg_day := NA]
data[fvgreen1 == 555, veg_day := 0]
data[(fvgreen1 > 100) & (fvgreen1 < 200), veg_day := fvgreen1-100]
data[(fvgreen1 > 200) & (fvgreen1 < 300), veg_day := (fvgreen1-200)/7]
data[(fvgreen1 > 300) & (fvgreen1 < 400), veg_day := (fvgreen1-300)/30]

## TESTING
data[vegetab2 == 300, veg_oth := 0.02]
data[vegetab2 %in% c(777, 999), veg_oth := NA]
data[vegetab2 == 555, veg_oth := 0]
data[(vegetab2 > 100) & (vegetab2 < 200), veg_oth := vegetab2-100]
data[(vegetab2 > 200) & (vegetab2 < 300), veg_oth := (vegetab2-200)/7]
data[(vegetab2 > 300) & (vegetab2 < 400), veg_oth := (vegetab2-300)/30]
data[, veg_day := veg_oth+veg_day]

## BINARY VEGETABLE
data[veg_day > 23, veg_day := NA]
data[veg_day >=3, veg_cat := 1]
data[veg_day < 3, veg_cat := 0]

## RECODE PHYSICAL ACTIVITY
data[paind == 1, pa := 1]
data[paind == 2, pa := 0]
data[paind == 9, pa := NA]

## CREATE CLEAN INPUT DATA TABLE
input <- data[, .(fruit_cat, veg_cat, pa, move, age, education, income, race, sdhmeals, smoke, sex, ststr, psu, finalwt)]
input <- input[complete.cases(input)]

#############################################################################################
###                            PREP RELATIVE RISK COMPUTATION                             ###
#############################################################################################

## RECODE AGE
new <- copy(input)
new[age %in% c(1,2,3), age1 := "18-44"]
new[age %in% c(4,5,6), age1 := "45+"]

## RACE
new[race == 1, race := 1] # WHITE
new[race != 1, race := 0] # NON-WHITE

## RECODE SES
new[education %in% c(1,2), education := 1]
new[income %in% c(1, 2, 3, 4), income_cat := "less than $50k"]
new[income == 5, income_cat := "$50k+"]

## COMPLETE CASE ANALYSIS
new <- new[, .(fruit_cat, veg_cat, pa, age1, race, education, income_cat, smoke, sdhmeals, move, sex, ststr, psu, finalwt)]
new[complete.cases(new)]

## LABEL MOVING VARIABLE
new[move == 0, move_cat := "non-mobile"]
new[move == 1, move_cat := "mobile"]
new[move == 2, move_cat := "highly mobile"]

## PREVALENCE FOR MALES
test <- new[sex == 1]
round(prop.table(table(test$fruit_cat, test$move, useNA = "ifany"), 2)*100, 1)
round(prop.table(table(test$veg_cat, test$move, useNA = "ifany"), 2)*100, 1)
round(prop.table(table(test$pa, test$move, useNA = "ifany"), 2)*100, 1)

## PREVALENCE FOR FEMALES
test <- new[sex == 2]
round(prop.table(table(test$fruit_cat, test$move, useNA = "ifany"), 2)*100, 1)
round(prop.table(table(test$veg_cat, test$move, useNA = "ifany"), 2)*100, 1)
round(prop.table(table(test$pa, test$move, useNA = "ifany"), 2)*100, 1)

#############################################################################################
###                               RELATIVE RISK COMPUTATION                               ###
#############################################################################################

## CREATE A MOBILE AND NON-MOBILE TABLE
new1 <- new[move %in% c(0, 1)]
new1[, confounder := paste0(income_cat, "_", education)]

## PARAMERTIZE VARIABLES
new1[, move_cat := relevel(factor(move_cat), ref="mobile")]
new1[, fruit_cat := relevel(factor(fruit_cat), ref=2)]
new1[, veg_cat := relevel(factor(veg_cat), ref=2)]
new1[, pa := relevel(factor(pa), ref=2)]

## CRDUE FRUIT
tab <- table(new1$move_cat, new1$fruit_cat)
epi.2by2(tab)

## CRUDE VEG
tab <- table(new1$move_cat, new1$veg_cat)
epi.2by2(tab)

## CRUDE PA
tab <- table(new1$move_cat, new1$pa)
epi.2by2(tab)

## SES ADJUSTED FRUIT
tab <- table(new1$move_cat, new1$fruit_cat, new1$confounder)+1
epi.2by2(tab)

## SES ADJUSTED VEG
tab <- table(new1$move_cat, new1$veg_cat, new1$confounder)+1
epi.2by2(tab)

## SES ADJUSTED PA
tab <- table(new1$move_cat, new1$pa, new1$confounder)+1
epi.2by2(tab)

## ALL CONFOUNDER
new1[, confounder := paste0(smoke, "_", education, "_", age1, "_", race, "_", income_cat,"_", sex )]

## ALL ADJUSTED FRUIT
tab <- table(new1$move_cat, new1$fruit_cat, new1$confounder)+1
epi.2by2(tab)

## ALL ADJUSTED VEG
tab <- table(new1$move_cat, new1$veg_cat, new1$confounder)+1
epi.2by2(tab)

## ALL ADJUSTED PA
tab <- table(new1$move_cat, new1$pa, new1$confounder)+1
epi.2by2(tab)

#############################################################################################
###                              SEX STRATIFIED RELATIVE RISK                             ###
#############################################################################################

## 
male <- new1[sex == 1]
male[, confounder := paste0(income_cat, "_", education)]

## CRDUE FRUIT
tab <- table(male$move_cat, male$fruit_cat)
epi.2by2(tab)

## CRUDE VEG
tab <- table(male$move_cat, male$veg_cat)
epi.2by2(tab)

## CRUDE PA
tab <- table(male$move_cat, male$pa)
epi.2by2(tab)

## SES ADJUSTED FRUIT
tab <- table(male$move_cat, male$fruit_cat, male$confounder)+1
epi.2by2(tab)

## SES ADJUSTED VEG
tab <- table(male$move_cat, male$veg_cat, male$confounder)+1
epi.2by2(tab)

## SES ADJUSTED PA
tab <- table(male$move_cat, male$pa, male$confounder)+1
epi.2by2(tab)

## ALL CONFOUNDER
male[, confounder := paste0(smoke, "_", education, "_", age1, "_", race, "_", income_cat,"_", sex )]

## ALL ADJUSTED FRUIT
tab <- table(male$move_cat, male$fruit_cat, male$confounder)+1
epi.2by2(tab)

## ALL ADJUSTED VEG
tab <- table(male$move_cat, male$veg_cat, male$confounder)+1
epi.2by2(tab)

## ALL ADJUSTED PA
tab <- table(male$move_cat, male$pa, male$confounder)+1
epi.2by2(tab)

#############################################################################################
###                             FEMALE STRATIFIED RELATIVE RISK                           ###
#############################################################################################

## 
female <- new1[sex == 2]
female[, confounder := paste0(income_cat, "_", education)]

## CRDUE FRUIT
tab <- table(female$move_cat, female$fruit_cat)
epi.2by2(tab)

## CRUDE VEG
tab <- table(female$move_cat, female$veg_cat)
epi.2by2(tab)

## CRUDE PA
tab <- table(female$move_cat, female$pa)
epi.2by2(tab)

## SES ADJUSTED FRUIT
tab <- table(female$move_cat, female$fruit_cat, female$confounder)+1
epi.2by2(tab)

## SES ADJUSTED VEG
tab <- table(female$move_cat, female$veg_cat, female$confounder)+1
epi.2by2(tab)

## SES ADJUSTED PA
tab <- table(female$move_cat, female$pa, female$confounder)+1
epi.2by2(tab)

## ALL CONFOUNDER
female[, confounder := paste0(smoke, "_", education, "_", age1, "_", race, "_", income_cat,"_", sex )]

## ALL ADJUSTED FRUIT
tab <- table(female$move_cat, female$fruit_cat, female$confounder)+1
epi.2by2(tab)

## ALL ADJUSTED VEG
tab <- table(female$move_cat, female$veg_cat, female$confounder)+1
epi.2by2(tab)

## ALL ADJUSTED PA
tab <- table(female$move_cat, female$pa, female$confounder)+1
epi.2by2(tab)

#############################################################################################
###                       RELATIVE RISK COMPUTATION FOR HIGHLY MOBILE                     ###
#############################################################################################

## CREATE A MOBILE AND NON-MOBILE TABLE
new1 <- new[move %in% c(0, 2)]
new1[, confounder := paste0(income_cat, "_", education)]

## PARAMERTIZE VARIABLES
new1[, move_cat := relevel(factor(move_cat), ref="highly mobile")]
new1[, fruit_cat := relevel(factor(fruit_cat), ref=2)]
new1[, veg_cat := relevel(factor(veg_cat), ref=2)]
new1[, pa := relevel(factor(pa), ref=2)]

## CRDUE FRUIT
tab <- table(new1$move_cat, new1$fruit_cat)
epi.2by2(tab)

## CRUDE VEG
tab <- table(new1$move_cat, new1$veg_cat)
epi.2by2(tab)

## CRUDE PA
tab <- table(new1$move_cat, new1$pa)
epi.2by2(tab)

## SES ADJUSTED FRUIT
tab <- table(new1$move_cat, new1$fruit_cat, new1$confounder)+1
epi.2by2(tab)

## SES ADJUSTED VEG
tab <- table(new1$move_cat, new1$veg_cat, new1$confounder)+1
epi.2by2(tab)

## SES ADJUSTED PA
tab <- table(new1$move_cat, new1$pa, new1$confounder)+1
epi.2by2(tab)

## ALL CONFOUNDER
new1[, confounder := paste0(smoke, "_", education, "_", age1, "_", race, "_", income_cat,"_", sex )]

## ALL ADJUSTED FRUIT
tab <- table(new1$move_cat, new1$fruit_cat, new1$confounder)+1
epi.2by2(tab)

## ALL ADJUSTED VEG
tab <- table(new1$move_cat, new1$veg_cat, new1$confounder)+1
epi.2by2(tab)

## ALL ADJUSTED PA
tab <- table(new1$move_cat, new1$pa, new1$confounder)+1
epi.2by2(tab)

#############################################################################################
###                              SEX STRATIFIED RELATIVE RISK                             ###
#############################################################################################

## 
male <- new1[sex == 1]
male[, confounder := paste0(income_cat, "_", education)]

## CRDUE FRUIT
tab <- table(male$move_cat, male$fruit_cat)
epi.2by2(tab)

## CRUDE VEG
tab <- table(male$move_cat, male$veg_cat)
epi.2by2(tab)

## CRUDE PA
tab <- table(male$move_cat, male$pa)
epi.2by2(tab)

## SES ADJUSTED FRUIT
tab <- table(male$move_cat, male$fruit_cat, male$confounder)+1
epi.2by2(tab)

## SES ADJUSTED VEG
tab <- table(male$move_cat, male$veg_cat, male$confounder)+1
epi.2by2(tab)

## SES ADJUSTED PA
tab <- table(male$move_cat, male$pa, male$confounder)+1
epi.2by2(tab)

## ALL CONFOUNDER
male[, confounder := paste0(smoke, "_", education, "_", age1, "_", race, "_", income_cat,"_", sex )]

## ALL ADJUSTED FRUIT
tab <- table(male$move_cat, male$fruit_cat, male$confounder)+1
epi.2by2(tab)

## ALL ADJUSTED VEG
tab <- table(male$move_cat, male$veg_cat, male$confounder)+1
epi.2by2(tab)

## ALL ADJUSTED PA
tab <- table(male$move_cat, male$pa, male$confounder)+1
epi.2by2(tab)

#############################################################################################
###                             FEMALE STRATIFIED RELATIVE RISK                           ###
#############################################################################################

## 
female <- new1[sex == 2]
female[, confounder := paste0(income_cat, "_", education)]

## CRDUE FRUIT
tab <- table(female$move_cat, female$fruit_cat)
epi.2by2(tab)

## CRUDE VEG
tab <- table(female$move_cat, female$veg_cat)
epi.2by2(tab)

## CRUDE PA
tab <- table(female$move_cat, female$pa)
epi.2by2(tab)

## SES ADJUSTED FRUIT
tab <- table(female$move_cat, female$fruit_cat, female$confounder)+1
epi.2by2(tab)

## SES ADJUSTED VEG
tab <- table(female$move_cat, female$veg_cat, female$confounder)+1
epi.2by2(tab)

## SES ADJUSTED PA
tab <- table(female$move_cat, female$pa, female$confounder)+1
epi.2by2(tab)

## ALL CONFOUNDER
female[, confounder := paste0(smoke, "_", education, "_", age1, "_", race, "_", income_cat,"_", sex )]

## ALL ADJUSTED FRUIT
tab <- table(female$move_cat, female$fruit_cat, female$confounder)+1
epi.2by2(tab)

## ALL ADJUSTED VEG
tab <- table(female$move_cat, female$veg_cat, female$confounder)+1
epi.2by2(tab)

## ALL ADJUSTED PA
tab <- table(female$move_cat, female$pa, female$confounder)+1
epi.2by2(tab)

#############################################################################################
###                                   REGRESSION TESTS                                    ###
#############################################################################################

## GET SURVEY WEIGHTS
options(survey.lonely.psu="adjust")
sd1 <- svydesign(data=input, id=~psu, strata=~ststr, weight=~finalwt, nest=T)

# VEGETABLE
model <- svyglm(veg_cat ~ factor(move), design = sd1, family = quasibinomial(link = "log"))
summary(model)
exp(model$coefficients)

model <- svyglm(veg_cat ~ factor(move) + factor(education) + factor(income), design = sd1, family = quasibinomial(link = "log"))
summary(model)
exp(model$coefficients)

model <- svyglm(veg_cat ~ factor(move) + factor(education) + factor(income) + factor(sex) + factor(race) + factor(age) + factor(smoke), design = sd1, family = quasibinomial(link = "log"))
summary(model)
exp(model$coefficients)

model <- svyglm(veg_cat ~ factor(move) * factor(sex) + factor(education) + factor(income) + factor(sex) + factor(race) + factor(age) + factor(smoke), design = sd1, family = quasibinomial(link = "log"))

summary(model)

model <- svyglm(factor(pa) ~ factor(move) * factor(sex) + factor(education) + factor(income) + factor(sex) + factor(race) + factor(age) + factor(smoke), design = sd1, family = quasibinomial(link = "log"))
summary(model)
exp(coef(model))
exp(confint(model))
```




