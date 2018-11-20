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
global TABLEDIR         "${USERPATH}/output/tables"
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
rename incRatio    incRatio_FF

* AGE
rename  age age_m
gen     age_temp = age_m / 12
gen     age = int(age_temp)
drop    age_temp age_m

* STATE
gen statefip = . // as place holder for merge

* GENDER, MOTHER AGE, MOTHER RACE
foreach var in gender moAge moWhite moBlack moHispanic moOther moEduc {
    rename  `var' `var'_temp
    egen    `var' = max(`var'_temp), by(id) 
    drop    `var'_temp
}
gen female = . 
replace female = 1 if gender == 2
replace female = 0 if gender == 1
drop gender

* LABEL
label data              "Household structure FF"
label var year          "Year interview"
label var famSize       "No. of fam members"
label var hhSize        "No. of household members"
label var incRatio_FF   "Poverty ratio % from FF"
label var avgInc        "Family income"
label var hhInc         "Household income"
label var age           "Age child (years)"
label var female        "Child female"
label var wave          "Wave"
label var moAge         "Mother's age at birth"
label var moWhite       "Mother's race: White"
label var moBlack       "Mother's race: Black"
label var moHispanic    "Mother's race: Hispanic"
label var moOther       "Mother's race: Other"
label var moEduc        "Mother's education"
label var ratio_size    "Ratio hh size to family size"
label var statefip      "State of residence fips codes"

label define female 0 "Male" 1 "Female"
label values female female

order id wave year age famSize statefip female
sort id wave

* LIMIT SAMPLE
    * Drop if family didn't complete interview
    drop if year == .

    * Do with actual medi
    * Drop if not enough observations per person (min. 3 observations out of 6)
    gen observation = 1 if year != .
    bysort id: egen countMedi = count(observation)
    drop if countMedi < 3
    drop observation
    label var countMedi "No. of observations"

    * Drop if no income value
    drop if hhInc == .

    * Replace age in wave 0

    * If fam size missing impute ratio from previous wave (mostly if no wave 9)


tab year
drop chLiveMo moHH_size_c

* ONE observation per WAVE and ID
describe
save "${TEMPDATADIR}/household_FF.dta", replace

* Summary statistics
* Make family income in thousand
* Make child race
* tabstat famSize female female if wave == 0, columns(statistics)  statistics(mean sd min max)
sum famSize female avgInc moAge moWhite moBlack moHispanic moOther ///
moEduc countMedi if wave == 0

sutex famSize female avgInc moAge moWhite moBlack moHispanic moOther ///
moEduc countMedi if wave == 0, labels digits(2) nobs ///
title("Summary statistics Fragile Families") file("${TABLEDIR}/SumStat_Y0.tex") replace

/*
* ACTUAL ELIGIBILITY
* Merge Poverty levels for incRatio
merge m:1 year famSize statefip using "${CLEANDATADIR}/PovertyLevels.dta"
keep if _merge == 3
drop _merge
*/

* SIMULATED ELIGIBILITY
* Merge with simulated eligibility - how?

