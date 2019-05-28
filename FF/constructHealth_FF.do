* -----------------------------------
* Project:      MA Thesis
* Content:      Combine health vars
* Data:         Fragile Families
* Author:       Michelle Rosenberger
* Date:         November 7, 2018
* -----------------------------------

/* This code combines and constructs the relevant health outcomes across all
waves from the Fragile Families data.

* ----- INPUT DATASETS (TEMPDATADIR):
prepareHealth.dta

* ----- OUTPUT DATASETS (TEMPDATADIR):
health.dta
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

* ---------------------------------------------------------------------------- *
* ---------------------------------- GENERAL --------------------------------- *
* ---------------------------------------------------------------------------- *
* ----------------------------- LOAD DATA
use "${TEMPDATADIR}/prepareHealth.dta", clear 

order idnum wave
sort idnum wave

* ----------------------------- VALUE LABELS
label define health 	1 "1 Excellent" 2 "2 Very good" 3 "3 Good" 4 "4 Fair" 5 "5 Poor"
label define YESNO 		0 "0 No" 		1 "1 Yes"
label define numRegDoc 	0 "0 Never" 	1 "1 1-3 times" 2 "2 4+ times"
label define regDoc		0 "No" 			1 "Yes"

label values chHealth moHealth faHealth chHealthSelf health
label values numRegDoc numRegDoc
label values regDoc regDoc
label values everAsthma everADHD foodDigestive eczemaSkin diarrheaColitis ///
headachesMigraines earInfection stuttering breathing limit docAccInj docIll ///
medication chMediHI chPrivHI everSmoke everDrink feverRespiratory anemia ///
seizures diabetes regDoc asthmaAttack asthmaER diagnosedDepression YESNO

* ---------------------------------------------------------------------------- *
* ---------------------------- CONSTRUCT VARIABLES --------------------------- *
* ---------------------------------------------------------------------------- *
* ----------------------------- RECODE VARIABLES
* RECODE such that a higher score represents better health

* ----- CHILD & MOTHER HEALTH
recode chHealth (1 = 5) (2 = 4) (3 = 3) (4 = 2) (5 = 1), gen(chHealth_neg)
* recode moHealth (1 = 5) (2 = 4) (3 = 3) (4 = 2) (5 = 1), gen(moHealth_neg)

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

* ----- HEALTH BEHAVIOURS
recode everSmoke 			(1 = 0) (0 = 1), gen(neverSmoke)
recode everDrink 			(1 = 0) (0 = 1), gen(neverDrink)

* ----- LABELS
label define healthneg 	1 "1 Poor" 	2 "2 Fair" 3 "3 Good" 4 "4 Very good" 5 "5 Excellent"
label define NOYES 		0 "0 Had" 	1 "1 Never"
label values chHealth_neg healthneg // moHealth_neg
label values no_* NOYES
label values neverDrink neverSmoke YESNO


* ----------------------------- FACTOR SCORE
* NOTE: HIGHER SCORE REPRESENTS A BETTER OUTCOME 

* ----------------------------- FACTOR SCORE: GENERAL HEALTH (AGE 9 & 15)
* ----- SEM
* CHILD HEALTH, CHILD HAD IN PAST ...
sem (GeneralHealth -> chHealth_neg no*), method(mlmv) var(GeneralHealth@1)

foreach wave in 9 15 {
	* ----- PREDICT AND STANDARDIZE HEALTH FACTOR
	predict healthFactor_`wave'_temp if (e(sample) == 1 & wave == `wave'), latent(GeneralHealth)
	egen healthFactor_`wave' 	= std(healthFactor_`wave'_temp)
	drop healthFactor_`wave'_temp
}


* ----------------------------- FACTOR SCORE: MEDICAL UTILIZATION (AGE 9 & 15)
* ----- SEM
* MEDICATION, DOC ILLNESS, DOC REGULAR, ER
sem (UtilFactor -> numDocIll medication numRegDoc emRoom), method(mlmv) var(UtilFactor@1) 

foreach wave in 9 15 {
	* ----- PREDICT AND STANDARDIZE UTILIZATION FACTOR
	predict medicalFactor_`wave'_temp if (e(sample) == 1 & wave == `wave'), latent(UtilFactor)
	egen medicalFactor_`wave' 	= std(medicalFactor_`wave'_temp)
	drop medicalFactor_`wave'_temp
}


* ----------------------------- FACTOR SCORE: HEALTH BEHAVIOURS (AGE 15)
* ----- SEM
sem (BehavFactor -> activityVigorous neverSmoke neverDrink bmi), method(mlmv) var(BehavFactor@1)

* ----- PREDICT AND STANDARDIZE UTILIZATION FACTOR
predict behavFactor_15_temp if (e(sample) == 1 & wave == 15), latent(BehavFactor)
egen behavFactor_15 = std(behavFactor_15_temp)
drop behavFactor_15_temp


* ----------------------------- LIMITATIONS (AGE 9 & 15)
* ----- ABSENT (AGE 9 & 15)
label define absent9 	0 "0 Never" 	1 "1 Once or twice this year" ///
						2 "2 More then twice but less than 10 times" ///
						3 "3 About once a month" 4 "4 A few times a month or more"

gen absent = .
replace absent = 0 if absent_15 == 0 						& wave == 15
replace absent = 1 if (absent_15 == 1 | absent_15 == 2)		& wave == 15
replace absent = 2 if (absent_15 > 2 & absent_15 < 10) 		& wave == 15
replace absent = 3 if (absent_15 >= 10 & absent_15 < 13)	& wave == 15
replace absent = 4 if absent_15 >= 13 						& wave == 15
replace absent = absent_9 if wave == 9

label values absent absent_9 absent9

* ----- LIMIT (AGE 15)
tab limit if wave == 15


* ----------------------------- MENTAL HEALTH (AGE 15)
* ----- FEEL DEPRESSED (SELF-REPORT)
tab depressed

* RECODE: HIGHER MORE DEPRESSED
recode depressed (1 = 4) (2 = 3) (3 = 2) (4 = 1), gen(depressed_neg)
label define depressed	1 "1 Strongly disagree" 2 "2 Somewhat disagree" ///
						3 "3 Somewhat agree"	4 "4 Stronlgy agree"
label values depressed_neg depressed

* ----- EVER DIAGNOSED WITH DEPRESSION/ANXIETY
tab diagnosedDepression



* ----------------------------- FORMAT & SAVE
* ----- LABELS
label var idnum 				"Family ID"
label var wave 					"Wave"
label var chHealth 				"Child health (1 highest)"
label var chHealth_neg			"Child health (5 highest)"
label var everAsthma			"Ever diagnosed with asthma"
label var diagnosedDepression	"Ever diagnosed with depression/anxiety"
label var everADHD				"Ever diagnosed with ADD/ADHD"
label var foodDigestive			"Had food/digestive allergy past year"
label var eczemaSkin			"Had eczema/skin allergy past year"
label var diarrheaColitis		"Had frequent diarrhea/colitis past year"
label var headachesMigraines	"Had frequent headaches/migraines past year"
label var earInfection			"Had ear infection past year"
label var stuttering			"Had stuttering or stammering problem past year"
label var breathing				"Had trouble breathing/chest problem past year"
label var limit 				"Limitations in usual activities due to health problems"
label var absent 				"Days absent from school due to health past year"
label var docAccInj				"Saw doctor for accident or injury past year"
label var docIll				"Saw doctor for an illness past year"
label var regDoc				"Saw doctor for regular check-up past year"
label var medication 			"Takes doctor prescribed medication"
label var chMediHI				"Covered by Medicaid/public insurance plan"
label var chPrivHI				"Covered by private insurance plan"
label var moHealth				"Mother health (self-reported)"
label var depressed_neg			"Feel depressed (self-reported)"
label var chHealthSelf			"Description health (self-reported)"
label var absentSelf			"Days absent from school due to health past year (self-reported)"
label var activity60			"Days physically active for 60+ min (past week)"
label var activity30			"Days physical activity for 30+ min (typical week)"
label var activityVigorous		"Days vigorous physical activity (typical week)"
label var everSmoke				"Ever smoked entire cigarette"
label var ageSmoke				"Age when first smoked a whole cigarette (years)"
label var monthSmoke			"Num times smoked cigarettes (past month)"
label var cigsSmoke				"Num cigarettes/day (past month)"
label var everDrink				"Ever drank alcohol 2+ times without parents"
label var ageDrink				"Age first drank alcohol"
label var monthTimesDrink		"Num times drank alcohol (past month)"
label var monthManyDrink		"Num alcoholic drinks had each time (past month)"
label var yearTimesDrink		"Num times drank alcohol (past year)"
label var yearManyDrink			"Num alcoholic drinks had each time (past year)"
label var bmi					"Constructed - Youth's Body Mass Index (BMI)"
label var faHealth 				"Father health (self-reported)"
label var feverRespiratory		"Had hay fever or respiratory allergy past year"
label var anemia				"Had anemia (past year)"
label var seizures				"Had seizures (past year)"
label var diabetes				"Had diabetes (past year)"
label var numRegDoc				"Num regular check-ups by doctor, nurse (past year)"
label var numDoc 				"Num times saw doctor/nurse due to illness, accident, injury"
label var emRoom				"Num times taken to emergency room (past year)"
label var numDocAccInj			"Num visit doctor due to accident/injury"
label var emRoomAccInj			"Num visit emRoom due tio accident/injury"
label var asthmaAttack			"Episode of asthma or asthma attack"
label var asthmaER				"Emergency/urgent care treatment for asthma"
label var asthmaERnum			"Num visits urget care center/ER due to asthma (past year)"
label var numDocIll				"Num visits health care professional due to illness"
label var numDocIllInj			"Num visits health care professional due to illness/injury"
label var numDocInj				"Num visits health care professional for injury (since birth)"

label var healthFactor_9		"General health factor (age 9)"
label var healthFactor_15		"General health factor (age 15)"
label var medicalFactor_9		"Medical utilization factor (age 9)"
label var medicalFactor_15		"Medical utilization factor (age 15)"
label var behavFactor_15		"Behav factor (age 15)"



* ----- SAVE
drop moReport
describe
save "${TEMPDATADIR}/health.dta", replace 



* ---------------------------------------------------------------------------- *
* ---------------------------------- NOT USED -------------------------------- *
* ---------------------------------------------------------------------------- *
// * ----------------------------- MEDICAID COVERAGE
// * ----- COVERAGE EACH WAVE
// foreach num of numlist 0 1 3 5 9 15 {
// 	gen mediCov_c`num' = chMediHI if wave == `num'
// 	sum mediCov_c`num'
// 	label var mediCov_c`num' "Medicaid coverage youth (parent-reported) - Wave `num'"
// }

// * ----- TOTAL COVERAGE UNTIL EACH YEAR
// foreach num of numlist 0 1 3 5 9 15 {
// 	egen mediCov_t`num' = total(chMediHI) if wave <= `num', by(id)
// 	sum mediCov_t`num'
// 	label var mediCov_t`num' "Medicaid coverage youth (parent-reported) - Total until wave `num'"
// }


