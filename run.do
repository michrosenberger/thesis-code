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
global CODEDIR  "/Users/michellerosenberger/Development/MA/code"

* Simulated Eligibility Instrument
do "${CODEDIR}\FPL_thresholds.do"              // OK
    display("Federal poverty line created.")
    display("Creates PovertyLevels.dta")

do "${CODEDIR}\medicaidEligibility.do"          // OK
    display("Eligibility data created.")
    display("Creates cutscombined.dta")

do "${CODEDIR}\cps_households.do"               // In process
    display("CPS household data created.")
    display("Creates cps.dta")

do "${CODEDIR}\simulatedEligibility.do"         // In process
    display("Instrument created.")

* Fragile families data


* Combine


* 