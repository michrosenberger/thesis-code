* Project: 	MA Thesis
* Data: 	Fragile Families - 06_Fifteen-Year (teen)
* Content: 	Analyze data FF
* Author: 	Michelle Rosenberger
* Date: 	Oct 1, 2018

capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000



************************************
* WORING DIRECTORIES AND GLOABL VARS
************************************
global USERPATH     	"/Users/michellerosenberger/Development/MA"	// Own directory data
global RAWDATADIR		"${USERPATH}/data/raw/FragileFamilies"
global CLEANDATADIR		"${USERPATH}/data/clean"    // general
global TEMPDATADIR      "${MYPATH}/data/temp"       // general
global CODEDIR			"${USERPATH}/code"
global INFODIR

log using ${CODEDIR}/varsTeen.log, replace 

************************************
* IMPORT DATA
************************************
use "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta", clear


************************************
* IDENTIFICATION
************************************
codebook idnum // Encrypted family ID

************************************
* RACE
************************************
tab ck6ethrace


************************************
* AGE
************************************
tab ck6yagey if ck6yagey > 0	// Age in years (at time of interview)
tab ck6yagem if ck6yagem > 0	// Age in months (at time of interview)

tab cp6intmon 		// Constructed - PCG interview month
tab cp6intyr		// Constructed - PCG interview year


capture log close



