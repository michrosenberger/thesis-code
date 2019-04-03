* -----------------------------------
* Project:      MA Thesis
* Content:      Run Analysis
* Author:       Michelle Rosenberger
* Date:         March 25, 2018
* -----------------------------------

/* This code performs the analysis part. It includes power calculations, MDE,
and regressions (OLS, RF, FS, IV-2SLS).

- Datasets needed:

- TO-DO:
	- CHECK ALL MERGES ARE GOOD AND IDENTIFY OBSERVATIONS UNIQUELY
	- CHECK CONSTRUCTION OF VARIABLES
	- CHECK EVERYTHING + THOMPSON
	- CHECK CUMULATIVE HEALTH
	- CHECK MODELS CORRECTLY SPECIFIED
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
    global USERPATH     "~/Development/MA"
}

global CLEANDATADIR		"${USERPATH}/data/clean"
global TEMPDATADIR  	"${USERPATH}/data/temp"
global CODEDIR			"${USERPATH}/code"
global TABLEDIR			"${USERPATH}/output/tables"
global FIGUREDIR		"${USERPATH}/output/figures"
global RAWDATADIR		"${USERPATH}/data/raw/FragileFamilies"

* ----------------------------- SET SWITCHES
global POWER			= 0			// MDE + Power Calculations
global PREPARE 			= 1			// Prepare data
global REGRESSIONS 		= 1 		// Perform regressions

* ----------------------------- LOG FILE


* ---------------------------------------------------------------------------- *
* ------------------------- COMBINE & PREPARE DATA --------------------------- *
* ---------------------------------------------------------------------------- *

if ${PREPARE} == 1 {
	* ----------------------------- LOAD HEALTH DATA FF
	use "${TEMPDATADIR}/health.dta", clear

	* ----------------------------- MERGE DEMOGRAPHICS FF
	merge 1:1 idnum wave using "${TEMPDATADIR}/household_FF.dta", nogen

	* ----------------------------- MERGE GENETIC DATA (RESTRICTED USE DATA)
	* ----- PREPARE
	preserve
		use "${RAWDATADIR}/rawData/ff_gen_9y_pub4.dta", clear
		gen wave = 9
		save "${TEMPDATADIR}/genetic.dta", replace
		* TO-DO: check missing values in genetic data

	restore

	* ----- MERGE
	merge 1:1 idnum wave using "${TEMPDATADIR}/genetic.dta", nogen



	/* ----------------------------- SAMPLE SELECTION
	* Drop if family didn't complete interview
	drop if year == .

	* Do with actual medi
	* Drop if not enough observations per person (min. 3 observations out of 6)
	gen observation = 1 if year != .
	bysort idnum: egen countMedi = count(observation)
	drop if countMedi < 3
	drop observation
	label var countMedi "Observations per child"

	* Drop if no income value
	drop if hhInc == .

	* Replace age in wave 0

	* If fam size missing impute ratio from previous wave (mostly if no wave 9)


	tab year
	drop chLiveMo moHH_size_c
	*/


	* ----------------------------- MERGE ACTUAL AND SIMULATED ELIGIBILITY TO REST
	* ----- PREPARE
	preserve
		use "${CLEANDATADIR}/cutscombined.dta", clear
		merge m:1 age statefip year using "${CLEANDATADIR}/simulatedEligbility.dta", nogen
		save "${CLEANDATADIR}/eligibility_final.dta", replace
		* VARIABLES: statefip year age medicut schipcut bpost1983 simulatedElig
	restore

	* ----- MERGE
	* TO-DO: Neither do uniquely identify - check bpost1983
	merge m:m age statefip year using "${CLEANDATADIR}/eligibility_final.dta"
	drop if idnum == ""


	* ----------------------------- ELIGIBILITY
	* ----- Calculate eligibility through income ratio and thresholds
	gen elig = . 
	replace elig = incRatio_FF <= medicut | incRatio_FF <= schipcut
	replace elig =. if medicut==. | schipcut==. | incRatio_FF==.


	* ----- CUMULATED ELIGIBILITY
	foreach wave in 0 1 3 5 9 15 {
		egen eligALL_`wave' = sum(elig) if wave <= `wave', by(idnum)
	}

	* ----- CUMULATED SIMULATED ELIGIBILITY
	foreach wave in 0 1 3 5 9 15 {
		egen simEligALL_`wave' = sum(simulatedElig) if wave <= `wave', by(idnum)
	}

	save "${CLEANDATADIR}/analysis.dta", replace

} // END PREPARE

use "${CLEANDATADIR}/analysis.dta", clear


* ---------------------------------------------------------------------------- *
* ------------------------------- POWER & MDE -------------------------------- *
* ---------------------------------------------------------------------------- *
* NOTE: For main effect (effect of public health insurance on child health)

* ----------------------------- PREVIOUS LITERATURE (THOMPSON (2017))
/* Standardized health index as outcome variable (N = 5465)
IV estimate: additional year of public health insurance eligibility increases
summary index of adult health by 0.079 standard deviations (standard error 0.035).
Estimate is statistically significant at the 5% level. */

if ${POWER} == 1 {
	* ----------------------------- MDE
	* ----- COMPUTE EFFECT SIZE
	* Information sample: N = 2800 with genetic data, N = 4700 original sample
	* Health factor will be standardized to mean = 0 , SD = 1
	* Assumption stata: power onemean assumes a 5%-level two-sided test

	* ----- ESTIMATES
	power onemean 0, power(0.8 0.9) n(2000 2500 2800 3000 3200 3500) sd(1)

	* ----- GRAPH
	power onemean 0, power(0.8 0.9) n(2000 2500 2800 3000 3200 3500) sd(1) ///
	graph(y(delta) title("") subtitle("") scheme(s1color))  
	graph export "${FIGUREDIR}/MDE.png", replace
		

	* ----------------------------- POWER CALULATION
	* ----- COMPUATE POWER CALC
	power onemean 0 0.079, sd(1) n(2000 2500 2800 3000 3200 3500)

} // END POWER



* ---------------------------------------------------------------------------- *
* ------------------------------- REGRESSIONS -------------------------------- *
* ---------------------------------------------------------------------------- *
* Coverage: 		mediCov_c1-mediCov_c15 or mediCov_t1-mediCov_t15
* Variables: 		chHealth_0-chHealth_15
* No vars:			no_*
* Health:				chHealth chHealth_neg moHealth moHealth_neg
* General:			healthFactor_a1_std-healthFactor_a15_std
* Utilization:	medicalFactor_a1_std-medicalFactor_a15_std
* Never:				neverSmoke neverDrink 
* Behaviour:		behavFactor_a15_std

if ${REGRESSIONS} == 1 {

	egen race = max(chRace), by(idnum)

	* ----------------------------- GLOBAL VARIABLES
	global ELIG 		elig						// elig eligALL_9
	global SIMELIG 		simulatedElig				// simulatedElig simEligALL_9
	global CONTROLS 	age female race moAge		// moEduc
	global OUTCOMES 	healthFactor_a9_std chHealth_neg numRegDoc absent

	* ----------------------------- OLS
	foreach outcome in $OUTCOMES {
		di "****** OLS for `outcome'"
		reg `outcome' ${ELIG} ${CONTROLS} i.statefip if wave == 9,  cluster(statefip) // cluster at state level
		est store `outcome'_OLS_9
		estadd local Controls		"$\checkmark$"
		estadd local StateFE		"$\checkmark$"
	}

	* ----------------------------- REDUCED FORM
	foreach outcome in $OUTCOMES {
		di "****** OLS for `outcome'"
		reg `outcome' ${SIMELIG} ${CONTROLS} i.statefip if wave == 9,  cluster(statefip)
		est store `outcome'_RF_9
		estadd local Controls		"$\checkmark$"
		estadd local StateFE		"$\checkmark$"
	}

	* ----------------------------- FIRST STAGE
	*** CHECK F-STATISTIK IN FIRST STAGE
	foreach outcome in $OUTCOMES {
		di "****** IV 2SLS for `outcome'"
		ivregress 2sls `outcome' ${CONTROLS} i.statefip (${ELIG} = ${SIMELIG}) if wave == 9, first cluster(statefip)
		estat firststage
	}

	/* TO SAVE F-STAT
	mat fstat = r(singleresults)
	estadd scalar fs = fstat[1,4] 
	
	esttab a  using table1.tex, collabels(none)  cells(b(star fmt(3) vacant({--})))  label replace ///
	stats(N r2 fs, fmt(0 3) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}")  labels(`"Observations"' `"\(R^{2}\)"' `"\(F\)"')) drop(_cons) 
	*/

	* ----------------------------- IV-2SLS
	foreach outcome in $OUTCOMES {
		di "****** IV 2SLS for `outcome'"
		ivregress 2sls `outcome' ${CONTROLS} i.statefip (${ELIG} = ${SIMELIG}) if wave == 9,  cluster(statefip)
		est store `outcome'_IV_9
		estadd local Controls 		"$\checkmark$"
		estadd local StateFE 		"$\checkmark$"
	}


	* ----------------------------- OUTPUT Window
	/* ----- RF
	estout healthFactor_a9_std_RF_9 chHealth_neg_RF_9 numRegDoc_RF_9, ///
	keep(simulatedElig age female moAge) cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) ///
	starlevels(* .1 ** .05 *** .01) numbers */

	* ----- OLS and IV factor + health
	estout healthFactor_a9_std_OLS_9 healthFactor_a9_std_IV_9, ///
	mlabels("Factor OLS" "Factor IV") ///
	keep(${ELIG} age female moAge) cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) ///
	starlevels(* .1 ** .05 *** .01) numbers

	* ----- OLS and IV health
	estout chHealth_neg_OLS_9 chHealth_neg_IV_9, ///
	mlabels("Health OLS" "Health IV") ///
	keep(${ELIG} age female moAge) cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) ///
	starlevels(* .1 ** .05 *** .01) numbers

	* ----- OLS and IV absent
	estout absent_OLS_9 absent_IV_9, ///
	mlabels("Absent OLS" "Absent IV") ///
	keep(${ELIG} age female moAge) cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) ///
	starlevels(* .1 ** .05 *** .01) numbers

	* ----- OLS and IV numRegDoc
	estout numRegDoc_OLS_9 numRegDoc_IV_9, ///
	mlabels("NumRegDoc OLS" "NumRegDoc IV") ///
	keep(${ELIG} age female moAge) cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) ///
	starlevels(* .1 ** .05 *** .01) numbers


	* ----------------------------- OUTPUT Latex
	* ----- LABELS
	label var age		"Age"
	label var elig		"Elgibility"

	* ----- AGE 9
	* TO-DO: also include without controls
	* TO-DO: check number of observation, something does not add up (too much)
	estout healthFactor_a9_std_OLS_9 healthFactor_a9_std_IV_9 chHealth_neg_OLS_9 chHealth_neg_IV_9 ///
	absent_OLS_9 absent_IV_9 numRegDoc_OLS_9 numRegDoc_IV_9 ///
	using "${TABLEDIR}/regression9.tex", replace label collabels(none) style(tex) ///
	mlabels("\rule{0pt}{3ex} OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") nonumbers ///
	keep(${ELIG} age female moAge _cons) order(${ELIG} age female moAge _cons) /// 		"\ "
	cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE N r2, fmt(%9.0f %9.0f %9.0f %9.3f) /// 						stats
	layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///							stats
	label("\hline \rule{0pt}{3ex}Controls" "State FE" Obs. "\$R^{2}$")) ///				stats
	mgroups("\rule{0pt}{3ex} Factor Health" "Child Health" "Absent" "Doc", ///			mgroups
	pattern(1 0 1 0 1 0 1 0) span ///													mgroups
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///		mgroups
	varlabels(_cons Constant, blist(${ELIG} "\hline ")) //								varlabels

	* ----- AGE 15
	* TO-DO: also include without controls
	* TO-DO: add correct measures (for age 15)
	estout healthFactor_a9_std_OLS_9 healthFactor_a9_std_IV_9 chHealth_neg_OLS_9 chHealth_neg_IV_9 ///
	absent_OLS_9 absent_IV_9 numRegDoc_OLS_9 numRegDoc_IV_9 ///
	using "${TABLEDIR}/regression15.tex", replace label collabels(none) style(tex) ///
	mlabels("\rule{0pt}{3ex} OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") nonumbers ///
	keep(${ELIG} age female moAge _cons) order(${ELIG} age female moAge _cons) /// 		"\ "
	cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE N r2, fmt(%9.0f %9.0f %9.0f %9.3f) /// 						stats
	layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///							stats
	label("\hline \rule{0pt}{3ex}Controls" "State FE" Obs. "\$R^{2}$")) ///				stats
	mgroups("\rule{0pt}{3ex} Factor Health" "Child Health" "Absent" "Doc", ///			mgroups
	pattern(1 0 1 0 1 0 1 0) span ///													mgroups
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///		mgroups
	varlabels(_cons Constant, blist(${ELIG} "\hline ")) //								varlabels



} // END REGRESSIONS


* capture log close


/* ----------------------------- EXAMPLE OUTPUT
					TABLE X - OUTCOMES AT AGES 9 AND 15
----------------------------------------------------------------------------
----------------------------------------------------------------------------
						AGE 9								AGE 15
		--------------------------------	--------------------------------
			OUT 1			OUT 2				OUT 1			OUT 2	
		--------------	--------------		--------------	--------------
		OLS 	IV		OLS		IV			OLS		IV		OLS		IV
		(1)		(2)		(3)		(4)			(5)		(6)		(7)		(8)
----------------------------------------------------------------------------
VAR 1	XX		XX		XX		XX			XX		XX		XX		XX	
VAR 2	XX		XX		XX		XX			XX		XX		XX		XX
VAR 3	XX		XX		XX		XX			XX		XX		XX		XX

CONT	Y		Y		Y		Y			Y		Y		Y		Y
FE		Y		Y		Y		Y			Y		Y		Y		Y
R2		XX		XX		XX		XX			XX		XX		XX		XX
N		XX		XX		XX		XX			XX		XX		XX		XX
----------------------------------------------------------------------------
NOTES: XXX
*/


* ----------------------------- NOTE USED
/* 	Interpretation code
	regression here
	* As percentage of a standard deviation
	local beta_allMediHI_`wave' = _b[allMediHI]
	sum chHealth_`wave'
	local chHealth_`wave'_sd = r(sd)
	*di " Increases on average by " (`beta_allMediHI_15' / `chHealth_15_sd') " of a standard deviation"
	listcoef, help */



