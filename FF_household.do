* Project:      MA Thesis
* Content:      HH structure FF
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
cd ${CODEDIR}

********************************************************************************
******************************* VARIABLES MERGE ********************************
********************************************************************************

* MERGE
use "${TEMPDATADIR}/parents_Y0.dta", clear
append using "${TEMPDATADIR}/parents_Y1.dta"
append using "${TEMPDATADIR}/parents_Y3.dta"
append using "${TEMPDATADIR}/parents_Y5.dta"
append using "${TEMPDATADIR}/parents_Y9.dta"
append using "${TEMPDATADIR}/parents_Y15.dta"

* RENAME
rename idnum       id
rename moYear      year
rename chFAM_size  famSize
rename chHH_size   hhSize
rename chAge       age
rename chGender    gender
rename chAvg_inc   avgInc
rename chHH_income hhInc

* AGE
rename age age_m
gen age_temp = age_m / 12
gen age = int(age_temp)
drop age_temp

* GENDER
rename gender gender_temp
egen gender = max(gender_temp), by(id) 
drop gender_temp

* LABEL
label data "Household structure FF"
label var year      "Year interview"
label var famSize   "Number of family members in hh"
label var hhSize    "Number of hh members"
label var incRatio  "Poverty ratio % (FF)"
label var avgInc    "Avg. hh income"
label var hhInc     "Household income"
label var age       "Age child (years)"
label var age_m     "Age child (months)"
label var gender    "Gender cild"
label var wave      "Wave"

order id wave year age famSize gender
sort id wave


tab year
describe

drop age_m

* ONE observation per WAVE and ID
save "${TEMPDATADIR}/household_FF.dta", replace


/* NOTES:
- Limit obersvations per person
- Drop those that year == .
- Label variables
*/




/* ----------------------------- NOT USED

/* Constructed variables
cm1relf     hh relationship mother */


/*
** Merge poverty levels
* no statefip in this data
merge m:1  year famSize statefip using "${CLEANDATADIR}/PovertyLevels.dta"
keep if _merge == 3
drop _merge
*/
