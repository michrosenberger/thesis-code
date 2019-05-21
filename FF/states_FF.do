* -----------------------------------
* Project:      MA Thesis
* Content:      Clean states
* Data:         Fragile families
* Author:       Michelle Rosenberger
* Date:         March 6, 2019
* -----------------------------------

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

* ----------------------------- SET WORKING DIRECTORIES
if "`c(username)'" == "michellerosenberger"  {
    global USERPATH     "~/Development/MA"
}

global RAWDATADIR	    "${USERPATH}/data/raw/FragileFamilies"
global CLEANDATADIR  	"${USERPATH}/data/clean"
global TEMPDATADIR  	"${USERPATH}/data/temp"
global CODEDIR          "${USERPATH}/code"


* ----------------------------- LOAD DATA
use "${RAWDATADIR}/rawData/contractcity6pub.dta", clear

keep idnum *stfips p6state_n

* ----------------------------- MISSING VALUES
foreach var in  m1stfips f1stfips m2stfips f2stfips m3stfips f3stfips ///
                m4stfips f4stfips m5stfips f5stfips p6state_n {
    replace `var' = . if `var' < 0                  // Missing
    replace `var' = . if `var' == 66 | `var' == 72  // Guam & Puerto Rico
}

* ----------------------------- MERGE
merge 1:m idnum using "${TEMPDATADIR}/health.dta", keepusing(moReport wave)

sort    idnum wave
order   idnum wave

* ----------------------------- NOTE
* If moReport == 0 the father report is used
* If moReport != 0 the mother report is used

* ----------------------------- REPORT USED DEPENDING ON WHERE CHILD LIVES
gen state = .

* ----- BASELINE (1)
replace state = m1stfips if moReport != 0 & wave == 0
replace state = f1stfips if moReport == 0 & wave == 0

* ----- WAVE 1  (2)
replace state = m2stfips if moReport != 0 & wave == 1
replace state = f2stfips if moReport == 0 & wave == 1

* ----- WAVE 3  (3)
replace state = m3stfips if moReport != 0 & wave == 3
replace state = f3stfips if moReport == 0 & wave == 3

* ----- WAVE 5  (4)
replace state = m4stfips if moReport != 0 & wave == 5
replace state = f4stfips if moReport == 0 & wave == 5

* ----- WAVE 9  (5)
replace state = m5stfips if moReport != 0 & wave == 9
replace state = f5stfips if moReport == 0 & wave == 9

* ----- WAVE 15 (6)
replace state = p6state_n if wave == 15


* ----------------------------- IMPUTE
* NOTE: If state in wave before and after the same impute the missing information
/* bysort idnum (wave) : replace state = state[_n-1] if state == . & state[_n-1] == state[_n+1] */


* ----------------------------- LABELS & SAVE
label var state "State of residence"
label values state fips
rename state statefip

keep idnum wave statefip 
save "${TEMPDATADIR}/states.dta", replace 

