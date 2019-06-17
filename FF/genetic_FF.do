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
	global CODEDIR		"~/Development/MA/code"
	*global CODEDIR		"/Volumes/g_econ_department$/econ/biroli/geighei/code/medicaidGxE/thesis-code"
}

do "${CODEDIR}/setDirectories.do"

* ----------------------------- LOG FILE
log using "${CODEDIR}/FF/genetic_FF.log", replace
    
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


* ----- BMI
gen FTO = .
replace FTO = 1 if gk5ftors9939609 == "AA" | gk5ftors9939609 == "AT" // risky
replace FTO = 0 if gk5ftors9939609 == "TT" // normal
label define FTO 0 "0 TT" 1 "1 AA/AT"
label values FTO FTO

gen BDNFrs65 = .
replace BDNFrs65 = 1 if gk5tmem18rs6548238 == "CC" // risky
replace BDNFrs65 = 0 if gk5tmem18rs6548238 == "TT" | gk5tmem18rs6548238 == "CT"  // normal
label define BDNFrs65 0 "0 TT/CT" 1 "1 CC"
label values BDNFrs65 BDNFrs65

gen MC4Rrs17 = .
replace MC4Rrs17 = 1 if gk5mc4rrs17782313 == "CC" | gk5mc4rrs17782313 == "CT" // risky
replace MC4Rrs17 = 0 if gk5mc4rrs17782313 == "TT" // normal
label define MC4Rrs17 0 "0 TT" 1 "1 CC/CT"
label values MC4Rrs17 MC4Rrs17

* INDEX
* FTO A risky
gen FTOIndex = .
replace FTOIndex = 2 if gk5ftors9939609 == "AA"
replace FTOIndex = 1 if gk5ftors9939609 == "AT"
replace FTOIndex = 0 if gk5ftors9939609 == "TT"

* BDNFrs65 C risky
gen BDNFIndex = .
replace BDNFIndex = 2 if gk5tmem18rs6548238 == "CC"
replace BDNFIndex = 1 if gk5tmem18rs6548238 == "CT"
replace BDNFIndex = 0 if gk5tmem18rs6548238 == "TT"

* MC4Rrs17 C risky
gen MC4RIndex = .
replace MC4RIndex = 2 if gk5mc4rrs17782313 == "CC"
replace MC4RIndex = 1 if gk5mc4rrs17782313 == "CT"
replace MC4RIndex = 0 if gk5mc4rrs17782313 == "TT"

egen bmiIndex = rowtotal(FTOIndex BDNFIndex MC4RIndex)
replace bmiIndex = . if FTOIndex == . & BDNFIndex == . & MC4RIndex == .

gen bmiIndexHigh = .
replace bmiIndexHigh = 1 if bmiIndex >= 3 & bmiIndex <= 6
replace bmiIndexHigh = 0 if bmiIndex >= 0 & bmiIndex <= 2


* ----- DEPRESSION
gen TPH2rs45 = .
replace TPH2rs45 = 1 if gk5tph2rs4570625 == "GG" // risky
replace TPH2rs45 = 0 if gk5tph2rs4570625 == "GT" | gk5tph2rs4570625 == "TT" // normal
label define TPH2rs45 0 "0 GT/TT" 1 "1 GG"
label values TPH2rs45 TPH2rs45



* ----- PREPARE DATA FOR MERGE
rename gk5saliva chGenetic
label define chGenetic	0 "0 No"	1 "1 Yes"
label values chGenetic chGenetic
label var chGenetic "Child has genetic information"

* ----- SAVE
drop num
save "${TEMPDATADIR}/genetic.dta", replace

