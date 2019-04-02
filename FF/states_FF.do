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

keep idnum *stfips

* ----------------------------- MISSING VALUES
foreach var in m1stfips f1stfips m2stfips f2stfips m3stfips f3stfips m4stfips f4stfips m5stfips f5stfips {
    replace `var' = . if `var' < 0 
}

* ----------------------------- MERGE
merge 1:m idnum using "${TEMPDATADIR}/health.dta", keepusing(chLiveMo wave)

sort idnum wave
order idnum wave

* Make loop
* Wave 15
* Check everything correctly

* ----------------------------- REPORT USED DEPENDING ON WHERE CHILD LIVES
gen state = .

* ----- BASELINE (1)
replace state = m1stfips if chLiveMo != 2 & wave == 0 	// mother + default
replace state = f1stfips if chLiveMo == 2 & wave == 0	// father


* ----- WAVE 1 (2)
replace state = m2stfips if chLiveMo != 2 & wave == 1	// mother + default
replace state = f2stfips if chLiveMo == 2 & wave == 1   // father


* ----- WAVE 3 (3)
replace state = m3stfips if chLiveMo != 2 & wave == 3	// mother + default
replace state = f3stfips if chLiveMo == 2 & wave == 3   // father


* ----- WAVE 5 (4)
replace state = m4stfips if chLiveMo != 2 & wave == 5	// mother + default
replace state = f4stfips if chLiveMo == 2 & wave == 5   // father


* ----- WAVE 9 (5)
replace state = m5stfips if chLiveMo != 2 & wave == 9	// mother + default
replace state = f5stfips if chLiveMo == 2 & wave == 9   // father


* ----- WAVE 15
* NOTE: Take state in which lived when age 9
replace state = state[_n-1] if wave == 15
* Check where it is and if not take from wave 15


* ----------------------------- LABELS & SAVE
label var state "State of residence"
label values state fips

keep idnum wave state 
save "${TEMPDATADIR}/states.dta", replace 


