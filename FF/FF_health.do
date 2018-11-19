* Project:      MA Thesis
* Content:      Health outcomes
* Data:         Fragile families
* Author:       Michelle Rosenberger
* Date:         November 7, 2018

********************************************************************************
*********************************** PREAMBLE ***********************************
********************************************************************************
capture log close
clear all
est clear
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

// Set working directories
if "`c(username)'" == "michellerosenberger"  {
    global USERPATH     "~/Development/MA"
}

global RAWDATADIR	    "${USERPATH}/data/raw/FragileFamilies"
global CLEANDATADIR  	"${USERPATH}/data/clean"
global TEMPDATADIR  	"${USERPATH}/data/temp"
global CODEDIR          "${USERPATH}/code"

do "${CODEDIR}/FF/FF_programs.do"      // Load programs


********************
* PROGRAMS
********************

* PARENT REPORTED HEALTH
capture program drop child_health
program define child_health
	args moreport fareport

	gen chHealth = .
	replace chHealth = `moreport' if chLiveMo != 2 	// mother + default
	replace chHealth = `fareport' if chLiveMo == 2	// father
end

* MEDICAID
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


********************************************************************************
********************************** OUTCOMES  ***********************************
********************************************************************************

********************
* Baseline
********************
use "${RAWDATADIR}/00_Baseline/ffmombspv3.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/00_Baseline/ffdadbspv3.dta", nogen
keep idnum m1g1 f1g1 m1a15 m1a13
missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y0.dta", keepusing(chLiveMo wave) nogen

* Health parents & youth
rename 	m1g1 moHealth	// health mother
rename 	f1g1 faHealth	// health father
gen 	chHealth = .

* Medicaid child from parents report
gen chMediHI = .
replace chMediHI = 1 if m1a15 == 1 | m1a15 == 101

* Doctor visists
gen moDoc = .
replace moDoc = 1 if m1a13 == 1	// doctor visit for pregnancy

keep idnum *Health wave
save "${TEMPDATADIR}/health.dta", replace 

********************
* Wave 1
********************
use "${RAWDATADIR}/01_One-Year Core/ffmom1ypv2.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/01_One-Year Core/ffdad1ypv2.dta"
keep idnum m2b2 f2b2 m2j1 f2j1 m2j3 m2j3a m2j4 m2j4a f2j3 f2j3a f2j4 f2j4a
missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y1.dta", keepusing(chLiveMo wave) nogen

* Health parents
rename 	m2j1 moHealth	// health mother
rename 	f2j1 faHealth	// health father

* Health youth by parents
child_health m2b2 f2b2

* Medicaid child from parents report
medicaid 2j3 2j3a 2j4 2j4a

keep idnum *Health wave ch*
append using "${TEMPDATADIR}/health.dta"
save "${TEMPDATADIR}/health.dta", replace 

********************
* Wave 3
********************
use "${RAWDATADIR}/02_Three-Year Core/ffmom3ypv2.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/02_Three-Year Core/ffdad3ypv2.dta"
keep idnum m3b2 f3b2 m3j1 f3j1 m3j3 m3j3a m3j4 m3j4a f3j3 f3j3a f3j4 f3j4a
missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y3.dta", keepusing(chLiveMo wave) nogen

* Health parents
rename m3j1 moHealth	// health mother
rename f3j1 faHealth	// health father

* Health youth by parents
child_health m3b2 f3b2

* Medicaid child from parents report
medicaid 3j3 3j3a 3j4 3j4a

keep idnum *Health wave ch*
append using "${TEMPDATADIR}/health.dta"
save "${TEMPDATADIR}/health.dta", replace 

********************
* Wave 5
********************
use "${RAWDATADIR}/03_Five-Year Core/ffmom5ypv1.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/03_Five-Year Core/ffdad5ypv1.dta"
keep idnum m4b2 f4b2 m4j1 f4j1 m4j3 m4j3a m4j4 m4j4a f4j3 f4j3a f4j4 f4j4a
missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y5.dta", keepusing(chLiveMo wave) nogen

* Health parents
rename m4j1 moHealth	// health mother
rename f4j1 faHealth	// health father

* Health youth by parents
child_health m4b2 f4b2

* Medicaid child from parents report
medicaid 4j3 4j3a 4j4 4j4a

keep idnum *Health wave ch*
append using "${TEMPDATADIR}/health.dta"
save "${TEMPDATADIR}/health.dta", replace 

********************
* Wave 9
********************
use "${RAWDATADIR}/04_Nine-Year Core/ff_y9_pub1.dta", clear
keep idnum p5h1 m5g1 f5g1 p5h13 p5h14 p5h3* p5l11 p5h6 p5h7 p5h9 k5h1
missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y9.dta", keepusing(chLiveMo wave) nogen

* Health parents
rename m5g1 moHealth	// health mother
rename f5g1 faHealth	// health father

* Health youth by parents
rename p5h1 chHealth

* Medicaid child - PCG report
rename p5h13 chMediHI 	// child covered by Medicaid 
rename p5h14 chPrivHI	// child covered by private HI
replace chMediHI = 0 if chMediHI == 2
replace chPrivHI = 0 if chPrivHI == 2

* Health variables
rename p5h3a fever_respiratory 	// Child had hay fever or respiratory allergy in last 12 months
rename p5h3b food_digestiv 		// Child had any food or digestive allergy in last 12 months
rename p5h3c eczema_skin 		// Child had eczema or skin allergy in last 12 months
rename p5h3d diarrhea_colitis 	// Child had frequent diarrhea or colitis in last 12 months
rename p5h3e anemia				// Child had anemia in last 12 months
rename p5h3f migraines 			// Child had frequent headaches or migraines in last 12 months
rename p5h3g ear_infection 		// Child had three or more ear infections in last 12 months
rename p5h3h seizures 			// Child had seizures in last 12 months
rename p5h3j diabetes 			// Child had diabetes in last 12 months

* Limit acitivties / school absent
rename p5l11 absent 			// Number of times child was absent from school during school year

* Doctor visits youth - PCG report
rename p5h6 docReg_num 			// Number of times child had regular check-up
rename p5h7 docPlace 			// Child has a usual place for routine health care
rename p5h9 docVisit 			// Number of times child saw doctor/nurse due to illness, accident, injury

* More variables (youth report)
rename k5h1 chHealth_self 		// Condition of health in general

* Recode
foreach var in fever_respiratory food_digestiv eczema_skin diarrhea_colitis anemia migraines ///
	ear_infection seizures diabetes docPlace {
	replace `var' = 0 if `var' == 2
}

* Health index
gen healthIndex = fever_respiratory + food_digestiv + eczema_skin + diarrhea_colitis + anemia ///
	+ migraines + ear_infection + seizures + diabetes

keep idnum *Health wave ch* fever_respiratory food_digestiv eczema_skin diarrhea_colitis anemia migraines ear_infection seizures diabetes healthIndex absent doc* 
append using "${TEMPDATADIR}/health.dta"
save "${TEMPDATADIR}/health.dta", replace 

********************
* Wave 15
********************
use "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta", clear
keep idnum p6b1 p6h2 p6b31 p6b32 p6b* p6b20 p6b21 p6b22 p6b23 p6b24 p6b26 k6d3 k6d4
missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y15.dta", keepusing(wave) nogen

* Health parents
rename p6h2 moHealth	// health PCG

* Health youth by parents
rename p6b1 chHealth

* Medicaid child - PCG report
rename p6b31 chMediHI 	// child covered by Medicaid 
rename p6b32 chPrivHI	// child covered by private HI
replace chMediHI = 0 if chMediHI == 2
replace chPrivHI = 0 if chPrivHI == 2

* Health index child - PCG report
rename p6b2 asthma
rename p6b3 anemia
rename p6b4 heartDisease
rename p6b5 depression
rename p6b6 diabetes
rename p6b7 limb
rename p6b8 seizures
rename p6b9 otherCondition

* Limit acitivties / school absent
rename p6b20 limit				// Health problems limit youth's usual activities
rename p6b21 absent				// Days youth absent from school due to health in past year

* Doctor visits youth - PCG report
rename p6b22 docInjuryAccident 	// Youth saw doctor for accident or injury in past year
rename p6b23 docIlness			// Youth saw doctor for an illness in past year
rename p6b24 docReg				// Youth saw doctor for regular check-up in past year
rename p6b26 docMedi			// Youth takes doctor prescribed medication

* More variables (youth report)
rename k6d3 chHealth_self 		// youth description own health
rename k6d4 absent_self 		// day absent

* Recode
foreach var in asthma anemia heartDisease depression diabetes limb seizures otherCondition ///
	docInjuryAccident docIlness docReg docMedi limit {
	replace `var' = 0 if `var' == 2
}

* Health index
gen healthIndex = asthma + anemia + heartDisease + depression + diabetes + limb + seizures + otherCondition

keep idnum *Health wave ch* asthma anemia heartDisease depression diabetes limb seizures otherCondition limit absent doc* healthIndex absent_self
append using "${TEMPDATADIR}/health.dta"
save "${TEMPDATADIR}/health.dta", replace 

********************
* General
********************

order idnum wave
sort idnum wave
label var chHealth "Child health rated by primary caregiver"
label var moHealth "Mother health (self-report)"
label var faHealth "Father health (self-report)"

label define health 1 "Excellent" 2 "Very good" 3 "Good" 4 "Fair" 5 "Poor"
label define YESNO 0 "No" 1 "Yes"

label values chHealth moHealth faHealth health
label values asthma anemia heartDisease depression diabetes limb seizures otherCondition ///
	fever_respiratory food_digestiv eczema_skin diarrhea_colitis migraines ear_infection ///
	docInjuryAccident docIlness docReg docMedi docPlace limit chMediHI chPrivHI YESNO

save "${TEMPDATADIR}/health.dta", replace 


********************
* Regressions
********************
use "${TEMPDATADIR}/health.dta", clear
rename idnum id

merge 1:1 id wave using "${TEMPDATADIR}/household_FF.dta"
keep if _merge == 3
drop _merge

* Total eligibility
egen allMediHI = total(chMediHI), by(id)	// number of years covered by Medicaid in total

foreach wave in 9 15 {
	* Regressions
	gen chHealth_`wave' = chHealth if wave == `wave'	// child health in a year
	reg chHealth chMediHI if wave == `wave'		// current year coverage on current year health
	reg chHealth_`wave' allMediHI age gender if wave == `wave'	// total years coverage on health in a wave

	* As percentage of a standard deviation
	local beta_allMediHI_`wave' = _b[allMediHI]
	sum chHealth_`wave'
	local chHealth_`wave'_sd = r(sd)
	*di " Increases on average by " (`beta_allMediHI_15' / `chHealth_15_sd') " of a standard deviation"
	listcoef, help
}









/* Some regressions
reg chHealth chMediHI if wave == 9
listcoef, help
* A one year increase in allMediHI increases on average parent-rated health by 0.1880 (bStdY) standard devation

reg chHealth_15 allMediHI age gender if wave == 15
listcoef, help

* A one standard deviation increase in allMediHI (1.81 years) produces on average an increase of 0.12 (bStdX) in parent rated health
* A one year increase in Medicaid coverage (allMediHI) increases parent rated health by 0.12/1.81
* A one year increase in allMediHI increases on average parent-rated health by 0.0782 (bStdY) standard devation
*/






