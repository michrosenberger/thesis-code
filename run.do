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
	global CODEDIR			"~/Development/MA/code"
	*global CODEDIR		"/Volumes/g_econ_department$/econ/biroli/geighei/code/medicaidGxE/thesis-code"
}

* ----------------------------- CPS DATA
* ----- YEAR 2017
do "${CODEDIR}/cpsmar2017.do"

* ----- YEAR 2018
do "${CODEDIR}/cpsmar2018.do"

* ----- COMBINE ALL CPS YEARS
do "${CODEDIR}/CPS_household.do"
    di("CPS household data created.")
    di("Data created: cps.dta")


* ----------------------------- INSTRUMENT
* ----- FEDERAL POVERTY LINE
do "${CODEDIR}/FPL_threshold.do"
    di("Federal poverty line created.")
    di("Data: PovertyLevels.dta")

* ----- ELIGIBILITY THRESHOLDS
do "${CODEDIR}/medicaidEligibility.do"
    di("Eligibility data created.")
    di("Data created: cutscombined.dta")


* ----- CREATE SIMULATED ELIGIBILITY
do "${CODEDIR}/simulatedEligibility.do"
   di("Instrument created.")

* ----------------------------- PREPARE FF DATA
* ----- PREPARE HH PANEL
do "${CODEDIR}/prepareHH_FF.do"
    di("FF household data prepared.")
    di("Data created: parents_Y0.dta - parents_Y15.dta")

* ----- PREPARE OUTCOME VARIABLES
do "${CODEDIR}/prepareHealth_FF.do"
    di("FF health data prepared.")
    di("Data created: prepareHealth.dta")

* ----- PREPARE STATES (RESTRICTED USE DATA)
do "${CODEDIR}/states_FF.do"
    di("FF states created.")
    di("Data created: states.dta")


* ----------------------------- CONSTRUCT VARS FF DATA
* ----- CONSTRUCT HH PANEL
do "${CODEDIR}/constructHH_FF.do"
    di("FF household data combined.")
    di("Data created: household_FF.dta")

* ----- CONSTRUCT OUTCOME VARIABLES
do "${CODEDIR}/constructHealth_FF.do"
    di("FF health data combined.")
    di("Data created: health.dta")



* ----------------------------- ANALYSIS
* ----- REGRESSIONS


* ----- MAPS
do "${CODEDIR}/maps.do"
    display("Maps created.")
    display("Output: *")