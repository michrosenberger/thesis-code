* Project: 	MA Thesis
* Content: 	Simulated eligbility instrument
* Author: 	Thompson, 2018
* Adapted:  Michelle Rosenberger
* Date:     October 17, 2018

capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

/* This code merges the data for the eligibility criteria. 

Input datasets:
- cutoff.dta 				:	Currie & Decker data 		(1986 - 2005)
- KFFTranscriptions.xlsx	:	Thompson KFF data			(2006 - 2011)
- KFFTranscriptions_M.xlsx 	:	Own transcripts of KFF data (2012 - 2018)

Output datasets:
- cutscombined.dta 			: 	statefip year age medicut schipcut bpost1983 cut
*/

************************************
* WORING DIRECTORIES AND GLOABL VARS
************************************
if "`c(username)'" == "michellerosenberger"  {
    global MYPATH		"~/Development/MA"
}
global RAWDATA      	"${MYPATH}/data/MedicaidDataPost/RawData"
global MYDATA       	"${MYPATH}/data/raw/KFF"
global CLEANDATADIR  	"${MYPATH}/data/clean"
global TEMPDATADIR  	"${MYPATH}/data/temp"


************************************
* Currie & Decker data
************************************
* 1986 - 2005	(from Thompson)

use "${RAWDATA}/cutoff.dta", clear 
gen bpost1983 = birthyear > 1983
collapse medicut schipcut, by(statefip year age bpost1983) 
reshape wide medicut schipcut, i(state year  bpost1983) j(age) 
gen medicut18 	= medicut17
gen schipcut18 	= schipcut17
reshape long medicut schipcut, i(state year  bpost1983) j(age)
save "${CLEANDATADIR}/cutscombined.dta", replace


************************************
* KFF data
************************************
* 2006 - 2018	(from Thompson)

* Import own transcriptions of KFF reports
import excel "${MYDATA}/KFFTranscriptions_M.xlsx", sheet("sheet1") firstrow clear
save "${TEMPDATADIR}/KFFTranscriptions_M.dta", replace

* Import Thompson transcripts of KFF reports & merge both datasets
import excel "${RAWDATA}/KFFTranscriptions.xlsx", sheet("sheet1") firstrow clear

merge 1:1 statefip using "${TEMPDATADIR}/KFFTranscriptions_M.dta", label
drop _merge

expand 	13
bysort 	statefip : 		egen year=seq(), from(2006) to(2018)
expand 	19
bysort 	statefip year : egen age=seq(), from(0) to(18)
gen 	medicut 	= .
gen 	schipcut 	= .


foreach year of numlist 2006/2018 {
	replace medicut 	= zero_`year' 		if year==`year' & age==0
	replace medicut 	= oneto5_`year' 	if year==`year' & (age>=1 & age<=5)
	replace medicut 	= sixplus_`year'	if year==`year' & age>=6
	replace schipcut	= CHIP_`year'		if year==`year'
}

replace medicut 	= medicut / 100
replace schipcut 	= schipcut / 100

keep statefip year age medicut schipcut
gen bpost1983 = 1

append using "${CLEANDATADIR}/cutscombined.dta"

keep if year >= 1998

************************************
* LABELS
************************************
label var statefip 	"State of residence (FIPS) coding"
label var year		"Year"
label var age		"Age"
label var medicut	"Medicaid threshold"
label var schipcut	"S-CHIP threshold"
label var bpost1983	"Child born after 1983"

save "${CLEANDATADIR}/cutscombined.dta", replace		// data 1995-2018