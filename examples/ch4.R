library(MedicalRiskPredictionModels)
prepareExamples()

# Chunk1
oc$survtime.5years <- pmin(oc$survtime,60) # stop time after 5 years
oc$survstatus.5years <- oc$survstatus # take a copy 
oc[oc$survtime>60,]$survstatus.5years <- 0 # reset status
oc[,c("survtime","survstatus","survtime.5years","survstatus.5years")]

# Chunk2
# logistic regression in learn data
nullmodel <- glm(ohss~1,data=ivftrain,family="binomial") 
# predicted risk in test data
ivftest$risk.null <- predictRisk(nullmodel,newdata=ivftest)
# result does not depend on predictor variables
ivftest[1:5,c("cyclelen","bmi","age","smoking","ant.foll","risk.null")]

# Chunk3
library(riskRegression)
# Kaplan-Meier estimate in training set
km <- prodlim(Hist(survtime,survstatus)~1,data=octrain)
# Predicted risk at 5 and 10 years in test set
octest$km.risk5 <- round(100*predictRisk(km,newdata=octest,times=60),1)
octest$km.risk10 <- round(100*predictRisk(km,newdata=octest,times=120),1)
# Predicted risks do not depend on predictor variables
octest[1:5,c("age","gender","tobacco","tumorthickness","km.risk5","km.risk10")]

# Chunk4
library(riskRegression)
# Aalen-Johansen estimate in training set
aj <- prodlim(Hist(asprogtime,asprog)~1,data=astrain)
# Predict the risks at 3 year horizon in the test set
astest$aj.progrisk3 <- round(100*predictRisk(aj,newdata=astest,times=3,cause="progression"),1)
astest$aj.deathrisk3 <- round(100*predictRisk(aj,newdata=astest,times=3,cause="death"),1)
# Predicted risks do not depend on predictor variables
astest[1:5,c("age5","psa","ct1","diaggs","aj.progrisk3","aj.deathrisk3")]

# Chunk5
fit <- glm(ohss~smoking,data=ivftrain,family="binomial")
publish(fit,intercept=1)

# Chunk6
library(data.table)
fit <- glm(ohss~smoking,data=ivftrain,family="binomial")
nd <- data.table(smoking=c("No","Yes"))
nd$risk.ohss <- predictRisk(fit,newdata=nd)
nd

# Chunk7
fit <- coxph(Surv(survtime, survstatus)~grade+gender,
             data=octrain,x=TRUE)
publish(fit)

# Chunk8
fit <- coxph(Surv(survtime, survstatus)~grade+gender,
             data=octrain,x=1)
nd <- data.table(expand.grid(grade=c("Well","Moderate","Poor"),gender=c("Male","Female")))
nd$risk.10years <- round(100*predictRisk(fit,times=120,newdata=nd),1)
nd

# Chunk9
fit <- CSC(Hist(asprogtime,asprog)~diaggs+ct1,data=astrain)
publish(fit,diaggs="Gleason score",ct1="Clinical stage")

# Chunk10
fit <- FGR(Hist(asprogtime,asprog)~diaggs+ct1,data=astrain,
           cause="progression")
publish(fit)

# Chunk11
ivftrain$age5 <- ivftrain$age/5 # odds ratio per 5 year increase of age
fit <- glm(ohss~age5,data=ivftrain,family="binomial")

# Chunk12
library(rms)
fit <- lrm(ohss~rcs(age),data=ivftrain)

# Chunk13
fit <-
coxph(Surv(survtime,survstatus)~tumorthickness,data=octrain,
      y=TRUE,x=TRUE)

# Chunk14
library(rms)
# fit Cox regression models
fit1=cph(Surv(survtime,survstatus)~tumorthickness,
         data=octrain,x=1,y=1)
# lsp means linear spline
fit2=cph(Surv(survtime,survstatus)~lsp(tumorthickness,c(.5,1,3)),
         data=octrain,x=1,y=1)
# rcs means restricted cubic spline
fit3=cph(Surv(survtime,survstatus)~rcs(tumorthickness,3),
         data=octrain,x=1,y=1)
# select tumor thickness values for which to predict
nd=data.frame(tumorthickness=c(0.1,.5,.75,seq(1,8,1)))
# extract 10 year predicted risks from Cox regression
R1=predictRisk(fit1, newdata=nd,times=120)
R2=predictRisk(fit2, newdata=nd,times=120)
R3=predictRisk(fit3, newdata=nd,times=120)
# put results in a table
nd$"10-year risk linear" <- 100*R1
nd$"10-year risk linear spline" <- 100*R2
nd$"10-year risk cubic spline" <- 100*R3
publish(nd,digits=1)

# Chunk15
fit1 <- CSC(Hist(asprogtime,asprog)~psa+ct1+diaggs,data=astrain,cause="progression")
fit2 <- CSC(Hist(asprogtime,asprog)~psa*ct1+diaggs,data=astrain,cause="progression")
# select 12 examples
nd=expand.grid(diaggs=c("GNA","3 and 3","3 and 4"),
               ct1=c("cT1","cT2"),
               psa=c(-3,-1))
# predict 3-year risk of progression
R1 <- 100*predictRisk(fit1,newdata=nd,cause="progression",times=3)
R2 <- 100*predictRisk(fit2,newdata=nd,cause="progression",times=3)
cbind(nd,"No interaction term"=R1,"With interaction term"=R2)

# Chunk16
fit1 <- glm(ohss~ant.foll+smoking+age,data=ivftrain,family="binomial")
fit2 <- glm(ohss~ant.foll*smoking+age,data=ivftrain,family="binomial")
# select 6 examples
nd <- expand.grid(ant.foll=c(10,30,50),
                  age=c(30),
                  smoking=factor(c("Yes","No")))
R1 <- 100*predictRisk(fit1,newdata=nd)
R2 <- 100*predictRisk(fit2,newdata=nd)
cbind(nd,"Without interaction term"=R1,"With interaction term"=R2)

# Chunk17
library(rms)
fit1 <- lrm(ohss~rcs(ant.foll,3)+rcs(age,3)+rcs(cyclelen,3)+smoking,data=ivftrain)
fit2 <- lrm(ohss~rcs(ant.foll,3)+rcs(age,3)+rcs(cyclelen,3)+smoking,data=ivftrain,penalty=5)
fit3 <- lrm(ohss~rcs(ant.foll,3)+rcs(age,3)+rcs(cyclelen,3)+smoking,data=ivftrain,penalty=10)
# select 5 covariate patterns
nd=expand.grid(ant.foll=c(10,20),
               age=28,
               cyclelen=c(27,32),
               smoking="No")
# predict risks
R1=100*predictRisk(fit1,nd)
R2=100*predictRisk(fit2,nd)
R3=100*predictRisk(fit3,nd)
cbind(nd,"no penalty"=R1,"penalty 5"=R2,"penalty 10"=R3)

# Chunk18
fit <- coxph(Surv(survtime,survstatus)~tumorthickness + age + gender * race * tobacco * site
            ,data=octrain,y=1,x=1)

# Chunk19
tab1 <- summary(utable(gender~age+deep.invasion+tobacco+tumorthickness+grade,data=octrain,
                       summary.format="median(x) (IQR(x)) [range(x)]"),show.pvalue=0)
tab1

# Chunk20
ivf$set <- factor(ivf$train,levels=c(TRUE,FALSE),
                 labels=c("Training","Validation"))
tab1 <- summary(utable(set~Q(age)+cyclelen+Q(bmi)+fsh+ant.foll+smoking,data=ivf),
                show.pvalues=0)
tab1

# Chunk21
tab2 <- followupTable(Hist(asprogtime,asprog)~age+ct1+erg.status,data=as,followup.time=5)
tab2

# Chunk22
fit <- coxph(Surv(survtime,survstatus)~age+gender+tumorthickness+grade,data=octrain)
publish(fit,probindex=TRUE)

# Chunk23
fit <- ARR(Hist(asprogtime, asprog)~ct1+erg.status+age5+psa+ppb5+lmax,
           data=astrain, times=5, cause="progression")
publish(fit)

# Chunk24 
uu <- datadist(ivf)
options(datadist="uu")
fit <- lrm(ohss~age+rcs(ant.foll)+smoking,data=ivf)
plot(nomogram(fit,fun=function(x)1/(1+exp(-x)),  # or fun=plogis
              funlabel=paste0("Risk of OHSS")))

# Chunk25 
u <- datadist(octrain)
options(datadist="u")
fit <- cph(Surv(survtime,survstatus)~age*grade+gender+rcs(tumorthickness),
           data=octrain,
           surv=1)
surv <- Survival(fit)
nom <- nomogram(fit, fun=list(function(x) 1-surv(60, x),
                              function(x) 1-surv(120, x)),
                funlabel=c("5-year risk", 
                           "10-year risk"))
plot(nom, xfrac=.5)
