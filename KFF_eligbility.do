* Project: 	MA Thesis
* Content: 	Simulated eligbility instrument
* Author: 	Thompson, 2018
* Adapted:  Michelle Rosenberger
* Date:     October 17, 2018

/* This code ...

*/

********************************************************************************
*********************************** PREAMBLE ***********************************
********************************************************************************

clear all
set more off

global MYPATH     	"/Users/michellerosenberger/Development/MA"  
global RAWDATA      "${MYPATH}/data/MedicaidDataPost/RawData"
global TEMPDATA     "${MYPATH}/data/KFF/temp1"
global MYDATA       "${MYPATH}/data/KFF/raw"
global OUTPUTDIR	"${MYPATH}/output"
global FIGUREDIR	"${OUTPUTDIR}/figures"
global TABLEDIR		"${OUTPUTDIR}/tables"

********************************************************************************
***************************** ELIGIBILITY CRITERIA *****************************
********************************************************************************

***********************
* Currie & Decker data
***********************
* 1986 - 2005

use "${RAWDATA}/cutoff.dta", clear 
g bpost1983=birthyear>1983
collapse (mean) medicut schipcut, by(statefip year age bpost1983) 
reshape wide medicut schipcut, i(state year  bpost1983) j(age) 
g medicut18=medicut17
g schipcut18=schipcut17
reshape long medicut schipcut, i(state year  bpost1983) j(age)
save "${TEMPDATA}/cutscombined", replace


***********************
* Prepare KFF data
***********************
* 2006 - 2018

* Import own transcriptions of KFF reports
import excel "${MYDATA}/KFFTranscriptions_M.xlsx", sheet("sheet1") firstrow clear
save "${TEMPDATA}/KFFTranscriptions_M", replace

* Import Thompson transcripts of KFF reports & merge both datasets
import excel "${RAWDATA}/KFFTranscriptions.xlsx", sheet("sheet1") firstrow clear

merge 1:1 statefip using "${TEMPDATA}/KFFTranscriptions_M.dta", label
drop _merge

expand 13
bysort statefip: egen year=seq(), from(2006) to(2018)
expand 19
bysort statefip year: egen age=seq(), from(0) to(18)
gen medicut = .
gen schipcut = .


foreach year of numlist 2006/2018 {
replace medicut=zero_`year' if year==`year' & age==0
replace medicut=oneto5_`year' if year==`year' & (age>=1 & age<=5)
replace medicut=sixplus_`year' if year==`year' & age>=6
replace schipcut=CHIP_`year' if year==`year'
}

replace medicut = medicut / 100
replace schipcut = schipcut / 100

keep statefip year age medicut schipcut
g bpost1983=1

append using "${TEMPDATA}/cutscombined"
save "${TEMPDATA}/cutscombined", replace

collapse medicut schipcut, by(year age statefip) 

foreach state of numlist 1(1)56 {
	foreach age of numlist 0(1)18 {
		quietly capture line medicut schipcut year if (statefip == `state' & age == `age'), ///
		title("Medicaid and CHIP cutoff") subtitle("State `state', age `age'")
		capture graph export "${FIGUREDIR}/cut_state`state'_age`age'.pdf", replace
	}
}

egen cut=rowmax(medicut schipcut)

scatter medicut schipcut cut year

* State-year-age simulated eligibility 2006-2018

********************************************************************************
*********************************** CPS DATA ***********************************
********************************************************************************
