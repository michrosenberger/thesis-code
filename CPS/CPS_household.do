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

/* Input datasets:
- cepr_march_`year'.dta		:	CPS March data 	(1998 - 2016)
- cpsmar`year'_clean.dta	:	CPS March data 	(2017 - 2018)
- PovertyLevels.dta 		:  	Poverty levels	(1997 - 2018)

Output datasets:
- cps.dta 					:	year age statefip incRatio */

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
global MERGEDATA		= 0			// merge data - time consuming

* ----------------------------- LOG FILE
* log using ${CODEDIR}/CPS_household.log, replace 

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
/* Conditions: Primary family member, not other relative and child
not older than 18 in family unit */

keep if famno == 1				// primary family member
drop if pfrel == 4				// other relative
drop if pfrel == 3 & age > 18	// child younger than 18

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

drop if numChild == 0	// drop if no children
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


* ----------------------------- PARENTS COHORT
gen moCohort_temp = .
replace moCohort_temp = year - age if female == 1 & (pfrel == 2 | pfrel == 5)
bysort hhseq year : egen moCohort = max(moCohort_temp)

gen faCohort_temp = .
replace faCohort_temp = year - age if female == 0 & (pfrel == 1 | pfrel == 5)
bysort hhseq year : egen faCohort = max(faCohort_temp)

drop *_temp

* ----------------------------- INCOME
if year < 2014 {
	/* Previous Medicaid eligibility
	Wages, salaries (incp_wag),
	Unemployment compensation (incp_uc), Self-employment (incp_se),
	Child support (incp_cs), Alimony received (incp_alm), SSI (incp_ssi),
	Social security / railroads (incp_ss), Veteran payments (incp_vet),
	Workers compensation (incp_wcp) */

	gen persInc = incp_wag + incp_uc + incp_se + incp_cs + incp_alm + incp_ssi ///
	+ incp_ss + incp_vet + incp_wcp
}
if year >= 2014 {			// MAGI
	/* MAGI
	Wages, salaries (incp_wag), Unemployment compensation (incp_uc),
	Self-employment (incp_se), Alimony received (incp_alm) */

	gen persInc = incp_wag + incp_uc + incp_se + incp_alm
}

* NOTE: famInc income only includes parents income
gen tempInc = persInc if (pfrel == 1 | pfrel == 2 | pfrel == 5)	
bysort hhseq year: egen famInc = sum(tempInc)
drop tempInc

label var persInc	"Personal income"
label var famInc	"Family income"

rename child1 child

* ----------------------------- RACE
rename wbho race
gen white 		= race == 1
gen black 		= race == 2
gen hispanic 	= race == 3
gen other 		= race == 4

* ----------------------------- STATES
decode state, gen(state2) // use labels
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

save "${TEMPDATADIR}/household_cps_povlevels.dta", replace


use "${TEMPDATADIR}/household_cps_povlevels.dta", clear
drop incp_* incf_all pvlfam persInc

* Unique identifiers
egen serial = group(hhseq year)				// identifier for each HH
bysort hhseq year : gen pernum = _n			// person number inside HH
drop hhseq
order year serial pernum

label var serial 	"Unique identifier for each hh"
label var pernum 	"Unique person identifier inside hh"
label data 			"CPS March data 1998-2018"

* ----------------------------- SUBSAMPLE
* Mirrors FF composition (by mother)

/*
* Mother cohort between 1955 and 1985 in FF
gen cohort = year - age
gen 	typeFF = 0
replace typeFF = 1 if pfrel == 2 & female == 1  & (cohort>=1955 & cohort<=1985)
replace typeFF = 1 if pfrel == 5 & (cohort>=1955 & cohort<=1985)
bysort serial year : egen typeFFhh = max(typeFF)

* What happens with missing
* Mother race
gen moWhite1 		= white if (pfrel == 2 | pfrel == 5) & female == 1
gen moBlack1 		= black if (pfrel == 2 | pfrel == 5) & female == 1
gen moHispanic1 	= hispanic if (pfrel == 2 | pfrel == 5) & female == 1
gen moOther1		= other if (pfrel == 2 | pfrel == 5) & female == 1
bysort serial year : egen moWhite 		= max(moWhite1)
bysort serial year : egen moBlack 		= max(moBlack1)
bysort serial year : egen moHispanic	= max(moHispanic1)
bysort serial year : egen moOther 		= max(moOther1)

* Father race
gen faWhite1 		= white if (pfrel == 1 | pfrel == 5) & female == 0
gen faBlack1 		= black if (pfrel == 1 | pfrel == 5) & female == 0
gen faHispanic1 	= hispanic if (pfrel == 1 | pfrel == 5) & female == 0
gen faOther1		= other if (pfrel == 1 | pfrel == 5) & female == 0
bysort serial year : egen faWhite 		= max(faWhite1)
bysort serial year : egen faBlack 		= max(faBlack1)
bysort serial year : egen faHispanic	= max(faHispanic1)
bysort serial year : egen faOther 		= max(faOther1)
drop white black hispanic other fa*1 mo*1

* Age mother at birth between 15 and 43 years old in FF
gen momCohort_temp = cohort	if (pfrel == 2 | pfrel == 5) & female == 1
bysort serial year : egen momCohort = min (momCohort_temp)
gen momGeb = cohort - momCohort
drop if momGeb < 15 | momGeb > 43
drop momCohort_temp

* Keep the flagged households
keep if typeFFhh == 1

* Not in FF sample
gen FF = 0
*/


* ----- KEEP ONLY CHILDREN
keep if pfrel == 3

* NOTE: if no subsample then put race before in code
rename white 		chWhite
rename black 		chBlack
rename hispanic 	chHispanic
rename other		chOther


/* Propsensity score matching on characteristics
	* MERGE datasets from CPS (FF = 0) and FF baseline wave (FF = 1)

	append using "${TEMPDATADIR}/mothers_FF.dta"		// FF data

	* drop incomes too high and too low?
	* probit FF momGeb incRatio
	probit FF momGeb moWhite moBlack moHispanic incRatio

	psmatch2 FF momGeb moWhite moBlack moHispanic incRatio, n(10) common

	sum moWhite momGeb moBlack moHispanic incRatio if FF == 1
	sum moWhite momGeb moBlack moHispanic incRatio if FF == 0
	sum moWhite momGeb moBlack moHispanic incRatio if FF == 0 & _weight != .

	tab year if _weight != .		// how year distribution looks

	tab age year if _weight != .

	* keep if _weight != .
*/

tabstat healthIns healthMedi childMedi childCHIP, by(year)


* ----- DATASET FOR SUMMARY STATS
keep year age statefip incRatio health* child* ch* moCohort faCohort famSize female
order year statefip age incRatio
sort year statefip age
save "${TEMPDATADIR}/cps_summary.dta", replace


* ----- DATASET FOR ANALYSIS
keep age state incRatio
save "${CLEANDATADIR}/cps.dta", replace


