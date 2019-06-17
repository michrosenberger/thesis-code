* -----------------------------------
* Project:      MA Thesis
* Content:      HH structure FF
* Data:         Fragile families
* Author:       Michelle Rosenberger
* Date:         November 7, 2018
* -----------------------------------

/* This code combines all the waves and constructs the necessary variables
for the household structure in the Fragile Families data.

* ----- INPUT DATASETS (TEMPDATADIR):
parents_Y0.dta; parents_Y1.dta; parents_Y3.dta; parents_Y5.dta;
parents_Y9.dta; parents_Y15.dta; states.dta

* ----- OUTPUT DATASETS (TEMPDATADIR):
household_FF.dta
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

* ----------------------------- SET WORKING DIRECTORIES & GLOBAL VARS
if "`c(username)'" == "michellerosenberger"  {
    global DATAPATH			"~/Development/MA/data"
	global CODEPATH			"~/Development/MA/code"
	global OUTPUTPATH		"~/Development/MA/output"
	*global DATAPATH		"/Volumes/g_econ_department$/econ/biroli/geighei/data/medicaidGxE/data"
	*global CODEPATH		"/Volumes/g_econ_department$/econ/biroli/geighei/code/medicaidGxE/thesis-code"
	*global OUTPUTPATH		"/Volumes/g_econ_department$/econ/biroli/geighei/data/medicaidGxE/output"
}

global CODEDIR          "${CODEPATH}"
global RAWDATADIR	    "${DATAPATH}/raw/FragileFamilies"
global CLEANDATADIR  	"${DATAPATH}/clean"
global TEMPDATADIR  	"${DATAPATH}/temp"
global TABLEDIR         "${OUTPUTPATH}/tables"

* ----------------------------- LOG FILE
log using "${CODEDIR}/FF/constructHH_FF.log", replace

* ---------------------------------------------------------------------------- *
* ------------------------------ VARIABLES MERGE ----------------------------- *
* ---------------------------------------------------------------------------- *

* ----------------------------- MERGE
use "${TEMPDATADIR}/parents_Y0.dta", clear

foreach wave in 1 3 5 9 15 {
    append using "${TEMPDATADIR}/parents_Y`wave'.dta"
}

* ----------------------------- RENAME
rename moYear       year
rename chFAM_size   famSize
rename chHH_size    hhSize
rename chAvg_inc    avgInc
rename chHH_income  hhInc
rename incRatio     incRatio_FF
rename chAge        chAge_temp

* ----------------------------- AGE
bysort idnum (year) : gen diff = year[_n+1] - year[_n]
bysort idnum (year) : replace chAge_temp =  chAge_temp[_n+1] - diff[_n]*12 if wave == 0

gen chAge = int(chAge_temp / 12)
replace chAge = 0 if chAge < 0

* ----------------------------- MERGE STATE (RESTRICTED USE DATA)
merge m:1 idnum wave using "${TEMPDATADIR}/states.dta", nogen

* ----------------------------- MERGE POVERTY LEVELS
merge m:1 year famSize statefip using "${CLEANDATADIR}/PovertyLevels.dta"
keep if _merge == 3
drop _merge

* ----- INCOME RATIO
* Divide FF family income by poverty line based on fam size and composition
gen incRatio = chFamInc / povLevel // gen incRatio2 = avgInc / povLevel
label var incRatio	"Family poverty level"


* ----------------------------- GENDER, RACE, MOTHER AGE, MOTHER RACE
foreach var in chGender moAge moCohort moWhite moBlack moHispanic moOther ///
moEduc faEduc faCohort chBlack chHispanic chOther chMulti chWhite chRace moRace {
    rename  `var' `var'_temp
    egen    `var' = max(`var'_temp), by(idnum) 
}

recode chGender (2 = 1) (1 = 0)
rename chGender chFemale

* ----- HAS SOME COLLEGE EDUCATION
gen moCollege = moEduc == 3
gen faCollege = faEduc == 3

* ----------------------------- FAM INCOME IN THOUSANDS
replace avgInc = avgInc / 1000

* ----------------------------- FORMAT & SAVE
* ----- DROP
drop chAge_temp diff *_temp moHH_size_c ratio_size

* ----- LABELS
label data              "Household structure FF"

label var idnum         "Family ID"
label var year          "Year interview"
label var wave          "Wave"
label var moReport      "Mother report used"
label var famSize       "Family size"
label var avgInc        "Family income (in 1'000 USD)"
label var hhSize        "Household size"
label var hhInc         "Household income"
label var incRatio_FF   "Poverty ratio from FF"
label var statefip      "State of residence (FIP)"
label var chAge         "Age"
label var chFemale      "Female"
label var chRace        "Race"
label var chWhite       "Race white"
label var chBlack       "Race black"
label var chHispanic    "Race Hispanic"
label var chOther       "Race other"
label var chMulti       "Race mutli-racial"
label var moAge         "Mother's age at birth"
label var moEduc        "Mother's education"
label var moCohort      "Mother's birth year"
label var moWhite       "Mother's race white"
label var moBlack       "Mother's race black"
label var moHispanic    "Mother's race hispanic"
label var moOther       "Mother's race other"
label var moRace        "Mother's race"
label var moCollege     "Mother has some college"
label var faEduc        "Father's education"
label var faCollege     "Father has some college"
label var faCohort      "Father's birth year"


* ----- VALUE LABELS
label define chFemale       0 "Male"                  1 "Female"
label define moReport       0 "No"                    1 "Yes"
label define raWhite        0 "Non-white"             1 "White"
label define raBlack        0 "Non-black"             1 "Black"
label define raHispaninc    0 "Non-hispanic"          1 "Hispanic"
label define raOther        0 "Non-other"             1 "Other"
label define raMutli        0 "Non-multi"             1 "Multi-racial"
label define moEduc         1 "Less than HS"          2 "HS or equivalent" ///
                            3 "Some college, tech"    4 "College or Grad"
label define chRace         1 "White" 2 "Black" 3 "Hispanic" 4 "Other" 5 "Multi-racial"
label define moRace         1 "White" 2 "Black" 3 "Hispanic" 4 "Other"

label values chFemale chFemale
label values moReport moReport
label values chWhite moWhite raWhite
label values chBlack moBlack raBlack
label values chHispanic moHispanic raHispaninc
label values chOther moOther raOther
label values chMulti raMutli
label values moEduc faEduc moEduc
label values chRace chRace
label values moRace moRace

rename chAge age

* ----- IMPUTE CHILD RACE WITH MOTHER RACE IF MISSING
replace chRace = moRace if chRace == .

* ----- LABELS
* NOTE: ONE observation per WAVE and ID
drop hhSize hhInc 
order idnum wave year age famSize statefip chFemale
sort idnum wave

describe
save "${TEMPDATADIR}/household_FF.dta", replace


