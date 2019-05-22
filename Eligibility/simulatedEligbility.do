* -----------------------------------
* Project: 	    MA Thesis
* Content:      Create Simulated Eligbility
* Author:       Thompson
* Adapted by:   Michelle Rosenberger
* Date: 	    Nov 1, 2018
* -----------------------------------
capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

/* This code ...

* ----- INPUT DATASETS:
cps.dta (age statefip (year) incRatio);
cutscombined.dta (age statefip year medicut schipcut bpost1983)

* ----- OUTPUT DATASETS:
simulatedEligbility.dta (age statefip year simelig) */

* ---------------------------------------------------------------------------- *
* --------------------------------- PREAMBLE --------------------------------- *
* ---------------------------------------------------------------------------- *
* ----------------------------- WORKING DIRECTORIES AND GLOABL VARS
if "`c(username)'" == "michellerosenberger"  {
    global MYPATH		"~/Development/MA"
}
global CLEANDATADIR  	"${MYPATH}/data/clean"
global TEMPDATADIR  	"${MYPATH}/data/temp"


* ---------------------------------------------------------------------------- *
* -------------------------------- INSTRUMENT -------------------------------- *
* ---------------------------------------------------------------------------- *
* ----------------------------- CREATE SIMULATED INSTRUMENT
* ----- CREATE EMPTY DATASET
foreach var in statefip year age {
    gen `var' = .
}
save "${CLEANDATADIR}/simulatedEligbility.dta", replace


* ----- POPULATE DATASET WITH INFORMATION
use "${CLEANDATADIR}/cutscombined.dta", clear
levelsof statefip, local(states)

foreach age of numlist 0(1)18 {
    foreach state of local states {
        foreach year of numlist 1998(1)2018 {
            di "* ----- Age: `age', Year: `year', State: `state'"
            qui use "${CLEANDATADIR}/cps.dta" if age == `age', clear
            keep age state incRatio

            * ----- USE ALL STATES, EXCEPT FOR THE STATE IN QUESTION
            qui drop if statefip == `state'
            qui drop statefip

            qui gen bpost1983   = `year' - `age' > 1983

            * ----- CREATE OBS FRO STATE & YEAR IN QUESTION
            qui gen statefip    = `state'
            qui gen year        = `year'

            * ----- COMPARE ELIGIBILITY THRESHOLDS
            qui merge m:1 statefip year age bpost1983 using "${CLEANDATADIR}/cutscombined.dta", norep
            qui keep if _merge == 3
            qui gen simulatedElig = incRatio <= medicut | incRatio <= schipcut

            qui collapse (mean) simulatedElig, by(statefip year age)
            qui append using "${CLEANDATADIR}/simulatedEligbility.dta"
            qui save "${CLEANDATADIR}/simulatedEligbility.dta", replace
        }
    }
}


