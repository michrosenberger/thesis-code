* -----------------------------------
* Project: 	MA Thesis
* Content:  Create FPL for each year
* Author: 	Michelle Rosenberger
* Date: 	Oct 15, 2018
* -----------------------------------

/* Constructs poverty levels dataset for each year and state (1997-2018) 

Input datasets:
- FPL`year'.xlsx 			:	Federal poverty line    (1997-2018)

Output datasets:
- PovertyLevels.dta 		: 	statefip year famSize povLevel
*/

* ---------------------------------------------------------------------------- *
* --------------------------------- PREAMBLE --------------------------------- *
* ---------------------------------------------------------------------------- *
capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

* ----------------------------- WORKING DIRECTORIES AND GLOABL VARS
if "`c(username)'" == "michellerosenberger"  {
	global CODEDIR		"~/Development/MA/code"
	*global CODEDIR		"/Volumes/g_econ_department$/econ/biroli/geighei/code/medicaidGxE/thesis-code"
}

do "${CODEDIR}/setDirectories.do"

* ----------------------------- SWITCHES
global PROGRAMS = 0			// Install the packages

* ----------------------------- INSTALL PACKAGES
if ${PROGRAMS} == 1 {
    ssc install statastates
}

* ---------------------------------------------------------------------------- *
* ------------------------------ POVERTY LEVELS ------------------------------ *
* ---------------------------------------------------------------------------- *

* ----------------------------- POVERTY LEVELS
* ----- CREATE EMPTY DATASET
set obs 1
gen state       = ""
gen year        = .
gen famSize     = .
gen povLevel    = .
save "${CLEANDATADIR}/PovertyLevels.dta", replace

* ----- INSERT DATA
forvalues year = 1997(1)2018 { 
    import excel "${RAWDATADIRFPL}/FPL`year'.xlsx", sheet("Sheet1") firstrow clear
    gen year = `year'
    reshape long FS, i(STATE) j(famSize)
    rename FS povLevel 
    rename STATE state
    order state year 
    append using "${CLEANDATADIR}/PovertyLevels.dta"
    save "${CLEANDATADIR}/PovertyLevels.dta", replace
}

* ----- CLEAN DATA
replace state = "District of Columbia" if state == "D.C."
drop if year == .

statastates, name(state) nogen
rename state_fips       statefip
rename state            state_name

* ----- LABELS
label data "Poverty levels 1997 - 2018"

label var year          "Year"
label var famSize       "Family size"
label var povLevel      "Poverty level"
label var statefip 	    "State of residence fips codes"
label var state_name 	"State of residence abbreviation"
label var state_abbrev 	"State of residence name"

* ----------------------------- SAVE
order year famSize povLevel state_abbrev state_name statefip
sort year famSize statefip

save "${CLEANDATADIR}/PovertyLevels.dta", replace

