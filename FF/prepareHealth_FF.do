* -----------------------------------
* Project:      MA Thesis
* Content:      Extract health vars
* Data:         Fragile Families
* Author:       Michelle Rosenberger
* Date:         November 7, 2018
* -----------------------------------

/* This code extracts all the necessary health variables from the Fragile
Families data for all the waves.

Input datasets:
- "${RAWDATADIR}/00_Baseline/ffmombspv3.dta"
- "${RAWDATADIR}/00_Baseline/ffdadbspv3.dta"
- "${RAWDATADIR}/01_One-Year Core/ffmom1ypv2.dta"
- "${RAWDATADIR}/01_One-Year Core/ffdad1ypv2.dta"
- "${RAWDATADIR}/02_Three-Year Core/ffmom3ypv2.dta"
- "${RAWDATADIR}/02_Three-Year Core/ffdad3ypv2.dta"
- "${RAWDATADIR}/02_Three-Year In-Home/InHome3yr.dta"
- "${RAWDATADIR}/03_Five-Year Core/ffmom5ypv1.dta"
- "${RAWDATADIR}/03_Five-Year Core/ffdad5ypv1.dta"
- "${RAWDATADIR}/03_Five-Year In-Home/Inhome5yr2011_stata/inhome5yr2011.dta"
- "${RAWDATADIR}/04_Nine-Year Core/ff_y9_pub1.dta"
- "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta"

Output datasets:
- "${TEMPDATADIR}/prepareHealth.dta"
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


* ---------------------------------------------------------------------------- *
* --------------------------------- PROGRAMS --------------------------------- *
* ---------------------------------------------------------------------------- *
* ----------------------------- PARENT REPORTED HEALTH
capture program drop child_health
program define child_health
	args moreport fareport

	gen chHealth = .
	replace chHealth = `moreport' if chLiveMo != 2 	// mother + default
	replace chHealth = `fareport' if chLiveMo == 2	// father
end

* ----------------------------- MEDICAID
capture program drop medicaid
program define medicaid
	args mo_covered mo_who fa_covered fa_who

	* Medicaid parents report
	local int = 1
	local num : word count mo fa
	while `int' <= `num' {
		local parent    : word `int' of     mo  fa
		local letter    : word `int' of     m   f
		local int = `int' + 1

		gen chMediHI_`parent' 		= 0
		replace chMediHI_`parent' 	= 1 if `letter'`mo_covered' == 1 & (`letter'`mo_who' == 2 | `letter'`mo_who' == 3)
		replace chMediHI_`parent'	= . if `letter'`mo_covered' >= .
		gen chPrivHI_`parent'		= 0
		replace chPrivHI_`parent' 	= 1 if `letter'`fa_covered' == 1 & (`letter'`fa_who' == 2 | `letter'`fa_who' == 3)
		replace chPrivHI_`parent'	= . if `letter'`fa_covered' >= .
	}

	* Medicaid child
	foreach healthins in chMediHI chPrivHI {
		gen `healthins' = .
		replace `healthins' = `healthins'_mo if chLiveMo != 2	// mother + default
		replace `healthins' = `healthins'_fa if chLiveMo == 2	// father
	}
	drop *_mo *_fa

end


* ---------------------------------------------------------------------------- *
* --------------------------------- BASELINE --------------------------------- *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/00_Baseline/ffmombspv3.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/00_Baseline/ffdadbspv3.dta", nogen
keep idnum m1g1 f1g1 m1a15 m1a13
missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y0.dta", keepusing(chLiveMo wave) nogen

* ----------------------------- HEALTH & MEDICAID (CORE REPORT)
* Health parents
rename 	m1g1 moHealth	// health mother
rename 	f1g1 faHealth	// health father

* Health youth
gen 	chHealth = .

* Medicaid child from parents report
gen chMediHI = 0
replace chMediHI = 1 if m1a15 == 1 | m1a15 == 101


* ----------------------------- DOCTOR VARS (CORE)
* Doctor visit for pregnancy (binary)
rename m1a13 moDoc
replace moDoc = 1 if moDoc == 2

* ----------------------------- SAVE
keep idnum *Health wave chMediHI moDoc
save "${TEMPDATADIR}/prepareHealth.dta", replace 



* ---------------------------------------------------------------------------- *
* ---------------------------------- WAVE 1 ---------------------------------- *
* ---------------------------------------------------------------------------- *

use "${RAWDATADIR}/01_One-Year Core/ffmom1ypv2.dta", clear				// Core
merge 1:1 idnum using "${RAWDATADIR}/01_One-Year Core/ffdad1ypv2.dta"	// Core

keep idnum m2b2 f2b2 m2j1 f2j1 m2j3 m2j3a m2j4 m2j4a f2j3 f2j3a f2j4 f2j4a ///
m2b11 f2b11 m2b11a f2b11a m2b11b m2b6 m2b7 mx2b7 m2b7a m2b8 m2b8a ///
cm2gad_case cm2md_case_con cm2md_case_lib f2b11b f2b6 f2b7 fx2b7 f2b7a f2b7a ///
f2b8 f2b8a

missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y1.dta", keepusing(chLiveMo wave) nogen

* ----------------------------- HEALTH & MEDICAID (CORE REPORT)
* ----- HEALTH PARENTS
rename 	m2j1 moHealth		// health mother
rename 	f2j1 faHealth		// health father

* ----- HEALTH YOUTH BY PARENTS
child_health m2b2 f2b2		// chHealth

* ----- MEDICAID CHILD FROM PARENTS REPORT
medicaid 2j3 2j3a 2j4 2j4a	// chMediHI chPrivHI


* ----------------------------- ASTHMA (CORE REPORT)
* ----- Has a health care professional ever told you child has asthma?
gen everAsthma = .
replace everAsthma = m2b11 if chLiveMo != 2	// mother + default
replace everAsthma = f2b11 if chLiveMo == 2	// father
replace everAsthma = 0 if everAsthma == 2

* ----- Since birth, has child had an episode of asthma or an asthma attack?
gen asthmaAttack = .
replace asthmaAttack = m2b11a if chLiveMo != 2	// mother + default
replace asthmaAttack = f2b11a if chLiveMo == 2	// father
replace asthmaAttack = 0 if asthmaAttack == 2

* ----- Since birth, has child required emergency/urgent care treatment for asthma?
gen asthmaER = . 
replace asthmaER = m2b11b if chLiveMo != 2		// mother + default
replace asthmaER = f2b11b if chLiveMo == 2		// father
replace asthmaER = 0 if asthmaER == 2


* ----------------------------- DOCTOR VARS (CORE REPORT)
* ----- How many times since birth has child been to health car profssnal for well visit (range)
rename m2b6 monumRegDoc
rename f2b6 fanumRegDoc

* ----- How many times since birth has child been to health care prfssnal for illness? (num)
rename m2b7 monumDocIll
rename f2b7 fanumDocIll

* ----- How many times has child been seen by health care prof. b/c illness/injury? (num)
rename mx2b7 monumDocIllInj
rename fx2b7 fanumDocIllInj

* ----- How many times since birth has child been to health care prfssnal for injury? (num)
rename m2b7a monumDocInj
rename f2b7a fanumDocInj

* ----- How many times since birth has child been to emergency room? (num)
rename m2b8 moemRoom
rename f2b8 faemRoom
				
* ----- How many visits to emergency room for accident or injury? (num)
rename m2b8a moemRoomAccInj
rename f2b8a faemRoomAccInj

* ----- WHICH REPORT
foreach var in numRegDoc numDocIll numDocIllInj numDocInj emRoom emRoomAccInj {
	gen `var' = . 
	replace `var' = mo`var' if chLiveMo != 2		// mother + default
	replace `var' = fa`var' if chLiveMo == 2		// father
}
drop mo* fa*

* ----- BINARY VAR DERIVED FROM numRegDoc
gen regDoc = .
replace regDoc = 1 if ( numRegDoc == 1 | numRegDoc == 2 )
replace regDoc = 0 if ( numRegDoc == 0 )

* ----- Binary Youth saw doc for illness in past year (numDocIll)
gen docIll = .
replace docIll = 0 if numDocIll == 0
replace docIll = 1 if (numDocIll >= 1 & numDocIll <= 90)

* ----- LABELS
label var numDocIllInj "How many times has child been seen by health care prof. b/c illness/injury?"
label var numDocInj "How many times since birth has child been to health care prfssnal for injury?"

* ----------------------------- MOTHER MENTAL HEALTH (CORE REPORT)
* ----- CONSTRUCTED - MOTHER MEETS ANXIOUS CRITERIA
rename cm2gad_case		moAnxious	// binary

* ----- CONSTRUCTED - MOTHER MEETS DEPRESSION CRTIERIA (CONSERVATIVE)
rename cm2md_case_con 	moDepresCon	// binary	

* ----- CONSTRUCTED - MOTHER MEETS DEPRESSION CRITIERIA (LIBERAL)
rename cm2md_case_lib	moDepresLib	// binary


* ----------------------------- SAVE
keep idnum wave *Health ch* ever* mo* num* em* asthma* regDoc docIll
append using "${TEMPDATADIR}/prepareHealth.dta"
save "${TEMPDATADIR}/prepareHealth.dta", replace 


* ----------------------------- OTHER VARS
* NOTE: Hospital questions not used
/* m2b3	Does child have any physical disabilities?		
m2b4a	What type of physical disability?-Cerebral Palsy		
m2b4b	What type of physical disability?-Total blindness		
m2b4c	What type of physical disability?-Partial blindness		
m2b4d	What type of physical disability?-Total deafness		
m2b4e	What type of physical disability?-Partial deafness		
m2b4f	What type of physical disability?-Down's syndrome		
m2b4g	What type of physical disability?-Problems with limbs		
m2b4h	What type of physical disability?-Other */


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

missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y3.dta", keepusing(chLiveMo wave) nogen


* ---------------------- HEALTH & MEDICAID (CORE REPORT) --------------------- *
* ----- HEALTH PARENTS
rename m3j1 moHealth	// health mother
rename f3j1 faHealth	// health father

* ----- HEALTH YOUTH BY PARENTS
child_health m3b2 f3b2

* ----- MEDICAID CHILD FROM PARENTS REPORT
medicaid 3j3 3j3a 3j4 3j4a



* ----------------------------- ASTHMA (IN-HOME) ----------------------------- *
* ----- Has a doctor or health professional ever told you that (child) has asthma? (binary)
rename a17 everAsthma

* ----- During past 12m, has (child) had an episode of asthma or an asthma attack? (binary)
rename a18 asthmaAttack

* ----- In past 12m how often did child have to visit urgent care center/er for ast (range)
rename a19 asthmaERnum

* ----- During past 12M did child have to visit ER/urg care center for asthma<Pilot (binary)
rename a19_ asthmaER


* -------------------------- DOCTOR VARS (IN-HOME) --------------------------- *
* ----- In past 12M, how many regular check-ups (by doctor, nurse) did child have? (range)
rename a4 	numRegDoc

	* ----- Binary variable derived from numRegDoc
	gen regDoc = .
	replace regDoc = 1 if ( numRegDoc == 1 | numRegDoc == 2 )
	replace regDoc = 0 if ( numRegDoc == 0 )

* ----- In past 12M: # of times child seen by doctor/nurse for illness/accident/inj. (number)
rename a7 	numDoc

* ----- How many of those health visits were, because of an accident or injury? (number)
rename a8 	numDocAccInj
	
	* ----- Binary variable
	gen docAccInj = .
	replace docAccInj = 0 if ( numDocAccInj == 0 )
	replace docAccInj = 1 if ( numDocAccInj >= 1 & numDocAccInj <= 8)

	* ----- Difference between numDoc and numDocAccInj due to illness
	gen numDocIll = numDoc - numDocAccInj

	* ----- Binary variable
	gen docIll = .
	replace docIll = 0 if ( numDocIll == 0 )
	replace docIll = 1 if ( numDocIll >= 1 & numDocIll <= 72)

* ----- In past 12m how many times has child been taken to the emergency room (number)
rename a9 	emRoom

* ----- How many of those ER visits were because of accident or injury? (number)
rename a10 	emRoomAccInj

* a5		does child have a usual place for routine health care like regular checkup?
* a5a		where does child usually go for health care?	
* a5a_oth	child usual place for health care- other (specify)


* -------------------- MOTHER MENTAL HEALTH (CORE REPORT) -------------------- *
* ----- Constructed - Mother meets anxious criteria (binary)
rename cm3gad_case		moAnxious

* ----- Constructed - Mother meets depression criteria (conservative) (binary)
rename cm3md_case_con	moDepresCon

* ----- Constructed - Mother meets depression criteria (liberal) (binary)
rename cm3md_case_lib	moDepresLib


* cm3alc_case		Constructed - Mother alcohol dependence (CIDI)				
* cm3drug_case		Constructed - Mother drug dependence (CIDI)



* ----------------------------------- SAVE ----------------------------------- *
keep idnum *Health wave ch* num* em* ever* mo* asthma* regDoc docAccInj ///
numDocIll docIll
append using "${TEMPDATADIR}/prepareHealth.dta"
save "${TEMPDATADIR}/prepareHealth.dta", replace 


* ------------------------------- IN HOME VARS ------------------------------- *
/* int5		relationship respondent to child
int5_oth	other relationship respondent to child
a1			a1: in general, wld you say child's health is 
a2			a2: does (child) have any physical disability?					
a3_1		a3_1: does child have cerebral palsy?					
a3_2		a3_2: does child have total blindness?					
a3_3		a3_3: does child have partial blindness?					
a3_4		a3_4: does child have total deafness?					
a3_5		a3_5: does child have partial deafness?					
a3_6		a3_6: does child have down's syndrome?					
a3_7		a3_7: does child have problem with limbs?
BMI variables */



* ---------------------------------------------------------------------------- *
* ---------------------------------- WAVE 5 ---------------------------------- *
* ---------------------------------------------------------------------------- *

use "${RAWDATADIR}/03_Five-Year Core/ffmom5ypv1.dta", clear						// Core
merge 1:1 idnum using "${RAWDATADIR}/03_Five-Year Core/ffdad5ypv1.dta", nogen	// Core
merge 1:1 idnum using "${RAWDATADIR}/03_Five-Year In-Home/Inhome5yr2011_stata/inhome5yr2011.dta", nogen	// In-Home

keep idnum m4b2 f4b2 m4j1 f4j1 m4j3 m4j3a m4j4 m4j4a f4j3 f4j3a f4j4 f4j4a ///
m4b2a f4b2a m4b2b f4b2b m4b2c f4b2c a6 a12 a13 a14 a15 cm4md_case_con ///
cm4md_case_lib int5 int_5ot a1 a2_a a2_b a2_c a2_d a2_e a2_f a2_g a2_h a2_i ///
a2_j a2_k a2_l a2_m a2_n a3_a a3_b a3_c a3_d a3_e a3_f a3_g a3_h a3_i

missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y5.dta", keepusing(chLiveMo wave) nogen

* ---------------------- HEALTH & MEDICAID (CORE REPORT) --------------------- *
* ----- HEALTH PARENTS
rename m4j1 moHealth		// health mother
rename f4j1 faHealth		// health father

* ----- HEALTH CHILD BY PARENTS
child_health m4b2 f4b2		// chHealth

* ----- MEDICAID CHILD FROM PARENTS REPORT
medicaid 4j3 4j3a 4j4 4j4a	// chMediHI chPrivHI


* --------------------------- ASTHMA (CORE REPORT) --------------------------- *
* ----- EVER ASTHMA
* Has a doctor or other health professional ever told you that child has asthma?
gen everAsthma = .
replace everAsthma = m4b2a if chLiveMo != 2			// mother + default
replace everAsthma = f4b2a if chLiveMo == 2			// father
replace everAsthma = 0 if everAsthma == 2

* ----- EPISODE ASTHMA
* Since birth, has child had an episode of asthma or an asthma attack?
gen asthmaAttack = .
replace asthmaAttack = m4b2b if chLiveMo != 2	// mother + default
replace asthmaAttack = f4b2b if chLiveMo == 2	// father
replace asthmaAttack = 0 if asthmaAttack == 2

* ----- ER ASTHMA
* In past 12 months did child visit ER or urgent care ctr because of asthma?
gen asthmaER = .
replace asthmaER = m4b2c if chLiveMo != 2		// mother + default
replace asthmaER = f4b2c if chLiveMo == 2		// father
replace asthmaER = 0 if asthmaER == 2


* ------------------------ DOCTOR VARS (CORE REPORT) ------------------------- *
* ----- REGULAR CHECK-UP (12 MONTHS)
* Last 12m, how many times child been seen by doctor/hlh prof for reg chk (range)
rename a6 numRegDoc
recode numRegDoc 1=0 2=1 3=2	// make comparable across waves

	* ----- BINARY VAR DERIVED FROM numRegDoc
	gen regDoc = .
	replace regDoc = 1 if ( numRegDoc == 1 | numRegDoc == 2 )
	replace regDoc = 0 if ( numRegDoc == 0 )

* ----- DOCTOR ILLNESS/ACC/INJ (12 MONTHS)
* Last 12 m: how many times child saw a dr/hlth prof for illness/accident/inj (number)
rename a12 numDoc

* ----- DOCTOR ACCIDENT/INJ (12 MONTHS)
* Was this visit/how many of (number in a12 were), b/c of an accident/injury? (number)
rename a13 numDocAccInj

	* ----- BINARY FROM numDocAccInj
	gen docAccInj = . 
	replace docAccInj = 0 if ( numDocAccInj == 0 )
	replace docAccInj = 1 if ( numDocAccInj >= 1 & numDocAccInj <= 25)

* ----- ER
* How many times has child been taken to the emergency room? (number)
rename a14 emRoom

* ----- ER ACCIDENT/INJ
* Was visit/how many of (# in a14 visits were) to the er b/c of accident/inju (number)
rename a15 emRoomAccInj

* a7	Does child have a usual place for routine health care (regular check-ups)?
* a8	Where does child usually go for health care?
* a8_ot	Where does (child) usually go for health care (other specify)


* ----------------------- PAST 12 MONTHS HAD (IN-HOME) ----------------------- *
* ----- FEVER OF RESPIRATORY ALLERGY (binary)
rename a3_a feverRespiratory

* ----- FOOD OR DIGESTIVE ALLERGY (binary)
rename a3_b foodDigestive

* ----- ECZEMA OR SKIN ALLERGY (binary)
rename a3_c eczemaSkin

* ----- DIARRHEA OR COLITIS (binary)
rename a3_d diarrheaColitis

* ----- ANEMIA (binary)
rename a3_e anemia

* ----- HEADACHES OR MIGRAINES (binary)
rename a3_f headachesMigraines

* ----- 3+ EAR INFECTIONS (binary)
rename a3_g earInfection

* ----- SEIZURES (binary)
rename a3_h seizures

* ----- STUTTERING OR STAMMERING (binary)
rename a3_i stuttering


* --------------------- DOCTOR EVER DIAGNOSED (IN-HOME) ---------------------- *
* ----- ADHD
* Has a doctor ever told you that child has attention deficit disorder add) (binary)
rename a2_a everADHD 



* --------------------- MOTHER MENTAL HEALTH (IN-HOME) ----------------------- *
* ----- DEPRESSION CONSERVATIVE
* Constructed - Mother meets depression criteria (conservative) (binary)
rename cm4md_case_con	moDepresCon

* ----- DEPRESSION LIBERAL
* Constructed - Mother meets depression criteria (liberal) (binary)
rename cm4md_case_lib	moDepresLib	


* ----------------------------------- SAVE ----------------------------------- *
keep idnum *Health wave ch* ever* num* em*  mo* feverRespiratory ///
foodDigestive eczemaSkin diarrheaColitis anemia headachesMigraines ///
earInfection seizures stuttering everADHD asthma* regDoc docAccInj

append using "${TEMPDATADIR}/prepareHealth.dta"
save "${TEMPDATADIR}/prepareHealth.dta", replace 


* ---------------------------------- OTHERS ---------------------------------- *
/* int5	int5: What is the relationship of the respondent to the child?					
int_5ot	int_5ot: What is the relationship of the respondent to the child (oth specify)?
a1	a1: In general, how would you describe (childís) health		
a2_b	a2_b: Has a doctor ever told you that child has mental retardation/developmental	
a2_c	a2_c: Has a doctor ever told you that child has downís syndrome?					
a2_d	a2_d: Has a doctor ever told you that child has cerebral palsy?					
a2_e	a2_e: Has a doctor ever told you that child has sickle cell anemia?					
a2_f	a2_f: Has a doctor ever told you that child has autism?					
a2_g	a2_g: Has a doctor ever told you that child has congenital heart disease/oth hea	
a2_h	a2_h: Has a doctor ever told you that child has asthma?					
a2_i	a2_i: Has a doctor ever told you that child has total blindness?					
a2_j	a2_j: Has a doctor ever told you that child has partial blindness?					
a2_k	a2_k: Has a doctor ever told you that child has total deafness?					
a2_l	a2_l: Has a doctor ever told you that child has partial deafness?					
a2_m	a2_m: Has a doctor ever told you that child has speech or language problem?
a2_n	a2_n: Has a doctor ever told you that child has problems with limbs (specify)?*/



* ---------------------------------------------------------------------------- *
* ---------------------------------- WAVE 9 ---------------------------------- *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/04_Nine-Year Core/ff_y9_pub1.dta", clear		// ALL

keep idnum p5h1 m5g1 f5g1 p5h13 p5h14 p5h3* p5l11 p5h6 p5h7 p5h9 k5h1 p5h1b ///
p5h10 p5h2a hv5_12 hv5_13 p5h3a1 cm5md_case_con cm5md_case_lib

missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y9.dta", keepusing(chLiveMo wave) nogen

/* -------------------- Health & Medicaid (Core report) -------------------- */
* Health parents
rename m5g1 moHealth	// health mother
rename f5g1 faHealth	// health father

* Health youth by parents
rename p5h1 chHealth

* Health youth self-report
rename k5h1 chHealthSelf

* Medicaid child - PCG report
rename p5h13 chMediHI 	// child covered by Medicaid 
rename p5h14 chPrivHI	// child covered by private HI
replace chMediHI = 0 if chMediHI == 2
replace chPrivHI = 0 if chPrivHI == 2
/* ----------------------------------  END ---------------------------------- */


/* -------------------------- Asthma (Core report) -------------------------- */
* Child diagnosed with asthma by doctor or health professional 		- binary
rename p5h1b everAsthma	
replace everAsthma = 0 if everAsthma == 2

/* 	2225	"p5h1ca"	"H1CA. Amount of time asthma kept child from getting things done"
	2226	"p5h1cb"	"H1CB. Frequency child had shortness of breath in past month"
	2227	"p5h1cc"	"H1CC. Frequency child's asthma symptoms awoke child"
	2228	"p5h1cd"	"H1CD. Frequency child used rescue inhaler in past month"
	2229	"p5h1ce"	"H1CE. Rate child's control of asthma during the past month" */
/* ----------------------------------  END ---------------------------------- */


/* ------------------------ Doctor vars (Core report) ----------------------- */
*  Number of times child had regular check-up 						- range
rename p5h6 numRegDoc
recode numRegDoc 1=0 2=1 3=2	// make comparable across waves

	* Binary variable derived from numRegDoc
	gen regDoc = .
	replace regDoc = 1 if ( numRegDoc == 1 | numRegDoc == 2 )
	replace regDoc = 0 if ( numRegDoc == 0 )

* Number of times child saw doctor/nurse due to illness, accident, injury - number
rename p5h9 numDoc

* Number of times child taken to emergency room in last 12 months 	- number
rename p5h10 emRoom	

/* 	p5h7	H7. Child has a usual place for routine health care
	p5h8	H8. Place child usually goes for health care */
* Hospital questions omitted
/* ----------------------------------  END ---------------------------------- */


/* -------------------- Past 12 months had (Core report) -------------------- */
local MONTHSVAR	feverRespiratory foodDigestive eczemaSkin diarrheaColitis ///
anemia headachesMigraines earInfection seizures stuttering diabetes

* Child had hay fever or respiratory allergy in last 12 months 		- binary
rename p5h3a feverRespiratory

* Child had any food or digestive allergy in last 12 months 		- binary
rename p5h3b foodDigestive

* Child had eczema or skin allergy in last 12 months 				- binary
rename p5h3c eczemaSkin

* Child had frequent diarrhea or colitis in last 12 months 			- binary
rename p5h3d diarrheaColitis

* Child had anemia in last 12 months 								- binary
rename p5h3e anemia

* Child had frequent headaches or migraines in last 12 months 		- binary
rename p5h3f headachesMigraines

* Child had three or more ear infections in last 12 months 			- binary
rename p5h3g earInfection

* Child had seizures in last 12 months 								- binary
rename p5h3h seizures

* Child had stuttering or stammering in past 12 months 				- binary
rename p5h3i stuttering

* Child had diabetes in last 12 months 								- binary
rename p5h3j diabetes

foreach var in `MONTHSVAR' {
	replace `var' = 0 if `var' == 2
}
/* ----------------------------------  END ---------------------------------- */


/* ------------------- Doctor ever diagnosed (Core report) ------------------- */
* Doctor has diagnosed ADD/ADHD - binary
rename p5h2a everADHD
replace everADHD = 0 if everADHD == 2

/* 	p5h1a	H1A. Wheezing or whistling in child's chest
	p5h2b	H2B. Doctor has diagnosed mental retardation or developmental delay
	p5h2c	H2C. Doctor has diagnosed down syndrome
	p5h2d	H2D. Doctor has diagnosed cerebral palsy
	p5h2e	H2E. Doctor has diagnosed sickle cell anemia
	p5h2f	H2F. Doctor has diagnosed autism
	p5h2g	H2G. Doctor has diagnosed congenital heart disease or heart condition
	p5h2h	H2H. Doctor has diagnosed total blindness
	p5h2i	H2I. Doctor has diagnosed partial blindness
	p5h2j	H2J. Doctor has diagnosed total deafness
	p5h2k	H2K. Doctor has diagnosed partial deafness
	p5h2l	H2L. Doctor has diagnosed a speech or language problem
	p5h2m	H2M. Doctor has diagnosed problems with limbs */
* 	Recode
/* ----------------------------------  END ---------------------------------- */


/* --------------------- Takes medication (Core report) --------------------- */
* Child takes medicine where a prescription was needed 				- binary
rename p5h3a1 medication
replace medication = 0 if medication == 2 

/* 	p5h3b1_1	H3B1_1. Child takes medication for ADHD
	p5h3b1_2	H3B1_2. Child takes medication for hay fever or respiratory allergy
	p5h3b1_3	H3B1_3. Child takes medication for food or digestive allergy
	p5h3b1_4	H3B1_4. Child takes medication for eczema or skin allergy
	p5h3b1_5	H3B1_5. Child takes medication for migraines
	p5h3b1_6	H3B1_6. Child takes medication for seizures
	p5h3b1_7	H3B1_7. Child takes medication for depression/anxiety
	p5h3b1_8	H3B1_8. Child takes medication for diabetes
	p5h3b1_91	H3B1_91. Child takes medication for other
	p5h3b1_101	H3B1_101. Child takes medication for asthma */
/* ----------------------------------  END ---------------------------------- */


/* ---------------- Problems without know cause (Core report) ---------------- */
/* 	p5q3bb1 	Child has physical problems without known medical cause: Aches or pains
	p5q3bb2 	Child has physical problems without known medical cause: Headaches
	p5q3bb3 	Child has physical problems without known medical cause: Nausea
	p5q3bb4 	Child has physical problems without known medical cause: Problems with ey
	p5q3bb5 	Child has rashes other skin problems without known medical cause
	p5q3bb6 	Child has stomach aches or cramps without known medical cause.
	p5q3bb7 	Child has vomiting, throwing up without known medical cause.
	p5q3bb8 	Child has physical problems without known medical cause: Other

	p5q3bb_101 	Child has asthma or breathing problems without known cause
	p5q3bb_102 	Child has allergies without known cause
	p5q3bb_103 	Child has nose bleeds without known cause
	p5q3bb_104 	Child has learning disability without known cause */
/* ----------------------------------  END ---------------------------------- */


/* ----------------------- School absent (Core report) ---------------------- */
* Number of times child was absent from school during school year 	- range
rename p5l11 absent

/* 	p5l12a 	Illness or other physical problem
	p5l12b 	An emotional or mental condition
	p5l12c 	Illness in the family
	p5l12d 	The family moved
	p5l12e 	The student shifted to another school
	p5l12f 	A parent wanted child at home
	p5l12g 	Child was suspended and or expelled
	p5l12h 	Child skipped school
	p5l12i 	Specify if there is something else */
/* ----------------------------------  END ---------------------------------- */


/* ----------------------- Saliva sample (Core report) ---------------------- */
* Mother - options
rename hv5_12 moSaliva

* Child - options
rename hv5_13 chSaliva
/* ----------------------------------  END ---------------------------------- */


/* -------------------- Mother mental health (Core report) ------------------ */
* Constructed - Mother meets depression criteria (conservative) 	- binary
rename cm5md_case_con moDepresCon

* Constructed - Mother meets depression criteria (liberal) 			- binary
rename cm5md_case_lib moDepresLib
/* ----------------------------------  END ---------------------------------- */



keep idnum *Health wave ch* absent ever* num* em* everADHD `MONTHSVAR' ///
medication absent mo* regDoc

append using "${TEMPDATADIR}/prepareHealth.dta"
save "${TEMPDATADIR}/prepareHealth.dta", replace 


* ---------------------------------------------------------------------------- *
* ---------------------------------- WAVE 15 --------------------------------- *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta", clear			// ALL

keep idnum p6b1 p6h2 p6b31 p6b32 p6b* p6b20 p6b21 p6b22 p6b23 p6b24 p6b26 ///
k6d3 k6d4 k6d37 k6d38 k6d39 k6d40 k6d41 k6d42 k6d43 k6d48 k6d49 k6d50 k6d51 ///
k6d52 k6d53 k6d54 k6d55 k6d2ac cp6md_case_con cp6md_case_lib ch6cbmi

missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y15.dta", keepusing(wave) nogen

/* -------------------- Health & Medicaid (Core report) -------------------- */
* Health parents
rename p6h2 moHealth

* Health youth by parents
rename p6b1 chHealth

* Health youth self-report
rename k6d3 chHealthSelf

* Medicaid child - PCG report
rename p6b31 chMediHI 	// child covered by Medicaid 
rename p6b32 chPrivHI	// child covered by private HI
replace chMediHI = 0 if chMediHI == 2
replace chPrivHI = 0 if chPrivHI == 2
/* ----------------------------------  END ---------------------------------- */


/* -------------------------- Asthma (Core report) -------------------------- */
* Doctor diagnosed youth with asthma 								- binary
rename p6b2 everAsthma
replace everAsthma = 0 if everAsthma == 2
/* ----------------------------------  END ---------------------------------- */


/* ------------------------ Doctor vars (Core report) ----------------------- */
* Youth saw doctor for accident or injury in past year 				- binary
rename p6b22 docAccInj

* Youth saw doctor for an illness in past year 						- binary
rename p6b23 docIll

* Youth saw doctor for regular check-up in past year 				- binary
rename p6b24 regDoc

foreach var in docAccInj docIll regDoc {
	replace `var' = 0 if `var' == 2
}

/* 	p6b25	B25. Times youth has been injured in past year
	p6b28	B28. Youth has usual place for routine health care?
	p6b29	B29. Place youth usually goes for health care? */
/* ----------------------------------  END ---------------------------------- */


/* ------------------- Doctor ever diagnosed (Core report) ------------------- */
* Doctor diagnosed youth with ADD/ADHD								- binary
rename p6b10 everADHD
replace everADHD = 0 if everADHD == 2

/*	p6b3		B3. Doctor diagnosed youth with anemia
	p6b4		B4. Doctor diagnosed youth with heart disease/condition
	p6b5		B5. Doctor diagnosed youth with depression/anxiety
	p6b6		B6. Doctor diagnosed youth with diabetes
	p6b7		B7. Doctor diagnosed youth with limb problems
	p6b8		B8. Doctor diagnosed youth with seizures
	p6b9		B9. Doctor diagnosed youth with other condition
	p6b9_101	B9_101. What is other health condition - Headache/Migraines
	p6b9_102	B9_102. What is other health condition - Overweight/Obese
	p6b9_103	B9_103. What is other health condition - Allergies
	p6b9_104	B9_104. What is other health condition - Eczema
	p6b9_105	B9_105. What is other health condition - Blood pressure/Cholesterol
	p6b9_106	B9_106. What is other health condition - Scoliosis
	p6b9_107	B9_107. What is other health condition - Unspecified
	p6b11		B11. Doctor diagnosed youth with Autism
	p6b12		B12. Doctor diagnosed youth with other learning disability
	p6b12_101	B12_101. What is other learning disability - Speech problem
	p6b12_102	B12_102. What is other learning disability - Developmental delay
	p6b12_103	B12_103. What is other learning disability - Dyslexia
	p6b12_104	B12_104. What is other learning disability - Reading/Math difficulty
	p6b12_105	B12_105. What is other learning disability - Other
	RECODE */
/* ----------------------------------  END ---------------------------------- */


/* -------------------- Past 12 months had (Core report) -------------------- */
local MONTHSVAR foodDigestive eczemaSkin diarrheaColitis headachesMigraines ///
earInfection stuttering breathing

* Youth had food/digestive allergy in past year						- binary
rename p6b13 foodDigestive

* Youth had eczema/skin allergy in past year						- binary
rename p6b14 eczemaSkin

* Youth had frequent diarrhea/colitis in past year					- binary
rename p6b15 diarrheaColitis

* Youth had frequent headaches/migraines in past year				- binary
rename p6b16 headachesMigraines

* Youth had ear infection in past year								- binary
rename p6b17 earInfection

* Youth had stuttering or stammering problem in past year			- binary
rename p6b18 stuttering

* Youth had trouble breathing/chest problem in past year			- binary
rename p6b19 breathing

foreach var in `MONTHSVAR' {
	replace `var' = 0 if `var' == 2
}
/* ----------------------------------  END ---------------------------------- */


/* --------------------- Takes medication (Core report) --------------------- */
* Youth takes doctor prescribed medication?							- binary
rename p6b26 medication
replace medication = 0 if medication == 2

/*	p6b27_1		B27_1. Youth takes medication for ADD/ADHD
	p6b27_2		B27_2. Youth takes medication for anemia
	p6b27_3		B27_3. Youth takes medication for asthma
	p6b27_4		B27_4. Youth takes medication for heart condition
	p6b27_5		B27_5. Youth takes medication for depression/anxiety
	p6b27_6		B27_6. Youth takes medication for diabetes
	p6b27_7		B27_7. Youth takes medication for eczema
	p6b27_8		B27_8. Youth takes medication for diarrhea or colitis
	p6b27_9		B27_9. Youth takes medication for seizures
	p6b27_10	B27_10. Youth takes medication for headaches or migraines
	p6b27_11	B27_11. Youth takes medication for ear infections
	p6b27_12	B27_12. Youth takes medication for other health condition */
/* ----------------------------------  END ---------------------------------- */


/* ----------------------- School absent (Core report) ---------------------- */
* Health problems limit youth's usual activities 					- binary
rename p6b20 limit
replace limit = 0 if limit == 2

* Days youth absent from school due to health in past year 			- number
rename p6b21 absent

* Days absent from school due to health in past year - youth report - number
rename k6d4 absentSelf
/* ----------------------------------  END ---------------------------------- */


/* --------------------- Youth health behavs (Core report) ------------------ */
* Activity
** Days physically active for 60+ minutes in past week
rename k6d37 activity60

** Days engage in physical activity for 30+ minutes in typical week	- num
rename k6d38 activity30

** Days participate in vigorous physical activity in typical week	- num
rename k6d39 activityVigorous

* Smoking
** Ever smoked an entire cigarette?									- binary
rename k6d40 everSmoke
replace everSmoke = 0 if everSmoke == 2

** Age when youth first smoked a whole cigarette (years)			- num
rename k6d41 ageSmoke

** How often smoked cigarettes in past month?						- option
rename k6d42 monthSmoke

** How many cigarettes per day smoked in past month?				- option
rename k6d43 cigsSmoke


* Drinking
** Ever drank alcohol more than two times without parents?			- binary
rename k6d48 everDrink
replace everDrink = 0 if everDrink == 2

** 	How old were you when you first drank alcohol? (years)			- num
rename k6d49 ageDrink 

** 	How often drank alcohol in past month?							- option
rename k6d50 monthTimesDrink

** How many alcoholic drinks had each time in past month?
rename k6d51 monthManyDrink

** How often drank alcohol in past year?							- option
rename k6d52 yearTimesDrink

** How many alcoholic drinks had each time in past year?
rename k6d53 yearManyDrink


* BMI
** Constructed - Youth's Body Mass Index (BMI)
rename ch6cbmi bmi


* Mental health
** Doctor diagnosed youth with depression/anxiety
rename p6b5 diagnosedDepression
replace diagnosedDepression = 0 if diagnosedDepression == 2

** I feel depressed (youth)											- options
rename k6d2ac depressed

/* 	k6d54	How often drank five or more alcoholic drinks in past year?
	k6d55	How often got drunk in past year? */
/* ----------------------------------  END ---------------------------------- */


/* ---------------------- PCG mental health (Core report) ------------------- */
* Constructed - Mother meets depression criteria (conservative) 	- binary
rename cp6md_case_con moDepresCon

* Constructed - Mother meets depression criteria (liberal) 			- binary
rename cp6md_case_lib moDepresLib
/* ----------------------------------  END ---------------------------------- */


keep idnum *Health wave ch* regDoc ever* docAccInj docIll everADHD ///
`MONTHSVAR' medication limit absent* activity* *Smoke *Drink depressed bmi ///
diagnosedDepression

append using "${TEMPDATADIR}/prepareHealth.dta"
save "${TEMPDATADIR}/prepareHealth.dta", replace 



