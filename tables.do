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
global TABLEDIR         "${MYPATH}/output/tables"

* ssc install statastates

********************************************************************************
************************* TABLES SIMULATED ELIGIBILITY *************************
********************************************************************************

use "${CLEANDATADIR}/simulatedEligbility.dta", clear

gen simulatedElig100 = simulatedElig*100
gen Elig1998 = simulatedElig100 if year == 1998
gen Elig2018 = simulatedElig100 if year == 2018
statastates, fips(statefip) nogenerate   // abbreviation for state
save "${TEMPDATADIR}/simulatedElig100.dta", replace

collapse Elig1998 Elig2018, by(state_name)
gen Diff = Elig2018 - Elig1998
label var Elig1998 "1998"
label var Elig2018 "2018"
save "${TEMPDATADIR}/DiffElig.dta", replace


* Medicaid eligbility by year
use "${TEMPDATADIR}/simulatedElig100.dta", clear
eststo clear
estpost tabstat simulatedElig100, by(year) nototal
eststo
esttab . using "${TABLEDIR}/simulatedEligbility_year.tex", replace ///
cells( mean(fmt(a3)) ) nonumber noobs nodepvars label  ///
title("Medicaid eligibility by year") nomtitles compress collabels(none) ///
addnotes("Based on March CPS data" "from 1998-2018.") mlabels("\% eligible \\ Year & children")

* Medicaid eligbility by state and year
use "${TEMPDATADIR}/DiffElig.dta", clear
eststo clear
estpost tabstat Elig1998 Elig2018 Diff, by(state_name) nototal
eststo
esttab . using "${TABLEDIR}/simulatedEligbility_state.tex", replace label ///
nonumber cells("Elig1998(fmt(a3) label(1998)) Elig2018(fmt(a3) label(2018)) Diff(fmt(a3) label(Diff))") noobs ///
title("Medicaid eligibility by state") compress ///
addnotes("Based on March CPS data from 1998 and 2018.") longtable nomtitle
