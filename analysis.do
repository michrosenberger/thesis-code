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
	global CODEDIR		"~/Development/MA/code"
	// global CODEDIR		"/Volumes/g_econ_department$/econ/biroli/geighei/code/medicaidGxE/thesis-code"
}

do "${CODEDIR}/setDirectories.do"

* ----------------------------- SET SWITCHES
global PREPARE 			= 1		// Prepare data
global POWER			= 1		// MDE + Power Calculations
global DESCRIPTIVE		= 1		// Perform descriptive statistics
global REGRESSIONS 		= 1 	// Perform regressions
global COEFPLOT			= 1	
global ENROLLMENT		= 1		// Main effects with enrollment
global ASSUMPTIONS		= 1		// Check IV assumptions
global TABLESSIMULATED	= 1
global ADDITIONAL		= 1
global ROBUSTNESS		= 1		// Perform robustness checks
global HETEROGENOUS		= 1		// Heterogenous effects by race
global GXE				= 1

* ----------------------------- GLOBAL VARIABLES
global CONTROLS 	i.age 	chFemale i.chRace moAge age#chFemale

global ELIGVAR 		eligCum		// endogenous variable
global SIMELIGVAR 	simEligCum	// instrument

global OUTCOMES9 	healthFactor_9 chHealthRECODE medicalFactor_9 	regDoc 	absent
global OUTCOMES15 	behavFactor_15 chHealthRECODE medicalFactor_15	regDoc 	absent ///
					limit	depressedRECODE diagnosedDepression

* General health FACTOR (9)			: chHealthRECODE + *RECODE
* Health behav FACTOR	(15)		: activityVigorous neverSmoke neverDrink bmi
* Limitations 			(9 & 15)	: limit absent
* Mental health			(15)		: depressedRECODE diagnosedDepression
* Uitlization FACTOR	(9 & 15)	: emRoom docIll medication regDoc

* ----------------------------- LOG FILE
log using "${CODEDIR}/analysis.log", replace

* ---------------------------------------------------------------------------- *
* ------------------------- COMBINE & PREPARE DATA --------------------------- *
* ---------------------------------------------------------------------------- *

if ${PREPARE} == 1 {
	* ----------------------------- LOAD HEALTH DATA FF
	use "${TEMPDATADIR}/health.dta", clear
	
	* ----------------------------- MERGE DEMOGRAPHICS FF
	merge 1:1 idnum wave using "${TEMPDATADIR}/household_FF.dta", nogen

	* ----------------------------- MERGE GENETIC DATA FF (RESTRICTED USE DATA)
	merge 1:1 idnum wave using "${TEMPDATADIR}/genetic.dta", nogen

	* ----------------------------- MERGE CUTOFFS AND SIMULATED ELIGIBILITY
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
	foreach eligvar in eligCur simEligCum eligCum {
		gen `eligvar' = . 
	}

	rename simulatedElig simEligCur

	* ----- INDIVIDUAL ELIGIBILITY
	replace eligCur = incRatio <= medicut | incRatio <= schipcut
	replace eligCur = . if medicut == . | schipcut == . | incRatio == .

	* ----- CREATE CUMULATED ELIGIBILITY
	foreach eligvar in eligCur simEligCur {
		foreach wave in 0 1 3 5 9 15 {
			egen `eligvar'All`wave' = sum(`eligvar') if wave <= `wave', by(idnum)
		}
	}

	foreach wave in 0 1 3 5 9 15 {
		replace simEligCum 	= simEligCurAll`wave' 	if wave == `wave'
		replace eligCum 	= eligCurAll`wave' 		if wave == `wave'
	}

	label var eligCum		"Eligibility"
	label var simEligCum	"Simulated Elig"

	* ----- MEDICAID / CHIP TAKE-UP
	gen takeCum = .

	egen takeAll9 		= sum(chMediHI) if wave <= 9, by(idnum)
	egen takeAll15 		= sum(chMediHI) if wave <= 15, by(idnum)
	replace takeCum 	= takeAll9	if wave == 9
	replace takeCum 	= takeAll15	if wave == 15
	label var takeCum "Enrollment"

	* ----- LIMIT THE SAMPLE TO THE SAME INDIVIDUALS ACROSS ALL OUTCOMES
	egen numElig = count(eligCur) , by(idnum)

	* AGE 9
	qui ivregress 2sls healthFactor_9 ${CONTROLS} i.statefip (${ELIGVAR} = ${SIMELIGVAR}) ///
		if (wave == 9 & chGenetic == 1),  cluster(statefip)
	gen reg9 = e(sample)
	bysort idnum : egen samp1_temp = max(reg9)

	* AGE 15
	qui ivregress 2sls depressedRECODE ${CONTROLS} i.statefip (${ELIGVAR} = ${SIMELIGVAR}) ///
		if (wave == 15 & chGenetic == 1),  cluster(statefip)
	gen reg15 = e(sample)
	bysort idnum : egen samp2_temp = max(reg15)

	gen finSample = 1 if (samp1_temp == 1 & samp2_temp == 1)

	* ----- STANDARDIZE FACTOR SCORES
	foreach factorScore in healthFactor_9 healthFactor_15 medicalFactor_9 medicalFactor_15 behavFactor_15 {
		egen `factorScore' = std(`factorScore'_temp) if finSample == 1
	}

	* ----- Overweight + Obsese (85th percentile)
	gen bmi85 = .
	replace bmi85 = 0 if bmi_p >=0 & bmi_p < 85
	replace bmi85 = 1 if bmi_p >= 85 & bmi_p < 100

	* ----- Obese (95th percentile)
	gen bmi95 = .
	replace bmi95 = 0 if bmi_p >=0 & bmi_p < 95
	replace bmi95 = 1 if bmi_p >= 95 & bmi_p <= 100

	* ----------------------------- SAVE
	drop *All* *_temp reg9 reg15
	order idnum wave age 
	sort idnum wave 
	save "${CLEANDATADIR}/analysis.dta", replace

} // END PREPARE

use "${CLEANDATADIR}/analysis.dta", clear


* ---------------------------------------------------------------------------- *
* --------------------------------- PROGRAMS --------------------------------- *
* ---------------------------------------------------------------------------- *
* ----- PROGRAM TO ADD ROMANO-WOLF ADJUSTED PVALUES TO TABLE
	capture program drop formatTABLES
	program define formatTABLES
		args arg1 letter arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9 arg10 arg11 arg12

		foreach outcome in `arg2' `arg3' `arg4' `arg5' `arg6' `arg7' `arg8' `arg9' `arg10' `arg11' `arg12' {
			local `outcome'_`arg1' = e(rw_`outcome')
			local `outcome'_`arg1' : di %9.3f ``outcome'_`arg1''

			if (``outcome'_`arg1'' >= 0 & ``outcome'_`arg1'' < 0.01) { 	// ***
				global `outcome'_`arg1'_`letter' = "[``outcome'_`arg1'']***"
			}
			if (``outcome'_`arg1'' >= 0.01 & ``outcome'_`arg1'' < 0.05) {	// **
				global `outcome'_`arg1'_`letter' = "[``outcome'_`arg1'']**"
			}
			if (``outcome'_`arg1'' >= 0.05 & ``outcome'_`arg1'' < 0.1) {	// *
				global `outcome'_`arg1'_`letter' = "[``outcome'_`arg1'']*"
			}
			if (``outcome'_`arg1'' > 0.1) {
				global `outcome'_`arg1'_`letter' = "[``outcome'_`arg1'']"
			}
			di "`outcome'_`arg1'_`letter' ${`outcome'_`arg1'_`letter''}"
		}

	end

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
	grstyle clear
	grstyle init
	grstyle color background white
	grstyle color major_grid dimgray
	grstyle linewidth major_grid thin
	grstyle yesno draw_major_hgrid yes
	grstyle yesno grid_draw_min yes
	grstyle yesno grid_draw_max yes

	power onemean 0, power(0.8 0.9) n(2000 2500 2800 3000 3200 3500) sd(1) ///
	graph(y(delta) title("") subtitle(""))   // scheme(s1color)
	graph export "${FIGUREDIR}/MDE.${EXTENSION}", replace
		

	* ----------------------------- POWER CALULATION
	* ----- COMPUATE POWER CALC
	power onemean 0 0.079, sd(1) n(2000 2500 2800 3000 3200 3500)

} // END POWER


* ---------------------------------------------------------------------------- *
* -------------------------- DESCRIPTIVE STATISTICS -------------------------- *
* ---------------------------------------------------------------------------- *
if ${DESCRIPTIVE} == 1 {

	* ----------------------------- SAMPLE CHARACTERISTICS
	preserve 
		* ----------------------------- PREPARE DATA
		eststo clear

		drop chWhite chBlack chHispanic chOther chMulti

		global STATSVAR 	famSize female chWhite chBlack chHispanic chOther ///
							chMulti moCohort faCohort moAge avgInc incRatio ////
							chCohort moCollege faCollege numElig eligCum15 
		
		global COMPARVAR 	famSize female chWhite chBlack chHispanic moCohort ///
							faCohort chCohort moCollege faCollege

		rename chFemale female
		rename year chCohort

		* ONLY USE PRE-DETERMINED CHARACTERISTICS AT BASELINE
		foreach variable in moEduc faEduc {
			gen `variable'Base_temp = `variable' if wave == 0
			by idnum : egen `variable'Base = max(`variable'Base_temp)
			drop `variable'Base_temp
		}

		drop moCollege faCollege

		gen moCollege = moEducBase == 4
		gen faCollege = faEducBase == 4

		* CUMULATED ELIGIBILITY AT AGE 
		gen eligCum15_temp = eligCum if wave == 15
		egen eligCum15 = max(eligCum15_temp), by (idnum)

		* HISTOGRAM CUMULATED ELIGIBILITY
		label var eligCum15_temp "Cumulated Individual Eligibility"
		twoway histogram eligCum15_temp, fraction discrete ylabel(,grid) xlabel(0(1)6) ///
		xlabel(, valuelabel) color(emidblue) lcolor(navy)
		graph export "${FIGUREDIR}/cumulatedEligibility.${EXTENSION}", replace

		* INDICATORS FOR RACE
		tab chRace, gen(race)
		rename race1 chWhite
		rename race2 chBlack
		rename race3 chHispanic
		rename race4 chOther
		rename race5 chMulti

		keep idnum wave $STATSVAR finSample

		* ----------------------------- SUMMARY STATS FRAGILE FAMILIES
		* ----- PREPARE VARIABLES
		label var female 		"\:\:\:\: Female"
		label var chWhite 		"\:\:\:\: White"
		label var chBlack		"\:\:\:\: Black"
		label var chHispanic	"\:\:\:\: Hispanic"
		label var chOther		"\:\:\:\: Other race"
		label var chMulti		"\:\:\:\: Multi-racial"
		label var incRatio		"\:\:\:\: Poverty ratio"
		label var chCohort		"\:\:\:\: Birth year"
		label var avgInc		"\:\:\:\: Yearly family income (in \\$1'000)" // \\ \:\:\:\:\:\:\:\:
		label var moCollege		"\:\:\:\: Mother has college"
		label var faCollege		"\:\:\:\: Father has college"
		label var faCohort		"\:\:\:\: Father's birth year"
		label var moAge			"\:\:\:\: Mother's age at birth"
		label var moCohort		"\:\:\:\: Mother's birth year"
		label var famSize		"\:\:\:\: Family size"
		label var numElig		"\:\:\:\: Eligibility observed"
		label var eligCum15		"\:\:\:\: Cumulated eligibility"

		* ----- FF SUMMARY STATISTICS
		eststo statsFF: estpost tabstat $STATSVAR if (wave == 0 & finSample == 1), columns(statistics) statistics(mean sd median min max n) 

		* ----- LaTex TABLE
		esttab statsFF using "${TABLEDIR}/SumStat_FF.tex", style(tex) replace ///
		cells("mean(fmt(%9.0f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.0f %9.0f %9.2f)) sd(fmt(%9.2f)) p50 min max") mlabels("Mean & SD & Median & Min & Max \\ %") ///
		label nonumber /// 
		order(chCohort female chWhite chBlack chHispanic chMulti chOther numElig eligCum15 moAge moCohort faCohort moCollege faCollege famSize avgInc incRatio) ///
		stats(N, fmt(%9.0f) label(Observations)) collabels(none) ///
		refcat(chCohort "Child" moAge "Family", nolabel) alignment(rrrrr)


		* ----------------------------- SUMMARY STATS COMPARISON CPS & FF
		* COLUMNS: (1) FF (2) CPS (3) CPS restricted (4) Diff (5) pval diff

		* ----- PREPARE VARIABLES
		gen FF = 1
		append using  "${CLEANDATADIR}/cps.dta"
		replace FF = 0 if FF == .

		* ----- FULL FFCWS SUM STAT
		eststo compFF1: estpost tabstat $COMPARVAR if (wave == 0 & FF == 1), ///
		columns(statistics) statistics(mean sd n) 
		estadd local FullSamp		"Yes"
		estadd local WorkingSamp	"No"

		matrix compFF1_mean = e(mean)

		* ----- WOKRING SAMPLE FFCWS SUM STAT
		eststo compFF2: estpost tabstat $COMPARVAR if (wave == 0 & FF == 1 & finSample == 1), ///
		columns(statistics) statistics(mean sd n)
		estadd local FullSamp		"No"
		estadd local WorkingSamp	"Yes"

		* ----- COMPARISON DIFFERENCE BY FINSAMPLE
		replace finSample = 0 if finSample == .
 		eststo diff : estpost ttest $COMPARVAR  if ( wave == 0 & FF == 1), by(finSample)

		* ----- FULL CPS SUM STAT
		eststo compCPS1: estpost tabstat $COMPARVAR if FF == 0, ///
		columns(statistics) statistics(mean sd n)
		estadd local FullSamp		"Yes"
		estadd local WorkingSamp	"No"

		* ----- LaTex TABLE
		esttab compFF1 compFF2 compCPS1 using "${TABLEDIR}/SumStat_both.tex", replace ///
		cells("mean(fmt(%9.0f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.0f))") ///
		order(chCohort female chWhite chBlack chHispanic famSize moCollege faCollege moCohort faCohort) ///
		label collabels(none) mlabels("FFCWS" "FFCWS" "CPS") style(tex) /// 
		refcat(chCohort "Child" famSize "Family", nolabel) nonumbers alignment(rrrr) ///
		stats(FullSamp WorkingSamp N, fmt(%9.0f) ///
		layout("\multicolumn{1}{r}{@}" "\multicolumn{1}{r}{@}") ///
		label("Full Sample" "Working Sample" "Observations")) 

	restore


	* ----------------------------- HEALTH OUTCOMES
	preserve
		* ----------------------------- PREPARE DATA
		eststo clear

		global INDEX9		healthFactor_9 			medicalFactor_9
		global INDEXVARS9 	chHealthRECODE feverRespiratoryRECODE anemiaRECODE seizuresRECODE ///
							foodDigestiveRECODE eczemaSkinRECODE diarrheaColitisRECODE ///
							headachesMigrainesRECODE earInfectionRECODE /// asthmaAttackRECODE
							emRoom docIll medication regDoc
		global OTHERS9		absent

		global INDEX15		behavFactor_15 								medicalFactor_15
		global INDEXVARS15	activityVigorous neverSmoke neverDrink bmi 	emRoom docIll medication regDoc	
		global OTHERS15		chHealthRECODE  absent limit depressedRECODE diagnosedDepression

		keep idnum wave $INDEX9 $INDEXVARS9 $OTHERS9 $INDEX15 $INDEXVARS15 $OTHERS15 finSample

		* ----------------------------- SUMMARY STATS FRAGILE FAMILIES
		* ----- PREPARE VARIABLES
		label var healthFactor_9			"Health factor ^{1}"
		label var medicalFactor_9			"Utilization factor ^{1}"
		label var chHealthRECODE			"Child health"
		label var feverRespiratoryRECODE 	"No fever or respiratory allergy ^{2}"
		label var anemiaRECODE 				"No anemia ^{2}"
		label var seizuresRECODE			"No seizures ^{2}"
		label var foodDigestiveRECODE		"No food/digestiv allergy ^{2}"
		label var eczemaSkinRECODE			"No eczema/skin allergy ^{2}"
		label var diarrheaColitisRECODE		"No freq. diarrhea/colitis ^{2}"
		label var headachesMigrainesRECODE	"No freq. headaches/migraines ^{2}"
		label var earInfectionRECODE		"No ear infection ^{2}"	
		label var emRoom					"Num times taken to emergency room ^{2}"
		label var docIll					"Saw doctor for illness ^{2,3}"
		label var medication				"Takes doctor prescribed medication"
		label var regDoc					"Saw doctor for regular check-up ^{2}"
		label var absent					"Days absent from school due to health"

		label var behavFactor_15			"Behaviors factor ^{1}"
		label var medicalFactor_15			"Utilization factor ^{1}"
		label var activityVigorous			"Days vigorous activity typical week" 
		label var neverSmoke				"Never smoked"
		label var neverDrink				"Never drink"
		label var bmi						"BMI"
		label var limit						"Limitations in usual activities \\ \:\:\:\: due to health"
		label var depressedRECODE			"Feel depressed" // self-reported
		label var diagnosedDepression		"Ever diagnosed depression/anxiety"

		foreach var of varlist $INDEXVARS9 activityVigorous neverSmoke neverDrink bmi {
			label variable `var' `"\:\:\:\: `: variable label `var''"'
		}

		* ----- SUMMARY STATISTICS HEALTH VARIABLES
		eststo healthVars: estpost tabstat $INDEX9 $INDEXVARS9 $OTHERS9 ///
		if (wave == 9 & finSample == 1), columns(statistics) statistics(mean sd median min max n) 

		eststo healthVars2: estpost tabstat $INDEX15 $INDEXVARS15 $OTHERS15 ///
		if (wave == 15 & finSample == 1), columns(statistics) statistics(mean sd median min max n) 

		* ----- LaTex TABLE
		esttab healthVars using "${TABLEDIR}/descriptiveHealth.tex", replace ///
		cells("mean(fmt(%9.3f)) sd p50 min max count(fmt(%9.0f))") ///
		order(healthFactor_9 chHealthRECODE feverRespiratoryRECODE anemiaRECODE seizuresRECODE ///
		foodDigestiveRECODE eczemaSkinRECODE diarrheaColitisRECODE headachesMigrainesRECODE ///
		earInfectionRECODE medicalFactor_9 emRoom docIll medication regDoc absent) /// asthmaAttackRECODE
		style(tex) noobs nonumbers mlabels("Mean & SD & Median & Min & Max & N \\ %") ///
		collabels(none) label

		label var chHealthRECODE			"Child health"
		label var emRoom					"Num times taken to emergency room ^{2,3}"
		label var docIll					"Saw doctor for illness ^{2}"

		esttab healthVars2 using "${TABLEDIR}/descriptiveHealth2.tex", replace ///
		cells("mean(fmt(%9.3f)) sd p50 min max count(fmt(%9.0f))") ///
		order(behavFactor_15 activityVigorous neverSmoke neverDrink bmi ///
		medicalFactor_15 emRoom docIll medication regDoc chHealthRECODE absent limit depressedRECODE diagnosedDepression) ///
		style(tex) noobs nonumbers mlabels("Mean & SD & Median & Min & Max & N \\ %") ///
		collabels(none) label

	restore

} // END DESCRIPTIVE


* ---------------------------------------------------------------------------- *
* ------------------------------- REGRESSIONS -------------------------------- *
* ---------------------------------------------------------------------------- *
if ${REGRESSIONS} == 1 {

	* ----------------------------- REGRESSIONS AGE 9 & 15
	foreach wave in 9 15 {
		foreach outcome in ${OUTCOMES`wave'} {
			* ----- OLS
			eststo `outcome'_OLS_`wave': reg `outcome' ${ELIGVAR} ${CONTROLS} i.statefip ///
				if (wave == `wave' & chGenetic == 1 & finSample == 1), cluster(statefip)
			estadd local Controls		"Yes"
			estadd local StateFE		"Yes"

			* - MEAN
			sum `outcome' if e(sample) == 1
			estadd scalar meanElig =  r(mean)

			* ----- RF
			eststo `outcome'_RF_`wave': reg `outcome' ${SIMELIGVAR} ${CONTROLS} i.statefip ///
				if (wave == `wave' & chGenetic == 1 & finSample == 1),  cluster(statefip)
			estadd local Controls		"Yes"
			estadd local StateFE		"Yes"


			* ----- FS
			ivregress 2sls `outcome' ${CONTROLS} i.statefip (${ELIGVAR} = ${SIMELIGVAR}) ///
				if (wave == `wave' & chGenetic == 1 & finSample == 1), first cluster(statefip)
			gen samp_`outcome'`wave' = e(sample)
			estat firststage
			mat fstat`outcome' = r(singleresults)

			eststo `outcome'_FS_`wave' : reg ${ELIGVAR} ${SIMELIGVAR} ${CONTROLS} i.statefip ///
				if (wave == `wave' & samp_`outcome'`wave' == 1 & chGenetic == 1 & finSample == 1), cluster(statefip)
			estadd local Controls		"Yes"
			estadd local StateFE		"Yes"

			* - FS STATISTICS
			estadd scalar fs 			= fstat`outcome'[1,4] // can add in stats(fs) in the regression


			* ----- IV-2SLS
			eststo `outcome'_IV_`wave' : ivregress 2sls `outcome' ${CONTROLS} i.statefip ///
				(${ELIGVAR} = ${SIMELIGVAR}) if (wave == `wave' & chGenetic == 1 & finSample == 1), ///
				cluster(statefip)
			estadd local Controls 		"Yes"
			estadd local StateFE 		"Yes"

			* - MEAN
			sum `outcome' if e(sample) == 1
			estadd scalar meanElig =  r(mean)

			* - FS STATISTICS
			estat firststage
			mat fstat = r(singleresults)
			estadd scalar fs 			= fstat[1,4] // can add in stats(fs) in the regression

		}
	}

	* ----------------------------- COEFPLOT AGE 9 & 15
	if ${COEFPLOT} == 1 {
		* ----- DEFINE GRAPH STYLE
		grstyle clear
		grstyle init
		grstyle color background white
		grstyle color major_grid dimgray
		grstyle linewidth major_grid thin
		*grstyle yesno draw_major_hgrid yes
		grstyle yesno grid_draw_min yes
		grstyle yesno grid_draw_max yes
		grstyle linestyle legend none

		* ----- COEFPLOT
		global COL1 	offset(0.2)  mcolor(emidblue) ciopts(recast(. rcap) color(. emidblue) color(emidblue))
		global COL2 	offset(-0.2) mcolor(navy) ciopts(recast(. rcap) color(. navy) color(navy))

		coefplot 	(chHealthRECODE_IV_9, aseq(Child health) $COL1) 	(chHealthRECODE_OLS_9, aseq(Child health) $COL2) ///
					(absent_IV_9, aseq(Absent) $COL1) 					(absent_OLS_9, aseq(Absent) $COL2) ///
					(healthFactor_9_IV_9, aseq(Health factor) $COL1) 	(healthFactor_9_OLS_9, aseq(Health factor) $COL2) ///
					(medicalFactor_9_IV_9, aseq(Utilization factor) $COL1) 	(medicalFactor_9_OLS_9, aseq(Utilization factor) $COL2), ///
						bylabel(Age 9) keep(eligCum) || ///
					(chHealthRECODE_IV_15, aseq(Child health) $COL1) 	(chHealthRECODE_OLS_15, aseq(Child health) $COL2) ///
					(absent_IV_15, aseq(Absent) $COL1) 					(absent_OLS_15, aseq(Absent) $COL2) ///
					(limit_IV_15, aseq(Limitation) $COL1) 				(limit_OLS_15, aseq(Limitation) $COL2) ///
					(medicalFactor_15_IV_15, aseq(Utilization factor) $COL1) 	(medicalFactor_15_OLS_15, aseq(Utilization factor) $COL2) ///
					(behavFactor_15_IV_15, aseq(Behaviors factor) $COL1) (behavFactor_15_OLS_15, aseq(Behaviors factor) $COL2) ///
					(depressedRECODE_IV_15, aseq(Feels dep.) $COL1) 	(depressedRECODE_OLS_15, aseq(Feels dep.) $COL2) ///
					(diagnosedDepression_IV_15, aseq(Diagnosed dep.) $COL1) (diagnosedDepression_OLS_15, aseq(Diagnosed dep.) $COL2), ///
						bylabel(Age 15) keep(eligCum) ///
		xline(0) msymbol(D) msize(small)  levels(95 90) /// mcolor(emidblue)
		ciopts(recast(. rcap)) legend(rows(2) order(1 "95% CI" 2 "90% CI" 3 "IV" 4 "95% CI" 5 "90% CI" 6 "OLS")) ///
		aseq swapnames /// norecycle byopts(compact cols(1))
		subtitle(, size(medium) margin(small) justification(left) ///
		color(white) bcolor(emidblue) bmargin(top_bottom))

		graph export "${FIGUREDIR}/coefplot.${EXTENSION}", replace
	}

	* ----------------------------- ROMANO-WOLF ADJUSTED PVALUES
	foreach wave in 9 15 {
		* ----- UTILIZATION OLS
		rwolf medicalFactor_`wave' regDoc if (wave == `wave' & chGenetic == 1 & finSample == 1), ///
		method(regress) indepvar(${ELIGVAR}) controls(${CONTROLS}  i.statefip) cluster(statefip) ///
		vce(cluster statefip) reps(150) seed(1456)

		formatTABLES `wave' OLS medicalFactor_`wave' regDoc

		* ----- UTILIZATION IV
		rwolf medicalFactor_`wave' regDoc if (wave == `wave' & chGenetic == 1 & finSample == 1), ///
		method(ivregress)  indepvar(${ELIGVAR}) iv(${SIMELIGVAR}) controls(${CONTROLS}  i.statefip) ///
		vce(cluster statefip) reps(150) seed(1456)

		formatTABLES `wave' IV medicalFactor_`wave' regDoc
	}

	* ----- OUTCOMES OLS 9
	rwolf healthFactor_9 chHealthRECODE absent if (wave == 9 & chGenetic == 1 & finSample == 1), ///
	method(regress) indepvar(${ELIGVAR}) controls(${CONTROLS}  i.statefip) cluster(statefip) ///
	vce(cluster statefip) reps(150) seed(1456) // verbose

	formatTABLES 9 OLS healthFactor_9 chHealthRECODE absent

	* ----- OUTCOMES IV 9
	rwolf healthFactor_9 chHealthRECODE absent if (wave == 9 & chGenetic == 1 & finSample == 1), ///
	method(ivregress) indepvar(${ELIGVAR}) iv(${SIMELIGVAR}) controls(${CONTROLS}  i.statefip) ///
	vce(cluster statefip) reps(150) seed(1456) // verbose

	formatTABLES 9 IV healthFactor_9 chHealthRECODE absent

	* ----- OUTCOMES OLS 15
	rwolf behavFactor_15 chHealthRECODE absent limit depressedRECODE diagnosedDepression ///
	if (wave == 15 & chGenetic == 1 & finSample == 1), ///
	method(regress) indepvar(${ELIGVAR}) controls(${CONTROLS}  i.statefip) cluster(statefip) ///
	vce(cluster statefip) reps(150) seed(1456) // verbose

	formatTABLES 15 OLS behavFactor_15 chHealthRECODE absent limit depressedRECODE diagnosedDepression

	* ----- OUTCOMES IV 15
	rwolf behavFactor_15 chHealthRECODE absent limit depressedRECODE diagnosedDepression ///
	if (wave == 15 & chGenetic == 1 & finSample == 1), ///
	method(ivregress)  indepvar(${ELIGVAR}) iv(${SIMELIGVAR}) controls(${CONTROLS}  i.statefip) ///
	vce(cluster statefip) reps(150) seed(1456) verbose

	formatTABLES 15 IV behavFactor_15 chHealthRECODE absent limit depressedRECODE diagnosedDepression


	* ----------------------------- OUTPUT Latex
	* ----- LABELS
	label var medicalFactor_15	"Utilization"

	* ----- UTILIZATION (AGE 9 & 15)
	local titles "& \multicolumn{2}{c}{Utilization factor} & \multicolumn{2}{c}{Reg. check-up}  & \multicolumn{2}{c}{Utilization factor} & \multicolumn{2}{c}{Reg. check-up}  \\ \cmidrule(lr){2-3}\cmidrule(lr){4-5}\cmidrule(lr){6-7}\cmidrule(lr){8-9}"
	local numbers "& OLS & IV & OLS & IV & OLS & IV & OLS & IV \\"

	estout medicalFactor_9_OLS_9 medicalFactor_9_IV_9 regDoc_OLS_9 regDoc_IV_9 ///  
	medicalFactor_15_OLS_15 medicalFactor_15_IV_15 regDoc_OLS_15 regDoc_IV_15 /// 
	using "${TABLEDIR}/utilization.tex", replace label collabels(none) style(tex) ///
	mlabels(none) nonumbers keep(${ELIGVAR} _cons) order(${ELIGVAR} _cons) /// 
	refcat(${ELIGVAR} "& ${medicalFactor_9_9_OLS} & ${medicalFactor_9_9_IV} & ${regDoc_9_OLS} & ${regDoc_9_IV} & ${medicalFactor_15_15_OLS} & ${medicalFactor_15_15_IV} & ${regDoc_15_OLS} & ${regDoc_15_IV}  \\ %", nolabel below) ///
	cells(b(fmt(%9.3fc)) se(par fmt(%9.3fc) star)) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE meanElig fs N, fmt(%9.0f %9.0f %9.3f %9.1f %9.0f) ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE" "Mean" "\textit{F}-Statistic" "Observations" )) ///
	mgroups("\rule{0pt}{3ex} Age 9" "Age 15", ///
	pattern(1 0 0 0 1 0 0 0) span ///
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	varlabels(_cons Constant, blist(${ELIGVAR} "\hline ")) posthead("`titles'" "`numbers'")

	* ----- OLS & IV (AGE 9)
	estout healthFactor_9_OLS_9 healthFactor_9_IV_9 chHealthRECODE_OLS_9 chHealthRECODE_IV_9 ///
	absent_OLS_9 absent_IV_9 ///
	using "${TABLEDIR}/regression9.tex", replace label collabels(none) style(tex) ///
	mlabels("\rule{0pt}{3ex} OLS" "IV" "OLS" "IV" "OLS" "IV") nonumbers ///
	keep(${ELIGVAR} 2.chRace _cons) order(${ELIGVAR} 2.chRace _cons) /// refcat(2.chRace, label(Ref. White)) ///
	refcat(2.chRace "& ${healthFactor_9_9_OLS} & ${healthFactor_9_9_IV} & ${chHealthRECODE_9_OLS} & ${chHealthRECODE_9_IV} & ${absent_9_OLS} & ${absent_9_IV}  \\ %", nolabel) ///
	cells(b(fmt(%9.3fc)) se(par fmt(%9.3fc) star)) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE meanElig fs N, fmt(%9.0f %9.0f %9.3f %9.1f %9.0f) ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE" "Mean" "\textit{F}-Statistic" "Observations")) ///
	mgroups("\rule{0pt}{3ex} Health factor" "Child health" "Absent", ///
	pattern(1 0 1 0 1 0) span ///
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	varlabels(_cons Constant, blist(${ELIGVAR} "\hline "))

	* ----- OLS & IV (AGE 15)
	estout behavFactor_15_OLS_15 behavFactor_15_IV_15 chHealthRECODE_OLS_15 chHealthRECODE_IV_15 ///
	absent_OLS_15 absent_IV_15 limit_OLS_15 limit_IV_15 depressedRECODE_OLS_15 depressedRECODE_IV_15 ///
	diagnosedDepression_OLS_15 diagnosedDepression_IV_15 ///
	using "${TABLEDIR}/regression15.tex", replace label collabels(none) style(tex) ///
	mlabels("\rule{0pt}{3ex} OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") nonumbers ///
	keep(${ELIGVAR} 2.chRace _cons) order(${ELIGVAR} 2.chRace _cons) ///
	refcat(2.chRace "& ${behavFactor_15_15_OLS} & ${behavFactor_15_15_IV} & ${chHealthRECODE_15_OLS} & ${chHealthRECODE_15_IV} &  ${absent_15_OLS} & ${absent_15_IV} & ${limit_15_OLS} & ${limit_15_IV} & ${depressedRECODE_15_OLS} & ${depressedRECODE_15_IV} & ${diagnosedDepression_15_OLS} & ${diagnosedDepression_15_IV} \\ %", nolabel) ///
	cells(b(fmt(%9.3fc)) se(par fmt(%9.3fc) star)) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE meanElig fs N, fmt(%9.0f %9.0f %9.3f %9.1f %9.0f) ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE" "Mean" "\textit{F}-Statistic" "Observations")) ///
	mgroups("\rule{0pt}{3ex} Behaviors factor" "Child health" "Absent" "Limit" "Feels depressed" "Diagnosed depressed", ///
	pattern(1 0 1 0 1 0 1 0 1 0 1 0) span ///
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	varlabels(_cons Constant, blist(${ELIGVAR} "\hline "))

	* ----- RF (AGE 9 & 15)
	estout healthFactor_9_RF_9 chHealthRECODE_RF_9 absent_RF_9 medicalFactor_9_RF_9 regDoc_RF_9 ///
	behavFactor_15_RF_15 chHealthRECODE_RF_15 absent_RF_15 limit_RF_15 depressedRECODE_RF_15 ///
	diagnosedDepression_RF_15 medicalFactor_15_RF_15 regDoc_RF_15 ///
	using "${TABLEDIR}/reducedForm.tex", replace label collabels(none) style(tex) ///
	mlabels("\shortstack[l]{Health \\ factor}" "\shortstack[l]{Child \\ health}" "Absent" "\shortstack[l]{Utilization \\ factor}" "\shortstack[l]{Regular \\ check-up}" "\shortstack[l]{Behaviors \\ factor}" "\shortstack[l]{Child \\ health}" "Absent" "\shortstack[l]{Limi- \\ tations}" "\shortstack[l]{Feels \\ depressed}" "\shortstack[l]{Diagnosed \\ depression}" "\shortstack[l]{Utilization \\ factor}" "\shortstack[l]{Regular \\ check-up}") ///
	nonumbers keep(${SIMELIGVAR} _cons) order(${SIMELIGVAR} _cons) ///
	cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE N, fmt(%9.0f %9.0f %9.0f) ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE" "Observations" )) ///
	mgroups("\rule{0pt}{3ex} Age 9" "Age 15", ///
	pattern(1 0 0 0 0 1 0 0 0 0 0 0 0) span ///
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	varlabels(_cons Constant, blist(${SIMELIGVAR} "\hline "))

	* ----- FS (AGE 9 & 15)
	local titles 	"& \multicolumn{13}{c}{Eligibility} \\ \cmidrule(lr){2-14}"
	local subtitles "& \multicolumn{5}{c}{Age 9} & \multicolumn{8}{c}{Age 15} \\ \cmidrule(lr){2-6}\cmidrule(lr){7-14}"
	local subsubtiles "& \shortstack[l]{Health \\ factor} & \shortstack[l]{Child \\ health} & Absent & \shortstack[l]{Utilization \\ factor} & \shortstack[l]{Regular \\ check-up} & \shortstack[l]{Behaviors \\ factor} & \shortstack[l]{Child \\ health} & Absent & \shortstack[l]{Limi- \\ tations} & \shortstack[l]{Feels \\ depressed} & \shortstack[l]{Diagnosed \\ depression} & \shortstack[l]{Utilization \\ factor} & \shortstack[l]{Regular \\ check-up} \\"

	estout healthFactor_9_FS_9 chHealthRECODE_FS_9 absent_FS_9 medicalFactor_9_FS_9 regDoc_FS_9 ///
	behavFactor_15_FS_15 chHealthRECODE_FS_15 absent_FS_15 limit_FS_15 depressedRECODE_FS_15 ///
	diagnosedDepression_FS_15 medicalFactor_15_FS_15 regDoc_FS_15 ///
	using "${TABLEDIR}/firstStage.tex", replace label collabels(none) style(tex) ///
	mlabels(none) ///
	nonumbers keep(${SIMELIGVAR} _cons) order(${SIMELIGVAR} _cons) ///
	cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE fs N, fmt(%9.0f %9.0f %9.1f %9.0f) ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE" "\textit{F}-Statistic" "Observations" )) ///
	varlabels(_cons Constant, blist(${SIMELIGVAR} "\hline ")) posthead("`titles'" "`subtitles'" "`subsubtiles'")


	* ----------------------------- HEALTH BEHAVIORS REGRESSIONS
	foreach outcome in behavFactor_15 activityVigorous neverSmoke neverDrink bmi bmi85 bmi95 {
		eststo `outcome'_all_IV_15 : ivregress 2sls `outcome' ${CONTROLS} i.statefip ///
			(${ELIGVAR} = ${SIMELIGVAR}) if (wave == 15 & chGenetic == 1 & finSample == 1), ///
			cluster(statefip)
		estadd local Controls 		"Yes"
		estadd local StateFE 		"Yes"

		* - FS STATISTICS
		estat firststage
		mat fstat`outcome' = r(singleresults)
		estadd scalar fs 			= fstat`outcome'[1,4] 

		* - MEAN
		sum `outcome' if e(sample) == 1
		estadd scalar meanElig =  r(mean)
	}

	label var ${ELIGVAR}		"Eligibility"
	label var ${SIMELIGVAR}		"Simulated Elig"

	* ----- Adjusted pvalues 
	rwolf behavFactor_15 activityVigorous neverSmoke neverDrink bmi bmi85 bmi95 ///
	if (wave == 15 & chGenetic == 1 & finSample == 1), ///
	method(ivregress) indepvar(${ELIGVAR}) iv(${SIMELIGVAR}) controls(${CONTROLS}  i.statefip) ///
	vce(cluster statefip) reps(150) seed(1456)

	formatTABLES 15 IV behavFactor_15 activityVigorous neverSmoke neverDrink bmi bmi85 bmi95

	* ----- LaTex
	estout behavFactor_15_all_IV_15 activityVigorous_all_IV_15 neverSmoke_all_IV_15 ///
	neverDrink_all_IV_15 bmi_all_IV_15 bmi85_all_IV_15 bmi95_all_IV_15 ///
	using "${TABLEDIR}/healthBehavs.tex", replace label collabels(none) style(tex) nonumbers ///
	keep(${ELIGVAR} 2.chRace _cons) order(${ELIGVAR} 2.chRace _cons) /// refcat(2.chRace, label(Ref. White)) ///
	refcat(2.chRace "& ${behavFactor_15_15_IV} & ${activityVigorous_15_IV} & ${neverSmoke_15_IV} & ${neverDrink_15_IV} & ${bmi_15_IV} & ${bmi85_15_IV} & ${bmi95_15_IV} \\ %", nolabel) ///
	cells(b(fmt(%9.3fc)) se(par fmt(%9.3fc) star)) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE meanElig fs N, fmt(%9.0f %9.0f %9.3f %9.1f %9.0f) ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE" "Mean" "\textit{F}-Statistic" "Observations")) ///
	mlabels("\shortstack[l]{Behaviors \\ factor}" "\shortstack[l]{Vigorous \\ activity}" "\shortstack[l]{Never \\ smoke}" "\shortstack[l]{Never \\ Drink}" "BMI" "BMI85" "BMI95") ///
	mgroups("\rule{0pt}{3ex} Age 15", pattern(1 0 0 0 0 0 0) span ///
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	varlabels(_cons Constant, blist(${ELIGVAR} "\hline "))


} // END REGRESSIONS


* ---------------------------------------------------------------------------- *
* --------------------------------- ENROLLMENT ------------------------------- *
* ---------------------------------------------------------------------------- *
if ${ENROLLMENT} == 1 {
	* ----- IV-2SLS TAKE-UP
	foreach wave in 9 15 {
		foreach outcome in ${OUTCOMES`wave'} {
			eststo `outcome'_T_`wave' : ivregress 2sls `outcome' ${CONTROLS} i.statefip ///
				(takeCum = ${SIMELIGVAR}) if (wave == `wave' & chGenetic == 1 & finSample == 1), ///
				cluster(statefip)
			estadd local Controls 		"Yes"
			estadd local StateFE 		"Yes"

			* - MEAN
			sum `outcome' if e(sample) == 1
			estadd scalar meanElig =  r(mean)

			* - FS STATISTICS
			estat firststage
			mat fstat = r(singleresults)
			estadd scalar fs 			= fstat[1,4] // can add in stats(fs) in the regression
		}
	}

	* ----- ADJUSTED P-VALUES AGE 9
	rwolf healthFactor_9 chHealthRECODE absent medicalFactor_9 regDoc if (wave == 9 & chGenetic == 1 & finSample == 1), ///
	method(ivregress) indepvar(takeCum) iv(${SIMELIGVAR}) controls(${CONTROLS}  i.statefip) ///
	vce(cluster statefip) reps(150) seed(1456) // verbose

	formatTABLES 9 E healthFactor_9 chHealthRECODE absent medicalFactor_9 regDoc

	* ----- ADJUSTED P-VALUES AGE 15
	rwolf behavFactor_15 chHealthRECODE absent limit depressedRECODE diagnosedDepression medicalFactor_15 regDoc ///
	if (wave == 15 & chGenetic == 1 & finSample == 1), ///
	method(ivregress)  indepvar(takeCum) iv(${SIMELIGVAR}) controls(${CONTROLS}  i.statefip) ///
	vce(cluster statefip) reps(150) seed(1456) // verbose

	formatTABLES 15 E behavFactor_15 chHealthRECODE absent limit depressedRECODE diagnosedDepression medicalFactor_15 regDoc

	* ----- APPENDIX ENROLLMENT (AGE 9 & 15)
	estout healthFactor_9_T_9 chHealthRECODE_T_9 absent_T_9 medicalFactor_9_T_9 regDoc_T_9 ///
	behavFactor_15_T_15 chHealthRECODE_T_15 absent_T_15 limit_T_15 depressedRECODE_T_15 ///
	diagnosedDepression_T_15 medicalFactor_15_T_15 regDoc_T_15 ///
	using "${TABLEDIR}/takeUP.tex", replace label collabels(none) style(tex) ///
	mlabels("\shortstack[l]{Health \\ factor}" "\shortstack[l]{Child \\ health}" "Absent" "\shortstack[l]{Utilization \\ factor}" "\shortstack[l]{Regular \\ check-up}" "\shortstack[l]{Behaviors \\ factor}" "\shortstack[l]{Child \\ health}" "Absent" "\shortstack[l]{Limi- \\ tations}" "\shortstack[l]{Feels \\ depressed}" "\shortstack[l]{Diagnosed \\ depression}" "\shortstack[l]{Utilization \\ factor}" "\shortstack[l]{Regular \\ check-up}") ///
	nonumbers keep(takeCum _cons) order(takeCum _cons) ///
	cells(b(fmt(%9.3fc)) se(par fmt(%9.3fc) star)) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE meanElig fs N, fmt(%9.0f %9.0f %9.3f %9.1f %9.0f) ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE" "Mean" "\textit{F}-Statistic" "Observations" )) ///
	mgroups("\rule{0pt}{3ex} Age 9" "Age 15", ///
	pattern(1 0 0 0 0 1 0 0 0 0 0 0 0) span ///
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	refcat(_cons "& ${healthFactor_9_9_E} & ${chHealthRECODE_9_E} & ${absent_9_E} & ${medicalFactor_9_9_E} & ${regDoc_9_E} & ${behavFactor_15_15_E} & ${chHealthRECODE_15_E} & ${absent_15_E} & ${limit_15_E} & ${depressedRECODE_15_E} & ${diagnosedDepression_15_E} & ${medicalFactor_15_15_E} & ${regDoc_15_E} \\ %", nolabel) ///
	varlabels(_cons Constant, blist(takeCum "\hline "))
}


* ---------------------------------------------------------------------------- *
* -------------------------------- ASSUMPTIONS ------------------------------- *
* ---------------------------------------------------------------------------- *
if ${ASSUMPTIONS} == 1 {

	* ----------------------------- BALANCE OF OBSERVABLES
	* ONLY USE PRE-DETERMINED CHARACTERISTICS AT BASELINE
	foreach variable in avgInc famSize moHealth moEduc faEduc {
		gen `variable'Base_temp = `variable' if wave == 0
		by idnum : egen `variable'Base = max(`variable'Base_temp)
		drop `variable'Base_temp
	}

	recode moHealthBase (1=5) (2=4) (3=3) (4=2) (5=1), gen(moHealthBaseRECODE)
	gen moCollegeBase = moEducBase == 4
	gen faCollegeBase = faEducBase == 4

	replace avgIncBase = avgIncBase*1000
	label var avgIncBase 			"Family income"
	label var famSizeBase			"Family size"
	label var moCollegeBase 		"Mother has college"
	label var faCollegeBase			"Father has college"
	label var moHealthBaseRECODE	"Mother health"

	global PRECHAR moCollegeBase faCollegeBase moCohort avgIncBase famSizeBase // moHealthBaseRECODE

	* ----- PREDICT INSTRUMENT WITH ALL COVARIATES
	eststo balanceElig: reg ${ELIGVAR}	${PRECHAR}	${CONTROLS} i.statefip ///
		if (wave == 9 & chGenetic == 1 & finSample == 1), cluster(statefip)
	estadd local Controls 		"Yes"
	estadd local StateFE		"Yes"
	test ${PRECHAR}
	estadd scalar Fstat = r(p) // r(p) r(F)


	eststo balanceSimElig : reg ${SIMELIGVAR} ${PRECHAR} ${CONTROLS} i.statefip ///
		if (wave == 9 & chGenetic == 1 & finSample == 1), cluster(statefip)
	estadd local Controls 		"Yes"
	estadd local StateFE		"Yes"
	test ${PRECHAR}
	estadd scalar Fstat = r(p)

	* ----- LaTex
	estout balanceElig balanceSimElig using "${TABLEDIR}/balance.tex", replace label style(tex) ///
	starlevels(* .1 ** .05 *** .01) cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) ///
	keep(${PRECHAR}) collabels(none) nonumbers ///
	mlabels("Eligibility \;\;\;\;\;\;\;\;\;\;" "Simulated \\ & & Eligibility \;\;\;\;") varlabels(, blist(moCollegeBase "\hline ")) ///
	stats(Controls StateFE Fstat N, fmt(%9.0f %9.0f %9.3f %9.0f) ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE" "\textit{p}-value \textit{F}-test" "Observations \;\;\;\;\;\;\;\;\;\;\;\;\;\;\;\;"))

} // END ASSUMPTIONS


* ---------------------------------------------------------------------------- *
* ----------------------- TABLES SIMULATED ELIGIBILITY ----------------------- *
* ---------------------------------------------------------------------------- *
if ${TABLESSIMULATED} == 1 {

	preserve
		* ----------------------------- PREPARE DATA
		eststo clear

		use "${CLEANDATADIR}/simulatedEligbility.dta", clear
		gen simulatedElig100 = simulatedElig*100
		gen Elig1998 = simulatedElig100 if year == 1998
		gen Elig2018 = simulatedElig100 if year == 2018

		statastates, fips(statefip) nogenerate
		save "${TEMPDATADIR}/simulatedElig100.dta", replace

		collapse Elig1998 Elig2018, by(state_abbrev)
		gen Diff = Elig2018 - Elig1998

		label var Elig1998 "1998"
		label var Elig2018 "2018"
		save "${TEMPDATADIR}/DiffElig.dta", replace

		* ----------------------------- MEDICAID ELIGIBILITY BY YEAR
		use "${TEMPDATADIR}/simulatedElig100.dta", clear
		eststo sim100: estpost tabstat simulatedElig100, by(year) nototal
		esttab sim100 using "${TABLEDIR}/simulatedEligbility_year.tex", replace ///
		cells(mean(fmt(a3))) nonumber noobs nodepvars label  ///
		title("Medicaid eligibility by year") nomtitles compress collabels(none) ///
		addnotes("Based on March CPS data" "from 1998-2018.") mlabels("\% eligible \\ Year & children")


		* ----------------------------- MEDICAID ELIGIBILITY BY STATE & YEAR
		use "${TEMPDATADIR}/DiffElig.dta", clear
		eststo diffElig: estpost tabstat Elig1998 Elig2018 Diff, by(state_abbrev) nototal
		esttab diffElig using "${TABLEDIR}/simulatedEligbility_state.tex", replace label ///
		nonumber cells("Elig1998(fmt(a3) label(1998)) Elig2018(fmt(a3) label(2018)) Diff(fmt(a3) label(Diff))") noobs compress longtable nomtitle

		* ----------------------------- DELETE FILES
		cd ${TEMPDATADIR}
		erase simulatedElig100.dta
		erase DiffElig.dta

	restore

} // END TABLESSIMULATED


* ---------------------------------------------------------------------------- *
* ------------------------- TABLES ADDITIONAL TABLES ------------------------- *
* ---------------------------------------------------------------------------- *
if ${ADDITIONAL} == 1 {

	preserve
		* ----------------------------- INCOME THRESHOLDS ACROSS YEARS
		use "${CLEANDATADIR}/cutscombined.dta", clear

		gen cut = .
		replace cut = medicut 	if medicut >= schipcut
		replace cut = schipcut 	if schipcut >= medicut
		replace cut = cut * 100  // in percentage of FPL

		collapse cut, by(age year)
		reshape wide cut, i(year) j(age)
		gen avg0 = cut0
		egen avg1_5 	= rowmean(cut1 cut2 cut3 cut4 cut5)
		egen avg6_18 	= rowmean(cut6 cut7 cut8 cut9 cut10 cut11 cut12 cut13 cut14 cut15 cut16 cut17 cut18)
		keep year avg*

		* Only keep every two years
		keep if (year == 1998 | year == 2000 | year == 2002 | year == 2004 | year == 2006 | year == 2008 | year == 2010 | year == 2012 | year == 2014 | year == 2016 | year == 2018)

		eststo incomeThresholds: estpost tabstat avg0 avg1_5 avg6_18, by(year) nototal

		esttab incomeThresholds using "${TABLEDIR}/incomeThresholds.tex", replace label ///
		nonumber compress nomtitle noobs ///
		cells("avg0(fmt(%12.0f) label(Ages 0-1)) avg1_5(fmt(%12.0f) label(Ages 1-5)) avg6_18(fmt(%12.0f) label(Ages 6-18))") 

	restore

} // END ADDITIONAL

* ---------------------------------------------------------------------------- *
* -------------------------- HETEROGENOUS EFFECTS ---------------------------- *
* ---------------------------------------------------------------------------- *
if ${HETEROGENOUS} == 1 {
	eststo clear

	* --------------------------------------------------
	* ----------------------------- REGRESSIONS BY RACE
	* --------------------------------------------------
	gen chRace_new = chRace
	replace chRace_new = 4 if chRace_new == 5

	* ----- REGRESSIONS: RACE AS CONTROL VARIABLE
	foreach wave in 9 15 {
		foreach outcome in ${OUTCOMES`wave'} {
			eststo rA`wave'_`outcome': ivregress 2sls `outcome'  ${CONTROLS} i.statefip ///
			(${ELIGVAR} = ${SIMELIGVAR}) if (wave == `wave' & chGenetic == 1 & finSample == 1), cluster(statefip)
		}
	}

	* ----- REGRESSIONS: SEPARATE FOR EACH RACE
	foreach wave in 9 15 {
		foreach outcome in ${OUTCOMES`wave'} {
			foreach race in 1 2 3 4 {
				di "Race : `race' and wave : `wave'"
				eststo r`wave'_`race'_`outcome': ivregress 2sls `outcome' age chFemale /// 
				moAge age#chFemale i.statefip (${ELIGVAR} = ${SIMELIGVAR}) ///
				if (wave == `wave' & chGenetic == 1 & finSample == 1 & chRace_new == `race'),  cluster(statefip)

				estat firststage
			}
		}
	}

	* ----- ADJUSTED PVALUES RACE
	local adjustedVars9 	healthFactor_9 chHealthRECODE absent medicalFactor_9

	local adjustedVars15 	behavFactor_15 chHealthRECODE absent limit depressedRECODE ///
							diagnosedDepression medicalFactor_15

	* AGE 9 IV: ALL
	rwolf `adjustedVars9' if (wave == 9 & chGenetic == 1 & finSample == 1), method(ivregress) ///
	indepvar(${ELIGVAR}) iv(${SIMELIGVAR}) controls(${CONTROLS} i.statefip) vce(cluster statefip) reps(150) seed(1456)

		formatTABLES 9 IVA `adjustedVars9'

	* AGE 15 IV: ALL
	rwolf `adjustedVars15' if (wave == 15 & chGenetic == 1 & finSample == 1), method(ivregress) ///
	indepvar(${ELIGVAR}) iv(${SIMELIGVAR}) controls(${CONTROLS}  i.statefip) vce(cluster statefip) reps(150) seed(1456)

		formatTABLES 15 IVA `adjustedVars15'

	* AGE 9 IV: FOR EACH RACE
	foreach race in 2 3 {
		rwolf `adjustedVars9' if (wave == 9 & chGenetic == 1 & finSample == 1 & chRace_new == `race'), method(ivregress) ///
		indepvar(${ELIGVAR}) iv(${SIMELIGVAR}) controls(${CONTROLS} i.statefip) vce(cluster statefip) reps(150) seed(1456)

		formatTABLES 9 IV`race' `adjustedVars9'
	}	
	
	* AGE 15 IV: FOR EACH RACE
	foreach race in 2 3 {
		rwolf `adjustedVars15' if (wave == 15 & chGenetic == 1 & finSample == 1 & chRace_new == `race'), method(ivregress) ///
		indepvar(${ELIGVAR}) iv(${SIMELIGVAR}) controls(${CONTROLS} i.statefip) vce(cluster statefip) reps(150) seed(1456)

			formatTABLES 15 IV`race' `adjustedVars15'
	}

	* ----- LATEX RACE
	foreach wave in 9 15 {
		foreach outcome in ${OUTCOMES`wave'} {

			esttab rA`wave'_`outcome' r`wave'_1_`outcome' r`wave'_2_`outcome' r`wave'_3_`outcome' r`wave'_4_`outcome', keep(${ELIGVAR}) se nostar
			matrix `outcome' = r(coefs)
			
			local rnames : rownames `outcome'
			local models : coleq `outcome'
			local models : list uniq models
			local letter  `outcome'
			local i 0
			foreach name of local rnames {
				local ++i
				local j 0
				capture matrix drop b
				capture matrix drop se
				foreach model in All Whites Blacks Hispanics Others {
					local ++j
					matrix tmp = `outcome'[`i', 2*`j'-1]
					if tmp[1,1]<. {
						matrix colnames tmp = `model'
						matrix b = nullmat(b), tmp
						matrix tmp[1,1] = `outcome'[`i', 2*`j']
						matrix se = nullmat(se), tmp
					}
				}
				ereturn post b
				quietly estadd matrix se
				estadd local Controls 		"Yes"
				estadd local StateFE 		"Yes"
				eststo `letter'_`wave'
			}
		}
	}

	local titles "Eligibility & \shortstack[l]{Health \\ factor} & \shortstack[l]{Child \\ health} & Absent & \shortstack[l]{Utilization \\ factor} & \shortstack[l]{Behaviors \\ factor} & \shortstack[l]{Child \\ health} & Absent & Limit & \shortstack[l]{Feels \\ depressed} & \shortstack[l]{Diagn. \\ depressed} & \shortstack[l]{Utilization \\ factor} & \\"

	estout healthFactor_9_9 chHealthRECODE_9 absent_9 medicalFactor_9_9 behavFactor_15_15 chHealthRECODE_15 ///
	absent_15 limit_15 depressedRECODE_15 diagnosedDepression_15 medicalFactor_15_15 ///
	using "${TABLEDIR}/heterogenousRace2.tex", replace label collabels(none) style(tex) nonumbers ///
	cells(b(fmt(%9.3fc)) se(par fmt(%9.3fc) star)) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE, ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE")) ///
	refcat(All "& ${healthFactor_9_9_IVA} & ${chHealthRECODE_9_IVA} & ${absent_9_IVA} & ${medicalFactor_9_9_IVA} & ${behavFactor_15_15_IVA} & ${chHealthRECODE_15_IVA} & ${absent_15_IVA} & ${limit_15_IVA} & ${depressedRECODE_15_IVA} & ${diagnosedDepression_15_IVA} & ${medicalFactor_15_15_IVA} \\ %" Blacks "& ${healthFactor_9_9_IV2} & ${chHealthRECODE_9_IV2} & ${absent_9_IV2} & ${medicalFactor_9_9_IV2} & ${behavFactor_15_15_IV2} & ${chHealthRECODE_15_IV2} & ${absent_15_IV2} & ${limit_15_IV2} & ${depressedRECODE_15_IV2} & ${diagnosedDepression_15_IV2} & ${medicalFactor_15_15_IV2} \\ %" Hispanics "& ${healthFactor_9_9_IV3} & ${chHealthRECODE_9_IV3} & ${absent_9_IV3} & ${medicalFactor_9_9_IV3} & ${behavFactor_15_15_IV3} & ${chHealthRECODE_15_IV3} & ${absent_15_IV3} & ${limit_15_IV3} & ${depressedRECODE_15_IV3} & ${diagnosedDepression_15_IV3} & ${medicalFactor_15_15_IV3} \\ %", nolabel below) ///
	mlabels(none) mgroups("\rule{0pt}{3ex} Age 9" "Age 15", ///
	pattern(1 0 0 0 1 0 0 0) span ///
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	varlabels(_cons Constant, blist(All "\hline ")) posthead("`titles'")

	// Whites "& ${healthFactor_9_9_IV1} & ${chHealthRECODE_9_IV1} & ${absent_9_IV1} & ${medicalFactor_9_9_IV1} & ${behavFactor_15_15_IV1} & ${chHealthRECODE_15_IV1} & ${absent_15_IV1} & ${limit_15_IV1} & ${depressedRECODE_15_IV1} & ${diagnosedDepression_15_IV1} & ${medicalFactor_15_15_IV1} \\ %"
	// Others "& ${healthFactor_9_9_IV4} & ${chHealthRECODE_9_IV4} & ${absent_9_IV4} & ${medicalFactor_9_9_IV4} & ${behavFactor_15_15_IV4} & ${chHealthRECODE_15_IV4} & ${absent_15_IV4} & ${limit_15_IV4} & ${depressedRECODE_15_IV4} & ${diagnosedDepression_15_IV4} & ${medicalFactor_15_15_IV4} \\ %"
	// foreach wave in 9 15 {
	// 	foreach outcome in `adjustedVars9' `adjustedVars15' {
	// 		global `outcome'_`wave'_IV1 = "[ \; \, \, \;]"
	// 		global `outcome'_`wave'_IV4 = "[ \; \, \, \;]"
	// 	}
	// }


	* -----------------------------------------------------
	* ----------------------------- REGRESSIONS BY GENDER
	* -----------------------------------------------------
	* ----- REGRESSION WITH GENDER INTERACTION
	qui sum ${ELIGVAR}
	gen eligxFEM 	=	(${ELIGVAR}-r(mean))*chFemale

	qui sum ${SIMELIGVAR}
	gen simEligxFEM = 	(${SIMELIGVAR}-r(mean))*chFemale
	label var eligxFEM "Elig $\times$ Female"

	foreach wave in 9 15 {
		foreach outcome in ${OUTCOMES`wave'} {
			eststo gen_`wave'_`outcome': ivregress 2sls `outcome'  ${CONTROLS} i.statefip ///
			(${ELIGVAR} eligxFEM = ${SIMELIGVAR} simEligxFEM) if (wave == `wave' & chGenetic == 1 & finSample == 1), cluster(statefip)
			estadd local Controls 		"Yes"
			estadd local StateFE 		"Yes"

			estat firststage, all
			mat fstat`outcome' 	= r(singleresults)
			estadd scalar fs1 	= fstat`outcome'[1,4] // F-stat eligCum
			estadd scalar fs2 	= fstat`outcome'[2,4] // F-stat eligxFEM

			* - MEAN
			sum `outcome' if e(sample) == 1
			estadd scalar meanElig =  r(mean)
		}
	}

	* ----- ADJUSTED PVALUES WITH GENDER INTERACTION
	local adjustedVars9 	healthFactor_9 chHealthRECODE absent medicalFactor_9

	local adjustedVars15 	behavFactor_15 chHealthRECODE absent limit depressedRECODE ///
							diagnosedDepression medicalFactor_15

	* AGE 9 IV: ${ELIGVAR}
	rwolf `adjustedVars9' if (wave == 9 & chGenetic == 1 & finSample == 1), ///
	method(ivregress) indepvar(${ELIGVAR}) otherendog(eligxFEM) iv(${SIMELIGVAR} simEligxFEM) ///
	controls(${CONTROLS} i.statefip) vce(cluster statefip) reps(150) seed(234) // verbose

		formatTABLES 9 ExF1 `adjustedVars9'

	* AGE 9 IV: eligxFEM
	rwolf `adjustedVars9' if (wave == 9 & chGenetic == 1 & finSample == 1), ///
	method(ivregress) indepvar(eligxFEM) otherendog(${ELIGVAR}) iv(${SIMELIGVAR} simEligxFEM) ///
	controls(${CONTROLS} i.statefip) vce(cluster statefip) reps(150) seed(234) // verbose

		formatTABLES 9 ExF2 `adjustedVars9'

	* AGE 15 IV: ${ELIGVAR}
	rwolf `adjustedVars15' if (wave == 15 & chGenetic == 1 & finSample == 1), ///
	method(ivregress) indepvar(${ELIGVAR}) otherendog(eligxFEM) iv(${SIMELIGVAR} simEligxFEM) ///
	controls(${CONTROLS} i.statefip) vce(cluster statefip) reps(150) seed(234) // verbose

		formatTABLES 15 ExF1 `adjustedVars15'

	* AGE 15 IV: eligxFEM
	rwolf `adjustedVars15' if (wave == 15 & chGenetic == 1 & finSample == 1), ///
	method(ivregress) indepvar(eligxFEM) otherendog(${ELIGVAR}) iv(${SIMELIGVAR} simEligxFEM) ///
	controls(${CONTROLS} i.statefip) vce(cluster statefip) reps(150) seed(234) // verbose

		formatTABLES 15 ExF2 `adjustedVars15'

	* ----- LATEX WITH GENDER INTERACTION BOTH AGES
	local titles "& \shortstack[l]{Health \\ factor} & \shortstack[l]{Child \\ health} & Absent & \shortstack[l]{Utilization \\ factor} & \shortstack[l]{Behaviors \\ factor} & \shortstack[l]{Child \\ health} & Absent & Limit & \shortstack[l]{Feels \\ depressed} & \shortstack[l]{Diagn. \\ depressed} & \shortstack[l]{Utilization \\ factor} \\"

	estout gen_9_healthFactor_9 gen_9_chHealthRECODE gen_9_absent gen_9_medicalFactor_9 gen_15_behavFactor_15 ///
	gen_15_chHealthRECODE gen_15_absent gen_15_limit gen_15_depressedRECODE gen_15_diagnosedDepression gen_15_medicalFactor_15 ///
	using "${TABLEDIR}/heterogenousGender.tex", replace label collabels(none) style(tex) nonumbers ///
	keep(${ELIGVAR} eligxFEM chFemale _cons) order(${ELIGVAR} eligxFEM chFemale _cons) /// 
	cells(b(fmt(%9.3fc)) se(par fmt(%9.3fc) star)) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE meanElig fs1 fs2 N, fmt(%9.0f %9.0f %9.3f %9.1f %9.1f %9.0f) ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE" "Mean" "\textit{F}-Statistic 1" "\textit{F}-Statistic 2" "Observations")) ///
	mlabels(none) mgroups("\rule{0pt}{3ex} Age 9" "Age 15",	pattern(1 0 0 0 1 0 0 0 0 0 0) span ///
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	refcat(${ELIGVAR} "& ${healthFactor_9_9_ExF1} & ${chHealthRECODE_9_ExF1} & ${absent_9_ExF1} & ${medicalFactor_9_9_ExF1} & ${behavFactor_15_15_ExF1} & ${chHealthRECODE_15_ExF1} & ${absent_15_ExF1} & ${limit_15_ExF1} & ${depressedRECODE_15_ExF1} & ${diagnosedDepression_15_ExF1} & ${medicalFactor_15_15_ExF1} \\ %" eligxFEM "& ${healthFactor_9_9_ExF2} & ${chHealthRECODE_9_ExF2} & ${absent_9_ExF2} & ${medicalFactor_9_9_ExF2} & ${behavFactor_15_15_ExF2} & ${chHealthRECODE_15_ExF2} & ${absent_15_ExF2} & ${limit_15_ExF2} & ${depressedRECODE_15_ExF2} & ${diagnosedDepression_15_ExF2} & ${medicalFactor_15_15_ExF2} \\ %", nolabel below) ///
	varlabels(_cons Constant, blist(${ELIGVAR} "\hline ")) posthead("`titles'")

}

* ---------------------------------------------------------------------------- *
* ----------------------------- GENE-ENVIRONMENT ----------------------------- *
* ---------------------------------------------------------------------------- *
if ${GXE} == 1 {

	* -----------------------------------------------------
	* ----------------------------- HEALTH BEHAVIORS
	* -----------------------------------------------------
	* ----- REGRESSIONS GxE HEALTH BEHAVIORS
	capture drop eligxDRD2rs18 simEligxDRD2rs18
	gen eligxDRD2rs18 		= ${ELIGVAR}*DRD2rs18 		// WITHOUT DEMEANING!
	gen simEligxDRD2rs18 	= ${SIMELIGVAR}*DRD2rs18	// WITHOUT DEMEANING!
	label var eligxDRD2rs18 "Elig $\times$ Risky DRD2"

	foreach outcome in behavFactor_15 activityVigorous neverSmoke neverDrink bmi {
		eststo GxE_`outcome'_DRD2 : ivregress 2sls `outcome' DRD2rs18 ${CONTROLS} ///
		i.statefip (${ELIGVAR} eligxDRD2rs18 = ${SIMELIGVAR} simEligxDRD2rs18)  ///
		if (wave == 15 & chGenetic == 1 & finSample == 1) ,  cluster(statefip)
		estadd local Controls 		"Yes"
		estadd local StateFE 		"Yes"

		estat firststage, all
		mat fstat`outcome' 	= r(singleresults)
		estadd scalar fs1 	= fstat`outcome'[1,4] // F-stat eligCum
		estadd scalar fs2 	= fstat`outcome'[2,4] // F-stat eligxGene

		sum `outcome' if e(sample) == 1
		estadd scalar meanElig =  r(mean)
	}

	* ----- ADJUSTED PVALUES GXE HEALTH BEHAVIORS
	local adjustedVars15 	behavFactor_15 activityVigorous neverSmoke neverDrink bmi

	* AGE 15 IV: ${ELIGVAR} 
	rwolf `adjustedVars15' if (wave == 15 & chGenetic == 1 & finSample == 1), ///
	method(ivregress) indepvar(${ELIGVAR}) otherendog(eligxDRD2rs18) iv(${SIMELIGVAR} simEligxDRD2rs18) ///
	controls(DRD2rs18 ${CONTROLS} i.statefip) vce(cluster statefip) reps(150) seed(234) // verbose

		formatTABLES 15 GxE1 `adjustedVars15'

	* AGE 15 IV: eligxDRD2rs18
	rwolf `adjustedVars15' if (wave == 15 & chGenetic == 1 & finSample == 1), ///
	method(ivregress) indepvar(eligxDRD2rs18) otherendog(${ELIGVAR}) iv(${SIMELIGVAR} simEligxDRD2rs18) ///
	controls(DRD2rs18 ${CONTROLS}  i.statefip) vce(cluster statefip) reps(150) seed(234) // verbose

		formatTABLES 15 GxE2 `adjustedVars15'

	* ----- LATEX GxE HEALTH BEHAVIORS WITHOUT DEMEANING!
	estout GxE_behavFactor_15_DRD2 GxE_activityVigorous_DRD2 GxE_neverSmoke_DRD2 ///
	GxE_neverDrink_DRD2 GxE_bmi_DRD2 ///
	using "${TABLEDIR}/GxE_BEHAVS_NORMAL.tex", replace label collabels(none) style(tex) nonumbers ///
	keep(${ELIGVAR} eligxDRD2rs18 DRD2rs18 _cons) order(${ELIGVAR} eligxDRD2rs18 DRD2rs18 _cons) ///
	cells(b(fmt(%9.3fc)) se(par fmt(%9.3fc) star)) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE meanElig fs1 fs2 N, fmt(%9.0f %9.0f %9.3f %9.1f %9.1f %9.0f) ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE" "Mean" "\textit{F}-Statistic 1" "\textit{F}-Statistic 2" "Observations")) ///
	mlabels("\shortstack[l]{Behaviors \\ factor}" "\shortstack[l]{Vigorous \\ activity}" "\shortstack[l]{Never \\ smoke}" "\shortstack[l]{Never \\ Drink}" "BMI") ///
	refcat(${ELIGVAR} "& ${behavFactor_15_15_GxE1} & ${activityVigorous_15_GxE1} & ${neverSmoke_15_GxE1} & ${neverDrink_15_GxE1} & ${bmi_15_GxE1} \\ %" eligxDRD2rs18 "& ${behavFactor_15_15_GxE2} & ${activityVigorous_15_GxE2} & ${neverSmoke_15_GxE2} & ${neverDrink_15_GxE2} & ${bmi_15_GxE2} \\ %", nolabel below) ///
	mgroups("\rule{0pt}{3ex} Age 15", pattern(1 0 0 0 0) span ///
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	varlabels(_cons Constant, blist(${ELIGVAR} "\hline "))


	* -----------------------------------------------------
	* ----------------------------- BMI
	* -----------------------------------------------------
	* ----- REGRESSIONS GXE BMI
	foreach genes in FTO TMEM18rs65 MC4Rrs17 riskIndexBMI { 

		qui sum ${ELIGVAR} if (wave == 15 & chGenetic == 1 & finSample == 1)
		gen eligx`genes' 	= (${ELIGVAR}-r(mean))*`genes'

		qui sum ${SIMELIGVAR} if (wave == 15 & chGenetic == 1 & finSample == 1)
		gen simEligx`genes' = (${SIMELIGVAR}-r(mean))*`genes'

		* G E 
		eststo GE_bmi_`genes' : ivregress 2sls bmi `genes' age chFemale moAge age#chFemale i.chRace ///
		i.statefip (${ELIGVAR} = ${SIMELIGVAR})  ///
		if (wave == 15 & chGenetic == 1 & finSample == 1),  cluster(statefip)
		estadd local Controls 		"Yes"
		estadd local StateFE 		"Yes"

		sum bmi if e(sample) == 1
		estadd scalar meanElig =  r(mean)

		* GxE 
		eststo GxE_bmi_`genes' : ivregress 2sls bmi `genes' age chFemale moAge age#chFemale i.chRace ///  
		i.statefip (${ELIGVAR} eligx`genes' = ${SIMELIGVAR} simEligx`genes')  ///
		if (wave == 15 & chGenetic == 1 & finSample == 1),  cluster(statefip)
		estadd local Controls 		"Yes"
		estadd local StateFE 		"Yes"

		estat firststage, all
		mat fstat`genes' 	= r(singleresults)
		estadd scalar fs1 	= fstat`genes'[1,4] // F-stat eligCum
		estadd scalar fs2 	= fstat`genes'[2,4] // F-stat eligxGene

		sum bmi if e(sample) == 1
		estadd scalar meanElig =  r(mean)

	}

	* ----- LATEX GXE BMI
	label var eligxFTO 				"Elig $\times$ Risky FTO"
	label var eligxTMEM18rs65 		"Elig $\times$ Risky TMEM18"
	label var eligxMC4Rrs17			"Elig $\times$ Risky MC4R" 
	label var eligxriskIndexBMI		"Elig $\times$ Risk Index"

	estout GE_bmi_FTO GxE_bmi_FTO GE_bmi_TMEM18rs65 GxE_bmi_TMEM18rs65 GE_bmi_MC4Rrs17 GxE_bmi_MC4Rrs17 ///
	GE_bmi_riskIndexBMI GxE_bmi_riskIndexBMI ///
	using "${TABLEDIR}/GxE_BMI.tex", replace label collabels(none) style(tex) ///
	keep(${ELIGVAR} eligxFTO FTO eligxTMEM18rs65 TMEM18rs65 eligxMC4Rrs17 MC4Rrs17 eligxriskIndexBMI riskIndexBMI _cons) ///
	order(${ELIGVAR} eligxFTO FTO eligxTMEM18rs65 TMEM18rs65 eligxMC4Rrs17 MC4Rrs17 eligxriskIndexBMI riskIndexBMI _cons) /// 
	cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE meanElig fs1 fs2 N, fmt(%9.0f %9.0f %9.2f %9.1f %9.1f %9.0f) ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE" "Mean" "\textit{F}-Statistic 1" "\textit{F}-Statistic 2" "Observations")) ///
	mlabels(none) numbers mgroups("\rule{0pt}{3ex} BMI", pattern(1 0 0 0 0 0 0 0) span ///
	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	varlabels(_cons Constant, blist(${ELIGVAR} "\hline "))

}





capture log close



* ---------------------------------------------------------------------------- *
* -------------------------------- NOTE USED --------------------------------- *
* ---------------------------------------------------------------------------- *

	/* ---- SEPARATE REGRESSIONS GXE HEALTH BEHAVIORS
	foreach outcome in behavFactor_15 activityVigorous neverSmoke neverDrink bmi {
		eststo `outcome'_DRD2H: ivregress 2sls `outcome' ${CONTROLS} ///
		i.statefip (${ELIGVAR} = ${SIMELIGVAR})  ///
		if (wave == 15 & chGenetic == 1 & finSample == 1 & DRD2rs18 == 1) ,  cluster(statefip)

		eststo `outcome'_DRD2L: ivregress 2sls `outcome' ${CONTROLS} ///
		i.statefip (${ELIGVAR} = ${SIMELIGVAR})  ///
		if (wave == 15 & chGenetic == 1 & finSample == 1 & DRD2rs18 == 0) ,  cluster(statefip)
	}


	* ----- LATEX 
	foreach outcome in behavFactor_15 activityVigorous neverSmoke neverDrink bmi {

		esttab `outcome'_DRD2H  `outcome'_DRD2L, keep(${ELIGVAR}) se nostar
		matrix `outcome' = r(coefs)

		
		local rnames : rownames `outcome'
		local models : coleq `outcome'
		local models : list uniq models
		*local letter  `outcome'
		local i 0
		foreach name of local rnames {
			local ++i
			local j 0
			capture matrix drop b
			capture matrix drop se
			foreach model in "High-risk DRD2" "Low-risk DRD2" {
				local ++j
				matrix tmp = `outcome'[`i', 2*`j'-1]
				if tmp[1,1]<. {
					matrix colnames tmp = "`model'"
					matrix b = nullmat(b), tmp
					matrix tmp[1,1] = `outcome'[`i', 2*`j']
					matrix se = nullmat(se), tmp
				}
			}
			ereturn post b
			quietly estadd matrix se
			estadd local Controls 		"Yes"
			estadd local StateFE 		"Yes"
			eststo `outcome'_HL
		}
	}

	local titles "Eligibility & \shortstack[l]{Behaviors \\ factor} & \shortstack[l]{Vigorous \\ activity} & \shortstack[l]{Never \\ smoke} & \shortstack[l]{Never \\ Drink} & BMI & \\"

	estout behavFactor_15_HL activityVigorous_HL neverSmoke_HL neverDrink_HL bmi_HL ///
	using "${TABLEDIR}/GxE_BEHAVS_SEP.tex", replace label collabels(none) style(tex) nonumbers ///
	cells(b(fmt(%9.3fc)) se(par fmt(%9.3fc) star)) starlevels(* .1 ** .05 *** .01) ///
	stats(Controls StateFE, ///
	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
	label("\hline \rule{0pt}{3ex}Controls" "State FE")) ///
	varlabels(_cons Constant, blist("High-risk DRD2" "\hline ")) posthead("`titles'") mlabels(none) */



	/* ----- CUMULATED HEALTH
	foreach outcome in chHealthRECODE {
		foreach wave in 1 3 5 9 15 {
			di "****** "
			ivregress 2sls `outcome' ${CONTROLS} i.statefip (${ELIGVAR} = ${SIMELIGVAR}) ///
				if (wave == `wave' & chGenetic == 1 & finSample == 1),  cluster(statefip)

			est store `outcome'_IV_SEP2_`wave'
			estadd local Controls 		"Yes"
			estadd local StateFE 		"Yes"

			estat firststage
			mat fstat = r(singleresults)
			estadd scalar fs = fstat[1,4] // can add in stats(fs) in the regression
		}
	}	 */


	* --------------------------------------------------------------------------------

	* ----- ELIGIBILITY AT EACH AGE
	// foreach elig in elig simulatedElig {
	// 	foreach wave in 0 1 3 5 9 15 {
	// 		gen `elig'`wave'_temp = `elig' if wave == `wave'
	// 		bysort idnum: egen `elig'`wave' = max(`elig'`wave'_temp)
	// 	}
	// }


* ---------------------------------------------------------------------------- *
* -------------------------------- ROBUSTNESS -------------------------------- *
* ---------------------------------------------------------------------------- *
// if ${ROBUSTNESS} == 1 {
// 	* ----------------------------- IV WITH AND WITHOUT CONTROLS
// 	* ----- OUTCOMES AGE 9
// 	foreach outcome in $OUTCOMES9 {
// 		* ----- IV-2SLS
// 		* WITH CONTROLS + FE
// 		eststo `outcome'_IV_9 : ivregress 2sls `outcome' ${CONTROLS} i.statefip (${ELIGVAR} = ${SIMELIGVAR}) ///
// 			if (wave == 9 & chGenetic == 1 & finSample == 1),  cluster(statefip)
// 		estadd local Controls 		"Yes"
// 		estadd local StateFE 		"Yes"

// 		* WITHOUT CONTROLS
// 		eststo `outcome'_IV_9_NOCO : ivregress 2sls `outcome' ${CONTROLS} (${ELIGVAR} = ${SIMELIGVAR}) ///
// 			if (wave == 9 & chGenetic == 1 & finSample == 1),  cluster(statefip)
// 		estadd local Controls 		"Yes"
// 		estadd local StateFE 		"No"

// 		* WITHOUT CONTROLS + FE
// 		eststo `outcome'_IV_9_NOCOFE : ivregress 2sls `outcome' (${ELIGVAR} = ${SIMELIGVAR}) ///
// 			if (wave == 9 & chGenetic == 1 & finSample == 1),  cluster(statefip)
// 		estadd local Controls 		"No"
// 		estadd local StateFE 		"No"
// 	}


// 	* ----- IV 9
// 	estout  healthFactor_9_IV_9_NOCOFE	healthFactor_9_IV_9_NOCO  	healthFactor_9_IV_9 ///
// 			chHealthRECODE_IV_9_NOCOFE 	chHealthRECODE_IV_9_NOCO 		chHealthRECODE_IV_9 ///
// 			absent_IV_9_NOCOFE  		absent_IV_9_NOCO 			absent_IV_9 ///
// 	using "${TABLEDIR}/robustnessControls.tex", replace label collabels(none) style(tex) ///
// 	mlabels(none) numbers keep(${ELIGVAR} _cons) order(${ELIGVAR} _cons) /// 
// 	cells(b(fmt(%9.3fc) star) se(par fmt(%9.3fc))) starlevels(* .1 ** .05 *** .01) ///
// 	stats(Controls StateFE N, fmt(%9.0f %9.0f %9.0f) ///
// 	layout("\multicolumn{1}{l}{@}" "\multicolumn{1}{l}{@}") ///
// 	label("\hline \rule{0pt}{3ex}Controls" "State FE" "Observations")) ///
// 	mgroups("\rule{0pt}{3ex} Health factor" "Child health" "Absent", ///
// 	pattern(1 0 0 1 0 0 1 0 0) span ///
// 	prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
// 	varlabels(_cons Constant, blist(${ELIGVAR} "\hline "))

// } // END ROBUSTNESS

	
