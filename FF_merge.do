* Project: 	MA Thesis
* Data: 	Fragile Families - Mothers
* Content: 	Analyze data FF Mothers
* Author: 	Michelle Rosenberger
* Date: 	Oct 1, 2018

capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 32767

************************************
* WORING DIRECTORIES AND GLOABL VARS
************************************
global USERPATH     	"/Users/michellerosenberger/Development/MA"
global RAWDATADIR		"${USERPATH}/data/raw/FragileFamilies"
global CLEANDATADIR 	"${MYPATH}/data/clean"		// general
global TEMPDATADIR  	"${MYPATH}/data/temp"		// general
global CODEDIR			"${USERPATH}/code"
global INFODIR		

*log using ${CODEDIR}/varsMother.log, replace 

************************************
* MERGE
************************************
use "${RAWDATADIR}/00_Baseline/ffmombspv3.dta", clear

merge 1:1 idnum using "${RAWDATADIR}/00_Baseline/ffdadbspv3.dta"
rename _merge _merge1

merge 1:1 idnum using "${RAWDATADIR}/01_One-Year Core/ffdad1ypv2.dta"
rename _merge _merge2

merge 1:1 idnum using "${RAWDATADIR}/01_One-Year Core/ffmom1ypv2.dta"
rename _merge _merge3

merge 1:1 idnum using "${RAWDATADIR}/02_Three-Year Core/ffmom3ypv2.dta"
rename _merge _merge4

merge 1:1 idnum using "${RAWDATADIR}/02_Three-Year Core/ffdad3ypv2.dta"
rename _merge _merge5

merge 1:1 idnum using "${RAWDATADIR}/03_Five-Year Core/ffmom5ypv1.dta"
rename _merge _merge6

merge 1:1 idnum using "${RAWDATADIR}/03_Five-Year Core/ffdad5ypv1.dta"
rename _merge _merge7

merge 1:1 idnum using "${RAWDATADIR}/04_Nine-Year Core/ff_y9_pub1.dta"
rename _merge _merge8

merge 1:1 idnum using "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta"
rename _merge _merge9

forvalues num = 1/9 {
	drop _merge`num'
}

// Label data set
order idnum mothid* fathid*
label data "FF - Mothers and fathers"

************************************
* IDENTIFICATION
************************************
codebook idnum		// mothid* fathid*

************************************
* CODE MISSING VALUES 
************************************
// Save all variables (except ID) in global macro
ds, has(type numeric)				// only numeric variables
global ALLVARIABLES = r(varlist)
macro list ALLVARIABLES				// show variables

foreach vars in $ALLVARIABLES {
	replace `vars' = .a if `vars' == -1 // refused
	replace `vars' = .b if `vars' == -2 // don't know
	replace `vars' = .c if `vars' == -3 // missing
	replace `vars' = .d if `vars' == -4 // multiple answers
	replace `vars' = .e if `vars' == -5 // not asked (not in survey version)
	replace `vars' = .f if `vars' == -6 // skipped
	replace `vars' = .g if `vars' == -7 // N/A
	replace `vars' = .h if `vars' == -8 // out-of-range
	replace `vars' = .i if `vars' == -9 // not in wave
	}
	
/* Numeric missing values are represented by large positive values.
The ordering is all nonmissing numbers < . < .a < .b < ... < .z
To exlude missing values,  ask whether the value is less than "."
list if age > 60 & age < . */

drop mothid* fathid*

save "${CLEANDATADIR}/parents.dta", replace


************************************
* SAVE VARS + LABELS
************************************
/*
descsave, list(order name varlab) keep(order name varlab) saving("${INFODIR}/parents.dta", replace)
use "${INFODIR}/parents.dta", clear
outsheet using "${INFODIR}/parents.txt", replace
shell rm "${INFODIR}/parents.dta"
*/





capture log close



