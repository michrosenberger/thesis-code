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


capture program drop missingvalues
program define missingvalues
	ds, has(type numeric)
	global ALLVARIABLES = r(varlist)

	foreach vars in $ALLVARIABLES {
		replace `vars' = .a if `vars' == -1 // refused
		replace `vars' = .b if `vars' == -2 // don't know
		replace `vars' = .c if `vars' == -3 // missing
		replace `vars' = .d if `vars' == -4 // multiple answers
		replace `vars' = .e if `vars' == -5 // not asked (not in survey version)
		replace `vars' = .f if `vars' == -6 // skipped
		replace `vars' = .g if `vars' == -7 // N/A
		replace `vars' = .h if `vars' == -8 // out-of-range
		replace `vars' = .i if `vars' == -9 // not in wave
		replace `vars' = .j if `vars' == -10 // jail
		replace `vars' = .k if `vars' == -12 // Shelter/Street 
		}
end

********************************************************************************
********************************** OUTCOMES  ***********************************
********************************************************************************

********************
* Baseline
********************
use "${RAWDATADIR}/00_Baseline/ffmombspv3.dta", clear
keep idnum

gen health = .
gen wave = 0
keep idnum health wave
save "${TEMPDATADIR}/health.dta", replace 

********************
* Wave 1
********************
use "${RAWDATADIR}/01_One-Year Core/ffmom1ypv2.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/01_One-Year Core/ffdad1ypv2.dta"
keep idnum m2a3 m2a4a *2b2
missingvalues	// recode missing values

* Child living arr.
gen 	chLiveMo = .
replace chLiveMo = 1 if (m2a3 == 1 | m2a3 == 2)	// wave 1
replace chLiveMo = 2 if (m2a3 != 1 & m2a3 != 2 & m2a4a == 1) // wave 1

* Health youth by parents
gen health = .
replace health = m2b2 if chLiveMo == 1          // mother
replace health = f2b2 if chLiveMo == 2                     // father
replace health = m2b2 if (chLiveMo != 1 & chLiveMo != 2)    // default

gen wave = 1
keep idnum health wave
append using "${TEMPDATADIR}/health.dta"
save "${TEMPDATADIR}/health.dta", replace 

********************
* Wave 3
********************
use "${RAWDATADIR}/02_Three-Year Core/ffmom3ypv2.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/02_Three-Year Core/ffdad3ypv2.dta"
keep idnum m3a2 m3a3a *3b2
missingvalues	// recode missing values

* Child living arr.
gen 	chLiveMo = .
replace chLiveMo = 1 if (m3a2 == 1 | m3a2 == 2)	// wave 1
replace chLiveMo = 2 if (m3a2 != 1 & m3a2 != 2 & m3a3a == 1) // wave 1

* Health
gen health = .
replace health = m3b2 if chLiveMo == 1          // mother
replace health = f3b2 if chLiveMo == 2                     // father
replace health = m3b2 if (chLiveMo != 1 & chLiveMo != 2)    // default

gen wave = 3
keep idnum health wave
append using "${TEMPDATADIR}/health.dta"
save "${TEMPDATADIR}/health.dta", replace 

********************
* Wave 5
********************
use "${RAWDATADIR}/03_Five-Year Core/ffmom5ypv1.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/03_Five-Year Core/ffdad5ypv1.dta"
keep idnum m4a2 m4a3a2 *4b2
missingvalues	// recode missing values

* Child living arr.
gen 	chLiveMo = .
replace chLiveMo = 1 if (m4a2 == 1 | m4a2 == 2)	// wave 1
replace chLiveMo = 2 if (m4a2 != 1 & m4a2 != 2 & m4a3a2 == 1) // wave 1

* Health
gen health = .
replace health = m4b2 if chLiveMo == 1          // mother
replace health = f4b2 if chLiveMo == 2                     // father
replace health = m4b2 if (chLiveMo != 1 & chLiveMo != 2)    // default

gen wave = 5
keep idnum health wave
append using "${TEMPDATADIR}/health.dta"
save "${TEMPDATADIR}/health.dta", replace 

********************
* Wave 9
********************
use "${RAWDATADIR}/04_Nine-Year Core/ff_y9_pub1.dta", clear
keep idnum p5h1
missingvalues	// recode missing values

rename p5h1 health

gen wave = 9
keep idnum health wave
append using "${TEMPDATADIR}/health.dta"
save "${TEMPDATADIR}/health.dta", replace 


********************
* Wave 15
********************
use "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta", clear
keep idnum p6b1
missingvalues	// recode missing values

rename p6b1 health

gen wave = 15
keep idnum health wave
append using "${TEMPDATADIR}/health.dta"

order idnum wave
sort idnum wave
label var health "Child health rated by primary caregiver"
label define health 1 "Excellent" 2 "Very good" 3 "Good" 4 "Fair" 5 "Poor"
label values health health

save "${TEMPDATADIR}/health.dta", replace 


* Find Medicaid questions

