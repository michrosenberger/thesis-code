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
global RAWDATADIR  		"${MYPATH}/data/raw"
global CLEANDATADIR  	"${MYPATH}/data/clean"
global TEMPDATADIR  	"${MYPATH}/data/temp"
global TABLEDIR         "${MYPATH}/output/tables"
global FIGUREDIR        "${MYPATH}/output/figures"

/*
* Install packages
ssc install spmap
ssc install shp2dta
ssc install mif2dta
ssc install geo2xy
ssc install maptile
*/
********************************************************************************
************************** MAPS SIMULATED ELIGIBILITY **************************
********************************************************************************

/* New approach
maptile_install using "http://files.michaelstepner.com/geo_state.zip"	// US map
destring statefips , replace
maptile simulatedElig , geo(state) geoid(statefip) fcolor(YlOrRd) nq(4)
*/

* Prepare map
cd "${RAWDATADIR}/cb_2017_us_state_20m/"
shp2dta using cb_2017_us_state_20m, database(US_database) coordinates(US_coordinates) genid(id) replace
use US_database, clear
describe
list id STATEFP NAME in 1/5

************************************
* % of eligible children per state
************************************

* Prepare simulated eligibility data
foreach year in 1998 2018 {
	use "${CLEANDATADIR}/simulatedEligbility.dta", clear

	keep if year == `year'
	sort statefip age
	collapse simulatedElig, by(statefip)			// mean (highest?)
	replace simulatedElig = simulatedElig * 100		// in percent
	rename statefip STATEFP

	* Make data compatible
	tostring STATEFP, replace
	forvalues num = 1/9 {
		replace STATEFP = "0`num'" if STATEFP == "`num'"
	}
	save "${CLEANDATADIR}/Elig`year'.dta", replace
}

* Merge database map and eligibility data (with same colors)
cd "${RAWDATADIR}/cb_2017_us_state_20m/"
foreach year in 1998 2018 {
	use "${CLEANDATADIR}/Elig`year'.dta", clear 
	merge 1:1 STATEFP using US_database

	drop if _merge!=3
	format simulatedElig %4.0f

	* Graph
	spmap simulatedElig using US_coordinates if NAME!="Alaska" & NAME!="Hawaii", id(id) ///
	fcolor(YlOrRd) clmethod(custom) clbreaks(20 25 30 35 40 50 60 70 80) ///
	legstyle(2) legend(pos(7)) legtitle("% of children")
	graph export "${FIGUREDIR}/MapElig`year'.pdf", replace
}

************************************
* % of FPL threshold per state
************************************

* FPL data
foreach year in 1998 2018 {
	use "${CLEANDATADIR}/cutscombined.dta", clear

	gen cut = .
	replace cut = medicut 	if medicut >= schipcut
	replace cut = schipcut 	if schipcut >= medicut
	replace cut = cut * 100 		// in percentage of FPL

	keep if year == `year'
	collapse (max) cut, by(statefip)		// max % covered
	rename statefip STATEFP

	* Make data compatible
	tostring STATEFP, replace
	forvalues num = 1/9 {
		replace STATEFP = "0`num'" if STATEFP == "`num'"
	}
	save "${CLEANDATADIR}/maxFPL`year'.dta", replace
}

* Merge database map and eligibility data (with same colors)
cd "${RAWDATADIR}/cb_2017_us_state_20m/"
foreach year in 1998 2018 {
	use "${CLEANDATADIR}/maxFPL`year'.dta", clear 
	merge 1:1 STATEFP using US_database

	drop if _merge!=3
	format cut %4.0f

	* Graph
	spmap cut using US_coordinates if NAME!="Alaska" & NAME!="Hawaii", id(id) ///
	fcolor(YlOrRd) clmethod(custom) clbreaks(100 150 200 250 300 350 400 450) ///
	legstyle(2) legend(pos(7) size(medsmall)) legtitle("% of FPL line") 
	graph export "${FIGUREDIR}/MapFPL`year'.pdf", replace
}

* To-do
* Label legend: % eligible 	// legend: < 200% of FPL (4 States)
* Maybe also do by age groups
* How to add labels for the states: need X and Y coordiantes
* For note() NOTE: FPL... SOURCE: ...
* Title: Elgibility for Medicaid/CHIP by Income as % of the FPL


********************************************************************************
************************* MEDIAN SIMULATED ELIGIBILITY *************************
********************************************************************************

use "${CLEANDATADIR}/simulatedEligbility.dta", clear
order statefip year age
sort statefip year age
label var year "Year"

* Median for each year
egen median_states = median(simulatedElig), by(year)
label var median_states "Median % of eligible children"
*  graph query, schemes
scatter median_states year, connect(L) msymbol(D) //scheme(s1mono)

* Median for each year by age group

