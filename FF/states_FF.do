* -----------------------------------
* Project:      MA Thesis
* Content:      Clean states
* Data:         Fragile families
* Author:       Michelle Rosenberger
* Date:         March 6, 2019
* -----------------------------------

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

* ----------------------------- LOAD DATA
use "${RAWDATADIR}/rawData/contractcity6pub.dta", clear
keep idnum *stfips p6state_n

merge 1:m idnum using "${TEMPDATADIR}/health.dta", keepus(moReport wave)

* ----------------------------- MISSING VALUES
foreach var in  m1stfips f1stfips m2stfips f2stfips m3stfips f3stfips ///
                m4stfips f4stfips m5stfips f5stfips p6state_n {
    replace `var' = . if `var' < 0                  // Missing
    replace `var' = . if `var' == 66 | `var' == 72  // Guam & Puerto Rico
}

* ----------------------------- REPORT USED DEPENDING ON WHERE CHILD LIVES
gen state = .

local int = 1
while `int' <= 5 {
    local wave  : word `int' of 1 2 3 4 5
    local age   : word `int' of 0 1 3 5 9
    local int = `int' + 1

    replace state = m`wave'stfips if moReport != 0 & wave == `age' // mother report used
    replace state = f`wave'stfips if moReport == 0 & wave == `age' // father report used
}

replace state = p6state_n if wave == 15

* ----------------------------- LABELS & SAVE
label var state "State of residence"
label values state fips
rename state statefip

order idnum wave
sort idnum wave
keep idnum wave statefip 
save "${TEMPDATADIR}/states.dta", replace 
