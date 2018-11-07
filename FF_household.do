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

do FF_prepareHH.do  // prepare data

use "${TEMPDATADIR}/parents_Y0.dta", clear
append using "${TEMPDATADIR}/parents_Y1.dta"
append using "${TEMPDATADIR}/parents_Y3.dta"
append using "${TEMPDATADIR}/parents_Y5.dta"
* WAVE 9
* WAVE 15

label data "Household structure FF"

rename idnum       id
rename moYear      year
rename chFAM_size  famSize
rename chHH_size   hhSize
rename chAge       age
rename chGender    gender
rename chAvg_inc   avgInc
rename chHH_income hhInc

order id wave year age famSize
sort id wave

label var year      "Year interview"
label var famSize   "Number of family members in hh"
label var hhSize    "Number of hh members"
label var incRatio  "Poverty ratio % (FF)"
label var avgInc    "Avg. hh income"
label var hhInc     "Household income"
label var age       "Age child (months)"
label var gender    "Gender cild"
label var wave      "Wave"

tab year
describe

* ONE observation per WAVE and ID
save "${TEMPDATADIR}/household_FF.dta", replace




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
