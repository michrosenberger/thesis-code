* -----------------------------------
* Project:      MA Thesis
* Content:      Combine health vars
* Data:         Fragile Families
* Author:       Michelle Rosenberger
* Date:         November 7, 2018
* -----------------------------------

/* This code combines and constructs the relevant health outcomes across all
waves from the Fragile Families data.

Input datasets:
- "${TEMPDATADIR}/prepareHealth.dta"

Output datasets:
- "${TEMPDATADIR}/health.dta"
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


* ----------------------------- LOAD PROGRAMS
do "${CODEDIR}/FF/programs_FF.do"


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
label define YESNO 		0 "0 No" 1 "1 Yes"
label define chLiveMo 	1 "1 Mother" 2 "Father"

label define numRegDoc 	0 "0 Never" 1 "1 1-3 times" 2 "2 4+ times"

label define regDoc		0 "No" 1 "Yes"

label values chHealth moHealth faHealth chHealthSelf health
label values chLiveMo chLiveMo
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

* ----------------------------- HEALTH 
* Youth health (parent-reported) observed each wave
foreach num of numlist 0 1 3 5 9 15 {
	gen chHealth_`num'_temp = chHealth if wave == `num'
	sum chHealth_`num'_temp
	egen chHealth_`num' = max(chHealth_`num'_temp), by(id)
}
drop *_temp



* ----------------------------- ELIGIBILITY 
* ----- ELIGIBILITY OBSERVED FOR EACH WAVE

* ----- TOTAL ELIGIBILITY




* ----------------------------- SIMULATED ELIGIBILITY
* ----- SIMULATED ELIGIBILITY OBSERVED FOR EACH WAVE

* ----- TOTAL SIMULATED ELIGIBILITY



* ----------------------------- COVERAGE
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

/* FACTOR SCORES
1. General factor score that includes all variables and the predicts factor
score at each age / wave
2. Construct a factor score for each age / wave */


* ----------------------------- RECODE VARIABLES
* RECODE such that a higher score represents better health
global RECODEVARS feverRespiratory anemia seizures foodDigestive eczemaSkin ///
diarrheaColitis headachesMigraines earInfection asthmaAttack 

foreach var in $RECODEVARS {
	gen no_`var' = . 
	replace no_`var' = 1 if `var' == 0
	replace no_`var' = 0 if `var' == 1
}

label define NOYES 0 "0 Yes" 1 "1 No"
label values no_* NOYES

foreach var in chHealth moHealth {
	gen `var'_neg = . 
	replace `var'_neg = 1 if `var' == 5
	replace `var'_neg = 2 if `var' == 4
	replace `var'_neg = 3 if `var' == 3
	replace `var'_neg = 4 if `var' == 2
	replace `var'_neg = 5 if `var' == 1
}

label define Health_neg 1 "Poor" 2 "Fair" 3 "Good" 4 "Very good" 5 "Excellent"
label values chHealth_neg moHealth_neg Health_neg



* ----------------------------- FACTOR SCORE: GENERAL HEALTH - higher score, better health
* ----- SEM
sem (GeneralHealth -> chHealth_neg no*), method(mlmv) var(GeneralHealth@1)
foreach num of numlist 1 3 5 9 15 {
	predict healthFactor_a`num' if (e(sample) == 1 & wave == `num'), latent(GeneralHealth)
}

* ----- STANDARDIZE 
foreach wave of numlist 1 3 5 9 15 {
	egen healthFactor_a`wave'_std = std(healthFactor_a`wave')
}
drop healthFactor_a1-healthFactor_a15


* ----------------------------- FACTOR SCORE: MEDICAL UTILIZATION
* NOTE: higher score, higher utilization
* NOTE: check if we have MEDICAL EXPENDITURE

* ----- SEM
sem (UtilFactor -> numDocIll medication numRegDoc emRoom), method(mlmv) var(UtilFactor@1)
foreach num of numlist 1 3 5 9 15 {
	predict medicalFactor_a`num' if (e(sample) == 1 & wave == `num'), latent(UtilFactor)
}

* ----- STANDARDIZE 
foreach wave of numlist 1 3 5 9 15 {
	egen medicalFactor_a`wave'_std = std(medicalFactor_a`wave')
}	

drop medicalFactor_a1-medicalFactor_a15


* ----------------------------- HEALTH BEHAVIOURS
* NOTE: NOT SURE IN WHICH DIRECTION
* NOTE: Check if other bmi and if for other years also
gen neverSmoke = .
gen neverDrink = .

replace neverSmoke = 1 if everSmoke == 0
replace neverSmoke = 0 if everSmoke == 1
replace neverDrink = 1 if everDrink == 0
replace neverDrink = 0 if everDrink == 1

* ----- SEM
sem (BehavFactor -> activity30 neverSmoke neverDrink bmi), method(mlmv) var(BehavFactor@1)
foreach num of numlist 15 { // 1 3 5 9
	predict behavFactor_a`num' if (e(sample) == 1 & wave == `num'), latent(BehavFactor)
}

* ----- STANDARDIZE 
foreach wave of numlist 15 { // 1 3 5 9 
	egen behavFactor_a`wave'_std = std(medicalFactor_a`wave')
}	

drop behavFactor_a15 // behavFactor_a1-


* ----------------------------- LIMITATIONS
* limit absent


* ----------------------------- MENTAL HEALTH
* depressed diagnosedDepression



* ----------------------------- FACTOR SCORE: GENERAL HEALTH - SPECIFIC FOR EACH AGE
// sem (Health -> chHealth ${RECODEVARS}) if wave == 9, method(mlmv) var(Health@1) standardized
// predict healthFactor_e9 if ( e(sample) == 1 & wave == 9 ), latent(Health)

// sem (Health -> chHealth foodDigestive eczemaSkin diarrheaColitis headachesMigraines earInfection limit) if wave == 15, method(mlmv) var(Health@1) standardized
// predict healthFactor_e15 if ( e(sample) == 1 & wave == 15 ), latent(Health)
// Add other ages

* Create binary index


* ----------------------------- SAVE
describe
save "${TEMPDATADIR}/health.dta", replace 

