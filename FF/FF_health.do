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

/* To-do
- Write programs
- Child health baseline with medical records?
- Mental health
- Health parents
- Physical health
- Accident
- Health behavior
*/

********************************************************************************
********************************** OUTCOMES  ***********************************
********************************************************************************

********************
* Baseline
********************
use "${RAWDATADIR}/00_Baseline/ffmombspv3.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/00_Baseline/ffdadbspv3.dta", nogen
keep idnum m1g1 f1g1
missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/parents_Y0.dta", keepusing(chLiveMo wave) nogen

rename 	m1g1 moHealth	// health mother
rename 	f1g1 faHealth	// health father
gen 	chHealth = .

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
gen chHealth = .
replace chHealth = m2b2 if chLiveMo != 2 	// mother + default
replace chHealth = f2b2 if chLiveMo == 2	// father

* Medicaid parents report
local int = 1
local num : word count mo fa
while `int' <= `num' {
	local parent    : word `int' of     mo  fa
	local letter    : word `int' of     m   f
	local int = `int' + 1

	gen chMediHI_`parent' 		= 0
	replace chMediHI_`parent' 	= 1 if `letter'2j3 == 1 & (`letter'2j3a == 2 | `letter'2j3a == 3)
	replace chMediHI_`parent'	= . if `letter'2j3 >= .
	gen chPrivHI_`parent'		= 0
	replace chPrivHI_`parent' 	= 1 if `letter'2j4 == 1 & (`letter'2j4a == 2 | `letter'2j4a == 3)
	replace chPrivHI_`parent'	= . if `letter'2j4 >= .
}

* Medicaid child
foreach healthins in chMediHI chPrivHI {
	gen `healthins' = .
	replace `healthins' = `healthins'_mo if chLiveMo != 2	// mother + default
	replace `healthins' = `healthins'_fa if chLiveMo == 2	// father
}
drop *_mo *_fa

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
gen chHealth = .
replace chHealth = m3b2 if chLiveMo != 2 	// mother + default
replace chHealth = f3b2 if chLiveMo == 2 	// father

* Medicaid parents report
local int = 1
local num : word count mo fa
while `int' <= `num' {
	local parent    : word `int' of     mo  fa
	local letter    : word `int' of     m   f
	local int = `int' + 1

	gen chMediHI_`parent' 		= 0
	replace chMediHI_`parent' 	= 1 if `letter'3j3 == 1 & (`letter'3j3a == 2 | `letter'3j3a == 3)
	replace chMediHI_`parent'	= . if `letter'3j3 >= .
	gen chPrivHI_`parent'		= 0
	replace chPrivHI_`parent' 	= 1 if `letter'3j4 == 1 & (`letter'3j4a == 2 | `letter'3j4a == 3)
	replace chPrivHI_`parent'	= . if `letter'3j4 >= .
}

* Medicaid child
foreach healthins in chMediHI chPrivHI {
	gen `healthins' = .
	replace `healthins' = `healthins'_mo if chLiveMo != 2	// mother + default
	replace `healthins' = `healthins'_fa if chLiveMo == 2	// father
}
drop *_mo *_fa

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
gen chHealth = .
replace chHealth = m4b2 if chLiveMo != 2 	// mother + default
replace chHealth = f4b2 if chLiveMo == 2 	// father

* Medicaid parents report
local int = 1
local num : word count mo fa
while `int' <= `num' {
	local parent    : word `int' of     mo  fa
	local letter    : word `int' of     m   f
	local int = `int' + 1

	gen chMediHI_`parent' 		= 0
	replace chMediHI_`parent' 	= 1 if `letter'4j3 == 1 & (`letter'4j3a == 2 | `letter'4j3a == 3)
	replace chMediHI_`parent'	= . if `letter'4j3 >= .
	gen chPrivHI_`parent'		= 0
	replace chPrivHI_`parent' 	= 1 if `letter'4j4 == 1 & (`letter'4j4a == 2 | `letter'4j4a == 3)
	replace chPrivHI_`parent'	= . if `letter'4j4 >= .
}

* Medicaid child
foreach healthins in chMediHI chPrivHI {
	gen `healthins' = .
	replace `healthins' = `healthins'_mo if chLiveMo != 2	// mother + default
	replace `healthins' = `healthins'_fa if chLiveMo == 2	// father
}
drop *_mo *_fa

keep idnum *Health wave ch*
append using "${TEMPDATADIR}/health.dta"
save "${TEMPDATADIR}/health.dta", replace 

********************
* Wave 9
********************
use "${RAWDATADIR}/04_Nine-Year Core/ff_y9_pub1.dta", clear
keep idnum p5h1 m5g1 f5g1 p5h13 p5h14
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

keep idnum *Health wave ch*
append using "${TEMPDATADIR}/health.dta"
save "${TEMPDATADIR}/health.dta", replace 

********************
* Wave 15
********************
use "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta", clear
keep idnum p6b1 p6h2 p6b31 p6b32
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

keep idnum *Health wave ch* 
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
label define health 1 "Excellent" 2 "Very good" 3 "Good" 4 "Fair" 5 "Poor"	// check that parents same
label values chHealth moHealth faHealth health

save "${TEMPDATADIR}/health.dta", replace 

rename idnum id

merge 1:1 id wave using "${TEMPDATADIR}/household_FF.dta"

* If no private and no medicaid
* reg chHealth chMediHI
* reg chHealth chMediHI if chPrivHI != 1 


