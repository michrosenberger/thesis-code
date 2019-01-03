* Project:      MA Thesis
* Content:      Health outcomes
* Data:         Fragile families
* Author:       Michelle Rosenberger
* Date:         November 7, 2018

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

* Set working directories
if "`c(username)'" == "michellerosenberger"  {
    global USERPATH     "~/Development/MA"
}

global CLEANDATADIR  	"${USERPATH}/data/clean"
global TEMPDATADIR  	"${USERPATH}/data/temp"
global CODEDIR          "${USERPATH}/code"
global TABLEDIR         "${USERPATH}/output/tables"
global FIGUREDIR        "${USERPATH}/output/figures"
global RAWDATADIR	    "${USERPATH}/data/raw/FragileFamilies"

* log

* Health variables
use "${TEMPDATADIR}/health.dta", clear
rename idnum id

* Demographics
merge 1:1 id wave using "${TEMPDATADIR}/household_FF.dta"
keep if _merge == 3
drop _merge
rename id idnum

preserve 
	collapse chBlack chHispanic chOther chMulti chWhite, by(idnum)

	* Saliva
	merge 1:1 idnum using "${RAWDATADIR}/04_Nine-Year Core/ff_y9_pub1.dta", keepusing(ck5saliva)
	drop if _merge != 3
	replace ck5saliva = . if ck5saliva == -9
	replace ck5saliva = . if ck5saliva == 0

restore

********************************************************************************
********************************** POWER & MDE *********************************
********************************************************************************
/* 
/* ---------------------------------- MDE ----------------------------------- */
* N = 3500, health factor standardized to std = 1 and mean = 0
power twomeans 1, power(0.8 0.9) n(500 1000 1500 2000 2500 3000 3500) sd(1) graph(y(delta)) byopts(bgcolor(white))

graph export "${FIGUREDIR}/MDE.png", replace
/* ----------------------------------  END ---------------------------------- */
 */

/* ---------------------------- POWER CALULATION ---------------------------- */

/* ----------------------------------  END ---------------------------------- */



/* ----------------------------------  END ---------------------------------- */


/* ------------------------------- REGRESSIONS ------------------------------ */
* Coverage: 	mediCov_c1-mediCov_c15 or mediCov_t1-mediCov_t15
* Variables: 	chHealth_0-chHealth_15
* No vars:		no_*
* Health:		chHealth chHealth_neg moHealth moHealth_neg
* General:		healthFactor_a1_std-healthFactor_a15_std
* Utilization:	medicalFactor_a1_std-medicalFactor_a15_std
* Never:		neverSmoke neverDrink 
* Behaviour:	behavFactor_a15_std

global CONTROLS age female moEduc moAge avgInc moHealth

reg chHealth 			mediCov_c15 ${CONTROLS} if wave == 15, robust
est store chHealth_15_fifteen
estadd local Controls 		"$\checkmark$"	// add checkmark "Controls"

* Current
/* reg healthFactor_a15 	mediCov_c15 ${CONTROLS}
est store healthFactor_a15_mediCov_c15
estadd local Controls 		"$\checkmark$"	// add checkmark "Controls" */

foreach var in healthFactor_a15_std medication everSmoke everDrink activityVigorous {
	reg healthFactor_a15_std 	mediCov_c15 ${CONTROLS} if wave == 15, robust
	est store `var'_fifteen
	estadd local Controls 		"$\checkmark$"	// add checkmark "Controls"
}

/* reg numRegDoc  	mediCov_c9 ${CONTROLS} if wave == 9, robust
est store numRegDoc_nine
estadd local Controls 		"$\checkmark$"	// add checkmark "Controls" */

* LaTex
label var mediCov_c15 	"Current Medicaid Coverage"
label var age			"Age"
label var moHealth		"Mother health"

estout healthFactor_a15_fifteen chHealth_15_fifteen ///
medication_fifteen everSmoke_fifteen everDrink_fifteen activityVigorous_fifteen ///
using "${TABLEDIR}/regression.tex", replace label cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) ///
collabels(none) ///
mlabels("Health index" "Child health" "Medication" "Ever smoke" "Ever drink" "Activity") ///
style(tex) starlevels(* .1 ** .05 *** .01) numbers ///
stats(Controls N r2, fmt(%9.0f %9.0f %9.3f) label(Controls Obs. "\$R^{2}$")) ///
varlabels(_cons Constant, blist(mediCov_c15 "\hline ") elist(_cons \hline)) // keep order
* numbers mlabels("" "" "" "" "") mgroups("`pheno'", pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))


/* 	Interpretation code
	regression here
	* As percentage of a standard deviation
	local beta_allMediHI_`wave' = _b[allMediHI]
	sum chHealth_`wave'
	local chHealth_`wave'_sd = r(sd)
	*di " Increases on average by " (`beta_allMediHI_15' / `chHealth_15_sd') " of a standard deviation"
	listcoef, help */

/* ----------------------------------  END ---------------------------------- */





* capture log close

