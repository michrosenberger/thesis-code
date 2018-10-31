* Project: 	MA Thesis
* Content:
* Data: 	March CPS (1990 - 2016)
* Author: 	Michelle Rosenberger
* Date: 	Oct 1, 2018

capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

************************************
* WORING DIRECTORIES AND GLOABL VARS
************************************
global USERPATH     	"/Users/michellerosenberger/Development/MA"
global RAWDATADIR		"${USERPATH}/data/MarchCPS/raw"
global CLEANDATADIR  	"${USERPATH}/data/MarchCPS/clean"
global CODEDIR			"${USERPATH}/code/MarchCPS"
global OUTPUTDIR		"${USERPATH}/output"
global FIGUREDIR		"${OUTPUTDIR}/figures"
global TABLEDIR			"${OUTPUTDIR}/tables"

// log using ${CODEDIR}/CPS.log, replace 

************************************
* IMPORT DATA
************************************
* Data from 1990 until 2016 available
* Need data 2017/18

use "${RAWDATADIR}/cepr_march_1998.dta", clear
foreach year of numlist 1999(1)2016 {		//change back
	append using "${RAWDATADIR}/cepr_march_`year'.dta", force
}

************************************
* GENERAL VARIABLES
************************************
* hhseq		Household ID within file
* perno		Person no.
* id		Unqiue person ID

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
label var child1	"Child indicator in family"
label var numChild	"Number of children in family"
label var husband	"Husband indicator in family"
label var wife		"Wife indicator in family"
label var unmarried	"Unmarried parent indicator in family"
label var famSize	"Family size"

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
/* Income values refer to the previous calendar year, NOT
the current survey year */

/* Total family income in Thompson, 2018:
Sum of income for mother + spouse: wages, salaries, business and farm operation
profits, unemployment insurance and child support payments */

/* PERSONAL INCOME IN PREVIOUS YEAR
This income measure includes: 
- Income from wage and salary (nominal) incp_wag
- Income from self-employment (nominal) incp_se (farm + nonfarm)
- Income from child support (nominal) icnp_cs
- Income from unemployment compensation (nominal) incp_uc */
gen persInc = incp_wag + incp_se + incp_cs + incp_uc

* FAMILY INCOME IN PREVIOUS YEAR (Note: now also salary from other siblings included - check rules medicaid (without sibling salary)
by hhseq year: egen famInc = sum(persInc)

label var persInc	"Personal income"
label var famInc	"Family income"

/* To-do:
* Exclude children from parents with miliatry services
* lag income
* CPI adjust income */

keep year month hhid hhseq id female wbho pfrel age famSize husband wife numChild child1 unmarried incp_wag incp_se incp_cs incp_uc persInc famInc state pvcfam incf_all pvlfam

rename child1 child

* Collapse to see the summary statistic


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

gen state_temp = ""
replace state_temp = "Maine"				if state == 11
replace state_temp = "New Hampshire" 		if state == 12
replace state_temp = "Vermont" 				if state == 13 
replace state_temp = "Massachusetts" 		if state == 14
replace state_temp = "Rhode Island" 		if state == 15
replace state_temp = "Connecticut" 			if state == 16
replace state_temp = "New York" 			if state == 21
replace state_temp = "New Jersey" 			if state == 22
replace state_temp = "Pennsylvania" 		if state == 23
replace state_temp = "Ohio" 				if state == 31
replace state_temp = "Indiana" 				if state == 32
replace state_temp = "Illinois" 			if state == 33
replace state_temp = "Michigan" 			if state == 34
replace state_temp = "Wisconsin" 			if state == 35
replace state_temp = "Minnesota" 			if state == 41 
replace state_temp = "Iowa" 				if state == 42
replace state_temp = "Missouri" 			if state == 43
replace state_temp = "North Dakota" 		if state == 44
replace state_temp = "South Dakota" 		if state == 45
replace state_temp = "Nebraska" 			if state == 46
replace state_temp = "Kansas" 				if state == 47
replace state_temp = "Delaware" 			if state == 51
replace state_temp = "Maryland" 			if state == 52
replace state_temp = "District of Columbia"	if state == 53
replace state_temp = "Virginia" 			if state == 54
replace state_temp = "West Virginia" 		if state == 55
replace state_temp = "North Carolina" 		if state == 56
replace state_temp = "South Carolina" 		if state == 57
replace state_temp = "Georgia" 				if state == 58
replace state_temp = "Florida" 				if state == 59 
replace state_temp = "Kentucky" 			if state == 61
replace state_temp = "Tennessee" 			if state == 62
replace state_temp = "Alabama" 				if state == 63
replace state_temp = "Mississippi" 			if state == 64
replace state_temp = "Arkansas" 			if state == 71
replace state_temp = "Louisiana" 			if state == 72
replace state_temp = "Oklahoma" 			if state == 73
replace state_temp = "Texas" 				if state == 74
replace state_temp = "Montana" 				if state == 81
replace state_temp = "Idaho" 				if state == 82
replace state_temp = "Wyoming" 				if state == 83
replace state_temp = "Colorado" 			if state == 84
replace state_temp = "New Mexico" 			if state == 85
replace state_temp = "Arizona"		 		if state == 86
replace state_temp = "Utah" 				if state == 87
replace state_temp = "Nevada" 				if state == 88
replace state_temp = "Washington" 			if state == 91
replace state_temp = "Oregon" 				if state == 92
replace state_temp = "California" 			if state == 93
replace state_temp = "Alaska" 				if state == 94
replace state_temp = "Hawaii" 				if state == 95
drop state
rename state_temp state

save "${CLEANDATADIR}/household_cps.dta", replace

************************************
* MERGE POVERTY LEVELS
************************************

merge m:1  year famSize state using "/Users/michellerosenberger/Development/MA/data/POVLEVEL/clean/PovertyLevels.dta"
keep if _merge == 3
drop _merge

************************************
* Income ratio
************************************
/* Divide CPS family income by the applicable poverty line (based on family size and composition) */
gen incRatio = famInc / povLevel * 100

label var incRatio	"Family poverty level"
* winsorize income p1 and p99?
* browse incp_* famInc if incRatio < 0
* check value -9999 incp_se			// only this cat minus values

gen testRatio = incf_all / pvcfam * 100

* browse famInc incf_all povLevel pvcfam incRatio  pvlfam

save "${CLEANDATADIR}/household_cps_povlevels.dta", replace

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


line fraq_hischip fraq_himcaid year
graph export "${FIGUREDIR}/time1.pdf", replace

twoway area fraq_himcaid fraq_hischip year
graph export "${FIGUREDIR}/time2.pdf", replace


/*
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