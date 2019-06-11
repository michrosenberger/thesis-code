* -----------------------------------
* Project:      MA Thesis
* Content:      Programs for FF
* Data:         Fragile families
* Author:       Michelle Rosenberger
* Date:         November 6, 2018
* -----------------------------------

* ---------------------------------------------------------------------------- *
* --------------------------------- PROGRAMS --------------------------------- *
* ---------------------------------------------------------------------------- *

* ----------------------------- MISSING VALUES
capture program drop    P_missingvalues
program define          P_missingvalues

	ds, has(type numeric)
	global ALLVARIABLES = r(varlist)

    /* -1 refused;  -2 don't know;  -3 missing; -4 multiple answers;    -5 not asked;
    -6 skipped; -7 NA;  -8 out of range;    -9 not in wave; -10 jail;   -12 Shelter/Street */

    mvdecode $ALLVARIABLES,  mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h \ -9 = .i \ -10 = .j \ -11 = .k \ -12 = .l)

end


* ----------------------------- PARENT REPORTED HEALTH
capture program drop    P_childHealth
program define          P_childHealth
	args moreport fareport

	gen chHealth = .
	replace chHealth = `moreport' if moReport != 0 	// mother + default
	replace chHealth = `fareport' if moReport == 0	// father
end


* ----------------------------- MEDICAID CHILD
capture program drop    P_medicaid
program define          P_medicaid
	args mo_covered mo_who fa_covered fa_who

	* Medicaid parents report
	local int = 1
	while `int' <= 2 {
		local parent    : word `int' of     mo  fa
		local letter    : word `int' of     m   f
		local int = `int' + 1

		gen chMediHI_`parent' 		= 0
		replace chMediHI_`parent' 	= 1 if `letter'`mo_covered' == 1 & (`letter'`mo_who' == 2 | `letter'`mo_who' == 3)
		replace chMediHI_`parent'	= . if `letter'`mo_covered' >= .
		gen chPrivHI_`parent'		= 0
		replace chPrivHI_`parent' 	= 1 if `letter'`fa_covered' == 1 & (`letter'`fa_who' == 2 | `letter'`fa_who' == 3)
		replace chPrivHI_`parent'	= . if `letter'`fa_covered' >= .
	}

	* Medicaid child
	foreach healthins in chMediHI chPrivHI {
		gen `healthins' = .
		replace `healthins' = `healthins'_mo if moReport != 0	// mother + default
		replace `healthins' = `healthins'_fa if moReport == 0	// father
	}
	drop *_mo *_fa

end


* ----------------------------- DEMOGRAPHICS
capture program drop    P_demographics
program define          P_demographics 
    args wave

    if wave == 0 {
        rename cm`wave'edu      moEduc
        rename cf`wave'edu      faEduc
        rename cm`wave'ethrace  moRace
        rename cf`wave'ethrace  faRace
        rename cm`wave'bsex     chGender
        gen moWhite             = moRace == 1
        gen moBlack             = moRace == 2
        gen moHispanic          = moRace == 3
        gen moOther             = moRace == 4
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

* ----------------------------- HH INCOME FF
capture program drop    P_hhIncome
program define          P_hhIncome
    args wave

    local int = 1
    while `int' <= 2 {
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

* ----------------------------- CONSTRUCTED HH STRUCTURE FROM INDIVIDUALS IN HH
capture program drop    P_hhStructure
program define          P_hhStructure

    args wave numpeople femvar agevar relatevar employvar

    local int = 1
    while `int' <= 2 {
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

* ----------------------------- CHILD LIVING ARR.
capture program drop    P_report
program define          P_report
    args timevar usuallyvar

    gen 	moReport = 1 // mother default
    replace moReport = 0 if (`timevar' != 1 & `timevar' != 2 & `usuallyvar' == 1)	// father (<0.5)
    replace moReport = . if `timevar'  >= . & `usuallyvar'  >= .

end


* ----------------------------- RESHAPE & MISSING VALUES
capture program drop    P_reshapeMissing
program define          P_reshapeMissing

    * RESHAPE
    if wave == 0 {
        keep idnum mo* fa* ch* wave moWhite moBlack moHispanic moOther moReport // cm1relf
        reshape long moHH_female moHH_age moHH_relate moHH_employ faHH_female faHH_age faHH_relate faHH_employ, i(idnum) j(noHH_member)
        keep idnum mo* fa* ch* no* wave moWhite moBlack moHispanic moOther moReport
    }
    if wave > 0 {
        keep idnum mo* fa* ch* wave moReport // cm1relf
        reshape long moHH_female moHH_age moHH_relate moHH_employ faHH_female faHH_age faHH_relate faHH_employ, i(idnum) j(noHH_member)
        keep idnum mo* fa* ch* no* wave moReport
    }

    order idnum wave

    * MISSING VALUES
    foreach parent in moHH faHH {
        foreach var in `parent'_female `parent'_age `parent'_relate `parent'_employ {
            replace `var' = . if (`var' == .a | `var' == .b | `var' == .c | `var' == .f | `var' == .i)
        }
    }

end

* ----------------------------- PARENTS FAM STRUCTURE
capture program drop    P_famStructure
program define          P_famStructure

    * Construct number of individuals in HH
    foreach parent in mo fa {
        replace `parent'HH_relate = . if `parent'HH_relate == 0 // None
        gen temp`parent' = 1 if `parent'HH_relate != .
        bysort temp`parent' idnum : gen `parent'HH_member = _n if `parent'HH_relate != .
        drop temp`parent'
        egen `parent'HH_size = count(`parent'HH_member), by(idnum)
        replace `parent'HH_size = `parent'HH_size + 1 // add respondent
        replace `parent'HH_size = . if moYear >=.           // replace with missing value if not in interview
    }


    tab moHH_relate
    tab faHH_relate

    * Construct number of family members in HH
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


* ----------------------------- CONSTRUCTED CHILD FAM STRUCTURE & FAM / HH INCOME
capture program drop    P_famSizeStructure
program define          P_famSizeStructure

    * FAM STRUCTURE
    /* IF moReport missing: mother report as default */
    foreach var in member female relate age employ size {
        gen     chFAM_`var' = moFAM_`var' if moReport == 1 // mother report
        replace chFAM_`var' = faFAM_`var' if moReport == 0 // father report
        replace chFAM_`var' = moFAM_`var' if (moReport != 1 & moReport != 0)  // default

    }
    gen     chFAM_size_f  = 1 if moReport != 0    // mother
    replace chFAM_size_f  = 0 if moReport == 0    // father
    label   define chFAM_size_f 0 "Father report" 1 "Mother report"
    label   values chFAM_size_f chFAM_size_f

    * INCOME
    * ----- DIVIDE INCOME BY HH SIZE AND MULTIPLY BY FAM SIZE
    foreach parent in mo fa {
        gen     `parent'Avg_inc = (`parent'HH_income / `parent'HH_size) * `parent'FAM_size
    }

    * ----- POVERTY RATIO CHILD DEPENDING ON PARENT REPORT
    gen     incRatio = moHH_povratio if moReport != 0
    replace incRatio = faHH_povratio if moReport == 0

    foreach variable in size income {
        gen     chHH_`variable' = moHH_`variable' if moReport != 0
        replace chHH_`variable' = faHH_`variable' if moReport == 0
    } 

    gen     chAvg_inc = moAvg_inc if moReport != 0
    replace chAvg_inc = faAvg_inc if moReport == 0

    * ----- COLLAPSE AND SAVE
    if wave == 0 {
        keep idnum moYear moMonth ch* incRatio wave moEduc faEduc moWhite moBlack moHispanic moOther moHH_size_c moReport moCohort faCohort moAge moRace
    }
    if wave > 0 {
        keep idnum moYear moMonth ch* incRatio wave moHH_size_c moReport
    }

    ds idnum, not
    global FINALVARS = r(varlist)
    collapse $FINALVARS, by(idnum)

    drop chFAM_member chFAM_female chFAM_relate chFAM_age chFAM_employ moMonth chFAM_size_f
    replace chFAM_size = . if moYear == .

    * ----- RATIO HH TO FAM SIZE
    gen ratio_size = chHH_size / chFAM_size

end

