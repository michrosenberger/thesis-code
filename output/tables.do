* Project: 	    MA Thesis
* Content:      Create simulated eligbility instrument
* Author:       Thompson
* Adapted by: 	Michelle Rosenberger
* Date: 	    Nov 1, 2018

********************************************************************************
*********************************** PREAMBLE ***********************************
********************************************************************************

capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

if "`c(username)'" == "michellerosenberger"  {
    global MYPATH		"~/Development/MA"
}
global CLEANDATADIR  	"${MYPATH}/data/clean"
global TEMPDATADIR  	"${MYPATH}/data/temp"
global TABLEDIR         "${MYPATH}/output/tables"

* Setting the switches for different parts of the code
global PROGRAMS		= 0			// install the packages

* Install packages
if ${PROGRAMS} == 1 {
    ssc install statastates
}

********************************************************************************
************************** TABLES SUMMARY STATISTICS ***************************
********************************************************************************
* Coverage: 	mediCov_c1-mediCov_c15 or mediCov_t1-mediCov_t15
* Variables: 	chHealth_0-chHealth_15
* No vars:		no_*
* Health:		chHealth chHealth_neg moHealth moHealth_neg
* General:		healthFactor_a1_std-healthFactor_a15_std
* Utilization:	medicalFactor_a1_std-medicalFactor_a15_std
* Never:		neverSmoke neverDrink 
* Behaviour:	behavFactor_a15_std


************************************
* Summary stats FF
************************************

* Change: Income ratio from family
* Check education mother comparable between two samples
* Add Index vars

use "${TEMPDATADIR}/household_FF.dta", clear        // FRAGILE FAMILIES

* Prepare data
gen wave15 = 1 if wave == 15    // limit sample to those with valid data in wave 15
bysort id : egen wave15_max = max(wave15)

label var moCohort "Birth year"

foreach var of varlist countMedi famSize female chWhite chBlack chHispanic ///
chOther chMulti moCohort avgInc incRatio_FF {
    label variable `var' `"\:\:\:\: `: variable label `var''"'
}

* Fragile families sum stat
eststo clear
estpost tabstat countMedi famSize female chWhite chBlack chHispanic chOther chMulti ///
moCohort avgInc incRatio_FF if wave == 0 & wave15_max == 1, /// 
columns(statistics) statistics(mean sd min max n)    // FRAGILE FAMILIES moEduc
eststo

* LaTex table
esttab est1 using "${TABLEDIR}/SumStat_FF.tex", ///
nonumber label collabels(none) cells("mean(fmt(%9.2fc))" sd(par fmt(%9.2fc))) ///
stats(N, fmt(%9.0f) label(Observations)) style(tex) alignment(r) mlabels("Mean")  ///
replace compress ///
refcat(countMedi "Child" chWhite "Race" moCohort "Mother" avgInc "Family", nolabel) ///
note("Standard deviation reported in brackets below mean.")


************************************
* Summary stats comparison
************************************
* Columns: (1) FF (2) CPS (3) CPS restricted (4) Diff (5) pval diff

gen FF = 1
append using  "${TEMPDATADIR}/cps_summary.dta"
replace FF = 0 if FF == .

* Fragile families sum stat
eststo clear
estpost tabstat famSize female chWhite chBlack chHispanic ///
moCohort if wave == 0 & wave15_max == 1 & FF == 1, ///
columns(statistics) statistics(mean sd min max n) // avgInc incRatio_FF moEduc
eststo

* CPS sum stat
estpost tabstat famSize female chWhite chBlack chHispanic ///
moCohort if FF == 0, columns(statistics) statistics(mean sd min max n)
eststo

* CPS restricted sample sum stat


* LaTex table
esttab est1 est2 using "${TABLEDIR}/SumStat_both.tex", cells("mean(fmt(%9.2fc))") ///
nonumber label collabels(none) mlabels("FF" "CPS") style(tex) alignment(r) replace ///
refcat(famSize "Child" chWhite "Race" moCohort "Mother", nolabel) wide



********************************************************************************
******************************* SUM STATS HEALTH *******************************
********************************************************************************
* Look at number of observations

use "${TEMPDATADIR}/health.dta", clear

local HEALTHVARS badHealth feverRespiratory anemia seizures ///
foodDigestive eczemaSkin diarrheaColitis headachesMigraines earInfection ///
asthmaAttack
local LIMITVARS     limit absent
local MENTALVARS    depressed diagnosedDepression
local BEHAVVARS     activity30 everSmoke everDrink bmi
local MEDIVARS      chMediHI
local DOCVARS       medication numDocIll numRegDoc emRoom // docIll regDoc

* Fair or poor health
tab chHealth, gen(health_temp)
egen badHealth = rowmax(health_temp4 health_temp5) // fair or poor health

foreach var in healthFactor chHealth_ mediCov_c mediCov_t medicalFactor behavFactor {
    gen `var' = . 

}

foreach wave of numlist 1 3 5 9 15 {
    replace healthFactor    = healthFactor_a`wave'_std  if wave == `wave'
    replace chHealth_       = chHealth_`wave'           if wave == `wave'
    replace mediCov_c       = mediCov_c`wave'           if wave == `wave' 
    replace mediCov_t       = mediCov_t`wave'           if wave == `wave'
    replace medicalFactor   = medicalFactor_a`wave'_std if wave == `wave'
}

replace behavFactor = behavFactor_a15_std

* Fragile families sum stat
eststo clear
foreach wave of numlist 1 3 5 9 15 { // chHealth_ healthFactor behavFactor mediCov_c mediCov_t medicalFactor
	di "Wave `wave'"
	estpost tabstat `HEALTHVARS' `LIMITVARS' ///
    `MENTALVARS' `BEHAVVARS' `MEDIVARS' `DOCVARS' if wave == `wave', ///
    columns(statistics) statistics(mean sd min max n)
	eststo
}

* LaTex table
label var chHealth_             "Child health"
label var healthFactor          "General health index"
label var mediCov_c             "Medical coverage - each year"
label var mediCov_t             "Medical coverage - cummulative"
label var medicalFactor         "Utilization index"
label var behavFactor           "Health behaviours index "
label var asthmaAttack			"Had an episode of asthma $^{\text{a}}$"
label var foodDigestive 		"Had food/digestive allergy $^{\text{a}}$"
label var eczemaSkin			"Had eczema/skin allergy $^{\text{a}}$"
label var diarrheaColitis 		"Had frequent diarrhea/colitis $^{\text{a}}$"
label var headachesMigraines 	"Had frequent headaches/migraines $^{\text{a}}$"
label var earInfection 			"Had ear infection $^{\text{a}}$"
label var feverRespiratory 		"Had hay fever or respiratory allergy $^{\text{a}}$"
label var anemia				"Had anemia $^{\text{a}}$"
label var seizures				"Had seizures $^{\text{a}}$"
label var depressed				"Feels depressed"
label var badHealth 			"Fair or poor health $^{\text{a}}$"
label var chMediHI				"Coverage"
label var limit					"Health problems limit usual activities"
label var absent 				"Days absent from school due to health $^{\text{a}}$"
label var medication			"Takes doctor prescribed medication"
label var activity30			"Days engage in physical activity for 30+ minutes in typical week"
label var everSmoke				"Ever smoked an entire cigarette"
label var everDrink				"Ever drank alcohol more than two times without parents"
label var docIll                "Saw doctor for an illness $^{\text{a}}$"
label var numDocIll             "No. visited health care professional due to illness $^{\text{a}}$"
label var regDoc                "Saw doctor for regular check-up $^{\text{a}}$"
label var numRegDoc             "No. regular check-ups $^{\text{a}}$"
label var emRoom                "No. taken to emergency room $^{\text{a}}$"

foreach var of varlist `HEALTHVARS' `LIMITVARS' `MENTALVARS' `BEHAVVARS' ///
    `MEDIVARS' `DOCVARS' { // chHealth_ healthFactor mediCov_c mediCov_t medicalFactor behavFactor
    label variable `var' `"\:\:\:\: `: variable label `var''"'
}

* Means
esttab est1 est2 est3 est4 est5 using "${TABLEDIR}/SumStat_Health.tex", ///
nonumber label collabels(none) cells("mean(fmt(%9.2fc))") ///
stats(N, fmt(%9.0f) label(Observations)) style(tex) alignment(r) ///
mlabels("Age 1" "Age 3" "Age 5" "Age 9" "Age 15")  replace compress ///
refcat(badHealth "Health conditions" limit "Limitations" depressed "Mental health" activity30 "Health behaviours" chMediHI "Medicaid" medication "Utilization", nolabel) ///
note("Standard deviation reported in brackets. Sample ..." "$^{\text{a}}$ refers to past year") ///
title("Means of several health variables\label{means}") // sd(par fmt(%9.2fc))

* Count
esttab est1 est2 est3 est4 est5 using "${TABLEDIR}/SumStat_Health_count.tex", ///
nonumber label collabels(none) cells("count(fmt(%9.0fc))") ///
stats(N, fmt(%9.0f) label(Observations)) style(tex) alignment(r) ///
mlabels("Age 1" "Age 3" "Age 5" "Age 9" "Age 15")  replace compress ///
refcat(badHealth "Health conditions" limit "Limitations" depressed "Mental health" activity30 "Health behaviours" chMediHI "Medicaid" medication "Utilization", nolabel) ///
note("Standard deviation reported in brackets. Sample ..." "$^{\text{a}}$ refers to past year") ///
title("Count of several health variables\label{count}") // sd(par fmt(%9.2fc))


********************************************************************************
************************* TABLES SIMULATED ELIGIBILITY *************************
********************************************************************************

use "${CLEANDATADIR}/simulatedEligbility.dta", clear

gen simulatedElig100 = simulatedElig*100
gen Elig1998 = simulatedElig100 if year == 1998
gen Elig2018 = simulatedElig100 if year == 2018
statastates, fips(statefip) nogenerate   // abbreviation for state
save "${TEMPDATADIR}/simulatedElig100.dta", replace

collapse Elig1998 Elig2018, by(state_abbrev)    // state_abbrev
gen Diff = Elig2018 - Elig1998
label var Elig1998 "1998"
label var Elig2018 "2018"
save "${TEMPDATADIR}/DiffElig.dta", replace

************************************
* Medicaid eligbility by year
************************************
use "${TEMPDATADIR}/simulatedElig100.dta", clear
eststo clear
estpost tabstat simulatedElig100, by(year) nototal
eststo
esttab . using "${TABLEDIR}/simulatedEligbility_year.tex", replace ///
cells( mean(fmt(a3)) ) nonumber noobs nodepvars label  ///
title("Medicaid eligibility by year") nomtitles compress collabels(none) ///
addnotes("Based on March CPS data" "from 1998-2018.") mlabels("\% eligible \\ Year & children")

************************************
* Medicaid eligbility by state & year
************************************
use "${TEMPDATADIR}/DiffElig.dta", clear
eststo clear
estpost tabstat Elig1998 Elig2018 Diff, by(state_abbrev) nototal
eststo
esttab . using "${TABLEDIR}/simulatedEligbility_state.tex", replace label ///
nonumber cells("Elig1998(fmt(a3) label(1998)) Elig2018(fmt(a3) label(2018)) Diff(fmt(a3) label(Diff))") noobs ///
title("Medicaid eligibility by state") compress ///
addnotes("Based on March CPS data" "from 1998 and 2018.") longtable nomtitle


* Delete files
cd ${TEMPDATADIR}
erase simulatedElig100.dta
erase DiffElig.dta


