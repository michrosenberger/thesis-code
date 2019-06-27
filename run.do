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
	// global CODEDIR		"/Volumes/g_econ_department$/econ/biroli/geighei/code/medicaidGxE/thesis-code"
}

* ----------------------------- FEDERAL POVERTY LINE
do "${CODEDIR}/Eligibility/FPL_threshold.do"
    di("Federal poverty line created.")
    di("Data: PovertyLevels.dta")


* ----------------------------- CPS DATA
* ----- YEAR 2017
do "${CODEDIR}/CPS/cpsmar2017.do"

* ----- YEAR 2018
do "${CODEDIR}/CPS/cpsmar2018.do"

* ----- COMBINE ALL CPS YEARS
do "${CODEDIR}/CPS/CPS_household.do"
    di("CPS household data created.")
    di("Data created: cps.dta")


* ----------------------------- INSTRUMENT
* ----- ELIGIBILITY THRESHOLDS
do "${CODEDIR}/Eligibility/medicaidEligibility.do"
    di("Eligibility data created.")
    di("Data created: cutscombined.dta")

* ----- CREATE SIMULATED ELIGIBILITY
// do "${CODEDIR}/Eligibility/simulatedEligbility.do"
//    di("Instrument created.")


* ----------------------------- FFCWS DATA
* ----- PREPARE HH PANEL
do "${CODEDIR}/FF/prepareHH_FF.do"
    di("FF household data prepared.")
    di("Data created: parents_Y0.dta - parents_Y15.dta")

* ----- PREPARE OUTCOME VARIABLES
do "${CODEDIR}/FF/prepareHealth_FF.do"
    di("FF health data prepared.")
    di("Data created: prepareHealth.dta")

* ----- CONSTRUCT OUTCOME VARIABLES
do "${CODEDIR}/FF/constructHealth_FF.do"
    di("FF health data combined.")
    di("Data created: health.dta")

* ----- PREPARE STATES (RESTRICTED USE DATA)
do "${CODEDIR}/FF/states_FF.do"
    di("FF states created.")
    di("Data created: states.dta")

* ----- PREPARE GENETIC DATA (RESTRICTED USE DATA)
do "${CODEDIR}/FF/genetic_FF.do"
    di("FF genetic data created.")
    di("Data created: genetic.dta")


* ----- CONSTRUCT HH PANEL
do "${CODEDIR}/FF/constructHH_FF.do"
    di("FF household data combined.")
    di("Data created: household_FF.dta")


* ----------------------------- ANALYSIS
* ----- REGRESSIONS
do "${CODEDIR}/analysis.do"
    display("Analysis performed.")

* ----- MAPS
do "${CODEDIR}/output/maps.do"
    display("Maps created.")

