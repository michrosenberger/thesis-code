/* Constructs poverty levels dataset for each year and state (1998-2017) */

global DATARAW      "/Users/michellerosenberger/Development/MA/data/POVLEVEL/raw"
global DATACLEAN    "/Users/michellerosenberger/Development/MA/data/POVLEVEL/clean"

/*
Mothers eligbility criteria
*/

*************************
* Poverty levels
*************************
clear all
set obs 1
gen state = ""
gen year = .
gen famSize = .
gen povLevel = .
save "${DATACLEAN}/PovertyLevels.dta", replace

forvalues year = 1998(1)2017 { 
    import excel "${DATARAW}/FPL`year'.xlsx", sheet("Sheet1") firstrow clear
    gen year = `year'
    reshape long FS, i(STATE) j(famSize)
    rename FS povLevel 
    rename STATE state
    order state year 
    append using "${DATACLEAN}/PovertyLevels.dta"
    save "${DATACLEAN}/PovertyLevels.dta", replace
}

label variable state ""
label variable famSize "Family size"
label variable povLevel "Poverty level"
label data "Poverty levels 1998 - 2017"
save "${DATACLEAN}/PovertyLevels.dta", replace