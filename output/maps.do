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
global CODEDIR          "${USERPATH}/code"

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

************************************
* % of eligible children per state
************************************

* Prepare simulated eligibility data
foreach year in 1998 2018 {
	use "${CLEANDATADIR}/simulatedEligbility.dta", clear
	keep if year == `year'
	collapse simulatedElig, by(statefip)			// mean (highest?)
	replace simulatedElig = simulatedElig * 100		// in percent
	rename simulatedElig simulatedElig`year'
	rename statefip statefips
	save "${CLEANDATADIR}/Elig`year'.dta", replace
}

merge 1:1 statefips using "${CLEANDATADIR}/Elig1998.dta", nogen
save  "${CLEANDATADIR}/Elig1998_2018.dta", replace

* Maps
maptile_install using "http://files.michaelstepner.com/geo_state.zip"	// load US map

do "${CODEDIR}/output/maps_labels.do"	// center state names

merge 1:1 statefips using "${CLEANDATADIR}/Elig1998_2018.dta", nogen // simulated Elig. data

* Generate break data
gen break2 = .
replace break2 = 25 if _ID == 26
replace break2 = 30 if _ID == 27
replace break2 = 40 if _ID == 1
replace break2 = 50 if _ID == 2
replace break2 = 60 if _ID == 3
replace break2 = 70 if _ID == 4
replace break2 = 71 if _ID == 5

foreach year in 1998 2018 {
	maptile simulatedElig`year', geo(state) geoid(statefips) fcolor( Blues2) ///
	spopt( label(xcoord(xcoord) ycoord(ycoord) label(state) ) legstyle(2) legjunction(" to ") ///
	legend(pos(5)) legtitle("% of children") line(data(line_data))) ///
	legformat(%4.0f) cutp(break2) 
	graph export "${FIGUREDIR}/MapElig`year'.pdf", replace
}

/*
* With labels for legend and state count
maptile simulatedElig2018, geo(state) geoid(statefips) fcolor(YlOrRd) ///
spopt( label(xcoord(xcoord) ycoord(ycoord) label(state)) legstyle(2) ///
legend( pos(5) label(2 "34.2-40.6% (9 states)") label(3 "40.6-42.1% (8 states)")) ///
line(data(line_data)) legtitle("% of children") legcount) legformat(%4.1f) 
*/

* To-do
* make comparable - same color patterns for both graphs
* clmethod(custom) doesn't work
* Maybe also do by age groups
* For note() NOTE: FPL... SOURCE: ...
* Title: Elgibility for Medicaid/CHIP by Income as % of the FPL
* Delete individual eligibility


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
	rename statefip statefips
	rename cut cut`year'

	save "${CLEANDATADIR}/maxFPL`year'.dta", replace
}

merge 1:1 statefips using "${CLEANDATADIR}/maxFPL1998.dta", nogen
save "${CLEANDATADIR}/maxFPL1998_2018.dta", replace

do "${CODEDIR}/output/maps_labels.do"	// center state names

merge 1:1 statefips using "${CLEANDATADIR}/maxFPL1998_2018.dta", nogen // data

foreach year in 1998 2018 {
	maptile cut`year', geo(state) geoid(statefips) fcolor(YlOrRd) ///
	spopt( label(xcoord(xcoord) ycoord(ycoord) label(state) ) legstyle(2) legend(pos(5)) legtitle("% of FPL") line(data(line_data)) ) legformat(%4.0f) 
	graph export "${FIGUREDIR}/MapFPL`year'.pdf", replace
}

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



