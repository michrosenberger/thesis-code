* -----------------------------------
* Project:      MA Thesis
* Content:      Prepare genetic data
* Author:       Michelle Rosenberger
* Date:         May 10, 2019
* -----------------------------------
capture log close
clear all
est clear
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

* ----------------------------- SET WORKING DIRECTORIES & GLOBAL VARS
if "`c(username)'" == "michellerosenberger"  {
    global USERPATH     "~/Development/MA"
}

global CLEANDATADIR		"${USERPATH}/data/clean"
global TEMPDATADIR  	"${USERPATH}/data/temp"
global RAWDATADIR		"${USERPATH}/data/raw/FragileFamilies"	
    
* ----------------------------- DATA
use "${RAWDATADIR}/rawData/ff_gen_9y_pub4.dta", clear

* ----- MISSING VALUES (NUMERIC)
mvdecode g*5telo gk5flag, mv(-9 = .a \ -7 = .b \ -5 = .c \ -3 = .d \ -1 = .e)

* ----- MISSING VALUES (STRING)
ds, has(type string)
global ALLVARIABLES = r(varlist)

foreach variable in $ALLVARIABLES {
    replace `variable' = "." if `variable' == "-9 Not in wave"
    replace `variable' = "." if `variable' == "-7 N/A PCG not Bio Mother"
    replace `variable' = "." if `variable' == "-5 Not collected"
    replace `variable' = "." if `variable' == "-3 Missing"
    replace `variable' = "." if `variable' == "-1 Refused"
}

* ----- COPY VALUES FOR EACH WAVE
expand 	6
bysort idnum : gen num = _n

gen wave = .
replace wave = 0 if num == 1
replace wave = 1 if num == 2
replace wave = 3 if num == 3
replace wave = 5 if num == 4
replace wave = 9 if num == 5
replace wave = 15 if num == 6

* ----- PREPARE DATA FOR MERGE
rename gk5saliva chGenetic_temp
label define chGenetic	0 "0 No"	1 "1 Yes"
label values chGenetic chGenetic
label var chGenetic "Child has genetic information"

* ----- SAVE
drop num
save "${TEMPDATADIR}/genetic.dta", replace

