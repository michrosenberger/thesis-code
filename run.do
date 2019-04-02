* -----------------------------------
* Project: 	MA Thesis
* Content:  Runs everything
* Author: 	Michelle Rosenberger
* Date: 	Nov 1, 2018
* -----------------------------------

capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

* ----------------------------- WORING DIRECTORIES AND GLOABL VARS
if "`c(username)'" == "michellerosenberger"  {
    global CODEDIR		"~/Development/MA/code"
}


* ----------------------------- INSTRUMENT
* ----- FEDERAL POVERTY LINE
do "${CODEDIR}/FPL_threshold.do"
    di("Federal poverty line created.")
    di("Output: PovertyLevels.dta")

* ----- 
do "${CODEDIR}/medicaidEligibility.do"
    di("Eligibility data created.")
    di("Output: cutscombined.dta")

* -----
do "${CODEDIR}/CPS_household.do"
    di("CPS household data created.")
    display("Output: cps.dta")

* -----
do "${CODEDIR}/simulatedEligibility.do"
   di("Instrument created.")

* ----------------------------- FF OUTCOME VARIABLES
* ----- PREPARE
do "${CODEDIR}/prepareHealth_FF.do"
    di("FF health data prepared.")
    di("Output: prepareHealth.dta")

* ----- COMBINE
do "${CODEDIR}/constructHealth_FF.do"
    di("FF health data combined.")
    di("Output: health.dta")

* ----------------------------- FF STATES (RESTRICTED USE DATA)
* ----- STATES
do "${CODEDIR}/FF_states.do"
    di("FF states created.")
    di("Output: states.dta")


* ----------------------------- FF HOUSEHOLD PANEL
* ----- 
do "${CODEDIR}/prepareHH_FF.do"
    di("FF household data prepared.")
    di("Output: parents_Y0.dta - parents_Y15.dta")

* ----- 
do "${CODEDIR}/constructHH_FF.do"
    di("FF household data combined.")
    di("Output: household_FF.dta")




* ----------------------------- ANALYSIS
* ----- REGRESSIONS


* ----- ROBUSTNESS CHECKS


* ----------------------------- OUTCOMES
* ----- TABLES
do "${CODEDIR}/tables.do"
    display("Tables created.")
    display("Output: *")

* ----- MAPS
do "${CODEDIR}/maps.do"
    display("Maps created.")
    display("Output: *")