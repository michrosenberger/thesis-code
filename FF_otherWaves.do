* Project:      MA Thesis
* Content:      Family demographics FF
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
    global USERPATH		"/Users/michellerosenberger/Development/MA"
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
******************************* VARIABLES YEAR 1 *******************************
********************************************************************************

*************************
** MERGE																	OKK
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
rename cm2age 	moAge1		// age mother
rename cf2age 	faAge1		// age father
rename cm2b_age chAge1		// age child
rename m2intyr	moYear1		// interview year mother
rename f2intyr 	faYear1		// interview year father
rename m2intmon	moMonth1	// interview month mother
rename f2intmon	faMonth1	// interview month father
gen moCohort1    = moYear1 - moAge1		// cohort mother
gen faCohort1    = faYear1 - faAge1		// cohort father

gen wave        = 1

*************************
** HH INCOME 
*************************
local int = 1
local num : word count mo fa
while `int' <= `num' {
    local parent    : word `int' of     mo  fa
    local letter    : word `int' of     m   f
    local int = `int' + 1

	rename c`letter'2hhinc `parent'HH_income1
	rename c`letter'2hhimp `parent'HH_income_f1
	rename c`letter'2povco `parent'HH_povratio1
	rename c`letter'2povca `parent'HH_povcat1
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
		/* 1 = spouse, 2 = partner, 5 = child, 101 = New partner, 102 = new spouse */
		
		* EMPLOYMENT hh member
		gen     `parent'HH_employ`member'   = .
		replace `parent'HH_employ`member'   = 1   if `letter'2f2e`member' == 1
		replace `parent'HH_employ`member'   = 0   if `letter'2f2e`member' == 2
	}
}

* HH size
gen	moHH_size_s1	= m2f1 + 1		// self-reported
gen	faHH_size_s1	= f2f1 + 1		// self-reported
gen	moHH_size_c1	= cm2adult + cm2kids		// constructed
gen	faHH_size_c1	= cf2adult + cf2kids		// constructed


*************************
** CHILD LIVING ARR.
*************************
codebook m2a3		// how much time
codebook m2a4a		// usually live with

gen 	chLiveMo1 = .
replace chLiveMo1 = 1 if (m2a3 == 1 | m2a3 == 2)				// mother (all or halftime)
replace chLiveMo1 = 0 if (m2a3 != 1 & m2a3 != 2 & m2a4a == 1)	// father
label var chLiveMo1      "Baby lives with mother"

keep idnum mo* fa* ch*
save "${TEMPDATADIR}/parents_Y1.dta", replace

********************************************************************************
******************************* VARIABLES YEAR 3 *******************************
********************************************************************************

*************************
** MERGE																	OKK
*************************
use "${RAWDATADIR}/02_Three-Year Core/ffmom3ypv2.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/02_Three-Year Core/ffdad3ypv2.dta"
tab _merge
drop _merge

keep idnum cm3age cf3age cm3b_age m3intyr f3intyr m3intmon f3intmon m3intyr f3intyr c*3hhinc c*hhimp c*povco c*3povca *3f2b* *3f2c* *3f2d* *3f2f* *3f1 c*3adult c*3kids m3a2 m3a3a

missingvalues	// recode missing values

gen wave        = 3

*************************
** DEMOGRAPHICS
*************************
rename cm3age 	moAge3		// age mother
rename cf3age	faAge3		// age father
rename cm3b_age	chAge3		// age child
rename m3intyr	moYear3		// interview year mother
rename f3intyr	faYear3		// interview year father
rename m3intmon moMonth3	// interview month mother
rename f3intmon faMonth3	// interview month father
gen moCohort3    = moYear3 - moAge3		// cohort mother
gen faCohort3    = faYear3 - faAge3		// cohort father

*************************
** HH INCOME 
*************************
local int = 1
local num : word count mo fa
while `int' <= `num' {
	local parent    : word `int' of     mo  fa
	local letter    : word `int' of     m   f
	local int = `int' + 1

	rename c`letter'3hhinc `parent'HH_income3 
	rename c`letter'3hhimp `parent'HH_income_f3
	rename c`letter'3povco `parent'HH_povratio3
	rename c`letter'3povca `parent'HH_povcat3
}

*************************
** HH STRUCTURE					// no. 3?
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
		/* 1 = spouse, 2 = partner, 5 = biochild, 14 = adopted */

        * EMPLOYMENT hh member
        gen     `parent'HH_employ`member'   = .
        replace `parent'HH_employ`member'   = 1   if `letter'3f2f`member' == 1
        replace `parent'HH_employ`member'   = 0   if `letter'3f2f`member' == 2
    }
}

* HH size
gen		moHH_size_s3	= m3f1 + 1		// self-reported
gen		faHH_size_s3	= f3f1 + 1		// self-reported
gen     moHH_size_c3   	= cm3adult + cm3kids		// constructed
gen     faHH_size_c3   	= cf3adult + cf3kids		// constructed


*************************
** CHILD LIVING ARR.
*************************
codebook m3a2		// how much time
codebook m3a3a		// usually live with

gen 	chLiveMo3 = .
replace chLiveMo3 = 1 if (m3a2 == 1 | m3a2 == 2)				// mother (most & half)
replace chLiveMo3 = 0 if (m3a2 != 1 & m3a2 != 2 & m3a3a == 1)	// father
label var chLiveMo3      "Baby lives with mother"

keep idnum mo* fa* ch*
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
rename cm4age 	moAge5
rename cf4age 	faAge5
rename cm4b_age	chAge5
rename m4intyr	moYear5
rename f4intyr	faYear5
rename m4intmon	moMonth5
rename f4intmon	faMonth5
gen moCohort5    = moYear5 - moAge5
gen faCohort5    = faYear5 - faAge5

gen wave        = 5

*************************
** HH INCOME 					// no. 5?
*************************
local int = 1
local num : word count mo fa
while `int' <= `num' {
    local parent    : word `int' of     mo  fa
    local letter    : word `int' of     m   f
    local int = `int' + 1

	rename c`letter'4hhinc 	`parent'HH_income5
	rename c`letter'4hhimp	`parent'HH_income_f5
	rename c`letter'4povco	`parent'HH_povratio5
	rename c`letter'4povca	`parent'HH_povcat5
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
gen		moHH_size_s5	= m4f1 + 1		// self-reported
gen		faHH_size_s5	= f4f1 + 1		// self-reported
gen     moHH_size_c5   	= cm4adult + cm4kids		// constructed
gen     faHH_size_c5   	= cf4adult + cf4kids		// constructed


*************************
** CHILD LIVING ARR.
*************************
codebook m4a2		// how much time
codebook m4a3a2		// usually live with

gen 	chLiveMo5 = .
replace chLiveMo5 = 1 if (m4a2 == 1 | m4a2 == 2)				// mother (most & half)
replace chLiveMo5 = 0 if (m4a2 != 1 & m4a2 != 2 & m4a3a2 == 1)	// father
label var chLiveMo5      "Baby lives with mother"


keep idnum mo* fa* ch*
save "${TEMPDATADIR}/parents_Y5.dta", replace

********************************************************************************
******************************* VARIABLES YEAR 9 *******************************
********************************************************************************
