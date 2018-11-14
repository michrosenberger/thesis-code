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

** Simulated Eligibility Instrument
do "${CODEDIR}/FPL_threshold.do"
    display("Federal poverty line created.")
    display("Creates: PovertyLevels.dta")

do "${CODEDIR}/medicaidEligibility.do"
    display("Eligibility data created.")
    display("Creates: cutscombined.dta")

do "${CODEDIR}/CPS_household.do"
    display("CPS household data created.")
    display("Creates: cps.dta")

do "${CODEDIR}/simulatedEligibility.do"
   display("Instrument created.")


** Fragile families data household panel
do "${CODEDIR}/FF_prepareHH.do"
    display("Prepare FF household data created.")
    display("Creates: parents_Y0.dta - parents_Y15.dta")

do "${CODEDIR}/FF_household.do"
    display("FF household data created.")
    display("Creates: household_FF.dta")


** Fragile families outcome variables
do "${CODEDIR}/FF_health.do"
    display("FF health data created.")
    display("Creates: health.dta")

* School / teacher outcomes

** Combine


** Outcomes
do "${CODEDIR}/tables.do"
    display("Tables created.")
    display("Creates: *")

do "${CODEDIR}/maps.do"
    display("Maps created.")
    display("Creates: *")