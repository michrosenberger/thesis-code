* Project: 	MA Thesis
* Content:	Create CPS households
* Author: 	Michelle Rosenberger
* Date: 	Oct 1, 2018

capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

/*
Input datasets:
- cepr_march_`year'.dta :	CPS March data 	(1998 - 2016)
- PovertyLevels.dta 	:  	Poverty levels	(1998 - 2017)

Output datasets:
- cps.dta 				:	year age statefip incRatio

Note:
- * CPI ADJUST INCOME
- * Need data 2017/18
- * winsorize income p1 and p99?
- Subsample: * CHECK FOR those households without mother
- Check subsample year and age
- * Summary statistics
*/

************************************
* WORING DIRECTORIES AND GLOABL VARS
************************************
if "`c(username)'" == "michellerosenberger"  {
    global MYPATH		"~/Development/MA"
}
global RAWDATADIR		"${MYPATH}/data/raw/MarchCPS"
global CODEDIR			"${MYPATH}/code"
global CLEANDATADIR  	"${MYPATH}/data/clean"
global TEMPDATADIR  	"${MYPATH}/data/temp"

// log using ${CODEDIR}/CPS.log, replace 

************************************
* IMPORT DATA
************************************
* Data from 1990 until 2016 available

use "${RAWDATADIR}/cepr_march_1998.dta", clear
foreach year of numlist 1999(1)2016 {
	qui append using "${RAWDATADIR}/cepr_march_`year'.dta", force
}

************************************
* FAMILY STRUCTURE CPS
************************************
* Conditions: primary family member, not other relative and child not older than 18 in family unit
keep if famno == 1				// primary family member
drop if pfrel == 4				// other relative
drop if pfrel == 3 & age > 18	// child younger than 18

bysort hhseq year : gen husband_temp = 1 if pfrel == 1
bysort hhseq year : egen husband = count(husband_temp)

bysort hhseq year : gen wife_temp = 1 if pfrel == 2
bysort hhseq year : egen wife = count(wife_temp)

bysort hhseq year : gen child_temp = 1 if pfrel == 3
bysort hhseq year : egen numChild = count(child_temp)
gen child1 = child_temp
replace child1 = 0 if child1 == .

bysort hhseq year : gen unmarried_temp = 1 if pfrel == 5
bysort hhseq year : egen unmarried = count(unmarried_temp)

drop if numChild == 0	// drop if no children
drop *_temp

gen famSize = husband + wife + numChild + unmarried

* LABELS
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


************************************
* INCOME
************************************
/* PERSONAL INCOME IN PREVIOUS YEAR
This income measure includes: 
- Income from wage and salary (nominal) incp_wag
- Income from self-employment (nominal) incp_se (farm + nonfarm)
- Income from child support (nominal) icnp_cs
- Income from unemployment compensation (nominal) incp_uc */

if year < 2014 {		// Previous Medicaid eligibility
	* Wages, salaries, profit from self-employment		incp_wag
	* Unemployment compensation							incp_uc
	* Self-employment 	counted							incp_se
	* Child support 	counted							icnp_cs
	* TANF and SSI 		counted							X
	* Alimony received	counted							incp_alm
	gen persInc = incp_wag + incp_uc + incp_se + incp_cs + incp_alm
}
if year >= 2014 {			// MAGI
	* Wages, salaries									incp_wag 
	* Unemployment compensation							incp_uc
	* Self-employment 	counted							incp_se
	* Child support 	NOT counted
	* TANF and SSI 		NOT counted
	* Alimony received	counted							incp_alm
	gen persInc = incp_wag + incp_uc + incp_se + incp_alm
}

gen tempInc = persInc if (pfrel == 1 | pfrel == 2 | pfrel == 5)
bysort hhseq year: egen famInc = sum(tempInc)
drop tempInc

label var persInc	"Personal income"
label var famInc	"Family income"

note incp_se : Bottom/TopCode*(Value): -9999/50000(80-81) -9999/75000 (82-84) -9999*/99999*(85-88) -19998*/199998*(89-95) -9999/760120*(96-97) -9999/546375*(98) -9999/624176*(1999) -9999/481887*(2000) -99999/456973*(2001) -99999/605159*(2002) -99999/789127*(2003) -99999/661717*(2004) -99999/880089*(2005) -99999/730116*(2006) -99999/766141*(2007) -99999/801198*(2008) -99999/736488*(2009) -99999/702914*(2010) -99999/9999999*(2011-on)

keep year month hhid hhseq id female wbho pfrel age famSize husband wife numChild child1 unmarried incp_wag incp_se incp_cs incp_uc persInc famInc state pvcfam incf_all pvlfam hins hipriv hipub hiep hipind himcaid himcc hischip

rename child1 child

************************************
* RACE
************************************
gen white 		= wbho == 1
gen black 		= wbho == 2
gen hispanic 	= wbho == 3
gen other 		= wbho == 4

************************************
* STATES
************************************
gen statefip = .
	replace statefip = 23	if state == 11 	// Maine
	replace statefip = 33 	if state == 12 	// New Hampshire
	replace statefip = 50 	if state == 13 	// Vermont
	replace statefip = 25 	if state == 14 	// Massachusetts
	replace statefip = 44 	if state == 15 	// Rhode Island
	replace statefip = 9  	if state == 16 	// Connecticut
	replace statefip = 36 	if state == 21 	// New York
	replace statefip = 34 	if state == 22 	// New Jersey
	replace statefip = 42 	if state == 23 	// Pennsylvania
	replace statefip = 39 	if state == 31 	// Ohio
	replace statefip = 18 	if state == 32 	// Indiana
	replace statefip = 17 	if state == 33 	// Illinois
	replace statefip = 26 	if state == 34 	// Michigan
	replace statefip = 55 	if state == 35 	// Wisconsin
	replace statefip = 27 	if state == 41 	// Minnesota 
	replace statefip = 19 	if state == 42 	// Iowa
	replace statefip = 29 	if state == 43 	// Missouri
	replace statefip = 38 	if state == 44 	// North Dakota
	replace statefip = 46 	if state == 45 	// South Dakota
	replace statefip = 31 	if state == 46 	// Nebraska
	replace statefip = 20 	if state == 47 	// Kansas
	replace statefip = 10 	if state == 51 	// Delaware
	replace statefip = 24 	if state == 52 	// Maryland
	replace statefip = 11 	if state == 53 	// District of Columbia
	replace statefip = 51 	if state == 54 	// Virginia
	replace statefip = 54 	if state == 55 	// West Virginia
	replace statefip = 37 	if state == 56 	// North Carolina
	replace statefip = 45 	if state == 57 	// South Carolina
	replace statefip = 13 	if state == 58 	// Georgia
	replace statefip = 12 	if state == 59 	// Florida 
	replace statefip = 21 	if state == 61 	// Kentucky
	replace statefip = 47 	if state == 62 	// Tennessee
	replace statefip = 1 	if state == 63 	// Alabama
	replace statefip = 28 	if state == 64 	// Mississippi
	replace statefip = 5 	if state == 71 	// Arkansas
	replace statefip = 22 	if state == 72 	// Louisiana
	replace statefip = 40 	if state == 73 	// Oklahoma
	replace statefip = 48 	if state == 74 	// Texas
	replace statefip = 30 	if state == 81 	// Montana
	replace statefip = 16 	if state == 82 	// Idaho
	replace statefip = 56 	if state == 83 	// Wyoming
	replace statefip = 8 	if state == 84 	// Colorado
	replace statefip = 35 	if state == 85 	// New Mexico
	replace statefip = 4 	if state == 86	// Arizona
	replace statefip = 49 	if state == 87 	// Utah
	replace statefip = 32 	if state == 88 	// Nevada
	replace statefip = 53 	if state == 91 	// Washington
	replace statefip = 41 	if state == 92 	// Oregon
	replace statefip = 6 	if state == 93 	// California
	replace statefip = 2 	if state == 94 	// Alaska
	replace statefip = 15 	if state == 95	// Hawaii

drop state

************************************
* HEALTH COVERAGE
************************************
rename hins		healthIns	// Health insurance
rename hipriv	healthPriv	// Health insurance, private
rename hipub	healthPubl	// Health insurance, public
rename hiep		healthEmp	// Health insurance, Employer-provided (private)
rename hipind	healthPriv2	// Health insurance, privately purchased
rename himcaid	healthMedi	// Health insurance, Medicaid
rename himcc 	childMedi	// Child covered by Medicaid
rename hischip 	childCHIP	// Child covered by SCHIP
* More child covered by ... options

************************************
* MERGE POVERTY LEVELS
************************************
merge m:1  year famSize statefip using "${CLEANDATADIR}/PovertyLevels.dta"
keep if _merge == 3
drop _merge

************************************
* Income ratio
************************************
* Divide CPS fam income by poverty line based on fam size and composition
gen incRatio = famInc / povLevel
label var incRatio	"Family poverty level"

* browse famInc incf_all povLevel pvcfam incRatio  pvlfam
save "${TEMPDATADIR}/household_cps_povlevels.dta", replace


use "${TEMPDATADIR}/household_cps_povlevels.dta", clear
drop incp_* incf_all pvlfam persInc month id

* Unique identifiers
egen serial = group(hhseq year)				// identifier for each hh
bysort hhseq year : gen pernum = _n			// person number inside hh
drop hhid hhseq
order year serial pernum

label var serial "Unique identifier for each hh"
label var pernum "Unique person identifier inside hh"
label data "CPS March data 1998-2016"


************************************
* Subsample
************************************
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

* Keep only children
keep if pfrel == 3

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

tabstat healthIns healthMedi childMedi  childCHIP , by(year)

keep year age statefip incRatio health* child*
order year statefip age incRatio
sort year statefip age

drop year

save "${CLEANDATADIR}/cps.dta", replace













************************************
* INSURANCE QUESTIONS
************************************
/*
* CHIP data starts 2001
keep year himcaid hischip hins hipriv hiep hipind

foreach year of numlist 1990(1)2016 {
	foreach var in himcaid hischip hins {
		egen freq_`var'_`year' = count(`var') if (`var' == 1 & year == `year')
		egen total_`var'_`year' = count(`var') if (year == `year')
		gen fraq_`var'_`year' = (freq_`var'_`year' / total_`var'_`year') * 100 if year == `year'
	}
}

foreach var in himcaid hischip hins {
	egen freq_`var' = rowmax(freq_`var'_*)
	egen total_`var' = rowmax(total_`var'_*)
	egen fraq_`var' = rowmax(fraq_`var'_*)
}

// Income from social security, food stamps, WIC, EITC etc
tab hins 	// Health insurance
tab hipriv	// Health insurance, private
tab hiep	// Health insurance, employer-provided (private)
tab hipind	// Health insurance, privately purchased
tab himcaid	// Health insurance, Medicaid
tab himcare	// Health insurance, Medicare
tab hiothpub	// Health insurance, provided by CHAMPUS or military hc
tab hipub		// Health insurance, public
tab hiprivc		// Child under private HI
tab hiepc		// Child under HI provided by employers
tab hipindc	
tab hiprivc_none
tab himcc
tab hischip
tab hiepdep
tab hipindep
tab hiprivdep
tab hiepsp
tab hipindsp
tab hiprivsp
tab hi_emp
tab higj_all
tab higj_part
tab higj_none
tab higj_allprt
tab higj_pind
tab higj_priv
// hrearn hrwage
*/
*/