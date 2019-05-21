* -----------------------------------
* Project:      MA Thesis
* Content:      Run Analysis
* Author:       Michelle Rosenberger
* Date:         March 25, 2018
* -----------------------------------

/* This code performs the analysis part. It includes power calculations, MDE,
and regressions (OLS, RF, FS, IV-2SLS).

* ----- INPUT DATASETS:
health.dta; household_FF.dta; ff_gen_9y_pub4.dta; cutscombined.dta; 
simulatedEligbility.dta; 

* ----- OUTPUT DATASETS:
analysis.dta
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
global PREPARE 			= 1		// Prepare data
global POWER			= 0		// MDE + Power Calculations
global DESCRIPTIVE		= 1		// Perform descriptive statistics
global REGRESSIONS 		= 1 	// Perform regressions
global ASSUMPTIONS		= 1		// Check IV assumptions
global TABLESSIMULATED	= 1
global ROBUSTNESS		= 0		// Perform robustness checks

* ----------------------------- LOG FILE


* ---------------------------------------------------------------------------- *
* ------------------------- COMBINE & PREPARE DATA --------------------------- *
* ---------------------------------------------------------------------------- *

if ${PREPARE} == 1 {
	* ----------------------------- LOAD HEALTH DATA FF
	use "${TEMPDATADIR}/health.dta", clear
	* TO-DO: drop not used variables

	* ----------------------------- MERGE DEMOGRAPHICS FF
	merge 1:1 idnum wave using "${TEMPDATADIR}/household_FF.dta", nogen
	rename chAge age
	* TO-DO: drop not used variables

	* ----------------------------- MERGE GENETIC DATA (RESTRICTED USE DATA)
	* ----- PREPARE
	preserve
		use "${RAWDATADIR}/rawData/ff_gen_9y_pub4.dta", clear
		gen wave = 9
		mvdecode gm5* gk5*, mv(-9 = .a \ -7 = .b \ -5 = .c \ -3 = .d \ -1 = .e)
		rename gk5saliva chGenetic_temp
		save "${TEMPDATADIR}/genetic.dta", replace
	restore

	* ----- MERGE
	merge 1:1 idnum wave using "${TEMPDATADIR}/genetic.dta", nogen
    egen chGenetic = max(chGenetic_temp), by(idnum) 
	drop chGenetic_temp
	label define chGenetic	0 "0 No"	1 "1 Yes"
	label values chGenetic chGenetic

	* ----------------------------- MERGE ACTUAL AND SIMULATED ELIGIBILITY TO REST
	* ----- PREPARE
	gen bpost1983 = year > 1983

	* ----- MERGE
	merge m:1 age statefip year bpost1983 	using "${CLEANDATADIR}/cutscombined.dta"
	drop if _merge == 2
	drop _merge

	merge m:1 age statefip year 			using "${CLEANDATADIR}/simulatedEligbility.dta"
	drop if _merge == 2
	drop _merge

	* ----------------------------- ELIGIBILITY
	* ----- Calculate eligibility through income ratio and thresholds
	gen elig = . 
	replace elig = incRatio_FF <= medicut | incRatio_FF <= schipcut
	replace elig = . if medicut == . | schipcut == . | incRatio_FF == .

	* ----- ELIGIBILITY AT EACH AGE
	foreach elig in elig simulatedElig {
		foreach wave in 0 1 3 5 9 15 {
			gen `elig'`wave'_temp = `elig' if wave == `wave'
			bysort idnum: egen `elig'`wave' = max(`elig'`wave'_temp)
			drop `elig'`wave'_temp
		}
	}

	* ----- AVERAGE ELIGIBILITY ACROSS CHILDHOOD 		// eligAvg9 simulatedEligAvg9
	foreach elig in elig simulatedElig {
		egen `elig'Avg9 	= rowmean(`elig'1 `elig'3 `elig'5 `elig'9)
		egen `elig'Avg15 	= rowmean(`elig'1 `elig'3 `elig'5 `elig'9 `elig'15)

		replace `elig'Avg9 	= `elig'Avg9*4
		replace `elig'Avg15 = `elig'Avg15*5
	}

	* ----- CUMULATED ACTUAL + SIMULATED ELIGIBILITY	// eligAll9 simulatedElig9
	foreach elig in elig simulatedElig {
		foreach wave in 1 3 5 9 15 {
			egen `elig'All`wave' = sum(`elig') if wave <= `wave', by(idnum)
		}
	}

	* ----------------------------- SAMPLE SELECTION
	* ----- HOW MANY NON-MISSING ELIG OBSERVATIONS
	gen observation = 1 if elig != .
	bysort idnum: egen obs9 	= count(observation) if wave <= 9	// keep if obs9 >= 2
	bysort idnum: egen obs15 	= count(observation) if wave <= 15	// keep if obs15 >= 3

	drop observation

	* ----------------------------- SAVE
	label var chGenetic "Child has genetic information"

	order idnum wave age 
	sort idnum wave 

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
* -------------------------- DESCRIPTIVE STATISTICS -------------------------- *
* ---------------------------------------------------------------------------- *
if ${DESCRIPTIVE} == 1 {

	preserve 
		* ----------------------------- PREPARE DATA
		eststo clear

		global STATSVAR 	famSize female chWhite chBlack chHispanic chOther ///
							chMulti moCohort faCohort moAge avgInc incRatio_FF ////
							year moCollege faCollege moReport
		* ADD health variables from analysis
		
		global COMPARVAR 	famSize female chWhite chBlack chHispanic moCohort

        gen moCollege = moEduc == 3
		gen faCollege = faEduc == 3
		rename chFemale female
		keep idnum wave $STATSVAR

		* ----------------------------- SUMMARY STATS FRAGILE FAMILIES
		* ----- PREPARE VARIABLES
		label var female 		"Female"
		label var chWhite 		"White"
		label var chBlack		"Black"
		label var chHispanic	"Hispanic"
		label var chOther		"Other race"
		label var chMulti		"Multi-racial"
		label var incRatio_FF	"Poverty ratio"
		label var year			"Birth year"
		label var avgInc		"Family income \\ \:\:\:\:\:\:\:\: (in 1'000 USD)"
		label var moCollege		"Mother has some college"
		label var faCollege		"Father has some college"
		label var moReport		"Mother report used"
		label var faCohort		"Father's birth year"

		foreach var of varlist $STATSVAR {
			label variable `var' `"\:\:\:\: `: variable label `var''"'
		}

		* ----- FF SUMMARY STATISTICS
		* NOTE: LIMIT TO REGRESSION SAMPLE
		eststo statsFF: estpost tabstat $STATSVAR if wave == 0, columns(statistics) statistics(mean sd min max n) 

		* ----- LaTex TABLE
		esttab statsFF using "${TABLEDIR}/SumStat_FF.tex", style(tex) replace ///
		cells("mean(fmt(%9.0fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.0fc %9.0fc %9.2fc)) sd(fmt(%9.2fc))") ///
		label nonumber mlabels(none) /// 
		order(year female chWhite chBlack chHispanic chMulti chOther moAge moCohort faCohort moCollege faCollege moReport famSize avgInc incRatio_FF) ///
		stats(N, fmt(%9.0f) label(Observations)) collabels("Mean" "Standard \\ & & Deviation") ///
		refcat(year "Child" moAge "Family", nolabel)


		* ----------------------------- SUMMARY STATS COMPARISON CPS & FF
		* COLUMNS: (1) FF (2) CPS (3) CPS restricted (4) Diff (5) pval diff

		* ----- PREPARE VARIABLES
		gen FF = 1
		append using  "${TEMPDATADIR}/cps_summary.dta"
		replace FF = 0 if FF == .

		* ----- FULL FFCWS SUM STAT
		eststo compFF1: estpost tabstat $COMPARVAR if wave == 0 & FF == 1, ///
		columns(statistics) statistics(mean sd n) 
		estadd local FullSamp		"$\checkmark$"

		* ----- WOKRING SAMPLE FFCWS SUM STAT
		* NOTE: LIMIT TO REGRESSION SAMPLE
		eststo compFF2: estpost tabstat $COMPARVAR if wave == 0 & FF == 1, ///
		columns(statistics) statistics(mean sd n)
		estadd local WorkingSamp	"$\checkmark$"

		* ----- FULL CPS SUM STAT
		eststo compCPS1: estpost tabstat $COMPARVAR if FF == 0, ///
		columns(statistics) statistics(mean sd n)
		estadd local FullSamp		"$\checkmark$"

		* ----- WORKING SAMPLE CPS SUM STAT
		* NOTE: LIMIT MIRROR SAMPLE
		eststo compCPS2: estpost tabstat $COMPARVAR if FF == 0, ///
		columns(statistics) statistics(mean sd n)
		estadd local WorkingSamp	"$\checkmark$"

		* ----- LaTex TABLE
		esttab compFF1 compFF2 compCPS1 compCPS2 using "${TABLEDIR}/SumStat_both.tex", replace ///
		cells("mean(fmt(%9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.0fc))") ///
		order(female chWhite chBlack chHispanic famSize moCohort) ///
		label collabels(none) mlabels("FFCWS" "FFCWS" "CPS" "CPS") style(tex) alignment(r) ///
		refcat(female "Child" famSize "Family", nolabel) ///
		stats(FullSamp WorkingSamp N, fmt(%9.0f) ///
		layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
		label("Full Sample" "Working Sample" "Observations"))

	restore

} // END DESCRIPTIVE


* ---------------------------------------------------------------------------- *
* ------------------------------- REGRESSIONS -------------------------------- *
* ---------------------------------------------------------------------------- *
* NOTE: when running separate regressions: preserve keep if obs9 > X restore

* General health FACTOR (9)			: child health + had in past 12 months (no_)
* Limitations 			(9 & 15)	: limit absent
* Health behav FACTOR	(15)		: smoke, drink, vigorous activity
* WEIGHT							: BMI + indicator for overweight
* Mental health			(15)		: Self report dep + doctor diagnosed
* Uitlization FACTOR	(9 & 15)	: medication + doc illness + doc regular + ER

* ----------------------------- GLOBAL VARIABLES
global CONTROLS 	age chFemale chRace moAge

global ELIG9 		eligAll9				// elig eligAll9 eligAvg9 
global SIMELIG9 	simulatedEligAll9		// simulatedElig simulatedEligAll9 simulatedEligAvg9
global OUTCOMES9 	chHealth_neg healthFactor_a9_std medicalFactor_a9_std absent

global ELIG15 		eligAll15				// elig eligAll15 eligAvg15
global SIMELIG15 	simulatedEligAll15		// simulatedElig simulatedEligAll15 simulatedEligAvg15
global OUTCOMES15 	chHealth_neg behavFactor_a15_std medFac_a15_std absent limit bmi


if ${REGRESSIONS} == 1 {

	rename medicalFactor_a15_std medFac_a15_std

	* ----------------------------- OUTCOMES AGE 9
	foreach outcome in $OUTCOMES9 {
		* ----- OLS
		reg `outcome' ${ELIG9} ${CONTROLS} i.statefip if wave == 9 & chGenetic == 1, cluster(statefip)

		est store `outcome'_OLS_9
		estadd local Controls		"$\checkmark$"
		estadd local StateFE		"$\checkmark$"

		* ----- RF
		reg `outcome' ${SIMELIG9} ${CONTROLS} i.statefip if wave == 9 & chGenetic == 1,  cluster(statefip)

		est store `outcome'_RF_9
		estadd local Controls		"$\checkmark$"
		estadd local StateFE		"$\checkmark$"

		* ----- FS
		ivregress 2sls `outcome' ${CONTROLS} i.statefip (${ELIG9} = ${SIMELIG9}) if wave == 9 & chGenetic == 1, first cluster(statefip)
		gen samp_`outcome'9 = e(sample)

		reg ${ELIG9} ${SIMELIG9} ${CONTROLS} i.statefip if (wave == 9 & samp_`outcome'9 == 1 & chGenetic == 1), cluster(statefip)
		est store `outcome'_FS_9
		estadd local Controls		"$\checkmark$"
		estadd local StateFE		"$\checkmark$"

		* ----- IV-2SLS
		ivregress 2sls `outcome' ${CONTROLS} i.statefip (${ELIG9} = ${SIMELIG9}) if wave == 9 & chGenetic == 1,  cluster(statefip)

		est store `outcome'_IV_9
		estadd local Controls 		"$\checkmark$"
		estadd local StateFE 		"$\checkmark$"

		estat firststage
		mat fstat = r(singleresults)
		estadd scalar fs = fstat[1,4] // can add in stats(fs) in the regression
	}

	* ----------------------------- OUTCOMES AGE 15
	foreach outcome in $OUTCOMES15 {
		* ----- OLS
		reg `outcome' ${ELIG15} ${CONTROLS} i.statefip if wave == 15 & chGenetic == 1, cluster(statefip)
		est store `outcome'_OLS_15
		estadd local Controls		"$\checkmark$"
		estadd local StateFE		"$\checkmark$"

		* ----- RF
		reg `outcome' ${SIMELIG15} ${CONTROLS} i.statefip if wave == 15 & chGenetic == 1,  cluster(statefip)

		est store `outcome'_RF_15
		estadd local Controls		"$\checkmark$"
		estadd local StateFE		"$\checkmark$"

		* ----- FS
		ivregress 2sls `outcome' ${CONTROLS} i.statefip (${ELIG15} = ${SIMELIG15}) if wave == 15 & chGenetic == 1, first cluster(statefip)
		gen samp_`outcome'15 = e(sample)

		reg ${ELIG15} ${SIMELIG15} ${CONTROLS} i.statefip if (wave == 15 & samp_`outcome'15 == 1 & chGenetic == 1), cluster(statefip)
		est store `outcome'_FS_15
		estadd local Controls		"$\checkmark$"
		estadd local StateFE		"$\checkmark$"

		* ----- IV-2SLS
		ivregress 2sls `outcome' ${CONTROLS} i.statefip (${ELIG15} = ${SIMELIG15}) if wave == 15 & chGenetic == 1,  cluster(statefip)

		est store `outcome'_IV_15
		estadd local Controls 		"$\checkmark$"
		estadd local StateFE 		"$\checkmark$"

		estat firststage
		mat fstat = r(singleresults)
		estadd scalar fs = fstat[1,4] // can add in stats(fs) in the regression
	}


	* ----------------------------- CHILD HEALTH BY AGE (IV)
	* ----- CURRENT HEALTH
	foreach outcome in chHealth_neg {
		foreach wave in 1 3 5 9 15 {
			di "****** "
			ivregress 2sls `outcome' ${CONTROLS} i.statefip (elig = simulatedElig) if wave == `wave' & chGenetic == 1,  cluster(statefip)
			est store `outcome'_IV_SEP_`wave'
			estadd local Controls 		"$\checkmark$"
			estadd local StateFE 		"$\checkmark$"

			estat firststage
			mat fstat = r(singleresults)
			estadd scalar fs = fstat[1,4] // can add in stats(fs) in the regression
		}
	}	

	* ----- CUMULATED HEALTH
	foreach outcome in chHealth_neg {
		foreach wave in 1 3 5 9 15 {
			di "****** "
			ivregress 2sls `outcome' ${CONTROLS} i.statefip (eligAll`wave' = simulatedEligAll`wave') ///
			if wave == `wave' & chGenetic == 1,  cluster(statefip)

			est store `outcome'_IV_SEP2_`wave'
			estadd local Controls 		"$\checkmark$"
			estadd local StateFE 		"$\checkmark$"

			estat firststage
			mat fstat = r(singleresults)
			estadd scalar fs = fstat[1,4] // can add in stats(fs) in the regression
		}
	}	


	* ----------------------------- OUTPUT Latex
	* ----- LABELS
	label var age				"Age"
	label var chRace			"Race"
	label var ${ELIG9}			"Eligibility"
	label var ${ELIG15}			"Eligibility"
	label var ${SIMELIG9}		"Simulated Elig"
	label var ${SIMELIG15}		"Simulated Elig"
	label var medFac_a15_std	"Utilization"

	* ----- OLS & IV (AGE 9)
	estout healthFactor_a9_std_OLS_9 healthFactor_a9_std_IV_9 chHealth_neg_OLS_9 chHealth_neg_IV_9 ///
	absent_OLS_9 absent_IV_9 medicalFactor_a9_std_OLS_9 medicalFactor_a9_std_IV_9 ///
	using "${TABLEDIR}/regression9.tex", replace label collabels(none) style(tex) ///
	mlabels("\rule{0pt}{3ex} OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") nonumbers ///
	keep(${ELIG9} ${CONTROLS} _cons) order(${ELIG9} ${CONTROLS} _cons) /// 					"\ "
	cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE N r2 fs, fmt(%9.0f %9.0f %9.0f %9.3f %9.1f) /// 					stats
	layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///								stats
	label("\hline \rule{0pt}{3ex}Controls" "State FE" Obs. "\$R^{2}$" "F")) ///				stats
	mgroups("\rule{0pt}{3ex} Factor Health" "Child Health" "Absent" "Utilization", ///		mgroups
	pattern(1 0 1 0 1 0 1 0) span ///														mgroups
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///			mgroups
	varlabels(_cons Constant, blist(${ELIG9} "\hline ")) //									varlabels

	* ----- OLS & IV (AGE 15)
	estout behavFactor_a15_std_OLS_15 behavFactor_a15_std_IV_15 chHealth_neg_OLS_15 chHealth_neg_IV_15 ///
	absent_OLS_15 absent_IV_15 limit_OLS_15 limit_IV_15 medFac_a15_std_OLS_15 medFac_a15_std_IV_15 ///
	using "${TABLEDIR}/regression15.tex", replace label collabels(none) style(tex) ///
	mlabels("\rule{0pt}{3ex} OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") nonumbers ///
	keep(${ELIG15} ${CONTROLS} _cons) order(${ELIG15} ${CONTROLS} _cons) /// 					"\ "
	cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE N r2 fs, fmt(%9.0f %9.0f %9.0f %9.3f %9.1f) /// 						stats
	layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///									stats
	label("\hline \rule{0pt}{3ex}Controls" "State FE" Obs. "\$R^{2}$" "F")) ///					stats
	mgroups("\rule{0pt}{3ex} Factor Behav" "Child Health" "Absent" "Limit" "Utilization", ///	mgroups
	pattern(1 0 1 0 1 0 1 0 1 0) span ///														mgroups
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///				mgroups
	varlabels(_cons Constant, blist(${ELIG15} "\hline ")) //									varlabels

	* ----- RF & FS (9)
	estout healthFactor_a9_std_FS_9 healthFactor_a9_std_RF_9 chHealth_neg_FS_9 chHealth_neg_RF_9 ///
	absent_FS_9 absent_RF_9 medicalFactor_a9_std_FS_9 medicalFactor_a9_std_RF_9 ///
	using "${TABLEDIR}/RF_FS_9.tex", replace label collabels(none) style(tex) ///
	mlabels("\rule{0pt}{3ex} FS" "RF" "FS" "RF" "FS" "RF" "FS" "RF") nonumbers ///
	keep(${SIMELIG9} ${CONTROLS} _cons) order(${SIMELIG9} ${CONTROLS} _cons) /// 			"\ "
	cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE N r2, fmt(%9.0f %9.0f %9.0f %9.3f) /// 							stats
	layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///								stats
	label("\hline \rule{0pt}{3ex}Controls" "State FE" Obs. "\$R^{2}$")) ///					stats
	mgroups("\rule{0pt}{3ex} Factor Health" "Child Health" "Absent" "Utilization", ///		mgroups
	pattern(1 0 1 0 1 0 1 0) span ///														mgroups
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///			mgroups
	varlabels(_cons Constant, blist(${SIMELIG9} "\hline ")) //								varlabels

	* ----- RF & FS (15)
	estout behavFactor_a15_std_FS_15 behavFactor_a15_std_RF_15 chHealth_neg_FS_15 chHealth_neg_RF_15 ///
	absent_FS_15 absent_RF_15 limit_FS_15 limit_RF_15 medFac_a15_std_FS_15 medFac_a15_std_RF_15 ///
	using "${TABLEDIR}/RF_FS_15.tex", replace label collabels(none) style(tex) ///
	mlabels("\rule{0pt}{3ex} FS" "RF" "FS" "RF" "FS" "RF" "FS" "RF" "FS" "RF") nonumbers ///
	keep(${SIMELIG15} ${CONTROLS} _cons) order(${SIMELIG15} ${CONTROLS} _cons) /// 				"\ "
	cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE N r2, fmt(%9.0f %9.0f %9.0f %9.3f) /// 								stats
	layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///									stats
	label("\hline \rule{0pt}{3ex}Controls" "State FE" Obs. "\$R^{2}$")) ///						stats
	mgroups("\rule{0pt}{3ex} Factor Behav" "Child Health" "Absent" "Limit" "Utilization", ///	mgroups
	pattern(1 0 1 0 1 0 1 0 1 0) span ///														mgroups
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///				mgroups
	varlabels(_cons Constant, blist(${SIMELIG15} "\hline ")) //									varlabels

	* ----- CHILD HEALTH BY AGE (OLS & IV) - CURRENT ELIGIBILITY
	estout chHealth_neg_IV_SEP_1 chHealth_neg_IV_SEP_3 chHealth_neg_IV_SEP_5 ///
	chHealth_neg_IV_SEP_9 chHealth_neg_IV_SEP_15 ///
	using "${TABLEDIR}/chHealth_all.tex", replace label collabels(none) style(tex) ///
	mlabels(none) numbers ///
	keep(elig ${CONTROLS} _cons) order(elig ${CONTROLS} _cons) /// 							"\ "
	cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE N r2 fs, fmt(%9.0f %9.0f %9.0f %9.3f %9.1f) /// 					stats
	layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///								stats
	label("\hline \rule{0pt}{3ex}Controls" "State FE" Obs. "\$R^{2}$" "F")) ///				stats
	mgroups("\rule{0pt}{3ex} Age 1" "Age 3" "Age 5" "Age 9" "Age 15", ///					mgroups
	pattern(1 1 1 1 1) span ///																mgroups
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///			mgroups
	varlabels(_cons Constant, blist(elig "\hline ")) //										varlabels	

	* ----- CHILD HEALTH BY AGE (OLS & IV) - CUMULATED ELIGIBILITY
	estout chHealth_neg_IV_SEP2_1 chHealth_neg_IV_SEP2_3 chHealth_neg_IV_SEP2_5 ///
	chHealth_neg_IV_SEP2_9 chHealth_neg_IV_SEP2_15 ///
	using "${TABLEDIR}/chHealth_all2.tex", replace label collabels(none) style(tex) ///
	mlabels(none) numbers ///
	keep(eligAll1 eligAll3 eligAll5 eligAll9 eligAll15 ${CONTROLS} _cons) ///
	order(eligAll1 eligAll3 eligAll5 eligAll9 eligAll15 ${CONTROLS} _cons) /// 				"\ "
	cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE N r2 fs, fmt(%9.0f %9.0f %9.0f %9.3f %9.1f) /// 					stats
	layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///								stats
	label("\hline \rule{0pt}{3ex}Controls" "State FE" Obs. "\$R^{2}$" "FS")) ///			stats
	mgroups("\rule{0pt}{3ex} Age 1" "Age 3" "Age 5" "Age 9" "Age 15", ///					mgroups
	pattern(1 1 1 1 1) span ///																mgroups
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///			mgroups
	varlabels(_cons Constant, blist(eligAll1 "\hline ")) //									varlabels	

} // END REGRESSIONS


* ---------------------------------------------------------------------------- *
* -------------------------------- ASSUMPTIONS ------------------------------- *
* ---------------------------------------------------------------------------- *

if ${ASSUMPTIONS} == 1 {

	/* TESTS THE IV ASSUMPTIONS. */

	* ----------------------------- BALANCE OF OBSERVABLES
	* NOTE: which option to go?
	* NOTE: which covariates

	* ----- PREDICT EACH COVARIATE WITH THE MODEL
	foreach observable in moEduc {
		reg `observable' ${SIMELIG9} ${CONTROLS} i.statefip if wave == 9 & chGenetic == 1,  cluster(statefip)
		est store `observable'_9 
	}

	* ----- PREDICT INSTRUMENT WITH ALL COVARIATES
	reg ${SIMELIG9} moEduc if wave == 9 & chGenetic == 1

	* ----- LaTex
	estout moEduc_9 using "${TABLEDIR}/balance.tex", replace label style(tex) ///
	collabels("Coefficient" "SD" "P-value") nonumbers keep(${SIMELIG9}) ///
	starlevels(* .1 ** .05 *** .01) cells("b(fmt(%9.3fc) star) se(fmt(%9.3fc)) p") ///
	mlabels(none) varlabels(, blist(${SIMELIG9} "\hline ")) ///
	mgroups("\rule{0pt}{3ex} Insert text here" , ///
	pattern(1 0 0 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) 

} // END ASSUMPTIONS

* ---------------------------------------------------------------------------- *
* ----------------------- TABLES SIMULATED ELIGIBILITY ----------------------- *
* ---------------------------------------------------------------------------- *

if ${TABLESSIMULATED} == 1 {

	/* CREATES ...  */

	preserve

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

		* ----------------------------- MEDICAID ELIGIBILITY BY YEAR
		use "${TEMPDATADIR}/simulatedElig100.dta", clear
		eststo clear
		estpost tabstat simulatedElig100, by(year) nototal
		eststo
		esttab . using "${TABLEDIR}/simulatedEligbility_year.tex", replace ///
		cells( mean(fmt(a3)) ) nonumber noobs nodepvars label  ///
		title("Medicaid eligibility by year") nomtitles compress collabels(none) ///
		addnotes("Based on March CPS data" "from 1998-2018.") mlabels("\% eligible \\ Year & children")


		* ----------------------------- MEDICAID ELIGIBILITY BY STATE & YEAR
		use "${TEMPDATADIR}/DiffElig.dta", clear
		eststo clear
		estpost tabstat Elig1998 Elig2018 Diff, by(state_abbrev) nototal
		eststo
		esttab . using "${TABLEDIR}/simulatedEligbility_state.tex", replace label ///
		nonumber cells("Elig1998(fmt(a3) label(1998)) Elig2018(fmt(a3) label(2018)) Diff(fmt(a3) label(Diff))") noobs ///
		title("Medicaid eligibility by state") compress ///
		addnotes("Based on March CPS data" "from 1998 and 2018.") longtable nomtitle

		* ----------------------------- DELETE FILES
		cd ${TEMPDATADIR}
		erase simulatedElig100.dta
		erase DiffElig.dta

	restore

} // END TABLESSIMULATED

* ---------------------------------------------------------------------------- *
* -------------------------------- ROBUSTNESS -------------------------------- *
* ---------------------------------------------------------------------------- *

if ${ROBUSTNESS} == 1 {

	* ----------------------------- SELECTION / DROP-OUT


	* ----------------------------- IV WITH AND WITHOUT CONTROLS


} // END ROBUSTNESS




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


