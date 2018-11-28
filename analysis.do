* Project:      MA Thesis
* Content:      Health outcomes
* Data:         Fragile families
* Author:       Michelle Rosenberger
* Date:         November 7, 2018

********************************************************************************
*********************************** PREAMBLE ***********************************
********************************************************************************
capture log close
clear all
est clear
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

* Set working directories
if "`c(username)'" == "michellerosenberger"  {
    global USERPATH     "~/Development/MA"
}

global CLEANDATADIR  	"${USERPATH}/data/clean"
global TEMPDATADIR  	"${USERPATH}/data/temp"
global CODEDIR          "${USERPATH}/code"

********************************************************************************
********************************** Regressions *********************************
********************************************************************************

use "${TEMPDATADIR}/health.dta", clear
rename idnum id

merge 1:1 id wave using "${TEMPDATADIR}/household_FF.dta"
keep if _merge == 3
drop _merge

* Total eligibility
egen allMediHI = total(chMediHI), by(id)	// number of years covered by Medicaid in total
sum allMediHI 

foreach wave in 9 15 {
	* Regressions
	gen chHealth_`wave' = chHealth if wave == `wave'	// child health in a year
	reg chHealth chMediHI if wave == `wave'		// current year coverage on current year health
	reg chHealth_`wave' allMediHI age gender if wave == `wave'	// total years coverage on health in a wave

	* As percentage of a standard deviation
	local beta_allMediHI_`wave' = _b[allMediHI]
	sum chHealth_`wave'
	local chHealth_`wave'_sd = r(sd)
	*di " Increases on average by " (`beta_allMediHI_15' / `chHealth_15_sd') " of a standard deviation"
	listcoef, help
}









/* Some regressions
reg chHealth chMediHI if wave == 9
listcoef, help
* A one year increase in allMediHI increases on average parent-rated health by 0.1880 (bStdY) standard devation

reg chHealth_15 allMediHI age gender if wave == 15
listcoef, help

* A one standard deviation increase in allMediHI (1.81 years) produces on average an increase of 0.12 (bStdX) in parent rated health
* A one year increase in Medicaid coverage (allMediHI) increases parent rated health by 0.12/1.81
* A one year increase in allMediHI increases on average parent-rated health by 0.0782 (bStdY) standard devation
*/

