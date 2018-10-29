*************************
* Family structure - Fragile families
*************************
global USERPATH     	"/Users/michellerosenberger/Development/MA"
global RAWDATADIR		"${USERPATH}/data/FragileFamilies/raw"
global CLEANDATADIR		"${USERPATH}/data/FragileFamilies/clean"
global TEMPDATADIR		"${USERPATH}/data/FragileFamilies/temp1"

use "${RAWDATADIR}/00_Baseline/ffmombspv3.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/00_Baseline/ffdadbspv3.dta"
tab _merge
drop _merge

// Save all variables (except ID) in global macro
ds, has(type numeric)				// only numeric variables
global ALLVARIABLES = r(varlist)
macro list ALLVARIABLES				// show variables

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
	}

** Demographics
foreach parent in m f {
    gen `parent'educ = cm1edu      // mother education
    gen `parent'race = cm1ethrace  // mother race
    label values `parent'educ educ_mw1
    label values `parent'race race_mw1
}

** Income
foreach parent in m f {
    gen `parent'hh_income      = cm1hhinc
    gen `parent'hh_income_flag = cm1hhimp
    gen `parent'hh_povratio    = cm1inpov * 100
    gen `parent'hh_povcat      = cm1povca
    label values `parent'hh_income nolab_mw1
    label values `parent'hh_income_flag impute_mw1
    label values `parent'hh_povratio nolab_mw1
    label values `parent'hh_povcat pov1_mw1
}

** Household
foreach parent in m f {
    forvalues member = 1/8 {
        gen `parent'hh_female`member'   = .
            replace `parent'hh_female`member' = 1   if `parent'1e1c`member' == 2
            replace `parent'hh_female`member' = 0   if `parent'1e1c`member' == 1
        gen `parent'hh_age`member'      =   `parent'1e1d`member'
        gen `parent'hh_relate`member'   =   `parent'1e1b`member'          // Add labels
        gen `parent'hh_employ`member'   = .
            replace `parent'hh_employ`member' = 1   if `parent'1e1e`member' == 1
            replace `parent'hh_employ`member' = 0   if `parent'1e1e`member' == 2
    }
}

foreach parent in m f {
    gen `parent'year    = `parent'1intyr
    gen `parent'month   = `parent'1intmon
    label values `parent'year nolab_mw1
    label values `parent'month mon_mw1
}

keep idnum *hh_* *year *month meduc mrace feduc frace *hh_income* *hh_pov*

reshape long mhh_female mhh_age mhh_relate mhh_employ fhh_female fhh_age fhh_relate fhh_employ, i(idnum) j(hh_member)

foreach parent in m f {
    foreach var in `parent'hh_female `parent'hh_age `parent'hh_relate `parent'hh_employ {
        replace `var' = . if ( `var' == .a | `var' == .b | `var' == .c | `var' == .f | `var' == .i )
    }
}

foreach parent in m f {
    drop if (`parent'hh_relate == . & `parent'hh_female == . & `parent'hh_age == . & `parent'hh_employ == .) // skip those with missing information / maybe not afterwards when other waves
}

** Family
/* In family only mother / father, spouse and children under the age of 18. */
foreach parent in m f {
    gen `parent'fam_relate  = .
        replace `parent'fam_relate = `parent'hh_relate  if (`parent'hh_relate == 0 | `parent'hh_relate == 3 | `parent'hh_relate == 5)
        replace `parent'fam_relate = .          if ( `parent'hh_relate == 5 & `parent'hh_age > 18)
    gen `parent'fam_female  = .
        replace `parent'fam_female = `parent'hh_female  if (`parent'hh_relate == 0 | `parent'hh_relate == 3 | `parent'hh_relate == 5)
        replace `parent'fam_female = .          if ( `parent'hh_relate == 5 & `parent'hh_age > 18)
    gen `parent'fam_age     = .
        replace `parent'fam_age = `parent'hh_age        if (`parent'hh_relate == 0 | `parent'hh_relate == 3 | `parent'hh_relate == 5)
        replace `parent'fam_age = .             if ( `parent'hh_relate == 5 & `parent'hh_age > 18)
    gen `parent'fam_employ     = .
        replace `parent'fam_employ = `parent'hh_employ  if (`parent'hh_relate == 0 | `parent'hh_relate == 3 | `parent'hh_relate == 5)
        replace `parent'fam_employ = .          if ( `parent'hh_relate == 5 & `parent'hh_age > 18)

    gen temp`parent' = 1 if `parent'fam_relate != .
    sort temp`parent'
    bysort temp`parent' idnum : gen `parent'fam_member = _n if `parent'fam_relate != .
    drop temp`parent'

    egen `parent'hh_size = count(hh_member), by(idnum)
    replace `parent'hh_size = `parent'hh_size + 1       // Add mother

    egen `parent'fam_size = count(`parent'fam_member), by(idnum)
    replace `parent'fam_size = `parent'fam_size + 1
    
}

label list hhrelat_mw1
label values mhh_relate mfam_relate fhh_relate ffam_relate hhrelat_mw1

label define female 1 "female" 0 "male"
label values mhh_female mfam_female fhh_female ffam_female female

label define employed 1 "employed" 0 "unemployed"
label values mhh_employ mfam_employ fhh_employ ffam_employ employed

order idnum myear mmonth hh_member mhh_size mhh_relate mhh_female mhh_age mhh_employ mfam_member mfam_size mfam_relate mfam_female mfam_age mfam_employ
label data "Household structure (baseline)"
foreach parent in m f {
    foreach var in fam hh {
        label var `parent'fam_member    "Number fam member (`parent')"
        label var  hh_member            "Number hh member"
        label var `parent'`var'_female  "Gender `var' member (`parent')"
        label var `parent'`var'_age     "Age `var' member (`parent')"
        label var `parent'`var'_relate  "Relationship to mother `var' member (`parent')"
        label var `parent'`var'_employ  "Employment `var' member (`parent')"
        label var `parent'`var'_size    "Number of `var' members in hh (`parent')"
        label var `parent'year          "Year interview (`parent')"
        label var `parent'month         "Month interview (`parent')"
        label var `parent'educ          "Education (`parent')"
        label var `parent'race          "Race (`parent')"
        label var `parent'hh_income     "HH income (`parent')"
        label var `parent'hh_income_flag "HH income flag (`parent')"
        label var `parent'hh_povratio   "Poverty ratio % (`parent')"
        label var `parent'hh_povcat     "Poverty category (`parent')"

    }
}

// gen state = .

// for all waves - check if all waves have
// check when use father data
// Choose # of HH members from father or mother depending on where the baby lives
// focal baby also included?
// make names equal
// lag income

/* Mother married or cohabiting with father
gen together = (cm1relf == 1 | cm1relf == 2)
*/


/*
Constructed variables

cm1age      mother age
cm1bsex     baby gender
cm*b_age    baby age

cm1relf     hh relationship mother
cm1adult    # of adults in hh
cm1kids     # of kids in hh

cm1edu      mother education            OK both
cm1ethrace  mother race                 OK both

cm1hhinc    hh income                   OK both
cm1hhimp    hh flag                     OK both
cm1inpov    poverty ratio               OK both
cm1povca    poverty category            OK both

Notes:
Divide by members to get avg. income per family member
*/

describe

save "${TEMPDATADIR}/household.dta", replace

*************************
* Income
*************************
/* Total family income in Thompson, 2018:
Sum of income for mother + spouse: wages, salaries, business and farm operation
profits, unemployment insurance and child support payments

codebook cm1hhinc
codebook cm2hhinc
codebook cm3hhinc
codebook cm4hhinc 
*/


/* STRUCTURE CPS
year    statefip    month pernum  idnum  relate  age  gender 
htwsupp wtsupp      offtotval   offcutoff   inratio asecflag

inratio = offtotal / offcutoff
*/

/* STRUCTURE

ID  YEAR  FAMSIZE INRATIO
1   1998    1       5
1   1999    2       5


Own farm, own wages, spouse farm, spouse wages, child support, other sources, AFDC

Lag variables one year before
local year = "1979"
local yearlag = "1978"
while `year'<=1994 {
rename 
local year=`year'+1
local yearlag=`yearlag'+1


foreach year of numlist 1978(1)1993 1995(2)2011 {
egen income_`year'=rowtotal(Q13_9_`year' Q13_5_`year' Q13_18_`year' Q13_24_`year' Q13_33I_`year' Q13_75_`year' UNEMPR_TOTAL_`year'_XRND UNEMPSP_TOTAL_`year'_XRND), missing

*convert to long-form, merge on pov data, calc in-ratio, reshape back
reshape long  famSize income_ , i(identification) j(year) 
merge m:1  year famSize using PovertyLevels
drop if _merge==2 
drop _merge
g incomeRatio=income_/povLevel
drop povLevel  income_
reshape wide  incomeRatio famSize, i(identification) j(year) 

*/
