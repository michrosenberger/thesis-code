* Project:      MA Thesis
* Content:      Family demographics FF
* Data:         Fragile families
* Author:       Michelle Rosenberger
* Date:         October 15, 2018

********************************************************************************
*********************************** PREAMBLE ***********************************
********************************************************************************
capture log close
clear all
est clear
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

// Set working directories
if "`c(username)'" == "michellerosenberger"  {
    global USERPATH         "/Users/michellerosenberger/Development/MA"
}

global RAWDATADIR	    "${USERPATH}/data/raw/FragileFamilies"
global CLEANDATADIR  	"${USERPATH}/data/clean"		// general
global TEMPDATADIR  	"${USERPATH}/data/temp"		    // general

********************************************************************************
****************************** VARIABLES BASELINE ******************************
********************************************************************************

* RENAME VARIABLES 
* NEW STRUCTURE CODE

*************************
** MERGE
*************************
use "${RAWDATADIR}/00_Baseline/ffmombspv3.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/00_Baseline/ffdadbspv3.dta"
tab _merge
drop _merge

ds, has(type numeric)
global ALLVARIABLES = r(varlist)

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
	replace `vars' = .j if `vars' == -10 // jail
	replace `vars' = .k if `vars' == -12 // Shelter/Street 
	}

*************************
** DEMOGRAPHICS
*************************
rename cm1edu      moEduc0
rename cf1edu      faEduc0
rename cm1ethrace  moRace0
rename cf1ethrace  faRace0
rename cm1age      moAge0
rename cf1age      faAge0
rename cm1bsex     chGender0
rename m1intyr     moYear0
rename f1intyr     faYear0
rename m1intmon    moMonth0
rename f1intmon    faMonth0
gen chAge0       = 0
gen moCohort0    = moYear0 - moAge0
gen faCohort0    = faYear0 - faAge0

gen wave        = 0

*************************
** HH INCOME 
*************************
local int = 1
local num : word count mo fa
while `int' <= `num' {
    local parent    : word `int' of     mo  fa
    local letter    : word `int' of     m   f
    local int = `int' + 1

    rename c`letter'1hhinc  `parent'HH_income0
    rename c`letter'1hhimp  `parent'HH_income_f0
    rename c`letter'1inpov  `parent'HH_povratio0
    rename c`letter'1povca  `parent'HH_povcat0
}

*************************
** HH STRUCTURE					// no. 1?
*************************
local int = 1
local num : word count mo fa
while `int' <= `num' {
    local parent    : word `int' of     mo  fa
    local letter    : word `int' of     m   f
    local int = `int' + 1

    forvalues member = 1/8 {

        * GENDER hh member
        gen     `parent'HH_female`member'   = .
        replace `parent'HH_female`member'   = 1   if `letter'1e1c`member' == 2
        replace `parent'HH_female`member'   = 0   if `letter'1e1c`member' == 1

        * AGE and RELATIONSHIP hh member
        rename `letter'1e1d`member' `parent'HH_age`member'
        rename `letter'1e1b`member' `parent'HH_relate`member'
        /* 0 = none, 1 = partner, 5 = child, 6 = OtChld */

        * EMPLOYMENT hh member
        gen     `parent'HH_employ`member'   = .
        replace `parent'HH_employ`member'   = 1   if `letter'1e1e`member' == 1
        replace `parent'HH_employ`member'   = 0   if `letter'1e1e`member' == 2
    }
}

* HH size
gen     moHH_size_c0   = cm1adult + cm1kids
gen     faHH_size_c0   = cf1adult + cf1kids

*************************
** CHILD LIVING ARR.
*************************
tab m1a11a
rename m1a11a chLiveMo0

keep idnum mo* fa* ch* // cm1relf
drop mothid1 fathid1

reshape long moHH_female moHH_age moHH_relate moHH_employ faHH_female faHH_age faHH_relate faHH_employ, i(idnum) j(noHH_member)

rename moHH_relate  moHH_relate0
rename moHH_employ  moHH_employ0
rename moHH_female  moHH_female0
rename moHH_age     moHH_age0
rename faHH_relate  faHH_relate0
rename faHH_employ  faHH_employ0
rename faHH_female  faHH_female0
rename faHH_age     faHH_age0

*************************
** MISSING VALUES
*************************
foreach parent in moHH faHH {
    foreach var in `parent'_female0 `parent'_age0 `parent'_relate0 `parent'_employ0 {
        replace `var' = . if (`var' == .a | `var' == .b | `var' == .c | `var' == .f | `var' == .i)
    }
}

*************************
** PARENTS FAMILY STRUCTURE
*************************
/* In family only partner and children under the age of 18. */
foreach parent in mo fa {

    * Relationship to respondent
    gen     `parent'FAM_relate0 = .
    replace `parent'FAM_relate0 = `parent'HH_relate0    if (`parent'HH_relate0 == 3 | `parent'HH_relate0 == 5)
    replace `parent'FAM_relate0 = .                     if (`parent'HH_relate0 == 5 & `parent'HH_age0 > 18)   // child under 18

    * Gender hh member
    gen     `parent'FAM_female0 = .
    replace `parent'FAM_female0 = `parent'HH_female0    if (`parent'HH_relate0 == 3 | `parent'HH_relate0 == 5)
    replace `parent'FAM_female0 = .                     if (`parent'HH_relate0 == 5 & `parent'HH_age0 > 18) // child under 18

    * Age hh member
    gen     `parent'FAM_age0 = .
    replace `parent'FAM_age0 = `parent'HH_age0          if (`parent'HH_relate0 == 3 | `parent'HH_relate0 == 5)
    replace `parent'FAM_age0 = .                        if (`parent'HH_relate0 == 5 & `parent'HH_age0 > 18) // child under 18

    * Employment hh member
    gen     `parent'FAM_employ0 = .
    replace `parent'FAM_employ0 = `parent'HH_employ0    if (`parent'HH_relate0 == 3 | `parent'HH_relate0 == 5)
    replace `parent'FAM_employ0 = .                     if (`parent'HH_relate0 == 5 & `parent'HH_age0 > 18) // child under 18

    * Family size
    gen temp`parent' = 1 if `parent'FAM_relate0 != .
    bysort temp`parent' idnum : gen `parent'FAM_member0 = _n if `parent'FAM_relate0 != .
    drop temp`parent'

    egen `parent'FAM_size0 = count(`parent'FAM_member0), by(idnum)
    replace `parent'FAM_size0 = `parent'FAM_size0 + 1    // Add parent
}

*************************
** CHILD FAMILY STRUCTURE
*************************
/* IF chLiveMo missing: mother report as default */
foreach var in member female relate age employ size {
    gen     chFAM_`var' = moFAM_`var'0 if chLiveMo0 == 1 // mother report
    replace chFAM_`var' = faFAM_`var'0 if chLiveMo0 == 2 // father report
    replace chFAM_`var' = moFAM_`var'0 if (chLiveMo0 != 1 & chLiveMo0 != 2)  // default

}

** FLAG which report
gen     chFAM_size_f0  = 1 if chLiveMo0 != 2    // mother
replace chFAM_size_f0  = 0 if chLiveMo0 == 2    // father
label   define chFAM_size_f0 0 "Father report" 1 "Mother report"
label   values chFAM_size_f0 chFAM_size_f0

*************************
* CHILD FAMILY & HH INCOME
*************************
/* Total family income in Thompson, 2018:
Sum of income for mother + spouse: wages, salaries, business and farm operation
profits, unemployment insurance and child support payments */
/* INCOME LAG? */

* FAMILY INCOME
/* Divide by # of hh members and multiply by family members  */
gen     moAvg_inc0   = (moHH_income0 / moHH_size_c0) * moFAM_size0
gen     faAvg_inc0   = (faHH_income0 / faHH_size_c0) * faFAM_size0

gen     chHH_size0   = moHH_size_c0 if chLiveMo0 != 2       // mother report
replace chHH_size0   = faHH_size_c0 if chLiveMo0 == 2       // father report

gen     chHH_income0 = moHH_income0 if chLiveMo0 != 2       // mother report
replace chHH_income0 = faHH_income0 if chLiveMo0 == 2       // father report

gen     chAvg_inc0   = moAvg_inc0 if chLiveMo0 != 2        // mother report
replace chAvg_inc0   = faAvg_inc0 if chLiveMo0 == 2        // father report

* Poverty ratio FF (Child hh income ratio)
gen     incRatio0    = moHH_povratio0 if chLiveMo0 != 2   // mother report
replace incRatio0    = faHH_povratio0 if chLiveMo0 == 2   // father report


/*
*************************
** COLLAPSE
*************************
keep idnum moYear moMonth ch* incRatio
order idnum moYear moMonth
sort idnum

* browse if chHH_income < chAvg_inc     // why bigger?

ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

*************************
** LABELS
*************************
label data "Household structure (baseline)"

label var chFAM_member      "No. fam member (child)"
label var chFAM_female0      "Gender family member (child)"
label var chFAM_age         "Age family member (child)"
label var chFAM_relate      "Relationship to parent family member (child)"
label var chFAM_employ      "Employment family member (child)"
label var chFAM_size        "No. of family members in hh (child)"
label var chFAM_size_f      "Flag which report used"
label var moYear            "Year interview (mother)"
label var moMonth           "Month interview (child)"
label var chHH_size         "No. of hh members (child)"
label var incRatio          "Poverty ratio % (child)"
label var chAvg_inc         "HH income divided by members and multiplied by family members"
label var chAge             "Age"
label var chGender          "Gender"
label var chHH_income       "Household income"

label list hhrelat_mw1
label values chFAM_relate hhrelat_mw1

label define female 1 "female" 0 "male"
label values chFAM_female female

label define employed 1 "employed" 0 "unemployed"
label values chFAM_employ employed

rename idnum        id
rename moYear       year
rename chFAM_size   famSize
rename chHH_size    hhSize
rename chAge        age         // check with other waves
rename chGender     gender
rename chAvg_inc    avgInc
rename chHH_income  hhInc

drop chFAM_member chFAM_female chFAM_relate chFAM_age chFAM_employ moMonth chLiveMo chFAM_size_f
order id year age famSize
sort id year age famSize


tab year

describe

save "${TEMPDATADIR}/household.dta", replace





/* Constructed variables
cm1relf     hh relationship mother */


/*
** Merge poverty levels
* no statefip in this data
merge m:1  year famSize statefip using "${CLEANDATADIR}/PovertyLevels.dta"
keep if _merge == 3
drop _merge
*/
