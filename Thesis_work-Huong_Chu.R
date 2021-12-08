###############################################################################
####                            HUONG THI CHU                              ####
####                           MPH THESIS WORK                             ####
###############################################################################

# EMPTY THE ENVIRONMENT
rm(list = ls())

# LOAD PACKAGES
library(tidyverse)
library(ggplot2)
library(dplyr)
library(haven)
library(epiR)
library(geepack)
library(gee)
library(data.table)
library(expss)

# SET THE WORKING DIRECTORY
setwd("Documents\UW Master program\Thesis\thesis final paper")

###############################################################################
####                            DATA PREP                                  ####
###############################################################################

# LOAD THE DATASET
mother_data <- data.table(read_dta("Documents/UW Master program/Thesis/thesis final paper/hpv_prom_dinner_mother_data20200910_no_phi_mother-child_obs.dta"))
mother_include <- mother_data[is.na(log_mother_exclude)==TRUE]

# FILTER THE NUMBER OF EXCLUDED MOTHERS
mother_data_exclude <- unique(mother_data[!is.na(log_mother_exclude), .(dinner_id, study_id, log_mother_exclude)])
mother_data_exclude[, .(count = .N), by = log_mother_exclude]

mother_data_raw <- copy(mother_include)

# YEARS IN U.S.
mother_data_raw [birth_loc_imm_yr==6, birth_loc_imm_yr := NA]
mother_data_raw [, years_in_US := 2018 - birth_loc_imm_yr + 1]

# FLAG IF MOTHERS DID NOT ANSWER ANY QUESTIONS IN PRE-SURVEY
mycols <- names(mother_data_raw )[names(mother_data_raw ) %like% "_pre"]
mother_data_raw [is.na(vacc_get_where_pre) & is.na(hpv_vacc_cancer_pre) & is.na(vacc_6mo_doctor_pre), .SD, .SDcols=(mycols)]
mother_data_raw [is.na(vacc_get_where_pre) & is.na(hpv_vacc_cancer_pre) & is.na(vacc_6mo_doctor_pre), flag := 1]

# FLAG IF MOTHERS DID NOT ANSWER ANY QUESTIONS IN POST-SURVEY
mycols <- names(mother_data_raw )[names(mother_data_raw) %like% "_post"]
mother_data_raw [is.na(vacc_get_where_post) & is.na(hpv_vacc_cancer_post) & is.na(vacc_6mo_doctor_post), .SD, .SDcols=(mycols)]
mother_data_raw [is.na(vacc_get_where_post) & is.na(hpv_vacc_cancer_post) & is.na(vacc_6mo_doctor_post), flag := 2]

#EXCLUDE MOTHERS WHO DID NOT FINISHED EITHER PRE OR POST SURVEY
exclude_mother <- mother_data_raw [flag %in% c(1,2)]
unique(exclude_mother[, .(dinner_id,study_id, flag)])

# MOTHERS INCLUDE IN THIS STUDY - N = 115
mother_data <- mother_data_raw[is.na(flag)==TRUE]
unique(mother_data[, .(dinner_id, study_id)])

###############################################################################
####                     TABLE 2 - MOTHER DEMOGRAPHICS                     ####
###############################################################################

mother_demographic <- unique(mother_data[, .(dinner_id,study_id,age,ethnicity, years_in_US, birth_loc, eng_fluency, education,
                      religion, work, household_income, marital_status, birth_loc_imm_yr, child_report_qty)])

# TOTAL NUMBER OF ELIGIBLE MOTHERS FOR THIS STUDY
nrow(mother_demographic)

# N AND FREQUENCY
variables <- c("age","ethnicity", "birth_loc", "eng_fluency", "religion", "work", "household_income", "marital_status", "child_report_qty", "child_bring_birth")
for (i in variables[1:10]){
  tmp1 <- data.table(table(mother_demographic[, get(i)], useNA = "ifany", dnn=i))
  tmp2 <- data.table(prop.table(table(mother_demographic[, get(i)], dnn=i))*100) 
  setnames(tmp2, old="N", new="prop")
  print(merge(tmp1, tmp2, all.x = T))
}

# MEDIAN AND RANGE FOR EDUCATION AND YEARS IN U.S.
nrow(mother_demographic[is.na(education)])
median(mother_demographic$education, na.rm =TRUE)
range(mother_demographic$education, na.rm =TRUE)

nrow(mother_demographic[is.na(years_in_US)])
median(mother_demographic$years_in_US, na.rm =TRUE)
range(mother_demographic$years_in_US, na.rm =TRUE)

# AGE OF MOTHERS' CHILD
mother_child_age <- unique(mother_data[, .(dinner_id,study_id, child_report_age)])

child_13 = mother_child_age[child_report_age <=13]
nrow(unique(child_13[, .(dinner_id,study_id)]))
nrow(unique(child_13[, .(dinner_id,study_id)]))/115

child_14 = mother_child_age[child_report_age >=14]
nrow(unique(child_14[, .(dinner_id,study_id)]))
nrow(unique(child_14[, .(dinner_id,study_id)]))/115

# NUMBER OF 14-17 CHILD ATTENDED THE COMIC BOOK EVENT
num_child = mother_data[child_report_age >=14]
unique(num_child[, .(dinner_id,study_id, child_report_age)]) #147 children

# GENDER OF MOTHERS' CHILD
mother_child_gender <- unique(mother_data[, .(dinner_id, study_id, child_report_gender)])
mother_child_gender_1 <- data.frame(mother_child_gender) %>% na.omit() %>% 
  pivot_wider(names_from = child_report_gender,values_from = child_report_gender) %>% rename(males = `1`, females = `2`)
mother_child_gender_1 <- data.table(mother_child_gender_1)

#Both males and females
nrow(mother_child_gender_1[!is.na(females) & !is.na(males)])
nrow(mother_child_gender_1[!is.na(females) & !is.na(males)])/nrow(mother_child_gender_1)

#Males only
nrow(mother_child_gender_1[is.na(females) & !is.na(males)])
nrow(mother_child_gender_1[is.na(females) & !is.na(males)])/nrow(mother_child_gender_1)

#Females only
nrow(mother_child_gender_1[!is.na(females) & is.na(males)])
nrow(mother_child_gender_1[!is.na(females) & is.na(males)])/nrow(mother_child_gender_1)

nrow(mother_demographic) - nrow(mother_child_gender_1)

# COUNTRY OF BIRTH OF MOTHERS' CHILD
mother_child_birth <- unique(mother_data[, .(dinner_id, study_id, child_bring_birth)])
data.table(table(mother_child_birth$child_bring_birth, useNA = "ifany", dnn=i))

mother_child_birth[, count :=.N, by=.(dinner_id, study_id)]
missing_mother = nrow(mother_child_birth[count == 1 & is.na(child_bring_birth)])
missing_mother
data.table(table(mother_child_birth$child_bring_birth, dnn=i)*100/(115-missing_mother))


###############################################################################
####                TABLE 3 - PRE AND POST SURVEY FREQUENCY                ####
###############################################################################
# SUBSET DATA
mother_pre_post <-unique(mother_data[, c(3,4,54:89)])
mother_pre      <- mother_pre_post[, 3:20]
mother_post     <- mother_pre_post[, 21:38]
# N & FREQUENCY
for (i in 1:18){
  print(paste0("question: ", var_lab(mother_pre[, i, with=F])))
  print(stack(attr(data.frame(mother_pre)[, i], 'labels')))
  
  merge_pre_post <- data.table(pre=mother_pre[, i, with=F], post=mother_post[, i, with=F])
  merge_pre_post <- merge_pre_post[complete.cases(merge_pre_post)]
  setnames(merge_pre_post, old=names(merge_pre_post), new=c("pre", "post"))
  
  print(merge_pre_post[order(pre), .(pre_n=.N, pre_prop=round((.N)/nrow(merge_pre_post)*100, 4)), by=pre])
  print(merge_pre_post[order(post), .(post_n=.N, post_prop=round((.N)/nrow(merge_pre_post)*100, 4)), by=post])
  print("---------------------------------------------")
}

# McNemar TEST - PAIRED

# QUESTION 1,3,4,5,8,10,12,14,15

for (i in c(1,3,4,5,8,10,12,14,15)){
  print(paste0("question: ", var_lab(mother_pre[, i, with=F])))
  
  # merge identical pre and post question
  merge_pre_post <- data.table(pre=mother_pre[, i, with=F], post=mother_post[, i, with=F])
  merge_pre_post <- merge_pre_post[complete.cases(merge_pre_post)]
  setnames(merge_pre_post, old=names(merge_pre_post), new=c("pre", "post"))
  
  ##combine "not sure" with "false"
  merge_pre_post[pre == 3, pre := 2]
  merge_pre_post[post == 3, post := 2]
  
  table_pop = table(merge_pre_post$post, merge_pre_post$pre)
  print(mcnemar.test(table_pop, correct = FALSE))
  print("---------------------------------------------")
}

# QUESTION 2,6,7,9,11

for (i in c(2,6,7,9,11)){
  print(paste0("question: ", var_lab(mother_pre[, i, with=F])))
  
  # merge identical pre and post question
  merge_pre_post <- data.table(pre=mother_pre[, i, with=F], post=mother_post[, i, with=F])
  merge_pre_post <- merge_pre_post[complete.cases(merge_pre_post)]
  setnames(merge_pre_post, old=names(merge_pre_post), new=c("pre", "post"))
  
  ##combine "not sure" with "true"
  merge_pre_post[pre == 3, pre := 1]
  merge_pre_post[post == 3, post := 1]
  
  table_pop = table(merge_pre_post$post, merge_pre_post$pre)
  print(mcnemar.test(table_pop, correct = FALSE))
  print("---------------------------------------------")
}


# QUESTION 13
paste0("question: ", var_lab(mother_pre$ae_concern_pre))
q13 = mother_pre_post[, .(ae_concern_pre, ae_concern_post)]
q13 = q13[complete.cases(q13)] # drop NA

# Where pre-"not sure" mothers fell in post-test?
stack(attr(q13$ae_concern_pre, 'labels'))
q13_notsure <- q13[ae_concern_pre == 4]
q13_notsure[,.(n = .N),by=ae_concern_post]

# Recode (“Not sure” response is considered in the negative category)
q13[ae_concern_pre %in% c(1, 4), ae_concern_pre := 2]
q13[ae_concern_pre == 3, ae_concern_pre := 1]
q13[ae_concern_post %in% c(1, 4), ae_concern_post := 2]
q13[ae_concern_post == 3, ae_concern_post := 1]

table_q13 = table(q13$ae_concern_post, q13$ae_concern_pre)
mcnemar.test(table_q13, correct = FALSE)

# QUESTION 16

paste0("question: ", var_lab(mother_pre$vacc_get_feel_pre))
# merge identical pre and post question
merge_pre_post <- data.table(pre=mother_pre$vacc_get_feel_pre, post=mother_post$vacc_get_feel_post)
merge_pre_post <- merge_pre_post[complete.cases(merge_pre_post)]
setnames(merge_pre_post, old=names(merge_pre_post), new=c("pre", "post"))

##combine "not sure", "undecided" with "do not want him/her to get the vaccine"
merge_pre_post[pre %in% c(3,4), pre := 2]
merge_pre_post[post %in% c(3,4), post := 2]

table_pop = table(merge_pre_post$post, merge_pre_post$pre)
print(mcnemar.test(table_pop, correct = FALSE))
print("---------------------------------------------")

# QUESTION 17, 18

for (i in c(17, 18)){
  print(paste0("question: ", var_lab(mother_pre[, i, with=F])))
  
  # merge identical pre and post question
  merge_pre_post <- data.table(pre=mother_pre[, i, with=F], post=mother_post[, i, with=F])
  merge_pre_post <- merge_pre_post[complete.cases(merge_pre_post)]
  setnames(merge_pre_post, old=names(merge_pre_post), new=c("pre", "post"))
  
  ##combine "somewhat likely" with "very likely" / "not likely" with "not sure"
  merge_pre_post[pre == 2, pre := 1]
  merge_pre_post[pre %in% c(3,4), pre := 2]
  merge_pre_post[post == 2, post := 1]
  merge_pre_post[post %in% c(3,4), post := 2]
  
  table_pop = table(merge_pre_post$post, merge_pre_post$pre)
  print(mcnemar.test(table_pop, correct = FALSE))
  print("---------------------------------------------")
}

###############################################################################
####                         TABLE 4 - MEAN & SD                           ####
###############################################################################

##################### HPV KNOWLEDGE/BELIEFS QUESTIONS ########################
knowledge_pre <- mother_data[, c(3,4,54:57,72:75)]
knowledge_pre <- knowledge_pre[complete.cases(knowledge_pre)]

# recode HPV knowledge
for (i in c(3,5,6)) {
  # extract column name
  v1 <- names(knowledge_pre)[i]
  v2 <- names(knowledge_pre)[i+4]
  
  knowledge_pre[get(v1) == 3, (v1) := 2]
  knowledge_pre[get(v2) == 3, (v2) := 2]
}

knowledge_pre[hpv_rare_pre == 1, hpv_rare_pre := 3]
knowledge_pre[hpv_rare_pre == 2, hpv_rare_pre := 1]
knowledge_pre[hpv_rare_pre == 3, hpv_rare_pre := 2]

knowledge_pre[hpv_rare_post == 1, hpv_rare_post := 3]
knowledge_pre[hpv_rare_post == 2, hpv_rare_post := 1]
knowledge_pre[hpv_rare_post == 3, hpv_rare_post := 2]

# Total of correct answer for pre and post surveys
knowledge_pre$correct_ans_pre <-rowSums(knowledge_pre[,3:6]==1)
knowledge_pre$correct_ans_post <-rowSums(knowledge_pre[,7:10]==1)
knowledge_pre$myoffset <- 4

## Mean-SD
test = unique(knowledge_pre[, .(dinner_id, study_id,correct_ans_pre, correct_ans_post)])
mean_sd_knowledge=test[, .(pre_sum=sum(correct_ans_pre), post_sum=sum(correct_ans_post), n=.N)]
mean_sd_knowledge[, pre_prop := pre_sum/(n*4)][, post_prop := post_sum/(n*4)]
mean_sd_knowledge[, pre_sd   := sqrt((pre_prop*(1-pre_prop))/(n*4))][, post_sd := sqrt((post_prop*(1-post_prop))/(n*4))]
mean_sd_knowledge

# Reshape
knowledge <- copy(knowledge_pre)
knowledge<- data.table(pivot_longer(knowledge, cols = c(correct_ans_pre, correct_ans_post), names_to = "correct_ans", values_to = "num_correct_ans"))
knowledge[,pre_or_post :=  ifelse(knowledge$correct_ans=="correct_ans_pre", 0, 1)]


################## HPV VACCINE KNOWLEDGE/BELIEFS QUESTIONS #####################

hpvv_knowledge_pre <- mother_data[, c(3,4,58:63,76:81)]
hpvv_knowledge_pre <- hpvv_knowledge_pre[complete.cases(hpvv_knowledge_pre)]

# recode HPV vaccine knowledge
for (i in c(3,6,8)) {
  # extract column name
  v1 <- names(hpvv_knowledge_pre)[i]
  v2 <- names(hpvv_knowledge_pre)[i+6]
  
  hpvv_knowledge_pre[get(v1) == 3, (v1) := 2]
  hpvv_knowledge_pre[get(v2) == 3, (v2) := 2]
}

for (i in c(4,5,7)) {
  # extract column name
  v1 <- names(hpvv_knowledge_pre)[i]
  v2 <- names(hpvv_knowledge_pre)[i+6]
  
  hpvv_knowledge_pre[get(v1) == 1, (v1) := 3]
  hpvv_knowledge_pre[get(v1) == 2, (v1) := 1]
  hpvv_knowledge_pre[get(v1) == 3, (v1) := 2]
  
  hpvv_knowledge_pre[get(v2) == 1, (v2) := 3]
  hpvv_knowledge_pre[get(v2) == 2, (v2) := 1]
  hpvv_knowledge_pre[get(v2) == 3, (v2) := 2]
}

# Total of correct answer for pre and post surveys
hpvv_knowledge_pre$correct_ans_pre <-rowSums(hpvv_knowledge_pre[,3:8]==1) 
hpvv_knowledge_pre$correct_ans_post <-rowSums(hpvv_knowledge_pre[,9:14]==1)
hpvv_knowledge_pre$myoffset <- 6

## Mean-SD
test = unique(data.table(hpvv_knowledge_pre)[, .(dinner_id, study_id, correct_ans_pre, correct_ans_post)])
mean_sd_hpvv_knowledge=test[, .(pre_sum=sum(correct_ans_pre), post_sum=sum(correct_ans_post), n=.N)]
mean_sd_hpvv_knowledge[, pre_prop := pre_sum/(n*6)][, post_prop := post_sum/(n*6)]
mean_sd_hpvv_knowledge[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n*6))][, post_sd := sqrt((post_prop*(1-post_prop))/(n*6))]
mean_sd_hpvv_knowledge

# Reshape
hpvv_knowledge <- copy(hpvv_knowledge_pre)
hpvv_knowledge<- data.table(pivot_longer(hpvv_knowledge, cols = c(correct_ans_pre, correct_ans_post), names_to = "correct_ans", values_to = "num_correct_ans"))
hpvv_knowledge[,pre_or_post :=  ifelse(hpvv_knowledge$correct_ans=="correct_ans_pre", 0, 1)]

###################### SOCIAL NORMS/INFLUENCE QUESTIONS #######################

social_pre <- mother_data[, c(3,4,64,65,82,83)]
social_pre <- social_pre[complete.cases(social_pre)]

# recode social norms/influence
social_pre[hpv_vacc_comm_pre == 1, hpv_vacc_comm_pre := 3][hpv_vacc_comm_post == 1, hpv_vacc_comm_post := 3]
social_pre[hpv_vacc_comm_pre == 2, hpv_vacc_comm_pre := 1][hpv_vacc_comm_post == 2, hpv_vacc_comm_post := 1]
social_pre[hpv_vacc_comm_pre == 3, hpv_vacc_comm_pre := 2][hpv_vacc_comm_post == 3, hpv_vacc_comm_post := 2]

social_pre[hpv_vacc_imp_pre == 3, hpv_vacc_imp_pre := 2][hpv_vacc_imp_post == 3, hpv_vacc_imp_post := 2]


# Total of correct answer for pre and post surveys
social_pre$correct_ans_pre <-rowSums(social_pre[,3:4]==1)
social_pre$correct_ans_post <-rowSums(social_pre[,5:6]==1)

social_pre$myoffset <- 2

## Mean-SD
test = unique(data.table(social_pre)[, .(dinner_id, study_id, correct_ans_pre, correct_ans_post)])
mean_sd_social=test[, .(pre_sum=sum(correct_ans_pre), post_sum=sum(correct_ans_post), n=.N)]
mean_sd_social[, pre_prop := pre_sum/(n*2)][, post_prop := post_sum/(n*2)]
mean_sd_social[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n*2))][, post_sd := sqrt((post_prop*(1-post_prop))/(n*2))]
mean_sd_social

# Reshape
social <- copy(social_pre)
social<- data.table(pivot_longer(social, cols = c(correct_ans_pre, correct_ans_post), names_to = "correct_ans", values_to = "num_correct_ans"))
social[,pre_or_post :=  ifelse(social$correct_ans=="correct_ans_pre", 0, 1)]

########################### BARRIER QUESTIONS ##################################

barriers_pre <- mother_data[, c(3,4,66,84)]
barriers_pre <- barriers_pre[complete.cases(barriers_pre)]

# "Very Concerned", "Somewhat Concerned" and "Not sure" are combined 
barriers_pre[ae_concern_pre %in% c(1,4), ae_concern_pre := 2][ae_concern_post %in% c(1,4), ae_concern_post := 2]
barriers_pre[ae_concern_pre == 3, ae_concern_pre := 1][ae_concern_post == 3, ae_concern_post := 1]

# Total of correct answer for pre and post surveys
barriers_pre$correct_ans_pre <-rowSums(barriers_pre[,3]==1)
barriers_pre$correct_ans_post <-rowSums(barriers_pre[,4]==1)

barriers_pre$myoffset <- 1

## Mean-SD
test = unique(data.table(barriers_pre)[, .(dinner_id, study_id, correct_ans_pre, correct_ans_post)])
mean_sd_barriers=test[, .(pre_sum=sum(correct_ans_pre), post_sum=sum(correct_ans_post), n=.N)]
mean_sd_barriers[, pre_prop := pre_sum/(n)][, post_prop := post_sum/(n)]
mean_sd_barriers[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n))][, post_sd := sqrt((post_prop*(1-post_prop))/(n))]
mean_sd_barriers

# Reshape
barriers <- copy(barriers_pre)
barriers<- data.table(pivot_longer(barriers, cols = c(correct_ans_pre, correct_ans_post), names_to = "correct_ans", values_to = "num_correct_ans"))
barriers[,pre_or_post :=  ifelse(barriers$correct_ans=="correct_ans_pre", 0, 1)]

######################### SELF-EFFICACY QUESTIONS ################################

self_efficacy_pre <- mother_data[, c(3,4,67,68,85,86)]
self_efficacy_pre <- self_efficacy_pre[complete.cases(self_efficacy_pre)]

# Combine "not sure" with "Disagree"
self_efficacy_pre[vacc_get_info_pre == 3, vacc_get_info_pre := 2][vacc_get_info_post == 3, vacc_get_info_post := 2]
self_efficacy_pre[vacc_get_where_pre == 3, vacc_get_where_pre := 2][vacc_get_where_post == 3, vacc_get_where_post := 2]

# Total of correct answer for pre and post surveys
self_efficacy_pre$correct_ans_pre <-rowSums(self_efficacy_pre[,3:4]==1) 
self_efficacy_pre$correct_ans_post <-rowSums(self_efficacy_pre[,5:6]==1)

self_efficacy_pre$myoffset <- 2

## Mean-SD
test = unique(data.table(self_efficacy_pre)[, .(dinner_id, study_id, correct_ans_pre, correct_ans_post)])
mean_sd_self_efficacy= test[, .(pre_sum=sum(correct_ans_pre), post_sum=sum(correct_ans_post), n=.N)]
mean_sd_self_efficacy[, pre_prop := pre_sum/(n*2)][, post_prop := post_sum/(n*2)]
mean_sd_self_efficacy[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n*2))][, post_sd := sqrt((post_prop*(1-post_prop))/(n*2))]
mean_sd_self_efficacy

# Reshape
self_efficacy <- copy(self_efficacy_pre)
self_efficacy<- data.table(pivot_longer(self_efficacy, cols = c(correct_ans_pre, correct_ans_post), names_to = "correct_ans", values_to = "num_correct_ans"))
self_efficacy[,pre_or_post :=  ifelse(self_efficacy$correct_ans=="correct_ans_pre", 0, 1)]

######################### WILLINGNESS QUESTIONS ################################

willing_pre <- mother_data[, c(3,4,69,87)]
willing_pre <- willing_pre[complete.cases(willing_pre)]

#combine "You are undecided" & "Not sure" with "You do not want him / her to get the vaccine"
willing_pre[vacc_get_feel_pre %in% c(3,4), vacc_get_feel_pre := 2][vacc_get_feel_post %in% c(3,4), vacc_get_feel_post := 2]

##Create a new variable for the total of correct answer per mother for pre and post surveys
willing_pre$correct_ans_pre <-rowSums(willing_pre[,3]==1) 
willing_pre$correct_ans_post <-rowSums(willing_pre[,4]==1)

willing_pre$myoffset <- 1

## Mean-SD
test = unique(data.table(willing_pre)[, .(dinner_id, study_id, correct_ans_pre, correct_ans_post)])
mean_sd_willing=test[, .(pre_sum=sum(correct_ans_pre), post_sum=sum(correct_ans_post), n=.N)]
mean_sd_willing[, pre_prop := pre_sum/(n)][, post_prop := post_sum/(n)]
mean_sd_willing[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n))][, post_sd := sqrt((post_prop*(1-post_prop))/(n))]
mean_sd_willing

# Reshape
willing <- copy(willing_pre)
willing<- data.table(pivot_longer(willing, cols = c(correct_ans_pre, correct_ans_post), names_to = "correct_ans", values_to = "num_correct_ans"))
willing[,pre_or_post :=  ifelse(willing$correct_ans=="correct_ans_pre", 0, 1)]

######################### INTENTION QUESTIONS ################################

intention_pre <- mother_data[, c(3,4,70,71,88,89)]
intention_pre <- intention_pre[complete.cases(intention_pre)]

# combine "somewhat likely" with "very likely" / "not likely" with "not sure"
intention_pre[vacc_6mo_doctor_pre == 2, vacc_6mo_doctor_pre := 1][vacc_6mo_doctor_post == 2, vacc_6mo_doctor_post := 1]
intention_pre[vacc_6mo_doctor_pre %in% c(3,4), vacc_6mo_doctor_pre := 2][vacc_6mo_doctor_post %in% c(3,4), vacc_6mo_doctor_post := 2]

intention_pre[vacc_6m_get_pre == 2, vacc_6m_get_pre := 1][vacc_6m_get_post == 2, vacc_6m_get_post := 1]
intention_pre[vacc_6m_get_pre %in% c(3,4), vacc_6m_get_pre := 2][vacc_6m_get_post %in% c(3,4), vacc_6m_get_post := 2]

##Create a new variable for the total of correct answer per mother for pre and post surveys
intention_pre$correct_ans_pre <-rowSums(intention_pre[,3:4]==1) 
intention_pre$correct_ans_post <-rowSums(intention_pre[,5:6]==1)

intention_pre$myoffset <- 2

# Mean-SD
test = unique(data.table(intention_pre)[, .(dinner_id, study_id, correct_ans_pre, correct_ans_post)])
mean_sd_intention=test[, .(pre_sum=sum(correct_ans_pre), post_sum=sum(correct_ans_post), n=.N)]
mean_sd_intention[, pre_prop := pre_sum/(n*2)][, post_prop := post_sum/(n*2)]
mean_sd_intention[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n*2))][, post_sd := sqrt((post_prop*(1-post_prop))/(n*2))]
mean_sd_intention

# Reshape
intention <- copy(intention_pre)
intention<- data.table(pivot_longer(intention, cols = c(correct_ans_pre, correct_ans_post), names_to = "correct_ans", values_to = "num_correct_ans"))
intention[,pre_or_post :=  ifelse(intention$correct_ans=="correct_ans_pre", 0, 1)]

################# INTENTION BY GENDER #########################
intention_gender <- mother_data[, c(3,4,70,71,88,89)]
unique(mother_child_gender_1)
unique(intention_gender)
all <- merge(intention_gender, mother_child_gender_1)
all <- unique(all[,.(dinner_id, study_id, vacc_6mo_doctor_pre, vacc_6m_get_pre, vacc_6mo_doctor_post, vacc_6m_get_post, females, males)])

females_only <- all[(!is.na(females)) & (is.na(males))]
females_only1 <- females_only[,males := NULL]
males_only <- all[(is.na(females)) & (!is.na(males))]
males_only1 <- males_only[,females := NULL]

intention_pre <- females_only1[complete.cases(females_only1)]
intention_pre <- males_only1[complete.cases(males_only1)]

# combine "somewhat likely" with "very likely" / "not likely" with "not sure"
intention_pre[vacc_6mo_doctor_pre == 2, vacc_6mo_doctor_pre := 1][vacc_6mo_doctor_post == 2, vacc_6mo_doctor_post := 1]
intention_pre[vacc_6mo_doctor_pre %in% c(3,4), vacc_6mo_doctor_pre := 2][vacc_6mo_doctor_post %in% c(3,4), vacc_6mo_doctor_post := 2]

intention_pre[vacc_6m_get_pre == 2, vacc_6m_get_pre := 1][vacc_6m_get_post == 2, vacc_6m_get_post := 1]
intention_pre[vacc_6m_get_pre %in% c(3,4), vacc_6m_get_pre := 2][vacc_6m_get_post %in% c(3,4), vacc_6m_get_post := 2]

##Create a new variable for the total of correct answer per mother for pre and post surveys
intention_pre$correct_ans_pre <-rowSums(intention_pre[,3:4]==1) 
intention_pre$correct_ans_post <-rowSums(intention_pre[,5:6]==1)

intention_pre$myoffset <- 2

# Mean-SD
test = unique(data.table(intention_pre)[, .(dinner_id, study_id, correct_ans_pre, correct_ans_post)])
mean_sd_intention=test[, .(pre_sum=sum(correct_ans_pre), post_sum=sum(correct_ans_post), n=.N)]
mean_sd_intention[, pre_prop := pre_sum/(n*2)][, post_prop := post_sum/(n*2)]
mean_sd_intention[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n*2))][, post_sd := sqrt((post_prop*(1-post_prop))/(n*2))]
mean_sd_intention

# Reshape
intention <- copy(intention_pre)
intention<- data.table(pivot_longer(intention, cols = c(correct_ans_pre, correct_ans_post), names_to = "correct_ans", values_to = "num_correct_ans"))
intention[,pre_or_post :=  ifelse(intention$correct_ans=="correct_ans_pre", 0, 1)]

###############################################################################
####                         TABLE 4 - GEE MODELS                          ####
###############################################################################

variables <- c("knowledge", "hpvv_knowledge", "social", "barriers", "self_efficacy" ,"willing", "intention")
for (i in variables[1:7]){
  print(paste0("Question items: ", i))
  geeglm <- gee(num_correct_ans ~ pre_or_post+ offset(myoffset),data= unique(get(i)),id=study_id, family = "poisson", corstr="exchangeable")
  
  print(paste0("----RR----"))
  print(exp(geeglm$coefficients)) ## Crude RR
  
  print(paste0("----95% CI----"))
  se <- summary(geeglm)$coefficients["pre_or_post","Robust S.E."]
  print(exp(coef(geeglm)["pre_or_post"] + c(-1, 1) *se* qnorm(0.975)))
  
  print(paste0("----p-value----"))
  print(2 * pnorm(abs(coef(summary(geeglm))[,5]), lower.tail = FALSE))
  print("---------------------------------------------")
}

###############################################################################
####                                 FIGURE 1                              ####
###############################################################################

test_knowledge      = data.table(time=c("pre", "post"), prop=c(mean_sd_knowledge$pre_prop, mean_sd_knowledge$post_prop), name_ques = "HPV knowledge/beliefs")
test_hpvv_knowledge = data.table(time=c("pre", "post"), prop=c(mean_sd_hpvv_knowledge$pre_prop, mean_sd_hpvv_knowledge$post_prop), name_ques = "HPV vaccine knowledge/beliefs")
test_social         = data.table(time=c("pre", "post"), prop=c(mean_sd_social$pre_prop, mean_sd_social$post_prop), name_ques = "Social norms/influence")
test_barriers       = data.table(time=c("pre", "post"), prop=c(mean_sd_barriers$pre_prop, mean_sd_barriers$post_prop), name_ques = "Barriers")
test_self_efficacy  = data.table(time=c("pre", "post"), prop=c(mean_sd_self_efficacy$pre_prop, mean_sd_self_efficacy$post_prop), name_ques = "Self-efficacy")
test_willing        = data.table(time=c("pre", "post"), prop=c(mean_sd_willing$pre_prop, mean_sd_willing$post_prop), name_ques = "Willingness")
test_intention      = data.table(time=c("pre", "post"), prop=c(mean_sd_intention$pre_prop, mean_sd_intention$post_prop), name_ques = "Intention")

merge_mean_sd       <- rbind(test_knowledge, test_hpvv_knowledge, test_social, test_barriers, test_self_efficacy, test_willing, test_intention)
merge_mean_sd[, id := ifelse(time == "pre", 1, 2)]

ggplot(data = merge_mean_sd, aes(x=id, y=prop, color = name_ques)) + geom_line(size=1.2, alpha=0.75) + 
  scale_x_continuous(breaks=1:2, labels = c("Pre-survey", "Post-survey")) + 
  labs(x="Survey", y="Mean proportion of mothers with correct answers", color = "Constructs",
       title="Pre- and post-intervention changes in mothers' knowledge,\nbeliefs, attitudes and intention to vaccinate their children") + theme_bw() + ylim(0,1)+
  theme(axis.text = element_text(size=14), axis.title = element_text(size=14), 
        legend.text = element_text(size=12), legend.title = element_text(size=14),
        plot.title = element_text(hjust = 0.5, size = 20))


###########################################################################################
####                                  REVIEWERS' COMMENT                               ####
###########################################################################################


###############################################################################
####    TABLE 3 - PRE AND POST SURVEY FREQUENCY - REVIEWERS' COMMENT       ####
###############################################################################
mother_child_gender <- unique(mother_data[, .(dinner_id, study_id, child_report_gender)])
mother_child_gender_1 <- data.frame(mother_child_gender) %>% na.omit() %>% 
  pivot_wider(names_from = child_report_gender,values_from = child_report_gender) %>% rename(males = `1`, females = `2`)
mother_child_gender_1 <- data.table(mother_child_gender_1)

mother_pre_post_gender <- mother_data[, c(3,4,54:89)]
unique(mother_child_gender_1)
unique(mother_pre_post_gender)
all <- merge(mother_pre_post_gender, mother_child_gender_1)
#all <- unique(all[,.(dinner_id, study_id, vacc_6mo_doctor_pre, vacc_6m_get_pre, vacc_6mo_doctor_post, vacc_6m_get_post, females, males)])
all1 <- unique(all)

females_only <- all1[(!is.na(females)) & (is.na(males))]
females_only1 <- females_only[,males := NULL]
males_only <- all1[(is.na(females)) & (!is.na(males))]
males_only1 <- males_only[,females := NULL]

#intention_pre <- females_only1[complete.cases(females_only1)]
#intention_pre <- males_only1[complete.cases(males_only1)]

# SUBSET DATA
mother_pre      <- females_only1[, 3:20]
mother_post     <- females_only1[, 21:38]

mother_pre      <- males_only1[, 3:20]
mother_post     <- males_only1[, 21:38]
# N & FREQUENCY
for (i in c(8,9,16,17,18)){
  print(paste0("question: ", var_lab(mother_pre[, i, with=F])))
  print(stack(attr(data.frame(mother_pre)[, i], 'labels')))
  
  merge_pre_post <- data.table(pre=mother_pre[, i, with=F], post=mother_post[, i, with=F])
  merge_pre_post <- merge_pre_post[complete.cases(merge_pre_post)]
  setnames(merge_pre_post, old=names(merge_pre_post), new=c("pre", "post"))
  
  print(merge_pre_post[order(pre), .(pre_n=.N, pre_prop=round((.N)/nrow(merge_pre_post)*100, 1)), by=pre])
  print(merge_pre_post[order(post), .(post_n=.N, post_prop=round((.N)/nrow(merge_pre_post)*100, 1)), by=post])
  print("---------------------------------------------")
}
# McNemar TEST - PAIRED

# QUESTION 1,3,4,5,8,10,12,14,15

for (i in 8){
  print(paste0("question: ", var_lab(mother_pre[, i, with=F])))
  
  # merge identical pre and post question
  merge_pre_post <- data.table(pre=mother_pre[, i, with=F], post=mother_post[, i, with=F])
  merge_pre_post <- merge_pre_post[complete.cases(merge_pre_post)]
  setnames(merge_pre_post, old=names(merge_pre_post), new=c("pre", "post"))
  
  ##combine "not sure" with "false"
  merge_pre_post[pre == 3, pre := 2]
  merge_pre_post[post == 3, post := 2]
  
  table_pop = table(merge_pre_post$post, merge_pre_post$pre)
  print(mcnemar.test(table_pop, correct = FALSE))
  print("---------------------------------------------")
}

# QUESTION 2,6,7,9,11

for (i in 9){
  print(paste0("question: ", var_lab(mother_pre[, i, with=F])))
  
  # merge identical pre and post question
  merge_pre_post <- data.table(pre=mother_pre[, i, with=F], post=mother_post[, i, with=F])
  merge_pre_post <- merge_pre_post[complete.cases(merge_pre_post)]
  setnames(merge_pre_post, old=names(merge_pre_post), new=c("pre", "post"))
  
  ##combine "not sure" with "true"
  merge_pre_post[pre == 3, pre := 1]
  merge_pre_post[post == 3, post := 1]
  
  table_pop = table(merge_pre_post$post, merge_pre_post$pre)
  print(mcnemar.test(table_pop, correct = FALSE))
  print("---------------------------------------------")
}

# QUESTION 16

paste0("question: ", var_lab(mother_pre$vacc_get_feel_pre))
# merge identical pre and post question
merge_pre_post <- data.table(pre=mother_pre$vacc_get_feel_pre, post=mother_post$vacc_get_feel_post)
merge_pre_post <- merge_pre_post[complete.cases(merge_pre_post)]
setnames(merge_pre_post, old=names(merge_pre_post), new=c("pre", "post"))

##combine "not sure", "undecided" with "do not want him/her to get the vaccine"
merge_pre_post[pre %in% c(3,4), pre := 2]
merge_pre_post[post %in% c(3,4), post := 2]

table_pop = table(merge_pre_post$post, merge_pre_post$pre)
print(mcnemar.test(table_pop, correct = FALSE))
print("---------------------------------------------")

# QUESTION 17, 18

for (i in 18){
  print(paste0("question: ", var_lab(mother_pre[, i, with=F])))
  
  # merge identical pre and post question
  merge_pre_post <- data.table(pre=mother_pre[, i, with=F], post=mother_post[, i, with=F])
  merge_pre_post <- merge_pre_post[complete.cases(merge_pre_post)]
  setnames(merge_pre_post, old=names(merge_pre_post), new=c("pre", "post"))
  
  ##combine "somewhat likely" with "very likely" / "not likely" with "not sure"
  merge_pre_post[pre == 2, pre := 1]
  merge_pre_post[pre %in% c(3,4), pre := 2]
  merge_pre_post[post == 2, post := 1]
  merge_pre_post[post %in% c(3,4), post := 2]
  
  table_pop = table(merge_pre_post$post, merge_pre_post$pre)
  print(mcnemar.test(table_pop, correct = FALSE))
  print("---------------------------------------------")
}
###############################################################################
####                                 MAJOR 3                               ####
###############################################################################
##################### HPV KNOWLEDGE/BELIEFS QUESTIONS ########################
knowledge_pre <- mother_data[, c(3,4,54:57,72:75)]
knowledge_pre <- knowledge_pre[complete.cases(knowledge_pre)]

# recode HPV knowledge
for (i in c(3,5,6)) {
  # extract column name
  v1 <- names(knowledge_pre)[i]
  v2 <- names(knowledge_pre)[i+4]
  
  knowledge_pre[get(v1) == 3, (v1) := 2]
  knowledge_pre[get(v2) == 3, (v2) := 2]
}

knowledge_pre[hpv_rare_pre == 1, hpv_rare_pre := 3]
knowledge_pre[hpv_rare_pre == 2, hpv_rare_pre := 1]
knowledge_pre[hpv_rare_pre == 3, hpv_rare_pre := 2]

knowledge_pre[hpv_rare_post == 1, hpv_rare_post := 3]
knowledge_pre[hpv_rare_post == 2, hpv_rare_post := 1]
knowledge_pre[hpv_rare_post == 3, hpv_rare_post := 2]

# Total of correct answer for pre and post surveys
knowledge_pre$correct_ans_pre <-rowSums(knowledge_pre[,3:6]==1)
knowledge_pre$correct_ans_post <-rowSums(knowledge_pre[,7:10]==1)

knowledge_pre$incorrect_ans_pre <-rowSums(knowledge_pre[,3:6]==2)
knowledge_pre$incorrect_ans_post <-rowSums(knowledge_pre[,7:10]==2)
knowledge_pre$myoffset <- 4

## Mean-SD
test = unique(knowledge_pre[, .(dinner_id, study_id,incorrect_ans_pre, incorrect_ans_post)])
mean_sd_knowledge=test[, .(pre_sum=sum(incorrect_ans_pre), post_sum=sum(incorrect_ans_post), n=.N)]
mean_sd_knowledge[, pre_prop := pre_sum/(n*4)][, post_prop := post_sum/(n*4)]
mean_sd_knowledge[, pre_sd   := sqrt((pre_prop*(1-pre_prop))/(n*4))][, post_sd := sqrt((post_prop*(1-post_prop))/(n*4))]
mean_sd_knowledge

# Reshape
knowledge <- copy(knowledge_pre)
knowledge<- data.table(pivot_longer(knowledge, cols = c(incorrect_ans_pre, incorrect_ans_post), names_to = "incorrect_ans", values_to = "num_incorrect_ans"))
knowledge[,pre_or_post :=  ifelse(knowledge$incorrect_ans=="incorrect_ans_pre", 0, 1)]


################## HPV VACCINE KNOWLEDGE/BELIEFS QUESTIONS #####################

hpvv_knowledge_pre <- mother_data[, c(3,4,58:63,76:81)]
hpvv_knowledge_pre <- hpvv_knowledge_pre[complete.cases(hpvv_knowledge_pre)]

# recode HPV vaccine knowledge
for (i in c(3,6,8)) {
  # extract column name
  v1 <- names(hpvv_knowledge_pre)[i]
  v2 <- names(hpvv_knowledge_pre)[i+6]
  
  hpvv_knowledge_pre[get(v1) == 3, (v1) := 2]
  hpvv_knowledge_pre[get(v2) == 3, (v2) := 2]
}

for (i in c(4,5,7)) {
  # extract column name
  v1 <- names(hpvv_knowledge_pre)[i]
  v2 <- names(hpvv_knowledge_pre)[i+6]
  
  hpvv_knowledge_pre[get(v1) == 1, (v1) := 3]
  hpvv_knowledge_pre[get(v1) == 2, (v1) := 1]
  hpvv_knowledge_pre[get(v1) == 3, (v1) := 2]
  
  hpvv_knowledge_pre[get(v2) == 1, (v2) := 3]
  hpvv_knowledge_pre[get(v2) == 2, (v2) := 1]
  hpvv_knowledge_pre[get(v2) == 3, (v2) := 2]
}

# Total of correct answer for pre and post surveys
hpvv_knowledge_pre$correct_ans_pre <-rowSums(hpvv_knowledge_pre[,3:8]==1) 
hpvv_knowledge_pre$incorrect_ans_pre <-rowSums(hpvv_knowledge_pre[,3:8]==2) 
hpvv_knowledge_pre$correct_ans_post <-rowSums(hpvv_knowledge_pre[,9:14]==1)
hpvv_knowledge_pre$incorrect_ans_post <-rowSums(hpvv_knowledge_pre[,9:14]==2)
hpvv_knowledge_pre$myoffset <- 6

## Mean-SD
test = unique(data.table(hpvv_knowledge_pre)[, .(dinner_id, study_id, incorrect_ans_pre, incorrect_ans_post)])
mean_sd_hpvv_knowledge=test[, .(pre_sum=sum(incorrect_ans_pre), post_sum=sum(incorrect_ans_post), n=.N)]
mean_sd_hpvv_knowledge[, pre_prop := pre_sum/(n*6)][, post_prop := post_sum/(n*6)]
mean_sd_hpvv_knowledge[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n*6))][, post_sd := sqrt((post_prop*(1-post_prop))/(n*6))]
mean_sd_hpvv_knowledge

# Reshape
hpvv_knowledge <- copy(hpvv_knowledge_pre)
hpvv_knowledge<- data.table(pivot_longer(hpvv_knowledge, cols = c(incorrect_ans_pre, incorrect_ans_post), names_to = "incorrect_ans", values_to = "num_incorrect_ans"))
hpvv_knowledge[,pre_or_post :=  ifelse(hpvv_knowledge$incorrect_ans=="incorrect_ans_pre", 0, 1)]

###################### SOCIAL NORMS/INFLUENCE QUESTIONS #######################

social_pre <- mother_data[, c(3,4,64,65,82,83)]
social_pre <- social_pre[complete.cases(social_pre)]

# recode social norms/influence
social_pre[hpv_vacc_comm_pre == 1, hpv_vacc_comm_pre := 3][hpv_vacc_comm_post == 1, hpv_vacc_comm_post := 3]
social_pre[hpv_vacc_comm_pre == 2, hpv_vacc_comm_pre := 1][hpv_vacc_comm_post == 2, hpv_vacc_comm_post := 1]
social_pre[hpv_vacc_comm_pre == 3, hpv_vacc_comm_pre := 2][hpv_vacc_comm_post == 3, hpv_vacc_comm_post := 2]

social_pre[hpv_vacc_imp_pre == 3, hpv_vacc_imp_pre := 2][hpv_vacc_imp_post == 3, hpv_vacc_imp_post := 2]


# Total of correct answer for pre and post surveys
social_pre$correct_ans_pre <-rowSums(social_pre[,3:4]==1)
social_pre$correct_ans_post <-rowSums(social_pre[,5:6]==1)
social_pre$incorrect_ans_pre <-rowSums(social_pre[,3:4]==2)
social_pre$incorrect_ans_post <-rowSums(social_pre[,5:6]==2)
social_pre$myoffset <- 2

## Mean-SD
test = unique(data.table(social_pre)[, .(dinner_id, study_id, incorrect_ans_pre, incorrect_ans_post)])
mean_sd_social=test[, .(pre_sum=sum(incorrect_ans_pre), post_sum=sum(incorrect_ans_post), n=.N)]
mean_sd_social[, pre_prop := pre_sum/(n*2)][, post_prop := post_sum/(n*2)]
mean_sd_social[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n*2))][, post_sd := sqrt((post_prop*(1-post_prop))/(n*2))]
mean_sd_social

# Reshape
social <- copy(social_pre)
social<- data.table(pivot_longer(social, cols = c(incorrect_ans_pre, incorrect_ans_post), names_to = "incorrect_ans", values_to = "num_incorrect_ans"))
social[,pre_or_post :=  ifelse(social$incorrect_ans=="incorrect_ans_pre", 0, 1)]

########################### BARRIER QUESTIONS ##################################

barriers_pre <- mother_data[, c(3,4,66,84)]
barriers_pre <- barriers_pre[complete.cases(barriers_pre)]

# "Very Concerned", "Somewhat Concerned" and "Not sure" are combined 
barriers_pre[ae_concern_pre %in% c(1,4), ae_concern_pre := 2][ae_concern_post %in% c(1,4), ae_concern_post := 2]
barriers_pre[ae_concern_pre == 3, ae_concern_pre := 1][ae_concern_post == 3, ae_concern_post := 1]

# Total of correct answer for pre and post surveys
barriers_pre$correct_ans_pre <-rowSums(barriers_pre[,3]==1)
barriers_pre$correct_ans_post <-rowSums(barriers_pre[,4]==1)

barriers_pre$incorrect_ans_pre <-rowSums(barriers_pre[,3]==2)
barriers_pre$incorrect_ans_post <-rowSums(barriers_pre[,4]==2)
barriers_pre$myoffset <- 1

## Mean-SD
test = unique(data.table(barriers_pre)[, .(dinner_id, study_id, incorrect_ans_pre, incorrect_ans_post)])
mean_sd_barriers=test[, .(pre_sum=sum(incorrect_ans_pre), post_sum=sum(incorrect_ans_post), n=.N)]
mean_sd_barriers[, pre_prop := pre_sum/(n)][, post_prop := post_sum/(n)]
mean_sd_barriers[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n))][, post_sd := sqrt((post_prop*(1-post_prop))/(n))]
mean_sd_barriers

test = unique(data.table(barriers_pre)[, .(dinner_id, study_id, correct_ans_pre, correct_ans_post)])
mean_sd_barriers=test[, .(pre_sum=sum(correct_ans_pre), post_sum=sum(correct_ans_post), n=.N)]
mean_sd_barriers[, pre_prop := pre_sum/(n)][, post_prop := post_sum/(n)]
mean_sd_barriers[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n))][, post_sd := sqrt((post_prop*(1-post_prop))/(n))]
mean_sd_barriers

# Reshape
barriers <- copy(barriers_pre)
barriers<- data.table(pivot_longer(barriers, cols = c(incorrect_ans_pre, incorrect_ans_post), names_to = "incorrect_ans", values_to = "num_incorrect_ans"))
barriers[,pre_or_post :=  ifelse(barriers$incorrect_ans=="incorrect_ans_pre", 0, 1)]

######################### SELF-EFFICACY QUESTIONS ################################

self_efficacy_pre <- mother_data[, c(3,4,67,68,85,86)]
self_efficacy_pre <- self_efficacy_pre[complete.cases(self_efficacy_pre)]

# Combine "not sure" with "Disagree"
self_efficacy_pre[vacc_get_info_pre == 3, vacc_get_info_pre := 2][vacc_get_info_post == 3, vacc_get_info_post := 2]
self_efficacy_pre[vacc_get_where_pre == 3, vacc_get_where_pre := 2][vacc_get_where_post == 3, vacc_get_where_post := 2]

# Total of correct answer for pre and post surveys
self_efficacy_pre$correct_ans_pre <-rowSums(self_efficacy_pre[,3:4]==1) 
self_efficacy_pre$correct_ans_post <-rowSums(self_efficacy_pre[,5:6]==1)
self_efficacy_pre$incorrect_ans_pre <-rowSums(self_efficacy_pre[,3:4]==2) 
self_efficacy_pre$incorrect_ans_post <-rowSums(self_efficacy_pre[,5:6]==2)
self_efficacy_pre$myoffset <- 2

## Mean-SD
test = unique(data.table(self_efficacy_pre)[, .(dinner_id, study_id, incorrect_ans_pre, incorrect_ans_post)])
mean_sd_self_efficacy= test[, .(pre_sum=sum(incorrect_ans_pre), post_sum=sum(incorrect_ans_post), n=.N)]
mean_sd_self_efficacy[, pre_prop := pre_sum/(n*2)][, post_prop := post_sum/(n*2)]
mean_sd_self_efficacy[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n*2))][, post_sd := sqrt((post_prop*(1-post_prop))/(n*2))]
mean_sd_self_efficacy

# Reshape
self_efficacy <- copy(self_efficacy_pre)
self_efficacy<- data.table(pivot_longer(self_efficacy, cols = c(incorrect_ans_pre, incorrect_ans_post), names_to = "incorrect_ans", values_to = "num_incorrect_ans"))
self_efficacy[,pre_or_post :=  ifelse(self_efficacy$incorrect_ans=="incorrect_ans_pre", 0, 1)]

######################### WILLINGNESS QUESTIONS ################################

willing_pre <- mother_data[, c(3,4,69,87)]
willing_pre <- willing_pre[complete.cases(willing_pre)]

#combine "You are undecided" & "Not sure" with "You do not want him / her to get the vaccine"
willing_pre[vacc_get_feel_pre %in% c(3,4), vacc_get_feel_pre := 2][vacc_get_feel_post %in% c(3,4), vacc_get_feel_post := 2]

##Create a new variable for the total of correct answer per mother for pre and post surveys
willing_pre$correct_ans_pre <-rowSums(willing_pre[,3]==1) 
willing_pre$correct_ans_post <-rowSums(willing_pre[,4]==1)

willing_pre$incorrect_ans_pre <-rowSums(willing_pre[,3]==2) 
willing_pre$incorrect_ans_post <-rowSums(willing_pre[,4]==2)
willing_pre$myoffset <- 1

## Mean-SD
test = unique(data.table(willing_pre)[, .(dinner_id, study_id, incorrect_ans_pre, incorrect_ans_post)])
mean_sd_willing=test[, .(pre_sum=sum(incorrect_ans_pre), post_sum=sum(incorrect_ans_post), n=.N)]
mean_sd_willing[, pre_prop := pre_sum/(n)][, post_prop := post_sum/(n)]
mean_sd_willing[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n))][, post_sd := sqrt((post_prop*(1-post_prop))/(n))]
mean_sd_willing

# Reshape
willing <- copy(willing_pre)
willing<- data.table(pivot_longer(willing, cols = c(incorrect_ans_pre, incorrect_ans_post), names_to = "incorrect_ans", values_to = "num_incorrect_ans"))
willing[,pre_or_post :=  ifelse(willing$incorrect_ans=="incorrect_ans_pre", 0, 1)]

######################### INTENTION QUESTIONS ################################

intention_pre <- mother_data[, c(3,4,70,71,88,89)]
intention_pre <- intention_pre[complete.cases(intention_pre)]

# combine "somewhat likely" with "very likely" / "not likely" with "not sure"
intention_pre[vacc_6mo_doctor_pre == 2, vacc_6mo_doctor_pre := 1][vacc_6mo_doctor_post == 2, vacc_6mo_doctor_post := 1]
intention_pre[vacc_6mo_doctor_pre %in% c(3,4), vacc_6mo_doctor_pre := 2][vacc_6mo_doctor_post %in% c(3,4), vacc_6mo_doctor_post := 2]

intention_pre[vacc_6m_get_pre == 2, vacc_6m_get_pre := 1][vacc_6m_get_post == 2, vacc_6m_get_post := 1]
intention_pre[vacc_6m_get_pre %in% c(3,4), vacc_6m_get_pre := 2][vacc_6m_get_post %in% c(3,4), vacc_6m_get_post := 2]

##Create a new variable for the total of correct answer per mother for pre and post surveys
intention_pre$correct_ans_pre <-rowSums(intention_pre[,3:4]==1) 
intention_pre$correct_ans_post <-rowSums(intention_pre[,5:6]==1)
intention_pre$incorrect_ans_pre <-rowSums(intention_pre[,3:4]==2) 
intention_pre$incorrect_ans_post <-rowSums(intention_pre[,5:6]==2)
intention_pre$myoffset <- 2

# Mean-SD
test = unique(data.table(intention_pre)[, .(dinner_id, study_id, incorrect_ans_pre, incorrect_ans_post)])
mean_sd_intention=test[, .(pre_sum=sum(incorrect_ans_pre), post_sum=sum(incorrect_ans_post), n=.N)]
mean_sd_intention[, pre_prop := pre_sum/(n*2)][, post_prop := post_sum/(n*2)]
mean_sd_intention[, pre_sd := sqrt((pre_prop*(1-pre_prop))/(n*2))][, post_sd := sqrt((post_prop*(1-post_prop))/(n*2))]
mean_sd_intention

# Reshape
intention <- copy(intention_pre)
intention<- data.table(pivot_longer(intention, cols = c(incorrect_ans_pre, incorrect_ans_post), names_to = "incorrect_ans", values_to = "num_incorrect_ans"))
intention[,pre_or_post :=  ifelse(intention$incorrect_ans=="incorrect_ans_pre", 0, 1)]


variables <- c("knowledge", "hpvv_knowledge", "social", "barriers", "self_efficacy" ,"willing", "intention")
for (i in variables[1:7]){
  print(paste0("Question items: ", i))
  geeglm <- gee(num_incorrect_ans ~ pre_or_post+ offset(myoffset),data= unique(get(i)),id=study_id, family = "poisson", corstr="exchangeable")
  
  print(paste0("----RR----"))
  print(exp(geeglm$coefficients)) ## Crude RR
  
  print(paste0("----95% CI----"))
  se <- summary(geeglm)$coefficients["pre_or_post","Robust S.E."]
  print(exp(coef(geeglm)["pre_or_post"] + c(-1, 1) *se* qnorm(0.975)))
  
  print(paste0("----p-value----"))
  print(2 * pnorm(abs(coef(summary(geeglm))[,5]), lower.tail = FALSE))
  print("---------------------------------------------")
}
