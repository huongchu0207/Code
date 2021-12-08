
library(readxl)
library(dplyr)
library(stringr)
library(lubridate)
library(readxl)
library(KMsurv)
library(survival)
library(survminer)
library(survMisc)
library(data.table)
library(ggplot2)
library(readr)


## EMPTY THE ENVIRONMENT
rm(list = ls())

## LOAD DATA
# 1. People 75+ positive before 11/10/2020 and alive until 12/10/2020
test =  data.table(read_excel("C:/Users/Huong.Chu.ctr/Desktop/vax impact/vax_75_072721.xlsx"))

#People 75+ positive before 11/10/2020 and alive until 12/10/2020


#### DO NOT USE
#test =  fread("C:/Users/Huong.Chu.ctr/Desktop/vax impact/vax_impact_072721.csv")
#test =  data.table(read_csv("vax_impact_072721.csv"))

## CREATE ID VARIABLE
test[, IDL_person_id := NULL]
test[, id := 1:.N]
test[resulted_date_2 > T1, test_date := resulted_date_2]
test[resulted_date_3 > T1, test_date := resulted_date_3]

## SUBSET TO IMPORTANT VARIABLES
test <- test[, .(id, vax_date_1, vax_Date_2, T1, T2, Date_of_Death, death, test_date, vax_ind, cvx, age, Congregate_RorE, 
                 hosp_before_T0, admitted_after_T1, hosp_after_T1)]

## FORMAT DATES
test[, vax_date_1 := ymd(vax_date_1)]
test[, vax_Date_2 := ymd(vax_Date_2)]
test[, T1 := ymd(T1)]
test[, T2 := ymd(T2)]
test[, Date_of_Death := ymd(Date_of_Death)]
test[, admitted_after_T1 := ymd(admitted_after_T1)]


## CREATE VACCINE DAYS
test[, vax_date_11 := vax_date_1+ days(30)]
test[, vax_date_22 := vax_Date_2+ days(30)]
test[, time1 := vax_date_11-T1]
test[, time2 := vax_date_22-T1]
test[cvx == 212, time2 := vax_date_11-T1]

## CLEAN TIME VARIABLES
test[, time1 := tstrsplit(time1, " ")[1]]
test[, time2 := tstrsplit(time2, " ")[1]]
test[, time1 := as.integer(time1)]
test[, time2 := as.integer(time2)]

## CREATE MORTALITY VARIABLES
test[, time := Date_of_Death-T1]
test[is.na(time), time := T2-T1]
test[, time := tstrsplit(time, " ")[1]]
test[, time := as.integer(time)]

## CREATE TESTING VARIABLES
#test[, test_time := test_date-T1]
#test[, test_time := tstrsplit(test_time, " ")[1]]
#test[, test_time := as.integer(test_time)]

## CREATE HOSPITALIZATION VARIABLES
test[is.na(admitted_after_T1), admitted_after_T1 := T2]
test[, hosp_time := admitted_after_T1-T1]
test[, hosp_time := tstrsplit(hosp_time, " ")[1]]
test[, hosp_time := as.integer(hosp_time)]

## RESHAPE DATA USING TMERGE
one <- tmerge(test, test, id=id, endpt=event(time, death))
two <- tmerge(one, test, id=id, partial_vac=tdc(time1))
thr <- tmerge(two, one, id=id, full_vac=tdc(time2))
five <- data.table(thr)
#four<- tmerge(thr, two, id=id, test=tdc(test_time))
#five <- data.table(four)


five[partial_vac ==1 & full_vac ==1, vax_ind2 := 2]
five[partial_vac ==0 & full_vac ==0, vax_ind2 := 0]
five[partial_vac == 1 & full_vac == 0, vax_ind2 := 1]# partially vaccinated

#write.csv(five, file="vax impact/vax_model.csv", row.names = F)

## FIT A MODEL

fit <- coxph(Surv(tstart, tstop, endpt==1) ~ factor(vax_ind2) + age + hosp_before_T0 +cluster(id), data=five)
summary(fit)

## FIT A KAPLAN MIER CURVE
mod1 <- survfit(Surv(tstart, tstop, endpt) ~ factor(vax_ind2) , data=five)
summary(mod1)

# Immortal time bias
mod1 <- survfit(Surv(time, death) ~ factor(vax_ind2) , data=five)
summary(mod1)

plot(mod1, ylim = c(0.975, 1), xlab = "Days to Event", ylab = "Survival Probability",
     mark.time = F, col=c('red', 'orange','green4'), pch = 19, main = "30 days lag")
legend('bottomright', legend=c('Unvacinated', 'Partially vaccinated', 'Fully vaccinated'), 
       lty=2, col=c('red', 'orange','green4'), pch =19)


plot(mod1, ylim = c(0.975, 1), xlab = "Days to Event", ylab = "Survival Probability",
     mark.time = F, col=c('red','green4'), pch = 19, main = "30 days lag, 65+, hcw and CC residents")
legend('bottomright', legend=c('Unvacinated', 'Fully vaccinated'), 
       lty=2, col=c('red','green4'), pch =19)

