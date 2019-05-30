* -----------------------------------
* Project:      MA Thesis
* Content:      Extract health vars
* Data:         Fragile Families
* Author:       Michelle Rosenberger
* Date:         November 7, 2018
* -----------------------------------

/* This code extracts all the necessary health variables from the Fragile
Families data for all the waves.

* ----- INPUT DATASETS (RAWDATADIR):
ffmombspv3.dta; ffdadbspv3.dta; ffmom1ypv2.dta; ffdad1ypv2.dta; ffmom3ypv2.dta;
ffdad3ypv2.dta; InHome3yr.dta; 	ffmom5ypv1.dta; ffdad5ypv1.dta; inhome5yr2011.dta;
ff_y9_pub1.dta; FF_Y15_pub.dta

* ----- OUTPUT DATASETS (TEMPDATADIR):
prepareHealth.dta
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

* ----------------------------- NOTE
* If moReport == 0 the father report is used
* If moReport != 0 the mother report is used

* ---------------------------------------------------------------------------- *
* --------------------------------- BASELINE --------------------------------- *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/00_Baseline/ffmombspv3.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/00_Baseline/ffdadbspv3.dta", nogen
keep idnum m1g1 f1g1 m1a15

* ----- RECODE MISSING VALUES
P_missingvalues

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y0.dta", nogen keepus(moReport wave)

* ----------------------------- HEALTH & MEDICAID (CORE REPORT)
* ----- HEALTH PARENTS 	(SELF-REPORTED)
rename 	m1g1 moHealth
rename 	f1g1 faHealth

* ----- HEALTH YOUTH 	(PARENT REPORTED)
gen 	chHealth = .

* ----- MEDICAID CHILD 	(PARENT REPORTED)
gen 	chMediHI = 0
replace chMediHI = 1 if m1a15 == 1 | m1a15 == 101

* ----------------------------- SAVE
keep idnum *Health wave chMediHI
save "${TEMPDATADIR}/prepareHealth.dta", replace 

* ---------------------------------------------------------------------------- *
* ---------------------------------- WAVE 1 ---------------------------------- *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/01_One-Year Core/ffmom1ypv2.dta", clear				// Core
merge 1:1 idnum using "${RAWDATADIR}/01_One-Year Core/ffdad1ypv2.dta"	// Core

keep idnum m2b2 f2b2 m2j1 f2j1 m2j3 m2j3a m2j4 m2j4a f2j3 f2j3a f2j4 f2j4a ///
m2b11 f2b11 m2b11a f2b11a m2b11b m2b6 m2b7 mx2b7 m2b7a m2b8 m2b8a cm2gad_case ///
cm2md_case_con cm2md_case_lib f2b11b f2b6 f2b7 fx2b7 f2b7a f2b7a f2b8 f2b8a

* ----- RECODE MISSING VALUES
P_missingvalues

* ----- EQUALIZE
recode m2b11 f2b11 m2b11a f2b11a m2b11b f2b11b (2 = 0)

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y1.dta", nogen keepus(moReport wave)

* ----------------------------- HEALTH & MEDICAID (CORE REPORT)
* ----- HEALTH PARENTS	(SELF-REPORTED)
rename 	m2j1 moHealth
rename 	f2j1 faHealth

* ----- HEALTH YOUTH	(PARENT REPORTED)	chHealth
P_childHealth m2b2 f2b2

* ----- MEDICAID CHILD 	(PARENT REPORTED)	chMediHI chPrivHI
P_medicaid 2j3 2j3a 2j4 2j4a

* ----- EPISODE ASTHMA
* Since birth, has child had an episode of asthma or an asthma attack?
gen asthmaAttack = .
replace asthmaAttack = m2b11a if moReport != 0
replace asthmaAttack = f2b11a if moReport == 0

* ----------------------------- DOCTOR VARS (CORE REPORT)
* ----- WELL VISIT DOCTOR (RANGE)
rename m2b6 monumRegDoc
rename f2b6 fanumRegDoc

* ----- ILLNESS DOCTOR (NUM)
rename m2b7 monumDocIll
rename f2b7 fanumDocIll

* ----- ILLNESS / INJURY DOCTOR (NUM)
rename mx2b7 monumDocIllInj
rename fx2b7 fanumDocIllInj

* ----- INJURY DOCTOR (NUM)
rename m2b7a monumDocInj
rename f2b7a fanumDocInj

* ----- ER TOTAL (NUM)
rename m2b8 moemRoom
rename f2b8 faemRoom
				
* ----- ER ACCIDENT / INJURY (NUM)
rename m2b8a moemRoomAccInj
rename f2b8a faemRoomAccInj

	* ----- WHICH REPORT
	foreach var in numRegDoc numDocIll numDocIllInj numDocInj emRoom emRoomAccInj {
		gen `var' = . 
		replace `var' = mo`var' if moReport != 0
		replace `var' = fa`var' if moReport == 0
	}
	drop mo* fa*

* ----- BINARY WELL VISIST DOCTOR (FROM numRegDoc)
gen regDoc = .
replace regDoc = 1 if ( numRegDoc == 1 | numRegDoc == 2 )
replace regDoc = 0 if ( numRegDoc == 0 )

* ----- BINARY ILLNESS DOCTOR (FROM numDocIll)
gen docIll = .
replace docIll = 0 if numDocIll == 0
replace docIll = 1 if (numDocIll >= 1 & numDocIll <= 90)

* ----- LABELS
label var numDocIllInj 	"Num times child has been seen by health care prof. b/c illness/injury?"
label var numDocInj 	"Num times has child been to health care prfssnal for injury since birth?"

* ----------------------------- SAVE
keep idnum wave *Health ch* num* em* asthma* regDoc docIll
append using "${TEMPDATADIR}/prepareHealth.dta"
save "${TEMPDATADIR}/prepareHealth.dta", replace 


* ---------------------------------------------------------------------------- *
* ---------------------------------- WAVE 3 ---------------------------------- *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/02_Three-Year Core/ffmom3ypv2.dta", clear						// Core
merge 1:1 idnum using "${RAWDATADIR}/02_Three-Year Core/ffdad3ypv2.dta", nogen		// Core
merge 1:1 idnum using "${RAWDATADIR}/02_Three-Year In-Home/InHome3yr.dta", nogen	// In-home

keep idnum m3b2 f3b2 m3j1 f3j1 m3j3 m3j3a m3j4 m3j4a f3j3 f3j3a f3j4 f3j4a ///
int5 int5_oth a1 a2 a3_1 a3_2 a3_3 a3_4 a3_5 a3_6 a3_7 a4 a5 a5a a5a_oth a7 ///
a8 a9 a10 a15 a17 a18 a19 a19_ cm3alc_case cm3drug_case cm3gad_case ///
cm3md_case_con cm3md_case_lib

* ----- RECODE MISSING VALUES
P_missingvalues

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y3.dta", nogen keepus(moReport wave)

* ---------------------- HEALTH & MEDICAID (CORE REPORT) --------------------- *
* ----- HEALTH PARENTS 	(SELF-REPORTED)
rename m3j1 moHealth
rename f3j1 faHealth

* ----- HEALTH YOUTH 	(PARENT REPORTED)
P_childHealth m3b2 f3b2

* ----- MEDICAID CHILD 	(PARENT REPORTED)
P_medicaid 3j3 3j3a 3j4 3j4a

* ----------------------------- ASTHMA (IN-HOME) ----------------------------- *
* ----- EPISODE ASTHMA (BINARY)
rename a18 asthmaAttack

* -------------------------- DOCTOR VARS (IN-HOME) --------------------------- *
* ----- REGULAR CHECK-UP (RANGE)
rename a4 	numRegDoc

	* ----- BINARY REGULAR CHECK-UP (FROM numRegDoc)
	gen regDoc = .
	replace regDoc = 1 if ( numRegDoc == 1 | numRegDoc == 2 )
	replace regDoc = 0 if ( numRegDoc == 0 )

* ----- ILLNESS/ACCIDENT/INJ DOCTOR (NUM)
rename a7 	numDoc

* ----- ACCIDENT/INJURY DOCTOR (NUM)
rename a8 	numDocAccInj
	
	* ----- BINARY INJURY DOCTOR (FROM numDocAccInj)
	gen docAccInj = .
	replace docAccInj = 0 if ( numDocAccInj == 0 )
	replace docAccInj = 1 if ( numDocAccInj >= 1 & numDocAccInj <= 8 )

	* ----- ILLNESS DOCTOR (NUM) 
	gen numDocIll = numDoc - numDocAccInj

	* ----- BINARY ILLNESS DOCTOR (FROM numDocIll)
	gen docIll = .
	replace docIll = 0 if ( numDocIll == 0 )
	replace docIll = 1 if ( numDocIll >= 1 & numDocIll <= 72 )

* ----- ER TOTAL (NUM)
rename a9 	emRoom

* ----- ER ACCIDENT / INJURY (NUM)
rename a10 	emRoomAccInj


* ----------------------------- SAVE
keep idnum *Health wave ch* num* em* asthma* regDoc docAccInj numDocIll docIll mo*

append using "${TEMPDATADIR}/prepareHealth.dta"
save "${TEMPDATADIR}/prepareHealth.dta", replace 


* ---------------------------------------------------------------------------- *
* ---------------------------------- WAVE 5 ---------------------------------- *
* ---------------------------------------------------------------------------- *

use "${RAWDATADIR}/03_Five-Year Core/ffmom5ypv1.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/03_Five-Year Core/ffdad5ypv1.dta", nogen
merge 1:1 idnum using "${RAWDATADIR}/03_Five-Year In-Home/Inhome5yr2011_stata/inhome5yr2011.dta", nogen

keep idnum m4b2 f4b2 m4j1 f4j1 m4j3 m4j3a m4j4 m4j4a f4j3 f4j3a f4j4 f4j4a ///
m4b2a f4b2a m4b2b f4b2b m4b2c f4b2c a6 a12 a13 a14 a15 cm4md_case_con ///
cm4md_case_lib int5 int_5ot a1 a2_a a2_b a2_c a2_d a2_e a2_f a2_g a2_h a2_i ///
a2_j a2_k a2_l a2_m a2_n a3_a a3_b a3_c a3_d a3_e a3_f a3_g a3_h a3_i

* ----- RECODE MISSING VALUES
P_missingvalues

* ----- EQUALIZE
recode m4b2a f4b2a m4b2b f4b2b m4b2c f4b2c (2 = 0)

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y5.dta", nogen keepus(moReport wave)

* ---------------------- HEALTH & MEDICAID (CORE REPORT) --------------------- *
* ----- HEALTH PARENTS	(SELF-REPORTED)
rename m4j1 moHealth
rename f4j1 faHealth

* ----- HEALTH & MEDICAID CHILD	(PARENT REPORTED)
P_childHealth	m4b2 f4b2				// chHealth
P_medicaid 		4j3 4j3a 4j4 4j4a		// chMediHI chPrivHI

* --------------------------- ASTHMA (CORE REPORT) --------------------------- *
* ----- EPISODE ASTHMA
gen asthmaAttack = .
replace asthmaAttack = m4b2b if moReport != 0
replace asthmaAttack = f4b2b if moReport == 0

* ------------------------ DOCTOR VARS (CORE REPORT) ------------------------- *
* ----- REGULAR CHECK-UP (RANGE)
rename a6 numRegDoc
recode numRegDoc 1=0 2=1 3=2	// make comparable across waves

	* ----- BINARY REGULAR CHECK-UP (FROM numRegDoc)
	gen regDoc = .
	replace regDoc = 1 if ( numRegDoc == 1 | numRegDoc == 2 )
	replace regDoc = 0 if ( numRegDoc == 0 )

* ----- DOCTOR ILLNESS/ACC/INJ (NUM)
rename a12 numDoc

* ----- DOCTOR ACCIDENT/INJ (NUM)
rename a13 numDocAccInj

	* ----- ILLNESS DOCTOR (NUM) 
	gen numDocIll = numDoc - numDocAccInj
	replace numDocIll = 0 if numDocIll < 0

	* ----- BINARY ILLNESS DOCTOR (FROM numDocIll)
	gen docIll = .
	replace docIll = 0 if ( numDocIll == 0 )
	replace docIll = 1 if ( numDocIll >= 1 & numDocIll <= 72 )

	* ----- DOC ACCIDENT/INJ (FROM numDocAccInj)
	gen docAccInj = . 
	replace docAccInj = 0 if ( numDocAccInj == 0 )
	replace docAccInj = 1 if ( numDocAccInj >= 1 & numDocAccInj <= 25 )

* ----- ER TOTAL (NUM)
rename a14 emRoom

* ----- ER ACCIDENT/INJ (NUM)
rename a15 emRoomAccInj

* ----------------------- PAST 12 MONTHS HAD (IN-HOME) ----------------------- *
* NOTE: All are binary
rename a3_a feverRespiratory
rename a3_b foodDigestive
rename a3_c eczemaSkin
rename a3_d diarrheaColitis
rename a3_e anemia
rename a3_f headachesMigraines
rename a3_g earInfection		// 3 or 3+
rename a3_h seizures

* ----------------------------- SAVE
keep idnum *Health wave ch* num* em* feverRespiratory foodDigestive ///
eczemaSkin diarrheaColitis anemia headachesMigraines earInfection seizures ///
asthma* regDoc docAccInj mo* numDocIll docIll

append using "${TEMPDATADIR}/prepareHealth.dta"
save "${TEMPDATADIR}/prepareHealth.dta", replace 


* ---------------------------------------------------------------------------- *
* ---------------------------------- WAVE 9 ---------------------------------- *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/04_Nine-Year Core/ff_y9_pub1.dta", clear		// ALL

keep idnum p5h1 m5g1 f5g1 p5h13 p5h14 p5h3* p5l11 p5h6 p5h7 p5h9 k5h1 p5h1b ///
p5h10 p5h2a hv5_12 hv5_13 p5h3a1 cm5md_case_con cm5md_case_lib p5h7

* ----- RECODE MISSING VALUES
P_missingvalues

* ----- EQUALIZE
recode p5h13 p5h1b p5h3a p5h3b p5h3c p5h3d p5h3e p5h3f p5h3g p5h3h p5h3i p5h3j ///
p5h2a p5h3a1 p5h7 (2 = 0)

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y9.dta", nogen keepus(moReport wave)

* ---------------------- HEALTH & MEDICAID (CORE REPORT) --------------------- *
* ----- HEALTH PARENTS 	(SELF-REPORTED)
rename m5g1 moHealth
rename f5g1 faHealth

* ----- HEALTH YOUTH 	(PARENT REPORTED)
rename p5h1 chHealth

* ----- HEALTH YOUTH	(SELF-REPORTED)
rename k5h1 chHealthSelf

* ----- MEDICAID CHILD	(PARENT REPORTED) 
rename p5h13 chMediHI 	// child covered by Medicaid 
rename p5h14 chPrivHI	// child covered by private HI

* ------------------------- DOCTOR VARS (CORE REPORT) ------------------------ *
* ----- REGULAR CHECK-UP (RANGE)
rename p5h6 numRegDoc
recode numRegDoc (1 = 0) (2 = 1) (3 = 2)	// make comparable across waves

	* BINARY numRegDoc
	gen regDoc = .
	replace regDoc = 1 if ( numRegDoc == 1 | numRegDoc == 2 )
	replace regDoc = 0 if ( numRegDoc == 0 )

* ----- DOCTOR ILLNESS/ACC/INJ (NUM)
rename p5h9 numDoc

* ----- ER TOTAL (NUM)
rename p5h10 emRoom	

* ----- USUAL PLACE FOR ROUTINE HEALTH CARE
rename p5h7 access

* --------------------- PAST 12 MONTHS HAD (CORE REPORT) --------------------- *
rename p5h3a feverRespiratory
rename p5h3b foodDigestive
rename p5h3c eczemaSkin
rename p5h3d diarrheaColitis
rename p5h3e anemia
rename p5h3f headachesMigraines
rename p5h3g earInfection			// 3 or 3+
rename p5h3h seizures

* ---------------------- TAKES MEDICATION (CORE REPORT) ---------------------- *
* ----- MEDICINE IF PRESCRIPTION (BINARY)
rename p5h3a1 medication

* ----------------------- SCHOOL ABSENT (CORE REPORT) ------------------------ *
* ----- ABSENT SCHOOL (RANGE)
rename p5l11 absent_9

* ----------------------------- SAVE
keep idnum *Health wave ch* absent_9 num* em* medication ///
regDoc feverRespiratory foodDigestive eczemaSkin diarrheaColitis ///
anemia headachesMigraines earInfection seizures mo* access

append using "${TEMPDATADIR}/prepareHealth.dta"
save "${TEMPDATADIR}/prepareHealth.dta", replace 


* ---------------------------------------------------------------------------- *
* ---------------------------------- WAVE 15 --------------------------------- *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta", clear			// ALL

keep idnum p6b1 p6h2 p6b31 p6b32 p6b* p6b20 p6b21 p6b22 p6b23 p6b24 p6b26 ///
k6d3 k6d4 k6d37 k6d38 k6d39 k6d40 k6d41 k6d42 k6d43 k6d48 k6d49 k6d50 k6d51 ///
k6d52 k6d53 k6d54 k6d55 k6d2ac cp6md_case_con cp6md_case_lib ck6cbmi p6b28

* ----- RECODE MISSING VALUES
P_missingvalues

* ----- EQUALIZE
recode p6b13 p6b14 p6b15 p6b16 p6b17 p6b18 p6b19 p6b20 p6b26 k6d40 ///
k6d48 p6b5 p6b31 p6b32 p6b2 p6b24 p6b22 p6b23 p6b10 p6b28 (2 = 0)

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y15.dta", keepusing(wave) nogen

* ---------------------- HEALTH & MEDICAID (CORE REPORT) --------------------- *
* ----- HEALTH PARENTS	(SELF-REPORTED)
rename p6h2 moHealth

* ----- HEALTH CHILD 	(PARENT REPORTED)
rename p6b1 chHealth

* ----- HEALTH CHILD 	(SELF-REPORTED)
rename k6d3 chHealthSelf

* ----- MEDICAID CHILD 	(PARENT REPORTED)
rename p6b31 chMediHI 	// child covered by Medicaid 
rename p6b32 chPrivHI	// child covered by private HI

* ------------------------- DOCTOR VARS (CORE REPORT) ------------------------ *
* ----- REGULAR CHECK-UP (BINARY)
rename p6b24 regDoc

* ----- DOCTOR ACCIDENT/INJURY (BINARY)
rename p6b22 docAccInj

* ----- DOCTOR ILLNESS (BINARY)
rename p6b23 docIll

* ----- USUAL PLACE FOR ROUTINE HEALTH CARE
rename p6b28 access

* --------------------- PAST 12 MONTHS HAD (CORE REPORT) --------------------- *
rename p6b13 foodDigestive
rename p6b14 eczemaSkin
rename p6b15 diarrheaColitis
rename p6b16 headachesMigraines
rename p6b17 earInfection

* -------------------------- MEDICATION (CORE REPORT) ------------------------ *
* ----- PRESCRIBED MEDICATION (BINARY)
* Youth takes doctor prescribed medication?
rename p6b26 medication

* ------------------------- SCHOOL ABSENT (CORE REPORT) ---------------------- *
* ----- LIMITATIONS (BINARY)
rename p6b20 limit

* ----- ABSENT (PARENT REPORTED) (NUM)
rename p6b21 absent_15

* ----- ABSENT (SELF-REPORTED) (NUM)
rename k6d4 absentSelf

* ---------------------- YOUTH HEALTH BEHAVS (CORE REPORT) ------------------- *
* ----- DAYS ACTIVE 60+ (NUM)
rename k6d37 activity60

* ----- DAYS ACTIVE 30+ (NUM)
rename k6d38 activity30

* ----- DAYS VIGOROUS ACTIVITY (NUM)
rename k6d39 activityVigorous


* ----- EVER SMOKED (BINARY)
rename k6d40 everSmoke

* ----- AGE FIRST SMOKED (NUM)
rename k6d41 ageSmoke

* ----- SMOKED MONTH (OPTION)
rename k6d42 monthSmoke

* ----- SMOKED DAY (OPTION)
rename k6d43 cigsSmoke


* ------------ DRINKING
* ----- EVER ALCOHOL WITHOUT PARENTS (BINARY)
rename k6d48 everDrink

* ----- AGE FIRST ALCOHOL (NUM)
rename k6d49 ageDrink 

* ----- ALCOHOL MONTH (OPTION)
rename k6d50 monthTimesDrink

* ----- ALCOHOL EACH TIME MONTH (OPTION)
rename k6d51 monthManyDrink

* ----- ALCOHOL YEAR (OPTION)
rename k6d52 yearTimesDrink

* ----- ALCOHOL EACH TIME YEAR (OPTION)
rename k6d53 yearManyDrink

* ------------ BMI
rename ck6cbmi bmi

* ------------ MENTAL HEALTH
rename p6b5 diagnosedDepression

* ----- FEELS DEPRESSED (SELF-REPORTED)
rename k6d2ac depressed

* ----------------------------- SAVE
keep idnum *Health wave ch* regDoc ever* docAccInj docIll ///
medication limit absent* activity* *Smoke *Drink depressed bmi ///
diagnosedDepression foodDigestive eczemaSkin diarrheaColitis headachesMigraines ///
earInfection access


append using "${TEMPDATADIR}/prepareHealth.dta"
save "${TEMPDATADIR}/prepareHealth.dta", replace 




* ---------------------------------------------------------------------------- *
* ---------------------------------- NOT USED -------------------------------- *
* ---------------------------------------------------------------------------- *

* ----------------------------------------------------------------------------- *
* * ----------------------------- WAVE 1
* ----------------------------- ASTHMA (CORE REPORT)
* ----- EVER ASTHMA
/* * Has a health care professional ever told you child has asthma?
gen everAsthma = .
replace everAsthma = m2b11 if moReport != 0
replace everAsthma = f2b11 if moReport == 0 */

* ----- ER ASTHMA
/* * Since birth, has child required emergency/urgent care treatment for asthma?
gen asthmaER = . 
replace asthmaER = m2b11b if moReport != 0
replace asthmaER = f2b11b if moReport == 0 */
// * ----------------------------- DOCTOR VARS (CORE)
// * ----- DOCTOR VISIT FOR PREGNANCY (BINARY) 
// recode m1a13 (2 = 0)
// rename m1a13 moDoc

// * ----------------------------- MOTHER MENTAL HEALTH (CORE REPORT)
// * ----- MOTHER MEETS ANXIOUS CRITERIA (BINARY)
// rename cm2gad_case		moAnxious

// * ----- MOTHER MEETS DEPRESSION CRTIERIA (CONSERVATIVE) (BINARY)
// rename cm2md_case_con 	moDepresCon	

// * ----- MOTHER MEETS DEPRESSION CRITIERIA (LIBERAL) (BINARY)
// rename cm2md_case_lib	moDepresLib



* ----------------------------------------------------------------------------- *
* * ----------------------------- WAVE 3
* ----- EVER ASTHMA (BINARY)
* Has a doctor or health professional ever told you that (child) has asthma?
/* rename a17 everAsthma */

* ----- ER ASTHMA (RANGE)
* In past 12m how often did child have to visit urgent care center/er for ast
/* rename a19 asthmaERnum */

* ----- ER ASTHMA (BINARY)
* During past 12M did child have to visit ER/urg care center for asthma<Pilot
/* rename a19_ asthmaER */

// * -------------------- MOTHER MENTAL HEALTH (CORE REPORT) -------------------- *
// * ----- MOTHER MEETS ANXIOUS CRITERIA (BINARY)
// rename cm3gad_case		moAnxious

// * ----- MOTHER DEPRESSION CONSERVATIVE (BINARY)
// rename cm3md_case_con	moDepresCon

// * ----- MOTHER DEPRESSION LIBERAL (BINARY)
// rename cm3md_case_lib	moDepresLib



* ----------------------------------------------------------------------------- *
* * ----------------------------- WAVE 5
* ----- EVER ASTHMA
* Has a doctor or other health professional ever told you that child has asthma?
/* gen everAsthma = .
replace everAsthma = m4b2a if moReport != 0
replace everAsthma = f4b2a if moReport == 0 */

* ----- ER ASTHMA
* In past 12 months did child visit ER or urgent care ctr because of asthma?
/* gen asthmaER = .
replace asthmaER = m4b2c if moReport != 0
replace asthmaER = f4b2c if moReport == 0 */

// rename a3_i stuttering

* --------------------- DOCTOR EVER DIAGNOSED (IN-HOME) ---------------------- *
* ----- ADHD (BINARY)
* Has a doctor ever told you that child has attention deficit disorder add)
/* rename a2_a everADHD  */

// * --------------------- MOTHER MENTAL HEALTH (IN-HOME) ----------------------- *
// * ----- MOTHER DEPRESSION CONSERVATIVE (BINARY)
// rename cm4md_case_con	moDepresCon

// * ----- MOTHER DEPRESSION LIBERAL (BINARY)
// rename cm4md_case_lib	moDepresLib	



* ----------------------------------------------------------------------------- *
* * ----------------------------- WAVE 9

* --------------------------- ASTHMA (CORE REPORT) --------------------------- *
* ----- EVER ASTHMA (BINARY)
* Child diagnosed with asthma by doctor or health professional
/* rename p5h1b everAsthma	 */

// rename p5h3i stuttering
// rename p5h3j diabetes

* ------------------------ DOCTOR EVER (CORE REPORT) ------------------------- *
* ----- EVER ADHD (BINARY)
/* rename p5h2a everADHD */

// * ----------------------- SALIVA SAMPLE (CORE REPORT) ------------------------ *
// * ---- CHILD (OPTIONS)
// rename hv5_13 chSaliva


// * ----- MOTHER (OPTIONS)
// rename hv5_12 moSaliva

// * ------------------- MOTHER MENTAL HEALTH (CORE REPORT) --------------------- *
// * ----- MOTHER DEPRESSION CONSERVATIVE (BINARY)
// rename cm5md_case_con moDepresCon

// * ----- MOTHER DEPRESSION LIBERAL (BINARY)
// rename cm5md_case_lib moDepresLib



* ----------------------------------------------------------------------------- *
* * ----------------------------- WAVE 15
* --------------------------- ASTHMA (CORE REPORT) --------------------------- *
* ----- EVER DIAGNOSED ASTHMA (BINARY)
* Doctor diagnosed youth with asthma
/* rename p6b2 everAsthma */

// rename p6b18 stuttering
// rename p6b19 breathing

* -------------------- DOCTOR EVER DIAGNOSED (CORE REPORT) ------------------- *
* ----- ADD/ADHD (BINARY)
/* rename p6b10 everADHD */


// * ----------------------- PCG MENTAL HEALTH (CORE REPORT) -------------------- *
// * ----- MOTHER DEPRESSION CONSERVATIVE (BINARY)
// rename cp6md_case_con moDepresCon

// * ----- MOTHER DEPRESSION LIBERAL (BINARY)
// rename cp6md_case_lib moDepresLib

