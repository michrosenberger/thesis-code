* -----------------------------------
* Project: 	MA Thesis
* Content: 	Prepare Simulated Eligbility
* Author: 	Thompson, 2018
* Adapted:  Michelle Rosenberger
* Date:     October 17, 2018
* -----------------------------------

/* This code merges the data for the eligibility criteria. 

Input datasets:
- cutoff.dta 				:	Currie & Decker data 	 (1986 - 2005)
- KFFTranscriptions.xlsx	:	Thompson KFF data		 (2006 - 2011)
- KFFTranscriptions_M.xlsx 	:	Own transcripts KFF data (2012 - 2018)

Output datasets:
- cutscombined.dta 			: 	statefip year age medicut schipcut bpost1983
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


* ---------------------------------------------------------------------------- *
* ------------------------------- ELIGIBILITY -------------------------------- *
* ---------------------------------------------------------------------------- *

* ----------------------------- CURRIE & DECKER DATA (YEARS: 1986 - 2005)
* SOURCE: THOMPSON

use "${RAWDATADIRTHOMPSON}/cutoff.dta", clear 
gen bpost1983 	= birthyear > 1983
collapse medicut schipcut, by(statefip year age bpost1983) 

reshape wide medicut schipcut, i(statefip year bpost1983) j(age) 
	gen medicut18 	= medicut17
	gen schipcut18 	= schipcut17
reshape long medicut schipcut, i(state year  bpost1983) j(age)

save "${CLEANDATADIR}/cutscombined.dta", replace


* ----------------------------- KFF data (YEARS: 2006 - 2018)
* SOURCE: THOMPSON

* ----- IMPORT OWN TRANSCRIPTS (KFF REPORTS)
import excel "${RAWDATADIRKFF}/KFFTranscriptions_M.xlsx", sheet("sheet1") firstrow clear
save "${TEMPDATADIR}/KFFTranscriptions_M.dta", replace

* ----- IMPORT THOMPSON TRANSCRIPTS (KFF REPORTS)
import excel "${RAWDATADIRTHOMPSON}/KFFTranscriptions.xlsx", sheet("sheet1") firstrow clear

* ----- MERGE ALL KFF REPROTS
merge 1:1 statefip using "${TEMPDATADIR}/KFFTranscriptions_M.dta", label nogen

expand 	13
bysort 	statefip		: egen year = seq(), from(2006) to(2018)
expand 	19
bysort 	statefip year 	: egen age = seq(), from(0) to(18)

gen medicut		= .
gen schipcut 	= .

foreach year of numlist 2006(1)2018 {
	replace medicut 	= zero_`year' 		if year == `year' & (age == 0)
	replace medicut 	= oneto5_`year' 	if year == `year' & (age >= 1 & age <= 5)
	replace medicut 	= sixplus_`year'	if year == `year' & (age >= 6)
	replace schipcut	= CHIP_`year'		if year == `year'
}

replace medicut 	= medicut / 100
replace schipcut 	= schipcut / 100

keep statefip year age medicut schipcut
gen bpost1983 = 1

append using "${CLEANDATADIR}/cutscombined.dta"

keep if year >= 1998

* ----- LABELS & SAVE
label var statefip 	"State of residence (FIPS) coding"
label var year		"Year"
label var age		"Age"
label var medicut	"Medicaid threshold"
label var schipcut	"S-CHIP threshold"
label var bpost1983	"Child born after 1983"

save "${CLEANDATADIR}/cutscombined.dta", replace		// data 1998-2018

