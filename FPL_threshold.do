* Project: 	MA Thesis
* Content:  Create FPL for each year
* Author: 	Michelle Rosenberger
* Date: 	Oct 15, 2018

capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

/* Constructs poverty levels dataset for each year and state (1998-2017) 

Input datasets:
- FPL`year'.xlsx 			:	Federal poverty line    (1998 - 2017)

Output datasets:
- PovertyLevels.dta 		: 	statefip year famSize povLevel
*/

************************************
* WORING DIRECTORIES AND GLOABL VARS
************************************
global MYPATH     	    "/Users/michellerosenberger/Development/MA"
global DATARAW          "${MYPATH}/data/raw/FPL"
global CLEANDATADIR  	"${MYPATH}/data/clean"			// general
global TEMPDATADIR      "${MYPATH}/data/temp"			// general

*************************
* Poverty levels
*************************
clear all
set obs 1
gen state = ""
gen year = .
gen famSize = .
gen povLevel = .
save "${CLEANDATADIR}/PovertyLevels.dta", replace

forvalues year = 1998(1)2017 { 
    import excel "${DATARAW}/FPL`year'.xlsx", sheet("Sheet1") firstrow clear
    gen year = `year'
    reshape long FS, i(STATE) j(famSize)
    rename FS povLevel 
    rename STATE state
    order state year 
    append using "${CLEANDATADIR}/PovertyLevels.dta"
    save "${CLEANDATADIR}/PovertyLevels.dta", replace
}

* LABELS
replace state = "District of Columbia" if state == "D.C."
label variable state ""
label variable famSize "Family size"
label variable povLevel "Poverty level"
label data "Poverty levels 1998 - 2017"

*************************
* State
*************************
gen statefip = .
    replace statefip = 23	if state == "Maine"
    replace statefip = 33 	if state == "New Hampshire"
    replace statefip = 50 	if state == "Vermont"
    replace statefip = 25 	if state == "Massachusetts"
    replace statefip = 44 	if state == "Rhode Island"
    replace statefip = 9  	if state == "Connecticut"
    replace statefip = 36 	if state == "New York"
    replace statefip = 34 	if state == "New Jersey"
    replace statefip = 42 	if state == "Pennsylvania"
    replace statefip = 39 	if state == "Ohio"
    replace statefip = 18 	if state == "Indiana"
    replace statefip = 17 	if state == "Illinois"
    replace statefip = 26 	if state == "Michigan"
    replace statefip = 55 	if state == "Wisconsin"
    replace statefip = 27 	if state == "Minnesota"
    replace statefip = 19 	if state == "Iowa"
    replace statefip = 29 	if state == "Missouri"
    replace statefip = 38 	if state == "North Dakota"
    replace statefip = 46 	if state == "South Dakota"
    replace statefip = 31 	if state == "Nebraska"
    replace statefip = 20 	if state == "Kansas"
    replace statefip = 10 	if state == "Delaware"
    replace statefip = 24 	if state == "Maryland"
    replace statefip = 11 	if state == "District of Columbia"
    replace statefip = 51 	if state == "Virginia"
    replace statefip = 54 	if state == "West Virginia"
    replace statefip = 37 	if state == "North Carolina"
    replace statefip = 45 	if state == "South Carolina"
    replace statefip = 13 	if state == "Georgia"
    replace statefip = 12 	if state == "Florida"
    replace statefip = 21 	if state == "Kentucky"
    replace statefip = 47 	if state == "Tennessee"
    replace statefip = 1 	if state == "Alabama"
    replace statefip = 28 	if state == "Mississippi"
    replace statefip = 5 	if state == "Arkansas"
    replace statefip = 22 	if state == "Louisiana"
    replace statefip = 40 	if state == "Oklahoma"
    replace statefip = 48 	if state == "Texas"
    replace statefip = 30 	if state == "Montana"
    replace statefip = 16 	if state == "Idaho"
    replace statefip = 56 	if state == "Wyoming"
    replace statefip = 8 	if state == "Colorado"
    replace statefip = 35 	if state == "New Mexico"
    replace statefip = 4 	if state == "Arizona"
    replace statefip = 49 	if state == "Utah"
    replace statefip = 32 	if state == "Nevada"
    replace statefip = 53 	if state == "Washington"
    replace statefip = 41 	if state == "Oregon"
    replace statefip = 6 	if state == "California"
    replace statefip = 2 	if state == "Alaska"
    replace statefip = 15 	if state == "Hawaii"

drop state
drop if year == .

label var statefip 	"State of residence (FIPS) coding"
label var year      "Year"

*************************
* Save
*************************
save "${CLEANDATADIR}/PovertyLevels.dta", replace

