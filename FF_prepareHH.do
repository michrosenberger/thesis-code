* Project:      MA Thesis
* Content:      Household structure FF
* Data:         Fragile families
* Author:       Michelle Rosenberger
* Date:         November 6, 2018

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
    global USERPATH		"~/Development/MA"
}

global RAWDATADIR	    "${USERPATH}/data/raw/FragileFamilies"
global CLEANDATADIR  	"${USERPATH}/data/clean"
global TEMPDATADIR  	"${USERPATH}/data/temp"

capture program drop missingvalues
program define missingvalues
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
end

********************************************************************************
****************************** VARIABLES BASELINE ******************************
********************************************************************************

*************************
** MERGE
*************************
use "${RAWDATADIR}/00_Baseline/ffmombspv3.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/00_Baseline/ffdadbspv3.dta"
tab _merge
drop _merge

keep idnum c*1edu c*1ethrace c*1age cm1bsex *1intyr *1intmon c*1hhinc c*1hhimp c*1inpov c*1povca *1e1c* *1e1d* *1e1b* *1e1e* c*1kids c*1adult m1a11a

missingvalues	// recode missing values

*************************
** DEMOGRAPHICS
*************************
rename cm1edu      moEduc
rename cf1edu      faEduc
rename cm1ethrace  moRace
rename cf1ethrace  faRace
rename cm1age      moAge
rename cf1age      faAge
rename cm1bsex     chGender
rename m1intyr     moYear
rename f1intyr     faYear
rename m1intmon    moMonth
rename f1intmon    faMonth
gen moCohort	= moYear - moAge
gen faCohort	= faYear - faAge

*************************
** HH INCOME 
*************************
local int = 1
local num : word count mo fa
while `int' <= `num' {
    local parent    : word `int' of     mo  fa
    local letter    : word `int' of     m   f
    local int = `int' + 1

    rename c`letter'1hhinc  `parent'HH_income
    rename c`letter'1hhimp  `parent'HH_income_f
    rename c`letter'1inpov  `parent'HH_povratio
    rename c`letter'1povca  `parent'HH_povcat
}

*************************
** HH STRUCTURE
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
gen     moHH_size_c   = cm1adult + cm1kids
gen     faHH_size_c   = cf1adult + cf1kids

*************************
** CHILD LIVING ARR.
*************************
tab m1a11a
rename m1a11a chLiveMo

keep idnum mo* fa* ch* // cm1relf

reshape long moHH_female moHH_age moHH_relate moHH_employ faHH_female faHH_age faHH_relate faHH_employ, i(idnum) j(noHH_member)

gen wave		= 0
keep idnum mo* fa* ch* no* wave
order idnum wave

*************************
** MISSING VALUES
*************************
foreach parent in moHH faHH {
    foreach var in `parent'_female `parent'_age `parent'_relate `parent'_employ {
        replace `var' = . if (`var' == .a | `var' == .b | `var' == .c | `var' == .f | `var' == .i)
    }
}

*************************
** PARENTS FAM STRUCTURE
*************************
tab moHH_relate        // 3 = partner, 5 = child, 6 = other child
tab faHH_relate
/* In family only partner and children under the age of 18. */
foreach parent in mo fa {
    
    * Relationship to respondent
    gen     `parent'FAM_relate = .
    replace `parent'FAM_relate = `parent'HH_relate if (`parent'HH_relate == 3 | `parent'HH_relate == 5)
    replace `parent'FAM_relate = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18

    * Gender hh member
    gen     `parent'FAM_female = .
    replace `parent'FAM_female = `parent'HH_female if (`parent'HH_relate == 3 | `parent'HH_relate == 5)
    replace `parent'FAM_female = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18

    * Age hh member
    gen     `parent'FAM_age = .
    replace `parent'FAM_age = `parent'HH_age if (`parent'HH_relate == 3 | `parent'HH_relate == 5)
    replace `parent'FAM_age = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18

    * Employment hh member
    gen     `parent'FAM_employ = .
    replace `parent'FAM_employ = `parent'HH_employ if (`parent'HH_relate == 3 | `parent'HH_relate == 5)
    replace `parent'FAM_employ = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18

    * Family size
    gen temp`parent' = 1 if `parent'FAM_relate != .
    bysort temp`parent' idnum : gen `parent'FAM_member = _n if `parent'FAM_relate != .
    drop temp`parent'

    egen `parent'FAM_size = count(`parent'FAM_member), by(idnum)
    replace `parent'FAM_size = `parent'FAM_size + 1    // Add parent
}

*************************
** CHILD FAMILY STRUCTURE
*************************
/* IF chLiveMo missing: mother report as default */
foreach var in member female relate age employ size {
    gen     chFAM_`var' = moFAM_`var' if chLiveMo == 1 // mother report
    replace chFAM_`var' = faFAM_`var' if chLiveMo == 2 // father report
    replace chFAM_`var' = moFAM_`var' if (chLiveMo != 1 & chLiveMo != 2)  // default

}

gen     chFAM_size_f  = 1 if chLiveMo != 2    // mother
replace chFAM_size_f  = 0 if chLiveMo == 2    // father
label   define chFAM_size_f 0 "Father report" 1 "Mother report"
label   values chFAM_size_f chFAM_size_f

*************************
* CHILD FAMILY & HH INCOME
*************************
/* Total family income in Thompson, 2018:
Sum of income for mother + spouse: wages, salaries, business and farm operation
profits, unemployment insurance and child support payments */
/* INCOME LAG? */

/* Divide by # of hh members and multiply by family members  */
gen     moAvg_inc = (moHH_income / moHH_size_c) * moFAM_size
gen     faAvg_inc = (faHH_income / faHH_size_c) * faFAM_size

gen     chHH_size = moHH_size_c if chLiveMo != 2  // mo report
replace chHH_size = faHH_size_c if chLiveMo == 2  // fa report

gen     chHH_income = moHH_income if chLiveMo != 2    // mo report
replace chHH_income = faHH_income if chLiveMo == 2    // fa report

gen     chAvg_inc = moAvg_inc if chLiveMo != 2    // mo report
replace chAvg_inc = faAvg_inc if chLiveMo == 2    // fa report

* Poverty ratio FF (Child hh income ratio)
gen     incRatio = moHH_povratio if chLiveMo != 2   // mo report
replace incRatio = faHH_povratio if chLiveMo == 2   // fa report


keep idnum moYear moMonth ch* incRatio wave
order idnum moYear moMonth
sort idnum

ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

drop chFAM_member chFAM_female chFAM_relate chFAM_age chFAM_employ moMonth chLiveMo chFAM_size_f


save "${TEMPDATADIR}/parents_Y0.dta", replace


********************************************************************************
******************************* VARIABLES YEAR 1 *******************************
********************************************************************************

*************************
** MERGE
*************************
use "${RAWDATADIR}/01_One-Year Core/ffmom1ypv2.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/01_One-Year Core/ffdad1ypv2.dta"
tab _merge
drop _merge

keep idnum c*2age cm2b_age *2intyr *2intmon c*2hhinc c*2hhimp c*2povco c*2povca *2f2b* *2f2c* *2f2d* *2f2e* *2f1 c*2adult c*2kids m2a3 m2a4a

missingvalues	// recode missing values

*************************
** DEMOGRAPHICS
*************************
rename cm2age 	moAge		// age mother
rename cf2age 	faAge		// age father
rename cm2b_age chAge		// age child
rename m2intyr	moYear		// interview year mother
rename f2intyr 	faYear		// interview year father
rename m2intmon	moMonth	// interview month mother
rename f2intmon	faMonth	// interview month father
gen moCohort    = moYear - moAge		// cohort mother
gen faCohort    = faYear - faAge		// cohort father

*************************
** HH INCOME 
*************************
local int = 1
local num : word count mo fa
while `int' <= `num' {
    local parent    : word `int' of     mo  fa
    local letter    : word `int' of     m   f
    local int = `int' + 1

	rename c`letter'2hhinc `parent'HH_income
	rename c`letter'2hhimp `parent'HH_income_f
	rename c`letter'2povco `parent'HH_povratio
	rename c`letter'2povca `parent'HH_povcat
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

	forvalues member = 1/10 {

		* GENDER hh member
		gen     `parent'HH_female`member'   = .
		replace `parent'HH_female`member'   = 1   if `letter'2f2b`member' == 2
		replace `parent'HH_female`member'   = 0   if `letter'2f2b`member' == 1

		* AGE and RELATIONSHIP hh member
		rename `letter'2f2c`member' `parent'HH_age`member' 
		rename `letter'2f2d`member' `parent'HH_relate`member'
		
		* EMPLOYMENT hh member
		gen     `parent'HH_employ`member'   = .
		replace `parent'HH_employ`member'   = 1   if `letter'2f2e`member' == 1
		replace `parent'HH_employ`member'   = 0   if `letter'2f2e`member' == 2
	}
}

* HH size
gen	moHH_size_s	= m2f1 + 1		// self-reported
gen	faHH_size_s	= f2f1 + 1		// self-reported
gen	moHH_size_c	= cm2adult + cm2kids		// constructed
gen	faHH_size_c	= cf2adult + cf2kids		// constructed


*************************
** CHILD LIVING ARR.
*************************
codebook m2a3		// how much time
codebook m2a4a		// usually live with

gen 	chLiveMo = .
replace chLiveMo = 1 if (m2a3 == 1 | m2a3 == 2)				// mother (all or halftime)
replace chLiveMo = 0 if (m2a3 != 1 & m2a3 != 2 & m2a4a == 1)	// father
label var chLiveMo      "Baby lives with mother"

keep idnum mo* fa* ch* // cm1relf

reshape long moHH_female moHH_age moHH_relate moHH_employ faHH_female faHH_age faHH_relate faHH_employ, i(idnum) j(noHH_member)

gen wave		= 1
keep idnum mo* fa* ch* no* wave
order idnum wave

*************************
** MISSING VALUES
*************************
foreach parent in moHH faHH {
    foreach var in `parent'_female `parent'_age `parent'_relate `parent'_employ {
        replace `var' = . if (`var' == .a | `var' == .b | `var' == .c | `var' == .f | `var' == .i)
    }
}

*************************
** PARENTS FAM STRUCTURE
*************************
tab moHH_relate
tab faHH_relate
/* 1 = spouse, 2 = partner, 5 = child, 6 = stepchild, 101 = new partner, 102 = new spouse */

/* In family only partner and children under the age of 18. */
foreach parent in mo fa {
    
    * Relationship to respondent
    gen     `parent'FAM_relate = .
    replace `parent'FAM_relate = `parent'HH_relate if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 101 | `parent'HH_relate == 102)
    replace `parent'FAM_relate = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_relate = . if (`parent'HH_relate == 6 & `parent'HH_age > 18) // child under 18

    * Gender hh member
    gen     `parent'FAM_female = .
    replace `parent'FAM_female = `parent'HH_female if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 101 | `parent'HH_relate == 102)
    replace `parent'FAM_female = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_female = . if (`parent'HH_relate == 6 & `parent'HH_age > 18) // child under 18

    * Age hh member
    gen     `parent'FAM_age = .
    replace `parent'FAM_age = `parent'HH_age if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 101 | `parent'HH_relate == 102)
    replace `parent'FAM_age = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_age = . if (`parent'HH_relate == 6 & `parent'HH_age > 18) // child under 18

    * Employment hh member
    gen     `parent'FAM_employ = .
    replace `parent'FAM_employ = `parent'HH_employ if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 101 | `parent'HH_relate == 102)
    replace `parent'FAM_employ = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_employ = . if (`parent'HH_relate == 6 & `parent'HH_age > 18) // child under 18

    * Family size
    gen temp`parent' = 1 if `parent'FAM_relate != .
    bysort temp`parent' idnum : gen `parent'FAM_member = _n if `parent'FAM_relate != .
    drop temp`parent'

    egen `parent'FAM_size = count(`parent'FAM_member), by(idnum)
    replace `parent'FAM_size = `parent'FAM_size + 1    // Add parent
}

*************************
** CHILD FAMILY STRUCTURE
*************************
/* IF chLiveMo missing: mother report as default */
foreach var in member female relate age employ size {
    gen     chFAM_`var' = moFAM_`var' if chLiveMo == 1 // mother report
    replace chFAM_`var' = faFAM_`var' if chLiveMo == 2 // father report
    replace chFAM_`var' = moFAM_`var' if (chLiveMo != 1 & chLiveMo != 2)  // default

}

gen     chFAM_size_f  = 1 if chLiveMo != 2    // mother
replace chFAM_size_f  = 0 if chLiveMo == 2    // father
label   define chFAM_size_f 0 "Father report" 1 "Mother report"
label   values chFAM_size_f chFAM_size_f

*************************
* CHILD FAMILY & HH INCOME
*************************
/* Total family income in Thompson, 2018:
Sum of income for mother + spouse: wages, salaries, business and farm operation
profits, unemployment insurance and child support payments */
/* INCOME LAG? */

/* Divide by # of hh members and multiply by family members  */
gen     moAvg_inc = (moHH_income / moHH_size_c) * moFAM_size
gen     faAvg_inc = (faHH_income / faHH_size_c) * faFAM_size

gen     chHH_size = moHH_size_c if chLiveMo != 2  // mo report
replace chHH_size = faHH_size_c if chLiveMo == 2  // fa report

gen     chHH_income = moHH_income if chLiveMo != 2    // mo report
replace chHH_income = faHH_income if chLiveMo == 2    // fa report

gen     chAvg_inc = moAvg_inc if chLiveMo != 2    // mo report
replace chAvg_inc = faAvg_inc if chLiveMo == 2    // fa report

* Poverty ratio FF (Child hh income ratio)
gen     incRatio = moHH_povratio if chLiveMo != 2   // mo report
replace incRatio = faHH_povratio if chLiveMo == 2   // fa report


keep idnum moYear moMonth ch* incRatio wave
order idnum moYear moMonth
sort idnum

ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

drop chFAM_member chFAM_female chFAM_relate chFAM_age chFAM_employ moMonth chLiveMo chFAM_size_f
replace chFAM_size = . if moYear == .


save "${TEMPDATADIR}/parents_Y1.dta", replace





********************************************************************************
******************************* VARIABLES YEAR 3 *******************************
********************************************************************************

*************************
** MERGE
*************************
use "${RAWDATADIR}/02_Three-Year Core/ffmom3ypv2.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/02_Three-Year Core/ffdad3ypv2.dta"
tab _merge
drop _merge

keep idnum cm3age cf3age cm3b_age m3intyr f3intyr m3intmon f3intmon m3intyr f3intyr c*3hhinc c*hhimp c*povco c*3povca *3f2b* *3f2c* *3f2d* *3f2f* *3f1 c*3adult c*3kids m3a2 m3a3a

missingvalues	// recode missing values

*************************
** DEMOGRAPHICS
*************************
rename cm3age 	moAge		// age mother
rename cf3age	faAge		// age father
rename cm3b_age	chAge		// age child
rename m3intyr	moYear		// interview year mother
rename f3intyr	faYear		// interview year father
rename m3intmon moMonth	// interview month mother
rename f3intmon faMonth	// interview month father
gen moCohort3    = moYear - moAge		// cohort mother
gen faCohort3    = faYear - faAge		// cohort father

*************************
** HH INCOME 
*************************
local int = 1
local num : word count mo fa
while `int' <= `num' {
	local parent    : word `int' of     mo  fa
	local letter    : word `int' of     m   f
	local int = `int' + 1

	rename c`letter'3hhinc `parent'HH_income 
	rename c`letter'3hhimp `parent'HH_income_f
	rename c`letter'3povco `parent'HH_povratio
	rename c`letter'3povca `parent'HH_povcat
}

*************************
** HH STRUCTURE
*************************
local int = 1
local num : word count mo fa
while `int' <= `num' {
    local parent    : word `int' of     mo  fa
    local letter    : word `int' of     m   f
    local int = `int' + 1

    forvalues member = 1/10 {

        * GENDER hh member
        gen     `parent'HH_female`member'   = .
        replace `parent'HH_female`member'   = 1   if `letter'3f2b`member' == 2
        replace `parent'HH_female`member'   = 0   if `letter'3f2b`member' == 1

        * AGE and RELATIONSHIP hh member
		rename `letter'3f2c`member' `parent'HH_age`member'
		rename `letter'3f2d`member' `parent'HH_relate`member'

        * EMPLOYMENT hh member
        gen     `parent'HH_employ`member'   = .
        replace `parent'HH_employ`member'   = 1   if `letter'3f2f`member' == 1
        replace `parent'HH_employ`member'   = 0   if `letter'3f2f`member' == 2
    }
}

* HH size
gen		moHH_size_s	= m3f1 + 1		// self-reported
gen		faHH_size_s	= f3f1 + 1		// self-reported
gen     moHH_size_c = cm3adult + cm3kids		// constructed
gen     faHH_size_c = cf3adult + cf3kids		// constructed


*************************
** CHILD LIVING ARR.
*************************
codebook m3a2		// how much time
codebook m3a3a		// usually live with

gen 	chLiveMo = .
replace chLiveMo = 1 if (m3a2 == 1 | m3a2 == 2)	 // mother (most & half)
replace chLiveMo = 0 if (m3a2 != 1 & m3a2 != 2 & m3a3a == 1)	// father
label var chLiveMo      "Baby lives with mother"

keep idnum mo* fa* ch* // cm1relf

reshape long moHH_female moHH_age moHH_relate moHH_employ faHH_female faHH_age faHH_relate faHH_employ, i(idnum) j(noHH_member)

gen wave		= 3
keep idnum mo* fa* ch* no* wave
order idnum wave

*************************
** MISSING VALUES
*************************
foreach parent in moHH faHH {
    foreach var in `parent'_female `parent'_age `parent'_relate `parent'_employ {
        replace `var' = . if (`var' == .a | `var' == .b | `var' == .c | `var' == .f | `var' == .i)
    }
}

*************************
** PARENTS FAM STRUCTURE
*************************
tab moHH_relate
tab faHH_relate
/* 1 = spouse, 2 = partner, 5 = child, 6 = stepchild, 14 = adopted */

/* In family only partner and children under the age of 18. */
foreach parent in mo fa {
    
    * Relationship to respondent
    gen     `parent'FAM_relate = .
    replace `parent'FAM_relate = `parent'HH_relate if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 14)
    replace `parent'FAM_relate = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_relate = . if (`parent'HH_relate == 6 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_relate = . if (`parent'HH_relate == 14 & `parent'HH_age > 18) // child under 18

    * Gender hh member
    gen     `parent'FAM_female = .
    replace `parent'FAM_female = `parent'HH_female if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 14)
    replace `parent'FAM_female = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_female = . if (`parent'HH_relate == 6 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_female = . if (`parent'HH_relate == 14 & `parent'HH_age > 18) // child under 18

    * Age hh member
    gen     `parent'FAM_age = .
    replace `parent'FAM_age = `parent'HH_age if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 14)
    replace `parent'FAM_age = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_age = . if (`parent'HH_relate == 6 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_age = . if (`parent'HH_relate == 14 & `parent'HH_age > 18) // child under 18

    * Employment hh member
    gen     `parent'FAM_employ = .
    replace `parent'FAM_employ = `parent'HH_employ if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 14)
    replace `parent'FAM_employ = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_employ = . if (`parent'HH_relate == 6 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_employ = . if (`parent'HH_relate == 14 & `parent'HH_age > 18) // child under 18

    * Family size
    gen temp`parent' = 1 if `parent'FAM_relate != .
    bysort temp`parent' idnum : gen `parent'FAM_member = _n if `parent'FAM_relate != .
    drop temp`parent'

    egen `parent'FAM_size = count(`parent'FAM_member), by(idnum)
    replace `parent'FAM_size = `parent'FAM_size + 1    // Add parent
}

*************************
** CHILD FAMILY STRUCTURE
*************************
/* IF chLiveMo missing: mother report as default */
foreach var in member female relate age employ size {
    gen     chFAM_`var' = moFAM_`var' if chLiveMo == 1 // mother report
    replace chFAM_`var' = faFAM_`var' if chLiveMo == 2 // father report
    replace chFAM_`var' = moFAM_`var' if (chLiveMo != 1 & chLiveMo != 2)  // default

}

gen     chFAM_size_f  = 1 if chLiveMo != 2    // mother
replace chFAM_size_f  = 0 if chLiveMo == 2    // father
label   define chFAM_size_f 0 "Father report" 1 "Mother report"
label   values chFAM_size_f chFAM_size_f

*************************
* CHILD FAMILY & HH INCOME
*************************
/* Total family income in Thompson, 2018:
Sum of income for mother + spouse: wages, salaries, business and farm operation
profits, unemployment insurance and child support payments */
/* INCOME LAG? */

/* Divide by # of hh members and multiply by family members  */
gen     moAvg_inc = (moHH_income / moHH_size_c) * moFAM_size
gen     faAvg_inc = (faHH_income / faHH_size_c) * faFAM_size

gen     chHH_size = moHH_size_c if chLiveMo != 2  // mo report
replace chHH_size = faHH_size_c if chLiveMo == 2  // fa report

gen     chHH_income = moHH_income if chLiveMo != 2    // mo report
replace chHH_income = faHH_income if chLiveMo == 2    // fa report

gen     chAvg_inc = moAvg_inc if chLiveMo != 2    // mo report
replace chAvg_inc = faAvg_inc if chLiveMo == 2    // fa report

* Poverty ratio FF (Child hh income ratio)
gen     incRatio = moHH_povratio if chLiveMo != 2   // mo report
replace incRatio = faHH_povratio if chLiveMo == 2   // fa report


keep idnum moYear moMonth ch* incRatio wave
order idnum moYear moMonth
sort idnum

ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

drop chFAM_member chFAM_female chFAM_relate chFAM_age chFAM_employ moMonth chLiveMo chFAM_size_f
replace chFAM_size = . if moYear == .



save "${TEMPDATADIR}/parents_Y3.dta", replace




********************************************************************************
******************************* VARIABLES YEAR 5 *******************************
********************************************************************************

*************************
** MERGE
*************************
use "${RAWDATADIR}/03_Five-Year Core/ffmom5ypv1.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/03_Five-Year Core/ffdad5ypv1.dta"
tab _merge
drop _merge

keep idnum c*4age cm4b_age *4intyr *4intmon c*4hhinc c*4hhimp c*4povco c*4povca *4f2b* *4f2c* *4f2d* *4f2f* *4f1 m4a2 m4a3a2 c*4adult c*4kids

missingvalues	// recode missing values

*************************
** DEMOGRAPHICS
*************************
rename cm4age 	moAge
rename cf4age 	faAge
rename cm4b_age	chAge
rename m4intyr	moYear
rename f4intyr	faYear
rename m4intmon	moMonth
rename f4intmon	faMonth
gen moCohort    = moYear - moAge
gen faCohort    = faYear - faAge

*************************
** HH INCOME
*************************
local int = 1
local num : word count mo fa
while `int' <= `num' {
    local parent    : word `int' of     mo  fa
    local letter    : word `int' of     m   f
    local int = `int' + 1

	rename c`letter'4hhinc 	`parent'HH_income
	rename c`letter'4hhimp	`parent'HH_income_f
	rename c`letter'4povco	`parent'HH_povratio
	rename c`letter'4povca	`parent'HH_povcat
}

*************************
** HH STRUCTURE
*************************
local int = 1
local num : word count mo fa
while `int' <= `num' {
    local parent    : word `int' of     mo  fa
    local letter    : word `int' of     m   f
    local int = `int' + 1

    forvalues member = 1/10 {

        * GENDER hh member
        gen     `parent'HH_female`member'   = .
        replace `parent'HH_female`member'   = 1   if `letter'4f2b`member' == 2
        replace `parent'HH_female`member'   = 0   if `letter'4f2b`member' == 1

        * AGE and RELATIONSHIP hh member
		rename `letter'4f2c`member'	`parent'HH_age`member'
		rename `letter'4f2d`member'	`parent'HH_relate`member'
		/* 1 = spouse, 2 = partner, 6 = biochild, 16 = adopted
		7 = step child , 8 = foster child */

        * EMPLOYMENT hh member
        gen     `parent'HH_employ`member'   = .
        replace `parent'HH_employ`member'   = 1   if `letter'4f2f`member' == 1
        replace `parent'HH_employ`member'   = 0   if `letter'4f2f`member' == 2
    }
}

* HH size
gen		moHH_size_s	= m4f1 + 1		// self-reported
gen		faHH_size_s	= f4f1 + 1		// self-reported
gen     moHH_size_c   	= cm4adult + cm4kids		// constructed
gen     faHH_size_c   	= cf4adult + cf4kids		// constructed


*************************
** CHILD LIVING ARR.
*************************
codebook m4a2		// how much time
codebook m4a3a2		// usually live with

gen 	chLiveMo = .
replace chLiveMo = 1 if (m4a2 == 1 | m4a2 == 2)	// mother (most & half)
replace chLiveMo = 0 if (m4a2 != 1 & m4a2 != 2 & m4a3a2 == 1)	// father
label var chLiveMo      "Baby lives with mother"

keep idnum mo* fa* ch* // cm1relf

reshape long moHH_female moHH_age moHH_relate moHH_employ faHH_female faHH_age faHH_relate faHH_employ, i(idnum) j(noHH_member)

gen wave		= 5
keep idnum mo* fa* ch* no* wave
order idnum wave

*************************
** MISSING VALUES
*************************
foreach parent in moHH faHH {
    foreach var in `parent'_female `parent'_age `parent'_relate `parent'_employ {
        replace `var' = . if (`var' == .a | `var' == .b | `var' == .c | `var' == .f | `var' == .i)
    }
}

*************************
** PARENTS FAM STRUCTURE
*************************
tab moHH_relate
tab faHH_relate
/* 1 = spouse, 2 = partner, 6 = child, 7 = stepchild, 16 = adopted */

/* In family only partner and children under the age of 18. */
foreach parent in mo fa {
    
    * Relationship to respondent
    gen     `parent'FAM_relate = .
    replace `parent'FAM_relate = `parent'HH_relate if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 7 | `parent'HH_relate == 16)
    replace `parent'FAM_relate = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_relate = . if (`parent'HH_relate == 6 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_relate = . if (`parent'HH_relate == 7 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_relate = . if (`parent'HH_relate == 16 & `parent'HH_age > 18) // child under 18

    * Gender hh member
    gen     `parent'FAM_female = .
    replace `parent'FAM_female = `parent'HH_female if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 7 | `parent'HH_relate == 16)
    replace `parent'FAM_female = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_female = . if (`parent'HH_relate == 6 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_female = . if (`parent'HH_relate == 7 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_female = . if (`parent'HH_relate == 16 & `parent'HH_age > 18) // child under 18

    * Age hh member
    gen     `parent'FAM_age = .
    replace `parent'FAM_age = `parent'HH_age if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 7 | `parent'HH_relate == 16)
    replace `parent'FAM_age = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_age = . if (`parent'HH_relate == 6 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_age = . if (`parent'HH_relate == 7 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_age = . if (`parent'HH_relate == 16 & `parent'HH_age > 18) // child under 18

    * Employment hh member
    gen     `parent'FAM_employ = .
    replace `parent'FAM_employ = `parent'HH_employ if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 101 | `parent'HH_relate == 102)
    replace `parent'FAM_employ = . if (`parent'HH_relate == 5 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_employ = . if (`parent'HH_relate == 6 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_employ = . if (`parent'HH_relate == 7 & `parent'HH_age > 18) // child under 18
    replace `parent'FAM_employ = . if (`parent'HH_relate == 16 & `parent'HH_age > 18) // child under 18

    * Family size
    gen temp`parent' = 1 if `parent'FAM_relate != .
    bysort temp`parent' idnum : gen `parent'FAM_member = _n if `parent'FAM_relate != .
    drop temp`parent'

    egen `parent'FAM_size = count(`parent'FAM_member), by(idnum)
    replace `parent'FAM_size = `parent'FAM_size + 1    // Add parent
}

*************************
** CHILD FAMILY STRUCTURE
*************************
/* IF chLiveMo missing: mother report as default */
foreach var in member female relate age employ size {
    gen     chFAM_`var' = moFAM_`var' if chLiveMo == 1 // mother report
    replace chFAM_`var' = faFAM_`var' if chLiveMo == 2 // father report
    replace chFAM_`var' = moFAM_`var' if (chLiveMo != 1 & chLiveMo != 2)  // default

}

gen     chFAM_size_f  = 1 if chLiveMo != 2    // mother
replace chFAM_size_f  = 0 if chLiveMo == 2    // father
label   define chFAM_size_f 0 "Father report" 1 "Mother report"
label   values chFAM_size_f chFAM_size_f

*************************
* CHILD FAMILY & HH INCOME
*************************
/* Total family income in Thompson, 2018:
Sum of income for mother + spouse: wages, salaries, business and farm operation
profits, unemployment insurance and child support payments */
/* INCOME LAG? */

/* Divide by # of hh members and multiply by family members  */
gen     moAvg_inc = (moHH_income / moHH_size_c) * moFAM_size
gen     faAvg_inc = (faHH_income / faHH_size_c) * faFAM_size

gen     chHH_size = moHH_size_c if chLiveMo != 2  // mo report
replace chHH_size = faHH_size_c if chLiveMo == 2  // fa report

gen     chHH_income = moHH_income if chLiveMo != 2    // mo report
replace chHH_income = faHH_income if chLiveMo == 2    // fa report

gen     chAvg_inc = moAvg_inc if chLiveMo != 2    // mo report
replace chAvg_inc = faAvg_inc if chLiveMo == 2    // fa report

* Poverty ratio FF (Child hh income ratio)
gen     incRatio = moHH_povratio if chLiveMo != 2   // mo report
replace incRatio = faHH_povratio if chLiveMo == 2   // fa report


keep idnum moYear moMonth ch* incRatio wave
order idnum moYear moMonth
sort idnum

ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

drop chFAM_member chFAM_female chFAM_relate chFAM_age chFAM_employ moMonth chLiveMo chFAM_size_f
replace chFAM_size = . if moYear == .


save "${TEMPDATADIR}/parents_Y5.dta", replace

* Left: idnum moYear chAge chFAM_size chHH_size chHH_income chAvg_inc incRatio

********************************************************************************
******************************* VARIABLES YEAR 9 *******************************
********************************************************************************


