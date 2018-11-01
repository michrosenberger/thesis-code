* Project: 	MA Thesis
* Content:  Create simulated eligbility instrument
* Author: 	Michelle Rosenberger
* Date: 	Nov 1, 2018

capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

/*
Input datasets:
- cps :           age statefip incRatio
- cutscombined :  age statefip year medicuat schipcut bpost1983

Output datasets:
- simulatedEligbility : VARAIBLES HERE

Note:
- Thompson uses CPS data from 1980 - 1999, but does not use years but all observations combined */

************************************
* WORING DIRECTORIES AND GLOABL VARS
************************************
global MYPATH       "/Users/michellerosenberger/Development/MA"
global TEMPDIR  	"${MYPATH}/data/clean"
global CLEANDIR  	"${MYPATH}/data/temp"

// log using ${CODEDIR}/CPS.log, replace 

************************************
* CREATE SIMULATED INSTRUMENT
************************************
foreach var in statefip year age {  // create new dataset
    gen `var' = .
}
save "${CLEANDIR}/simulatedEligbility.dta", replace


use "${CLEANDIR}/cutscombined.dta", clear     // combine all datasets
levelsof statefip, local(states)
forvalues year = 1998/2016 {
    forvalues age = 0/18 {
        foreach state of local states {
            di "Age: `age', Year: `year', State: `state'"
            use "${CLEANDIR}/cps.dta" if age == `age', clear
            drop if statefip==`s'
            drop statefip
            gen bpost1983 = `year' - `age' > 1983
            gen statefip    = `state'
            gen year        = `year'

            merge m:1 statefip year age bpost1983 using cutscombined
            keep if _merge == 3
            gen simulatedElig = incRatio < = cut
            collapse simulatedElig, by(statefip year age)  // fraction by state, year and age
            append using "${CLEANDIR}/simulatedEligbility.dta"
            save "${CLEANDIR}/simulatedEligbility.dta", replace
        }
    }
}
