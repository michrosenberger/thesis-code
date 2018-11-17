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
rename  age age_m
gen     age_temp = age_m / 12
gen     age = int(age_temp)
drop    age_temp age_m

* GENDER
foreach var in gender moAge moWhite moBlack moHispanic moOther {
    rename  `var' `var'_temp
    egen    `var' = max(`var'_temp), by(id) 
    drop    `var'_temp
}


* LABEL
label data              "Household structure FF"
label var year          "Year interview"
label var famSize       "Number of family members in hh"
label var hhSize        "Number of hh members"
label var incRatio      "Poverty ratio % (FF)"
label var avgInc        "Avg. hh income"
label var hhInc         "Household income"
label var age           "Age child (years)"
label var gender        "Gender cild"
label var wave          "Wave"
label var moAge         "Age mother"
label var moWhite       "Mother white (race)"
label var moBlack       "Mother black (race)"
label var moHispanic    "Mother hispanic (race)"
label var moOther       "Mother other (race)"

order id wave year age famSize gender
sort id wave

* LIMIT SAMPLE
    * Drop if family didn't complete interview
    drop if year == .

    * Drop if not enough observations per person (min. 3 observations out of 6)
    gen observation = 1 if year != .
    bysort id: egen countObs = count(observation)
    drop if countObs < 3
    drop observation
    label var countObs "Number of observation per child"

    * Drop if no income value

    * Replace age in wave 0


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
