* -----------------------------------
* Project:      MA Thesis
* Content:      Household structure FF
* Data:         Fragile families
* Author:       Michelle Rosenberger
* Date:         November 6, 2018
* -----------------------------------

/* This code extracts the necessary variables for the household structure in
the Fragile Families data set in each wave.

* ----- INPUT DATASETS (RAWDATADIR):
ffmombspv3.dta; ffdadbspv3.dta; ffmom1ypv2.dta; ffdad1ypv2.dta; 
ffmom3ypv2.dta; ffdad3ypv2.dta; ffmom5ypv1.dta; ffdad5ypv1.dta;
ff_y9_pub1.dta; FF_Y15_pub.dta


* ----- OUTPUT DATASETS (TEMPDATADIR):
parents_Y0.dta; parents_Y1.dta; parents_Y3.dta; parents_Y5.dta;
parents_Y9.dta; parents_Y15.dta

* ----- PROGRAMS:
* P_P_missingvalues   : Recodes missing values
* P_childHealth       : Uses correct parent report to impute child health
* P_medicaid          : Uses correct parent report to impute medicaid coverage
* P_demographics      : Cleans demographic variables
* P_hhIncome          : Cleans HH income, poverty ratio, and poverty category
* P_hhStructure       : Construct HH structure from individuals in HH
* P_report            : Choose parent report depending on living arrangement
* P_reshapeMissing    : Reshape and clean missing values
* P_famStructure      : Construct parent fam size from individuals in HH
* P_famSizeStructure  : Construct child fam size + HH income
*/

* ---------------------------------------------------------------------------- *
* --------------------------------- PREAMBLE --------------------------------- *
* ---------------------------------------------------------------------------- *
capture log close
clear all
est clear
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

* ----------------------------- SET WORKING DIRECTORIES
if "`c(username)'" == "michellerosenberger"  {
	global CODEDIR		"~/Development/MA/code"
	*global CODEDIR		"/Volumes/g_econ_department$/econ/biroli/geighei/code/medicaidGxE/thesis-code"
}

do "${CODEDIR}/setDirectories.do"

* ----------------------------- LOAD PROGRAMS
do "${CODEDIR}/FF/programs_FF.do"

* ---------------------------------------------------------------------------- *
* ------------------------------- VARS BASELINE ------------------------------ *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/00_Baseline/ffmombspv3.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/00_Baseline/ffdadbspv3.dta", nogen

keep idnum c*1edu c*1ethrace c*1age cm1bsex *1intyr *1intmon c*1hhinc ///
c*1hhimp c*1inpov c*1povca *1e1c* *1e1d* *1e1b* *1e1e* c*1kids c*1adult ///
m1a11a cm1marf cf1marm

gen wave        = 0
gen moReport    = 1 // MOTHER REPORT USED AT TIME OF BIRTH

* ----- PARENT'S MARRIED
rename cm1marf moMarried
rename cf1marm faMarried

* ----- PROGRAMS
P_missingvalues
P_demographics      1
P_hhIncome          1

P_hhStructure       1 1/8 1e1c 1e1d 1e1b 1e1e

P_reshapeMissing
P_famStructure
P_famSizeStructure

* ----- CHILD FAMILY INCOME
gen chFamInc = moFamInc if moReport == 1

* ----- COLLAPSE
keep idnum moYear moMonth ch* incRatio wave moEduc faEduc moWhite moBlack moHispanic moOther moHH_size_c moReport moCohort faCohort moAge moRace

ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

drop chFAM_member chFAM_female chFAM_relate chFAM_age chFAM_employ moMonth chFAM_size_f

* ----- RATIO HH TO FAM SIZE
replace chFAM_size = . if moYear == .
gen ratio_size = chHH_size / chFAM_size

save "${TEMPDATADIR}/parents_Y0.dta", replace


* ---------------------------------------------------------------------------- *
* -------------------------------- VARS YEAR 1 ------------------------------- *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/01_One-Year Core/ffmom1ypv2.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/01_One-Year Core/ffdad1ypv2.dta", nogen

keep idnum c*2age cm2b_age *2intyr *2intmon c*2hhinc c*2hhimp c*2povco ///
c*2povca *2f2b* *2f2c* *2f2d* *2f2e* *2f1 c*2adult c*2kids m2a3 m2a4a ///
cf2marp cm2marp cm2marf cf2marm

gen wave = 1

* ----- PROGRAMS
P_missingvalues
P_demographics      2
P_hhIncome          2

* ----- PARENT'S MARRIED
gen moMarried = 1 if cm2marf == 1 | cm2marp == 1
gen faMarried = 1 if cf2marm == 1 | cf2marp == 1

* ----- PROGRAMS
P_hhStructure       2 1/10 2f2b 2f2c 2f2d 2f2e

P_report            m2a3 m2a4a
P_reshapeMissing
P_famStructure
P_famSizeStructure

* ----- CHILD FAMILY INCOME
gen chFamInc = moFamInc if moReport == 1
replace chFamInc = faFamInc if moReport == 0
replace chFamInc = moFamInc if (moReport != 1 & moReport != 0)

* ----- COLLAPSE
keep idnum moYear moMonth ch* incRatio wave moHH_size_c moReport

ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

drop chFAM_member chFAM_female chFAM_relate chFAM_age chFAM_employ moMonth chFAM_size_f

* ----- RATIO HH TO FAM SIZE
replace chFAM_size = . if moYear == .
gen ratio_size = chHH_size / chFAM_size

save "${TEMPDATADIR}/parents_Y1.dta", replace


* ---------------------------------------------------------------------------- *
* -------------------------------- VARS YEAR 3 ------------------------------- *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/02_Three-Year Core/ffmom3ypv2.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/02_Three-Year Core/ffdad3ypv2.dta", nogen

keep idnum cm3age cf3age cm3b_age m3intyr f3intyr m3intmon f3intmon m3intyr ///
f3intyr c*3hhinc c*hhimp c*povco c*3povca *3f2b* *3f2c* *3f2d* *3f2f* *3f1 ///
c*3adult c*3kids m3a2 m3a3a cf3marp cm3marp cm3marf cf3marm

gen wave = 3

* ----- PROGRAMS
P_missingvalues
P_demographics      3
P_hhIncome          3

* ----- PARENT'S MARRIED
gen moMarried = 1 if cm3marf == 1 | cm3marp == 1
gen faMarried = 1 if cf3marm == 1 | cf3marp == 1

* ----- PROGRAMS
P_hhStructure       3 1/10 3f2b 3f2c 3f2d 3f2f

P_report            m3a2 m3a3a
P_reshapeMissing
P_famStructure
P_famSizeStructure

* ----- CHILD FAMILY INCOME
gen chFamInc = moFamInc if moReport == 1
replace chFamInc = faFamInc if moReport == 0
replace chFamInc = moFamInc if (moReport != 1 & moReport != 0)

* ----- COLLAPSE
keep idnum moYear moMonth ch* incRatio wave moHH_size_c moReport

ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

drop chFAM_member chFAM_female chFAM_relate chFAM_age chFAM_employ moMonth chFAM_size_f

* ----- RATIO HH TO FAM SIZE
replace chFAM_size = . if moYear == .
gen ratio_size = chHH_size / chFAM_size

save "${TEMPDATADIR}/parents_Y3.dta", replace

* ---------------------------------------------------------------------------- *
* -------------------------------- VARS YEAR 5 ------------------------------- *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/03_Five-Year Core/ffmom5ypv1.dta", clear
merge 1:1 idnum using "${RAWDATADIR}/03_Five-Year Core/ffdad5ypv1.dta", nogen

keep idnum c*4age cm4b_age *4intyr *4intmon c*4hhinc c*4hhimp c*4povco ///
c*4povca *4f2b* *4f2c* *4f2d* *4f2f* *4f1 m4a2 m4a3a2 c*4adult c*4kids ///
cf4marp cm4marp cm4marf cf4marm

gen wave = 5

* ----- PROGRAMS
P_missingvalues
P_demographics      4
P_hhIncome          4

* ----- PARENT'S MARRIED
gen moMarried = 1 if cm4marf == 1 | cm4marp == 1
gen faMarried = 1 if cf4marm == 1 | cf4marp == 1

* ----- PROGRAMS
P_hhStructure       4 1/10 4f2b 4f2c 4f2d 4f2f

P_report            m4a2 m4a3a2
P_reshapeMissing
P_famStructure
P_famSizeStructure

* ----- CHILD FAMILY INCOME
gen chFamInc = moFamInc if moReport == 1
replace chFamInc = faFamInc if moReport == 0
replace chFamInc = moFamInc if (moReport != 1 & moReport != 0)

* ----- COLLAPSE
keep idnum moYear moMonth ch* incRatio wave moHH_size_c moReport

ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

drop chFAM_member chFAM_female chFAM_relate chFAM_age chFAM_employ moMonth chFAM_size_f

* ----- RATIO HH TO FAM SIZE
replace chFAM_size = . if moYear == .
gen ratio_size = chHH_size / chFAM_size

save "${TEMPDATADIR}/parents_Y5.dta", replace

* ---------------------------------------------------------------------------- *
* -------------------------------- VARS YEAR 9 ------------------------------- *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/04_Nine-Year Core/ff_y9_pub1.dta", clear
keep idnum c*5age cm5b_age c*5intyr c*5intmon c*5hhinc c*5hhimp c*5povco ///
c*5povca *5a5b* *5a5c* *5a5d* *5a5e* *5a51 c*5adult c*5kids m5a2 m5a3f ///
cf5marp cm5marp cm5marf cf5marm

gen wave = 9

* ----- PROGRAMS
P_missingvalues
P_demographics      5
P_hhIncome          5

* ----- PARENT'S MARRIED
gen moMarried = 1 if cm5marf == 1 | cm5marp == 1
gen faMarried = 1 if cf5marm == 1 | cf5marp == 1

* ----- PROGRAMS
P_hhStructure       5 1/9 5a5b0 5a5c0 5a5d0 5a5e0

P_report            m5a2 m5a3f
P_reshapeMissing
P_famStructure
P_famSizeStructure

* ----- CHILD FAMILY INCOME
gen chFamInc = moFamInc if moReport == 1
replace chFamInc = faFamInc if moReport == 0
replace chFamInc = moFamInc if (moReport != 1 & moReport != 0)

* ----- COLLAPSE
keep idnum moYear moMonth ch* incRatio wave moHH_size_c moReport

ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

drop chFAM_member chFAM_female chFAM_relate chFAM_age chFAM_employ moMonth chFAM_size_f

* ----- RATIO HH TO FAM SIZE
replace chFAM_size = . if moYear == .
gen ratio_size = chHH_size / chFAM_size

save "${TEMPDATADIR}/parents_Y9.dta", replace

* HH / Family members ratio
keep idnum ratio_size
save "${TEMPDATADIR}/ratio_Y9.dta", replace 


* ---------------------------------------------------------------------------- *
* -------------------------------- VARS YEAR 15 ------------------------------ *
* ---------------------------------------------------------------------------- *
use "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta", clear
keep idnum cp6age cp6yagey cp6yagem cp6intyr cp6intmon cp6hhinc cp6hhimp ///
cp6povco cp6povca cp6hhsize ck6ethrace p6e27_1 p6e28 p6k57 p6g5 cp6pmarb cp6pmarp

gen wave = 15

* ----- PROGRAMS
P_missingvalues

* ----- HH / FAM RATIO FROM Y9
merge 1:1 idnum using "${TEMPDATADIR}/ratio_Y9.dta", nogen

* ----------------------------- DEMOGRAPHICS (ONLY PRIMARY CAREGIVER)
rename cp6age 	    moAge
rename cp6yagem     chAge   // months
rename cp6intyr	    moYear
rename cp6intmon    moMonth
rename ck6ethrace   chRace
    gen chWhite     = chRace == 1
    gen chBlack     = chRace == 2
    gen chHispanic  = chRace == 3
    gen chOther     = chRace == 4
    gen chMulti     = chRace == 5
gen pgCohort = moYear - moAge

* ----------------------------- HH INCOME
rename cp6hhinc moHH_income
rename cp6hhimp	moHH_income_f
rename cp6povco	moHH_povratio
rename cp6povca	moHH_povcat

* ----------------------------- HH STRUCTURE
rename  cp6hhsize moHH_size       // includes PCG + child

gen moMarried = 1 if (cp6pmarp == 1 | cp6pmarb == 1)

* ----------------------------- Family income
* ----- DOES PARENT HAVE RESIDENT PARTNER?
rename p6e27_1 moPartner // partner/spouse in HH

* ----- DOES RESIDENT PARTNER WORK?
gen moPartnerWork = (p6g5 > 0 & p6g5 < .) // partner works if num weeks worked > 0

* ----- CALCUALTE AVERAGE HH INCOME
rename p6e28 moNumEmployed
replace moNumEmployed = 1 if (moNumEmployed == 0 & moPartnerWork == 1)
replace moNumEmployed = moNumEmployed + 1 // add mother
gen avgIncEmployed = moHH_income / moNumEmployed


* ----- FAMILY INCOME
gen partnerInc = avgIncEmployed if (moPartner == 1 & moPartnerWork == 1 & moMarried == 1)
gen ownInc = avgIncEmployed

egen chFamInc = rowtotal(partnerInc ownInc)
replace chFamInc = . if moHH_income >= .

* ----------------------------- CHILD FAM & HH INCOME
gen chHH_income     = moHH_income               // Income HH - PCG report
gen chHH_size       = moHH_size                 // Size HH - PCG report
gen chFAM_size      = chHH_size / ratio_size    // Impute fam size with ratio Y9
replace chFAM_size  = round(chFAM_size)
replace chFAM_size  = . if moYear == .
gen chAvg_inc       = (chHH_income / chHH_size) * chFAM_size
gen incRatio        = moHH_povratio            // Poverty ratio - PCG report


* ----------------------------- RESHAPE AND SAVE
keep idnum moYear ch* incRatio wave ratio_size
ds idnum, not
global FINALVARS = r(varlist)
collapse $FINALVARS, by(idnum)

save "${TEMPDATADIR}/parents_Y15.dta", replace

