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

/* Input datasets:
- cps                   : age statefip (year) incRatio
- cutscombined          : age statefip year medicut schipcut bpost1983

Output datasets:
- simulatedEligbility   : age statefip year simelig */

* ----------------------------- WORKING DIRECTORIES AND GLOABL VARS
if "`c(username)'" == "michellerosenberger"  {
    global MYPATH		"~/Development/MA"
}
global CLEANDATADIR  	"${MYPATH}/data/clean"
global TEMPDATADIR  	"${MYPATH}/data/temp"

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
            qui use "${CLEANDATADIR}/cps.dta" if age == `age' , clear

            * Use all states, except for the state in question
            qui drop if statefip == `state'
            qui drop statefip

            qui gen bpost1983   = `year' - `age' > 1983

            * Create obs for state & year in question
            qui gen statefip    = `state'
            qui gen year        = `year'

            qui merge m:1 statefip year age bpost1983 using "${CLEANDATADIR}/cutscombined.dta", norep
            qui keep if _merge == 3
            qui gen simulatedElig = incRatio <= medicut | incRatio <= schipcut

            qui collapse (mean) simulatedElig, by(statefip year age)
            qui append using "${CLEANDATADIR}/simulatedEligbility.dta"
            qui save "${CLEANDATADIR}/simulatedEligbility.dta", replace
        }
    }
}

