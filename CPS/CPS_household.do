* -----------------------------------
* Project: 	MA Thesis
* Content:	Create CPS households
* Author: 	Michelle Rosenberger
* Date: 	Oct 1, 2018
* -----------------------------------
capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

/* This code ...

* ----- INPUT DATASETS:
cepr_march_`year'.dta (1998 - 2016); cpsmar`year'_clean.dta (2017 - 2018);
PovertyLevels.dta

* ----- OUTPUT DATASETS:
cps.dta (year age statefip incRatio) */

* ---------------------------------------------------------------------------- *
* --------------------------------- PREAMBLE --------------------------------- *
* ---------------------------------------------------------------------------- *

* ----------------------------- WORKING DIRECTORIES AND GLOABL VARS
if "`c(username)'" == "michellerosenberger"  {
    global MYPATH		"~/Development/MA"
}
global RAWDATADIR		"${MYPATH}/data/raw/MarchCPS"
global CODEDIR			"${MYPATH}/code"
global CLEANDATADIR  	"${MYPATH}/data/clean"
global TEMPDATADIR  	"${MYPATH}/data/temp"


* ----------------------------- SWITCHES
global MERGEDATA		= 0			// MERGE DATA (TIME CONSUMING!)


* ---------------------------------------------------------------------------- *
* ----------------------------------- DATA ----------------------------------- *
* ---------------------------------------------------------------------------- *
* ----------------------------- IMPORT DATA
if ${MERGEDATA} == 1 {

	use "${RAWDATADIR}/cepr_march_1997.dta", clear
	foreach year of numlist 1998(1)2016 {
		qui append using "${RAWDATADIR}/cepr_march_`year'.dta", force
	}
	foreach year of numlist 2017(1)2018 {
		qui append using "${TEMPDATADIR}/cpsmar`year'_clean.dta", force
	}

	keep famno pfrel hhseq female age race year incp_wag incp_uc incp_se ///
	incp_cs incp_alm incp_ssi incp_ss incp_vet incp_wcp state gestfips hins ///
	hipriv hipub hiep hipind himcaid himcc hischip pvcfam incf_all pvlfam ///
	educ educ2 educ92

	save "${TEMPDATADIR}/cps_1997-2018.dta", replace

}

use "${TEMPDATADIR}/cps_1997-2018.dta", clear

* ----------------------------- FAMILY STRUCTURE CPS
/* CONDITIONS: PRIMARY FAMILY MEMBER (famno == 1);
NO OTHER RELATIVE (pfrel == 4);CHILD (pfrel == 3 & age < 18) */

keep if famno == 1
drop if pfrel == 4
drop if pfrel == 3 & age > 18

bysort hhseq year : gen husband_temp 	= 1 	if pfrel == 1
bysort hhseq year : egen husband 		= count(husband_temp)

bysort hhseq year : gen wife_temp 		= 1		if pfrel == 2
bysort hhseq year : egen wife 			= count(wife_temp)

bysort hhseq year : gen child_temp 		= 1		if pfrel == 3
bysort hhseq year : egen numChild 		= count(child_temp)

gen child1 = child_temp
replace child1 = 0 if child1 == .

bysort hhseq year : gen unmarried_temp 	= 1 	if pfrel == 5
bysort hhseq year : egen unmarried 		= count(unmarried_temp)

* ----- DROP IF NO CHILDREN
drop if numChild == 0
drop *_temp

* ----- FAMILY SIZE
gen famSize = husband + wife + numChild + unmarried

* ----- LABELS
label var child1		"Child indicator in family"
label var numChild		"Number of children in family"
label var husband		"Husband indicator in family"
label var wife			"Wife indicator in family"
label var unmarried		"Unmarried parent indicator in family"
label var famSize		"Family size"

label define husband 	1 "husband in fam" 			0 "no husband in fam"
label define wife		1 "wife in fam"				0 "no wife in fam"
label define child1		1 "child"					0 "no child"
label define unmarried	1 "unmarried head in fam"	0 "no unmarried head in fam"

label values husband husband
label values wife wife
label values child1 child1
label values unmarried unmarried

* ----------------------------- COHORT
gen moCohort_temp = .
gen faCohort_temp = .
gen chCohort_temp = .

replace moCohort_temp = year - age if female == 1 & (pfrel == 2 | pfrel == 5)
replace faCohort_temp = year - age if female == 0 & (pfrel == 1 | pfrel == 5)
replace chCohort_temp = year - age if pfrel == 3

bysort hhseq year : egen moCohort = max(moCohort_temp)
bysort hhseq year : egen faCohort = max(faCohort_temp)
bysort hhseq year : egen chCohort = max(chCohort_temp)

* ----------------------------- PARENTS EDUCATION
gen moCollege_temp = educ == 3 & female == 1 & (pfrel == 2 | pfrel == 5) // some college
gen faCollege_temp = educ == 3 & female == 0 & (pfrel == 1 | pfrel == 5) // some college

bysort hhseq year : egen moCollege = max(moCollege_temp)
bysort hhseq year : egen faCollege = max(faCollege_temp)

* ----------------------------- INCOME
* ----- PERSONAL INCOME
if year < 2014 {
	* BEFORE MAGI: Wages, salaries (incp_wag), Unemployment compensation (incp_uc),
	* Self-employment (incp_se), Child support (incp_cs), Alimony received (incp_alm),
	* SSI (incp_ssi), Social security / railroadS(incp_ss), Veteran payments (incp_vet),
	* Workers compensation (incp_wcp)

	gen persInc = incp_wag + incp_uc + incp_se + incp_cs + incp_alm + incp_ssi ///
	+ incp_ss + incp_vet + incp_wcp
}
if year >= 2014 {
	* MAGI: Wages, salaries (incp_wag), Unemployment compensation (incp_uc),
	* Self-employment (incp_se), Alimony received (incp_alm)

	gen persInc = incp_wag + incp_uc + incp_se + incp_alm
}

* ----- FAMILY INCOME
* NOTE: ONLY INCLUDES PARENT INCOME
gen tempInc = persInc if (pfrel == 1 | pfrel == 2 | pfrel == 5)	
bysort hhseq year: egen famInc = sum(tempInc)
drop tempInc

label var persInc	"Personal income"
label var famInc	"Family income"

rename child1 child

* ----------------------------- RACE
rename wbho race
gen chWhite 		= race == 1
gen chBlack 		= race == 2
gen chHispanic 		= race == 3
gen chOther 		= race == 4

* ----------------------------- STATES
decode state, gen(state2)
statastates, fips(gestfips) nogen
replace state2 = state_name   if state2 == ""
drop state_abbrev state_name

statastates, name(state2) nogen
rename state_fips 	statefip 
drop state2 state_abbrev state gestfips

* ----------------------------- HEALTH COVERAGE
rename hins		healthIns	// Health Ins.
rename hipriv	healthPriv	// Health Ins., private
rename hipub	healthPubl	// Health Ins., public
rename hiep		healthEmp	// Health Ins., Employer-provided (private)
rename himcaid	healthMedi	// Health Ins., Medicaid
rename himcc 	childMedi	// Child covered by Medicaid
rename hischip 	childCHIP	// Child covered by SCHIP

* ----------------------------- MERGE POVERTY LEVELS
merge m:1 year famSize statefip using "${CLEANDATADIR}/PovertyLevels.dta"
keep if _merge == 3
drop _merge

* ----------------------------- INCOME RATIO
* Divide CPS famInc by poverty line based on fam size and composition
gen incRatio = famInc / povLevel
label var incRatio	"Family poverty level"

drop incp_* incf_all pvlfam persInc

* ----------------------------- SUBSAMPLE
* drop if chCohort < 1998 & chCohort>=2000
* keep if moCohort >=1955 & moCohort<=1985

* ----------------------------- SAVE
label data 			"CPS March data 1998-2018"

* ----- KEEP ONLY CHILDREN
keep if pfrel == 3

* ----- SAVE
keep year age statefip incRatio health* child* ch* *Cohort famSize female *College
save "${TEMPDATADIR}/cps.dta", replace







* ---------------------------------------------------------------------------- *
* --------------------------------- NOT USED --------------------------------- *
* ---------------------------------------------------------------------------- *

// * ----------------------------- UNIQUE IDENTIFIERS
// * Unique identifiers
// egen serial = group(hhseq year)				// identifier for each HH
// bysort hhseq year : gen pernum = _n			// person number inside HH
// drop hhseq
// order year serial pernum

// label var serial 	"Unique identifier for each hh"
// label var pernum 	"Unique person identifier inside hh"

// * ----------------------------- SUBSAMPLE
// * Mirrors FF composition (by mother)

// * Mother cohort between 1955 and 1985 in FF
// gen 	typeFF_temp = 0
// replace typeFF_temp = 1 if pfrel == 2 & 				(moCohort>=1955 & moCohort<=1985) // wife
// replace typeFF_temp = 1 if pfrel == 5 & female == 1 & 	(moCohort>=1955 & moCohort<=1985) // unmarried head (female)

// bysort serial year : egen typeFF = max(typeFF_temp)
// drop typeFF_temp

// * What happens with missing
// * Mother race
// gen moRace_temp = race if (pfrel == 2 | pfrel == 5) & female == 1

// bysort serial year : egen moRace = max(moRace_temp)
// drop moRace_temp

// gen moWhite_temp		= white 	if (pfrel == 2 | pfrel == 5)	& female == 1
// bysort serial year : egen moWhite = max(moWhite_temp)

// * Age mother at birth between 15 and 43 years old in FF
// // gen momCohort_temp = moCohort	if (pfrel == 2 | pfrel == 5) & female == 1
// // bysort serial year : egen momCohort = min(momCohort_temp)
// // gen momGeb = moCohort - momCohort
// // tab momGeb
// // drop if momGeb < 15 | momGeb > 43
// // drop momCohort_temp

// * ----- KEEP FLAGGED HH
// * keep if typeFF == 1


// * ----------------------------- PROPSENSITY SCORE MATCHING
// * ----- DUMMY INDICATING CPS DATA
// gen FF = 0

// * ----- MERGE WITH FF BASELINE VARIABLES
// append using "${TEMPDATADIR}/parents_Y0.dta", keep(incRatio moRace moCohort famSize)
// // rename moAge momGeb
// replace FF = 1 if FF == .

// * ----- PERFORM PSM
// psmatch2 FF famSize incRatio moCohort, n(10) common 

// sum famSize moCohort incRatio if FF == 1
// sum famSize moCohort incRatio if FF == 0
// sum famSize moCohort incRatio if FF == 0 & _weight != .

// keep if _weight != .

