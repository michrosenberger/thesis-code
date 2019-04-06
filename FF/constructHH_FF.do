* -----------------------------------
* Project:      MA Thesis
* Content:      HH structure FF
* Data:         Fragile families
* Author:       Michelle Rosenberger
* Date:         November 7, 2018
* -----------------------------------

/* This code combines all the waves and constructs the necessary variables
for the household structure in the Fragile Families data.

Input datasets (TEMPDATADIR):
parents_Y0.dta; parents_Y1.dta; parents_Y3.dta; parents_Y5.dta;
parents_Y9.dta; parents_Y15.dta; states.dta

Output datasets (TEMPDATADIR):
household_FF.dta
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
global TABLEDIR         "${USERPATH}/output/tables"

cd ${CODEDIR}

* ---------------------------------------------------------------------------- *
* ------------------------------ VARIABLES MERGE ----------------------------- *
* ---------------------------------------------------------------------------- *

* ----------------------------- MERGE
use "${TEMPDATADIR}/parents_Y0.dta", clear
append using "${TEMPDATADIR}/parents_Y1.dta"
append using "${TEMPDATADIR}/parents_Y3.dta"
append using "${TEMPDATADIR}/parents_Y5.dta"
append using "${TEMPDATADIR}/parents_Y9.dta"
append using "${TEMPDATADIR}/parents_Y15.dta"

* ----------------------------- RENAME
rename moYear      year
rename chFAM_size  famSize
rename chHH_size   hhSize
rename chAge       age
rename chGender    gender
rename chAvg_inc   avgInc
rename chHH_income hhInc
rename incRatio    incRatio_FF

* ----------------------------- AGE
rename  age age_m
gen     age_temp = age_m / 12
gen     age = int(age_temp)
drop    age_temp age_m

* ----------------------------- MERGE STATE (RESTRICTED USE DATA)
merge 1:1 idnum wave using "${TEMPDATADIR}/states.dta", nogen
rename state statefip

* ----------------------------- GENDER, RACE, MOTHER AGE, MOTHER RACE
foreach var in gender moAge moWhite moBlack moHispanic moOther moEduc ///
chBlack chHispanic chOther chMulti chWhite chRace {
    rename  `var' `var'_temp
    egen    `var' = max(`var'_temp), by(idnum) 
    drop    `var'_temp
}

recode gender (2 = 1) (1 = 0)
rename gender female
tab female

rename chRace race

* ----------------------------- FAM INCOME IN THOUSANDS
replace avgInc = avgInc / 1000

* ----------------------------- LABEL
label data              "Household structure FF"
label var year          "Year interview"
label var famSize       "Family members"
label var hhSize        "No. of household members"
label var incRatio_FF   "Poverty ratio from FF"
label var avgInc        "Family income (in 1'000 USD)"
label var hhInc         "Household income"
label var age           "Age child (years)"
label var female        "Female"
label var wave          "Wave"
label var chWhite       "White"
label var chBlack       "Black"
label var chHispanic    "Hispanic"
label var chOther       "Other race"
label var chMulti       "Mutli-racial"
label var moAge         "Mother's age at birth"
label var moEduc        "Mother's education"
label var moCohort      "Mother's birth year"
label var ratio_size    "Ratio hh size to family size"
label var statefip      "State of residence fips codes"

label define female 0 "Male" 1 "Female"
label values female female


* ----------------------------- SAVE
* NOTE: ONE observation per WAVE and ID
order idnum wave year age famSize statefip female
sort idnum wave

describe
save "${TEMPDATADIR}/household_FF.dta", replace


