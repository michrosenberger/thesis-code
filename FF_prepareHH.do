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

********************************************************************************
*********************************** PROGRAMS ***********************************
********************************************************************************

* MISSING VALUES
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

* DEMOGRAPHICS
capture program drop demographics
program define demographics 
    args wave

    if wave == 0 {
        rename cm`wave'edu      moEduc          // mother education
        rename cf`wave'edu      faEduc          // father education
        rename cm`wave'ethrace  moRace          // mother race
        rename cf`wave'ethrace  faRace          // father race
        rename cm`wave'bsex     chGender        // child gender
        gen moWhite             = moRace == 1   // mother white
        gen moBlack             = moRace == 2   // mother black
        gen moHispanic          = moRace == 3   // mother hispanic
        gen moOther             = moRace == 4   // mother other
    }

    if wave == 0 | wave == 1 | wave == 3 | wave == 5 {
        rename m`wave'intyr	    moYear          // mother int year
        rename f`wave'intyr 	faYear          // father int year
        rename m`wave'intmon    moMonth	        // mother int month
        rename f`wave'intmon	faMonth	        // father int month
    }

    if wave == 9 {
        rename cm`wave'intyr	moYear          // mother int year
        rename cf`wave'intyr	faYear          // father int year
        rename cm`wave'intmon	moMonth         // mother int month
        rename cf`wave'intmon	faMonth         // father int month
    }

    if wave == 1 | wave == 3 | wave == 5 | wave == 9 {
        rename cm`wave'b_age    chAge           // child age
    }

    rename cm`wave'age 	        moAge           // mother age
    rename cf`wave'age 	        faAge           // father age
    gen moCohort                = moYear-moAge  // mother cohort
    gen faCohort                = faYear-faAge  // father cohort

end

* HH INCOME FF
capture program drop hh_incomeFF
program define hh_incomeFF
    args wave

    local int = 1
    local num : word count mo fa
    while `int' <= `num' {
        local parent    : word `int' of     mo  fa
        local letter    : word `int' of     m   f
        local int = `int' + 1

        rename c`letter'`wave'hhinc `parent'HH_income 
        rename c`letter'`wave'hhimp `parent'HH_income_f
        rename c`letter'`wave'povca `parent'HH_povcat

        if wave == 0 {
            rename c`letter'`wave'inpov `parent'HH_povratio
        }
        if wave > 0 {
            rename c`letter'`wave'povco `parent'HH_povratio
        }
    }

end

* CONSTRUCTED HH STRUCTURE FROM INDIVIDUALS IN HH
capture program drop hh_structure
program define hh_structure

    args wave numpeople femvar agevar relatevar employvar

    local int = 1
    local num : word count mo fa
    while `int' <= `num' {
        local parent    : word `int' of     mo  fa
        local letter    : word `int' of     m   f
        local int = `int' + 1

        forvalues member = `numpeople' {

            * GENDER hh member
            gen     `parent'HH_female`member'   = .
            replace `parent'HH_female`member'   = 1   if `letter'`femvar'`member' == 2
            replace `parent'HH_female`member'   = 0   if `letter'`femvar'`member' == 1

            * AGE and RELATIONSHIP hh member
            rename `letter'`agevar'`member' `parent'HH_age`member'
            rename `letter'`relatevar'`member' `parent'HH_relate`member'

            * EMPLOYMENT hh member
            gen     `parent'HH_employ`member'   = .
            replace `parent'HH_employ`member'   = 1   if `letter'`employvar'`member' == 1
            replace `parent'HH_employ`member'   = 0   if `letter'`employvar'`member' == 2
        }
    }

    if wave == 9 {
        forvalues member = 10/11 {

            gen     moHH_female`member'   = .
            replace moHH_female`member'   = 1   if m5a5b`member' == 2
            replace moHH_female`member'   = 0   if m5a5b`member' == 1

            rename m5a5c`member'	moHH_age`member'
            rename m5a5d`member'	moHH_relate`member'

            gen     moHH_employ`member'   = .
            replace moHH_employ`member'   = 1   if m5a5e`member' == 1
            replace moHH_employ`member'   = 0   if m5a5e`member' == 2
        }
    }

    * HH size
    gen     moHH_size_c   = cm`wave'adult + cm`wave'kids
    gen     faHH_size_c   = cf`wave'adult + cf`wave'kids

end

* CHILD LIVING ARR.
capture program drop living_arr
program define living_arr
    args timevar usuallyvar

    codebook `timevar'		    // how much time
    codebook `usuallyvar'		// usually live with

    gen 	chLiveMo = .
    replace chLiveMo = 1 if (`timevar' == 1 | `timevar' == 2)	 // mother (most & half)
    replace chLiveMo = 2 if (`timevar' != 1 & `timevar' != 2 & `usuallyvar' == 1)	// father
    label var chLiveMo      "Child lives with mother"

end


* RESHAPE & MISSING VALUES
capture program drop reshape_missing
program define reshape_missing

    * RESHAPE
    if wave == 0 {
        keep idnum mo* fa* ch* wave moWhite moBlack moHispanic moOther // cm1relf

        reshape long moHH_female moHH_age moHH_relate moHH_employ faHH_female faHH_age faHH_relate faHH_employ, i(idnum) j(noHH_member)

        keep idnum mo* fa* ch* no* wave moWhite moBlack moHispanic moOther
    }
    if wave > 0 {
        keep idnum mo* fa* ch* wave // cm1relf

        reshape long moHH_female moHH_age moHH_relate moHH_employ faHH_female faHH_age faHH_relate faHH_employ, i(idnum) j(noHH_member)

        keep idnum mo* fa* ch* no* wave
    }

    order idnum wave

    * MISSING VALUES
    foreach parent in moHH faHH {
        foreach var in `parent'_female `parent'_age `parent'_relate `parent'_employ {
            replace `var' = . if (`var' == .a | `var' == .b | `var' == .c | `var' == .f | `var' == .i)
        }
    }

end

* PARENTS FAM STRUCTURE
capture program drop fam_structure
program define fam_structure

    tab moHH_relate
    tab faHH_relate

    /* In family only partner and children under the age of 18. */
    foreach parent in mo fa {
        gen     `parent'FAM_relate  = .
        gen     `parent'FAM_female  = .
        gen     `parent'FAM_age     = .
        gen     `parent'FAM_employ  = .

        if wave == 0 {
        /* 0 = None, 3 = R's partner, 5 = Child, 6 = Other Child */
            foreach var in relate female age employ {
                replace `parent'FAM_`var' = `parent'HH_`var' if (`parent'HH_relate == 3 | `parent'HH_relate == 5)
            }
            foreach var in relate female age employ {
                replace `parent'FAM_`var' = . if (`parent'HH_relate == 5    & `parent'HH_age > 18)
            }
        }

        /* 1 = Spouse, 2 = R's partner, 5 = Bio Child, 6 = Stepchild,
        7 = Foster Child, 101 = new partner, 102 = new spouse */
        if wave == 1 {  // keep primary family members
            foreach var in relate female age employ {
                replace `parent'FAM_`var' = `parent'HH_`var' if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 101 | `parent'HH_relate == 102)
            }
            foreach var in relate female age employ {   // child
                replace `parent'FAM_`var' = . if (`parent'HH_relate == 5    & `parent'HH_age > 18)
                replace `parent'FAM_`var' = . if (`parent'HH_relate == 6    & `parent'HH_age > 18)
            }
        }

        if wave == 3 { 
        /* 1 = spouse, 2 = partner, 5 = Bio child, 6 = stepchild, 7 = Foster child
         14 = adopted child */
            foreach var in relate female age employ { // keep primary family members
                replace `parent'FAM_`var' = `parent'HH_`var' if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 5 | `parent'HH_relate == 6 | `parent'HH_relate == 14)
            }
            foreach var in relate female age employ { // child
                replace `parent'FAM_`var' = . if (`parent'HH_relate == 5    & `parent'HH_age > 18)
                replace `parent'FAM_`var' = . if (`parent'HH_relate == 6    & `parent'HH_age > 18)
                replace `parent'FAM_`var' = . if (`parent'HH_relate == 14   & `parent'HH_age > 18)
            }
        }

        if wave == 5 {
        /* 1 = spouse, 2 = partner, 6 = bio child, 7 = stepchild, 8 = foster child
        16 = adopted child */
            foreach var in relate female age employ { // keep primary family members
                replace `parent'FAM_`var' = `parent'HH_`var' if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 6 | `parent'HH_relate == 7 | `parent'HH_relate == 16)  
            }
            foreach var in relate female age employ { // child
                replace `parent'FAM_`var' = . if (`parent'HH_relate == 6    & `parent'HH_age > 18)
                replace `parent'FAM_`var' = . if (`parent'HH_relate == 7    & `parent'HH_age > 18)
                replace `parent'FAM_`var' = . if (`parent'HH_relate == 16   & `parent'HH_age > 18)
            }
        }

        if wave == 9 {
        /* 1 = spouse, 2 = partner, 6 = bio child, 7 = step child, 8 = foster child
        16 = adopted child */
            foreach var in relate female age employ { // keep primary family members
                replace `parent'FAM_`var' = `parent'HH_`var' if (`parent'HH_relate == 1 | `parent'HH_relate == 2 | `parent'HH_relate == 6 | `parent'HH_relate == 7 | `parent'HH_relate == 16 )
            }
            foreach var in relate female age employ {
                replace `parent'FAM_`var' = . if (`parent'HH_relate == 6    & `parent'HH_age > 18)
                replace `parent'FAM_`var' = . if (`parent'HH_relate == 7    & `parent'HH_age > 18)
                replace `parent'FAM_`var' = . if (`parent'HH_relate == 16   & `parent'HH_age > 18)

            }
        }

        * Family size
        gen temp`parent' = 1 if `parent'FAM_relate != .
        bysort temp`parent' idnum : gen `parent'FAM_member = _n if `parent'FAM_relate != .
        drop temp`parent'

        egen `parent'FAM_size = count(`parent'FAM_member), by(idnum)
        replace `parent'FAM_size = `parent'FAM_size + 1    // Add parent
    }

end


* CONSTRUCTED CHILD FAM STRUCTURE & FAM / HH INCOME
capture program drop fam_structure_income
program define fam_structure_income

    * FAM STRUCTURE
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

    * INCOME
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

    * COLLAPSE AND SAVE
    if wave == 0 {
        keep idnum moYear moMonth ch* incRatio wave moAge moWhite moBlack moHispanic moOther
    }
    if wave > 0 {
        keep idnum moYear moMonth ch* incRatio wave
    }
    order idnum moYear moMonth
    sort idnum

    ds idnum, not
    global FINALVARS = r(varlist)
    collapse $FINALVARS, by(idnum)

    drop chFAM_member chFAM_female chFAM_relate chFAM_age chFAM_employ moMonth chLiveMo chFAM_size_f
    replace chFAM_size = . if moYear == .

end

********************************************************************************
****************************** VARIABLES BASELINE ******************************
********************************************************************************
use "${RAWDATADIR}/00_Baseline/ffmombspv3.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/00_Baseline/ffdadbspv3.dta", nogen

keep idnum c*1edu c*1ethrace c*1age cm1bsex *1intyr *1intmon c*1hhinc ///
c*1hhimp c*1inpov c*1povca *1e1c* *1e1d* *1e1b* *1e1e* c*1kids c*1adult m1a11a

gen wave = 0

missingvalues           // recode missing values pro.
demographics    1       // demographics pro.
hh_incomeFF     1       // hh income FF pro.

hh_structure 1 1/8 1e1c 1e1d 1e1b 1e1e  // hh structure from inidviduals pro.

rename m1a11a chLiveMo  // child living arrangement pro.

reshape_missing         // reshape & missing values pro.
fam_structure           // parents fam structure pro.
fam_structure_income    // child fam structure & fam / hh income

save "${TEMPDATADIR}/parents_Y0.dta", replace

* For simulated instrument propensity score matching
keep moAge incRatio moWhite moBlack moHispanic moOther
gen FF = 1
rename moAge momGeb
save "${TEMPDATADIR}/mothers_FF.dta", replace

********************************************************************************
******************************* VARIABLES YEAR 1 *******************************
********************************************************************************
use "${RAWDATADIR}/01_One-Year Core/ffmom1ypv2.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/01_One-Year Core/ffdad1ypv2.dta", nogen

keep idnum c*2age cm2b_age *2intyr *2intmon c*2hhinc c*2hhimp c*2povco ///
c*2povca *2f2b* *2f2c* *2f2d* *2f2e* *2f1 c*2adult c*2kids m2a3 m2a4a

gen wave = 1

missingvalues           // recode missing values pro.
demographics    2       // demographics pro.
hh_incomeFF     2       // hh income FF pro.

hh_structure 2 1/10 2f2b 2f2c 2f2d 2f2e // hh structure from inidviduals pro.

gen	moHH_size_s	= m2f1 + 1		// self-reported
gen	faHH_size_s	= f2f1 + 1		// self-reported

living_arr m2a3 m2a4a   // child living arrangement pro.
reshape_missing         // reshape & missing values pro.
fam_structure           // parents fam structure pro.
fam_structure_income    // child fam structure & fam / hh income

save "${TEMPDATADIR}/parents_Y1.dta", replace

********************************************************************************
******************************* VARIABLES YEAR 3 *******************************
********************************************************************************
use "${RAWDATADIR}/02_Three-Year Core/ffmom3ypv2.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/02_Three-Year Core/ffdad3ypv2.dta", nogen

keep idnum cm3age cf3age cm3b_age m3intyr f3intyr m3intmon f3intmon m3intyr ///
f3intyr c*3hhinc c*hhimp c*povco c*3povca *3f2b* *3f2c* *3f2d* *3f2f* *3f1 ///
c*3adult c*3kids m3a2 m3a3a

gen wave = 3

missingvalues           // recode missing values pro.
demographics    3       // demographics pro.
hh_incomeFF     3       // hh income FF pro.

hh_structure 3 1/10 3f2b 3f2c 3f2d 3f2f // hh structure from inidviduals pro.

gen		moHH_size_s	= m3f1 + 1		// self-reported
gen		faHH_size_s	= f3f1 + 1		// self-reported

living_arr m3a2 m3a3a   // child living arrangement pro.
reshape_missing         // reshape & missing values pro.
fam_structure           // parents fam structure pro.
fam_structure_income    // child fam structure & fam / hh income

save "${TEMPDATADIR}/parents_Y3.dta", replace

********************************************************************************
******************************* VARIABLES YEAR 5 *******************************
********************************************************************************
use "${RAWDATADIR}/03_Five-Year Core/ffmom5ypv1.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/03_Five-Year Core/ffdad5ypv1.dta", nogen

keep idnum c*4age cm4b_age *4intyr *4intmon c*4hhinc c*4hhimp c*4povco ///
c*4povca *4f2b* *4f2c* *4f2d* *4f2f* *4f1 m4a2 m4a3a2 c*4adult c*4kids

gen wave = 5

missingvalues           // recode missing values pro.
demographics    4       // demographics pro.
hh_incomeFF     4       // hh income FF pro.

hh_structure 4 1/10 4f2b 4f2c 4f2d 4f2f // hh structure from inidviduals pro.

gen		moHH_size_s	= m4f1 + 1		// self-reported
gen		faHH_size_s	= f4f1 + 1		// self-reported


living_arr m4a2 m4a3a2  // child living arrangement pro.
reshape_missing         // reshape & missing values pro.
fam_structure           // parents fam structure pro.
fam_structure_income    // child fam structure & fam / hh income

save "${TEMPDATADIR}/parents_Y5.dta", replace

********************************************************************************
******************************* VARIABLES YEAR 9 *******************************
********************************************************************************
use "${RAWDATADIR}/04_Nine-Year Core/ff_y9_pub1.dta", clear
keep idnum c*5age cm5b_age c*5intyr c*5intmon c*5hhinc c*5hhimp c*5povco ///
c*5povca *5a5b* *5a5c* *5a5d* *5a5e* *5a51 c*5adult c*5kids m5a2 m5a3f

gen wave = 9

missingvalues	        // recode missing values pro.
demographics    5       // demographics pro.
hh_incomeFF     5       // hh income FF pro.

hh_structure 5 1/9 5a5b0 5a5c0 5a5d0 5a5e0 // hh structure from inidviduals pro.

gen		moHH_size_s	= m5a51 + 2		// self-reported (var without self + child)
gen		faHH_size_s	= f5a51 + 2		// self-reported (var without self + child)


living_arr m5a2 m5a3f   // child living arrangement pro.
reshape_missing         // reshape & missing values pro.
fam_structure           // parents fam structure pro.
fam_structure_income    // child fam structure & fam / hh income

save "${TEMPDATADIR}/parents_Y9.dta", replace

********************************************************************************
****************************** VARIABLES YEAR 15 *******************************
********************************************************************************
use "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta", clear

keep idnum cp6age cp6yagey cp6yagem cp6intyr cp6intmon cp6hhinc cp6hhimp cp6povco cp6povca cp6hhsize

missingvalues	// recode missing values

gen wave		= 15

* DEMOGRAPHICS - only primary caregiver
rename cp6age 	    moAge
*rename cp6yagey    chAge   // years
rename cp6yagem     chAge   // months
rename cp6intyr	    moYear
rename cp6intmon    moMonth
gen pgCohort = moYear - moAge


* HH INCOME
rename cp6hhinc moHH_income
rename cp6hhimp	moHH_income_f
rename cp6povco	moHH_povratio
rename cp6povca	moHH_povcat


** HH STRUCTURE
rename  cp6hhsize moHH_size_c       // includes PCG + child

keep idnum mo* wave chAge  wave


* CHILD FAM & HH INCOME
    gen     chHH_income = moHH_income   // Income HH - pcg report
    gen     chHH_size = moHH_size_c     // Size HH - pcg report
    gen     incRatio = moHH_povratio    // Poverty ratio - pcg report


* RESHAPE AND SAVE
keep idnum moYear ch* incRatio wave
order idnum moYear
sort idnum

ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

save "${TEMPDATADIR}/parents_Y15.dta", replace

