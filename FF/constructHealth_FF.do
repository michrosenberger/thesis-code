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
label define moReport 	0 "Father" 		1 "1 Mother"
label define numRegDoc 	0 "0 Never" 	1 "1 1-3 times" 2 "2 4+ times"
label define regDoc		0 "No" 			1 "Yes"

label values chHealth moHealth faHealth chHealthSelf health
label values moReport moReport
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
foreach wave in 9 15 {
	gen chHealth_`wave'_temp = chHealth if wave == `wave'
	egen chHealth_`wave' = max(chHealth_`wave'_temp), by(idnum)
	drop chHealth_`wave'_temp
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



* ----------------------------- FORMAT & SAVE
* ----- LABELS
* NOTE: make file with all labels
label var idnum 				"Family ID"
label var wave 					"Wave"
label var chHealth 				"Child health (PCG report)"
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
label var depressed				"Feel depressed (self-reported)"
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
label var moReport				"Mother report used"
label var numDocAccInj			"Num visit doctor due to accident/injury"
label var emRoomAccInj			"Num visit emRoom due tio accident/injury"
label var asthmaAttack			"Episode of asthma or asthma attack"
label var asthmaER				"Emergency/urgent care treatment for asthma"
label var asthmaERnum			"Num visits urget care center/ER due to asthma (past year)"
label var numDocIll				"Num visits health care professional due to illness"
label var numDocIllInj			"Num visits health care professional due to illness/injury"
label var numDocInj				"Num visits health care professional for injury (since birth)"

label var chHealth_9			"Child health at age 9"
label var chHealth_15			"Child health at age 15"

// no_* never*
// *_std


* ----- SAVE
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


