* Project: 	MA Thesis
* Data: 	March CPS 1990 - 2016
* Content: 	
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
* Data from 1990 until 2016
* Need data 2017/18

use "${RAWDATADIR}/cepr_march_1990.dta", clear
foreach year of numlist 1991(1)2016 {
	append using "${RAWDATADIR}/cepr_march_`year'.dta", force
}


************************************
* IDENTIFICATION
************************************
codebook hhseq 	// (HOUSEHOLD ID within file)
codebook perno 	// (PERSON no.)
codebook id 	// (UNIQUE person ID)


************************************
* GENERAL VARIABLES
************************************
tab female			// gender
tab married 		// married
tab marstat			// martial status
tab age
tab wbho			// race // wbhao wbhaom

tab state
tab st_lyr			// State residence in March last year
tab csr				// City status
tab centcity		// Central/Principal city
tab suburbs			// Suburbs
tab rural			// Rural

/* Some CPS questions, such as income, ask about the previous year. Others,
such as age, refer to the time of the survey. The column labels indicate any
subject with a reference year which differs from the survey year.
https://www.census.gov/cps/data/cpstablecreator.html?# */


************************************
* FAMILY STRUCTURE CPS
************************************
tab famh
tab famrel

*browse hhseq perno famno famhh age pfrel famrel
keep if famno == 1		// drop if not primary family member
drop if pfrel == 4		// drop if other relative
*browse hhseq perno famno famhh age pfrel famrel state


drop if pfrel == 3 & age > 19		// drop children older than 18 in fam unit

bysort hhseq: gen husband_temp = 1 if pfrel == 1	// Husband in fam
egen husband = count(husband_temp), by(hhseq)

bysort hhseq: gen wife_temp = 1 if pfrel == 2		// Wife in fam
egen wife = count(wife_temp), by(hhseq)

bysort hhseq: gen child_temp = 1 if pfrel == 3		// Child in fam
egen nchild = count(child_temp), by(hhseq)			// Number of child in fam
gen child1 = child_temp
replace child1 = 0 if child1 == .

bysort hhseq: gen unmarried_temp = 1 if pfrel == 5	// Unmarried parent in fam
egen unmarried = count(unmarried_temp), by(hhseq)

drop if nchild == 0									// Drop if no children
drop *_temp

gen famSize = husband + wife + nchild + unmarried	// Fam size


browse hhseq famsize husband wife unmarried child1 nchild perno famno famhh age pfrel famrel


************************************
* INCOME
************************************
/* Income values refer to the previous calendar year, NOT
the current survey year */

* INFO
foreach var in incp_wag incp_se incp_cs incp_uc {
	codebook `var'
}

/* This income measure includes: 
- Income from wage and salary (nominal) incp_wag
- Income from self-employment (nominal) incp_se	--> farm + nonfarm
- Income from child support (nominal) icnp_cs
- Income from unemployment compensation (nominal) incp_uc */

/* Total family income in Thompson, 2018:
Sum of income for mother + spouse: wages, salaries, business and farm operation
profits, unemployment insurance and child support payments */

* PERSONAL INCOME IN PREVIOUS YEAR
gen incPers = incp_wag + incp_se + incp_cs + incp_uc


* Check papers for fam income + fam size
* What about pregnant women?
* Exclude children from parents with miliatry services
* Only income father, mother and child? or other siblings?
* Match on education?
* lag income



************************************
* STATES
************************************
gen statefip = .

replace statefip = 23 if state == "11" 	// Maine
replace statefip = 33 if state == "12" 	// New Hampshire
replace statefip = 50 if state == "13" 	// Vermont
replace statefip = 25 if state == "14" 	// Massachusetts
replace statefip = 44 if state == "15" 	// Rhode Island
replace statefip = 9 if state == "16" 	// Connecticut
replace statefip = 36 if state == "21" 	// New York
replace statefip = 34 if state == "22" 	// New Jersey
replace statefip = 42 if state == "23" 	// Pennsylvania
replace statefip = 39 if state == "31" 	// Ohio
replace statefip = 18 if state == "32" 	// Indiana
replace statefip = 17 if state == "33" 	// Illinois
replace statefip = 26 if state == "34" 	// Michigan
replace statefip = 55 if state == "35" 	// Wisconsin
replace statefip = 27 if state == "41" 	// Minnesota 
replace statefip = 19 if state == "42" 	// Iowa
replace statefip = 29 if state == "43" 	// Missouri
replace statefip = 38 if state == "44" 	// North Dakota
replace statefip = 46 if state == "45" 	// South Dakota
replace statefip = 31 if state == "46" 	// Nebraska
replace statefip = 20 if state == "47" 	// Kansas
replace statefip = 10 if state == "51" 	// Delaware
replace statefip = 24 if state == "52" 	// Maryland
replace statefip = 11 if state == "53" 	// District of Columbia
replace statefip = 51 if state == "54" 	// Virginia
replace statefip = 54 if state == "55" 	// West Virginia
replace statefip = 37 if state == "56" 	// North Carolina
replace statefip = 45 if state == "57" 	// South Carolina
replace statefip = 13 if state == "58" 	// Georgia
replace statefip = 12 if state == "59" 	// Florida 
replace statefip = 21 if state == "61" 	// Kentucky
replace statefip = 47 if state == "62" 	// Tennessee
replace statefip = 1 if state == "63" 	// Alabama
replace statefip = 28 if state == "64" 	// Mississippi
replace statefip = 5 if state == "71" 	// Arkansas
replace statefip = 22 if state == "72" 	// Louisiana
replace statefip = 40 if state == "73" 	// Oklahoma
replace statefip = 48 if state == "74" 	// Texas
replace statefip = 30 if state == "81" 	// Montana
replace statefip = 16 if state == "82" 	// Idaho
replace statefip = 56 if state == "83" 	// Wyoming
replace statefip = 8 if state == "84" 	// Colorado
replace statefip = 35 if state == "85" 	// New Mexico
replace statefip = 4 if state == "86"	// Arizona
replace statefip = 49 if state == "87" 	// Utah
replace statefip = 32 if state == "88" 	// Nevada
replace statefip = 53 if state == "91" 	// Washington
replace statefip = 41 if state == "92" 	// Oregon
replace statefip = 6 if state == "93" 	// California
replace statefip = 2 if state == "94" 	// Alaska
replace statefip = 15 if state == "95"	// Hawaii




************************************
* KEEP at the end
************************************
keep year month hhid id


*  psmatch2 NLSY momageb inratio, n(10) common 

*/
************************************
* INSURANCE QUESTIONS
************************************
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
