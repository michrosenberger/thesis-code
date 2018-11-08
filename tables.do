* Project: 	    MA Thesis
* Content:      Create simulated eligbility instrument
* Author:       Thompson
* Adapted by: 	Michelle Rosenberger
* Date: 	    Nov 1, 2018


********************************************************************************
*********************************** PREAMBLE ***********************************
********************************************************************************

capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

if "`c(username)'" == "michellerosenberger"  {
    global MYPATH		"~/Development/MA"
}
global CLEANDATADIR  	"${MYPATH}/data/clean"
global TEMPDATADIR  	"${MYPATH}/data/temp"
global FIGUREDIR        "${MYPATH}/output/tables"


********************************************************************************
************************* TABLES SIMULATED ELIGIBILITY *************************
********************************************************************************

use "${CLEANDATADIR}/simulatedEligbility.dta", clear

gen simulatedElig100 = simulatedElig*100
gen Elig1998 = simulatedElig100 if year == 1998
gen Elig2018 = simulatedElig100 if year == 2018

label var Elig1998 "1998"
label var Elig2018 "2018"

* LAG YEARS
* GENERATE DIFFERENCE

* ssc install statastates
statastates, fips(statefip) nogenerate   // abbreviation for state

* Medicaid eligbility by year
eststo clear
estpost tabstat simulatedElig100, by(year) nototal
eststo
esttab . using "${FIGUREDIR}/simulatedEligbility_year.tex", replace ///
cells( mean(fmt(a3)) ) nonumber noobs nodepvars label  ///
title("Medicaid eligibility by year") nomtitles compress ///
addnotes("Based on March CPS data from 1998-2018.") 

* Medicaid eligbility by state and year
eststo clear
estpost tabstat Elig1998 Elig2018, by(state_abbrev) nototal
eststo
esttab . using "${FIGUREDIR}/simulatedEligbility_state.tex", replace label ///
nonumber cells("Elig1998(fmt(a3)) Elig2018(fmt(a3))") noobs nodepvars ///
title("Medicaid eligibility by state") nomtitles compress ///
addnotes("Based on March CPS data from 1998 and 2018.") 