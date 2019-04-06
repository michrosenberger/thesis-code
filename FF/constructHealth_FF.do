* -----------------------------------
* Project:      MA Thesis
* Content:      Combine health vars
* Data:         Fragile Families
* Author:       Michelle Rosenberger
* Date:         November 7, 2018
* -----------------------------------

/* This code combines and constructs the relevant health outcomes across all
waves from the Fragile Families data.

Input datasets (TEMPDATADIR):
prepareHealth.dta

Output datasets (TEMPDATADIR):
health.dta

TO-DO:
- CHECK if we have MEDICAL EXPENDITURE
- CHECK BMI
*/

* ---------------------------------------------------------------------------- *
* --------------------------------- PREAMBLE --------------------------------- *
* ---------------------------------------------------------------------------- *
capture log close
clear all
est clear
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

* ----------------------------- SET WORKING DIRECTORIES & GLOBAL VARS
if "`c(username)'" == "michellerosenberger"  {
    global USERPATH     "~/Development/MA"
}

global RAWDATADIR	    "${USERPATH}/data/raw/FragileFamilies"
global CLEANDATADIR  	"${USERPATH}/data/clean"
global TEMPDATADIR  	"${USERPATH}/data/temp"
global CODEDIR          "${USERPATH}/code"


* ----------------------------- LOAD DATA
use "${TEMPDATADIR}/prepareHealth.dta", clear 


* ---------------------------------------------------------------------------- *
* ---------------------------------- GENERAL --------------------------------- *
* ---------------------------------------------------------------------------- *

order idnum wave
sort idnum wave
label var chHealth 		"Child health rated by primary caregiver"
label var moHealth 		"Mother health (self-report)"
label var faHealth 		"Father health (self-report)"
label var numDocIll 	"No. of times child has been at health care professional due to illness"
label var numRegDoc 	"No. regular check-ups (by doctor, nurse) in past 12 months"
label var asthmaER 		"Emergency/urgent care treatment for asthma"
label var asthmaAttack 	"Episode of asthma or asthma attack"

label define health 	1 "1 Excellent" 2 "2 Very good" 3 "3 Good" 4 "4 Fair" 5 "5 Poor"
label define YESNO 		0 "0 No" 		1 "1 Yes"
label define moReport 	0 "Father" 		1 "1 Mother"

label define numRegDoc 	0 "0 Never" 	1 "1 1-3 times" 2 "2 4+ times"

label define regDoc		0 "No" 			1 "Yes"

label values chHealth moHealth faHealth chHealthSelf health
label values moReport moReport
label values numRegDoc numRegDoc
label values regDoc regDoc

label values everAsthma everADHD foodDigestive eczemaSkin diarrheaColitis ///
headachesMigraines earInfection stuttering breathing limit docAccInj docIll ///
medication chMediHI chPrivHI moDepresCon moDepresLib everSmoke everDrink ///
feverRespiratory anemia seizures diabetes moAnxious moDoc regDoc ///
asthmaAttack asthmaER diagnosedDepression YESNO


* ---------------------------------------------------------------------------- *
* ---------------------------- CONSTRUCT VARIABLES --------------------------- *
* ---------------------------------------------------------------------------- *

* ----------------------------- RECODE VARIABLES
* RECODE such that a higher score represents better health

* ----- CHILD & MOTHER HEALTH
recode chHealth (1 = 5) (2 = 4) (3 = 3) (4 = 2) (5 = 1), gen(chHealth_neg)
recode moHealth (1 = 5) (2 = 4) (3 = 3) (4 = 2) (5 = 1), gen(moHealth_neg)

label define healthneg 1 "1 Poor" 2 "2 Fair" 3 "3 Good" 4 "4 Very good" 5 "5 Excellent"
label values chHealth_neg moHealth_neg healthneg


* ----- CHILD HAD ...
recode feverRespiratory 	(1 = 0) (0 = 1), gen(no_feverRespiratory)
recode anemia				(1 = 0) (0 = 1), gen(no_anemia)
recode seizures 			(1 = 0) (0 = 1), gen(no_seizures)
recode foodDigestive 		(1 = 0) (0 = 1), gen(no_foodDigestive)
recode eczemaSkin 			(1 = 0) (0 = 1), gen(no_eczemaSkin)
recode diarrheaColitis 		(1 = 0) (0 = 1), gen(no_diarrheaColitis)
recode headachesMigraines	(1 = 0) (0 = 1), gen(no_headachesMigraines)
recode earInfection 		(1 = 0) (0 = 1), gen(no_earInfection)
recode asthmaAttack 		(1 = 0) (0 = 1), gen(no_asthmaAttack)

label define NOYES 0 "0 Had" 1 "1 Never"
label values no_* NOYES


* ----- HEALTH BEHAVIOURS
recode everSmoke 	(1 = 0) (0 = 1), gen(neverSmoke)
recode everDrink 	(1 = 0) (0 = 1), gen(neverDrink)


* ----------------------------- CHILD HEALTH IN EACH WAVE
gen chHealth_9_temp = chHealth if wave == 9
egen chHealth_9 = max(chHealth_9_temp), by(idnum)

gen chHealth_15_temp = chHealth if wave == 15
egen chHealth_15 = max(chHealth_15_temp), by(idnum)


* ----------------------------- MEDICAID COVERAGE
* ----- COVERAGE EACH WAVE
foreach num of numlist 0 1 3 5 9 15 {
	gen mediCov_c`num' = chMediHI if wave == `num'
	sum mediCov_c`num'
	label var mediCov_c`num' "Medicaid coverage youth (parent-reported) - Wave `num'"
}

* ----- TOTAL COVERAGE UNTIL EACH YEAR
foreach num of numlist 0 1 3 5 9 15 {
	egen mediCov_t`num' = total(chMediHI) if wave <= `num', by(id)
	sum mediCov_t`num'
	label var mediCov_t`num' "Medicaid coverage youth (parent-reported) - Total until wave `num'"
}



* ----------------------------- FACTOR SCORE
* NOTE: HIGHER SCORE REPRESENTS A BETTER OUTCOME 

* ----------------------------- FACTOR SCORE: GENERAL HEALTH (AGE 9 & 15)
* ----- SEM
* child health + had in past 12 months (no_)
sem (GeneralHealth -> chHealth_neg no*), method(mlmv) var(GeneralHealth@1)
predict healthFactor_a9 	if (e(sample) == 1 & wave == 9),	latent(GeneralHealth)
predict healthFactor_a15 	if (e(sample) == 1 & wave == 15),	latent(GeneralHealth)


* ----- STANDARDIZE
egen healthFactor_a9_std 	= std(healthFactor_a9)
egen healthFactor_a15_std 	= std(healthFactor_a15)

drop healthFactor_a9 healthFactor_a15

* ----- BINARY

* ----------------------------- FACTOR SCORE: MEDICAL UTILIZATION (AGE 9 & 15)
* ----- SEM
* medication + doc illness + doc regular + ER
sem (UtilFactor -> numDocIll medication numRegDoc emRoom), method(mlmv) var(UtilFactor@1) 
predict medicalFactor_a9 	if (e(sample) == 1 & wave == 9),	latent(UtilFactor)
predict medicalFactor_a15 	if (e(sample) == 1 & wave == 15),	latent(UtilFactor)

* ----- STANDARDIZE 
egen medicalFactor_a9_std 	= std(medicalFactor_a9)
egen medicalFactor_a15_std 	= std(medicalFactor_a15)

drop medicalFactor_a9 medicalFactor_a15

* ----- BINARY


* ----------------------------- HEALTH BEHAVIOURS (AGE 15)
* ----- SEM
sem (BehavFactor -> activityVigorous neverSmoke neverDrink bmi), method(mlmv) var(BehavFactor@1) // bmi
predict behavFactor_a15 if (e(sample) == 1 & wave == 15),	latent(BehavFactor)

* ----- STANDARDIZE 
egen behavFactor_a15_std = std(behavFactor_a15)
drop behavFactor_a15

* ----- BINARY

* ----------------------------- BMI
* BMI + indicator for overweight


* ----------------------------- LIMITATIONS (AGE 9 & 15)
* limit (AGE 15)
* absent (AGE 9 & 15)


* ----------------------------- MENTAL HEALTH (AGE 15)
* depressed diagnosedDepression




* ----------------------------- SAVE
describe
save "${TEMPDATADIR}/health.dta", replace 








* ----------------------------- NOT USED
* ----- SEM (SPECIFIC FOR EACH AGE)
// sem (Health -> chHealth_neg no*) if wave == 9, method(mlmv) var(Health@1) standardized
// predict healthFactor_e9 	if (e(sample) == 1 & wave == 9), latent(Health)

* ----- STANDARDIZE (SPECIFIC FOR EACH AGE)
// egen healthFactor_e9_std = std(healthFactor_e9)
// drop healthFactor_e9


* ----------------------------- INFO FACTOR SCORE
* A factor score variable I can leverage the correlation across the observations
/* Manual: the output will be easier to interpret if we display standardized
values for paths rather than path coefficients. A standardized value is in
standard deviation units. It is the change in one variable given a change in
another, both measured in standard deviation units. We can obtain standardized
values by specifying sem’s standardized option, which we can do when we fit
the model or when we replay results.

The standardized coefficients for this model can be interpreted as the
correlation coefficients between the indicator and the latent variable
because each indicator measures only one factor. For instance, the standardized
path coefficient a1<-Affective is 0.90, meaning the correlation between a1 and
Affective is 0.90. */




