* Project: 	MA Thesis
* Content:  Master file
* Author: 	Michelle Rosenberger
* Date: 	Nov 1, 2018

capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

************************************
* WORING DIRECTORIES AND GLOABL VARS
************************************
if "`c(username)'" == "michellerosenberger"  {
    global CODEDIR		"~/Development/MA/code"
}

* Simulated Eligibility Instrument
do "${CODEDIR}/FPL_threshold.do"                // OK
    display("Federal poverty line created.")
    display("Creates: PovertyLevels.dta")

do "${CODEDIR}/medicaidEligibility.do"          // OK
    display("Eligibility data created.")
    display("Creates: cutscombined.dta")

do "${CODEDIR}/CPS_household.do"                // In process
    display("CPS household data created.")
    display("Creates: cps.dta")

* do "${CODEDIR}/simulatedEligibility.do"         // In process
*   display("Instrument created.")

* Fragile families data household panel
do "${CODEDIR}/FF_prepareHH.do"
    display("Prepare FF household data created.")
    display("Creates: parents_Y0.dta - parents_Y15.dta")

do "${CODEDIR}/FF_household.do"
    display("FF household data created.")
    display("Creates: household_FF.dta")

* Fragile families outcome variables




* Combine


* 