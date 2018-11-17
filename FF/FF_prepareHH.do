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
global CODEDIR          "${USERPATH}/code"

do "${CODEDIR}/FF/FF_programs.do"      // Load programs

********************************************************************************
****************************** VARIABLES BASELINE ******************************
********************************************************************************
use "${RAWDATADIR}/00_Baseline/ffmombspv3.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/00_Baseline/ffdadbspv3.dta", nogen

keep idnum c*1edu c*1ethrace c*1age cm1bsex *1intyr *1intmon c*1hhinc ///
c*1hhimp c*1inpov c*1povca *1e1c* *1e1d* *1e1b* *1e1e* c*1kids c*1adult m1a11a
*browse idnum m1j2a m1j2b m1j2c m1j2d mx1j2 m1j3 cm1hhinc cm1hhimp
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

living_arr m5a2 m5a3f   // child living arrangement pro.
reshape_missing         // reshape & missing values pro.
fam_structure           // parents fam structure pro.
fam_structure_income    // child fam structure & fam / hh income

save "${TEMPDATADIR}/parents_Y9.dta", replace

* HH / Family members ratio
keep idnum ratio_size
save "${TEMPDATADIR}/ratio_Y9.dta", replace 

********************************************************************************
****************************** VARIABLES YEAR 15 *******************************
********************************************************************************
use "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta", clear
keep idnum cp6age cp6yagey cp6yagem cp6intyr cp6intmon cp6hhinc cp6hhimp ///
cp6povco cp6povca cp6hhsize

gen wave = 15

missingvalues           // recode missing values pro.

merge 1:1 idnum using "${TEMPDATADIR}/ratio_Y9.dta", nogen  // hh/fam ratio Y9

* DEMOGRAPHICS - only primary caregiver
rename cp6age 	    moAge
rename cp6yagem     chAge   // months
rename cp6intyr	    moYear
rename cp6intmon    moMonth
gen pgCohort = moYear - moAge

* HH INCOME
rename cp6hhinc moHH_income
rename cp6hhimp	moHH_income_f
rename cp6povco	moHH_povratio
rename cp6povca	moHH_povcat

* HH STRUCTURE
rename  cp6hhsize moHH_size       // includes PCG + child

* CHILD FAM & HH INCOME
gen chHH_income     = moHH_income               // Income HH - PCG report
gen chHH_size       = moHH_size                 // Size HH - PCG report
gen chFAM_size      = chHH_size / ratio_size    // Impute fam size with ratio Y9
replace chFAM_size  = round(chFAM_size)
replace chFAM_size  = . if moYear == .
gen chAvg_inc       = (chHH_income / chHH_size) * chFAM_size
gen incRatio        = moHH_povratio            // Poverty ratio - PCG report

* RESHAPE AND SAVE
keep idnum moYear ch* incRatio wave ratio_size
ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

save "${TEMPDATADIR}/parents_Y15.dta", replace

