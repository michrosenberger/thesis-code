* -----------------------------------
* Project: 	MA Thesis
* Content:  Create FPL for each year
* Author: 	Michelle Rosenberger
* Date: 	Oct 15, 2018
* -----------------------------------

capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

/* Constructs poverty levels dataset for each year and state (1997-2018) 

Input datasets:
- FPL`year'.xlsx 			:	Federal poverty line    (1997-2018)

Output datasets:
- PovertyLevels.dta 		: 	statefip year famSize povLevel
*/

* ssc install statastates

* ----------------------------- WORKING DIRECTORIES AND GLOABL VARS
if "`c(username)'" == "michellerosenberger"  {
    global MYPATH		"~/Development/MA"
}
global DATARAW          "${MYPATH}/data/raw/FPL"
global CLEANDATADIR  	"${MYPATH}/data/clean"
global TEMPDATADIR      "${MYPATH}/data/temp"

* ----------------------------- POVERTY LEVELS
clear all
set obs 1
gen state       = ""
gen year        = .
gen famSize     = .
gen povLevel    = .
save "${CLEANDATADIR}/PovertyLevels.dta", replace

forvalues year = 1997(1)2018 { 
    import excel "${DATARAW}/FPL`year'.xlsx", sheet("Sheet1") firstrow clear
    gen year = `year'
    reshape long FS, i(STATE) j(famSize)
    rename FS povLevel 
    rename STATE state
    order state year 
    append using "${CLEANDATADIR}/PovertyLevels.dta"
    save "${CLEANDATADIR}/PovertyLevels.dta", replace
}

* ----- LABELS
replace state = "District of Columbia" if state == "D.C."
label variable state ""
label variable famSize "Family size"
label variable povLevel "Poverty level"
label data "Poverty levels 1997 - 2018"

drop if year == .

* ----------------------------- STATE
statastates, name(state) nogenerate   // gen statefips
rename state_fips       statefip
rename state            state_name

label var statefip 	    "State of residence fips codes"
label var state_name 	"State of residence abbreviation"
label var state_abbrev 	"State of residence name"
label var year          "Year"

order year famSize povLevel state_abbrev state_name statefip


* ----------------------------- SAVE
save "${CLEANDATADIR}/PovertyLevels.dta", replace

