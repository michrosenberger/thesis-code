* Project:      MA Thesis
* Content:      Extract information FF
* Data:         Fragile families
* Author:       Michelle Rosenberger
* Date:         November 5, 2018

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

if "`c(username)'" == "michellerosenberger"  {
	global MYPATH		"~/Development/MA"
}

global RAWDATADIR	    "${MYPATH}/data/raw/FragileFamilies"
global CLEANDATADIR  	"${MYPATH}/data/clean"
global TEMPDATADIR  	"${MYPATH}/data/temp"
global INFODIR			"${MYPATH}/data/references/FF_references/codebook"
cd ${INFODIR}

* log using ${CODEDIR}/varsTeen.log, replace 

************************************
* IMPORT DATA
************************************
use "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta", clear

* IDENTIFICATION
codebook idnum

* RACE
tab ck6ethrace

* AGE
tab ck6yagey if ck6yagey > 0	// Age in years (at time of interview)
tab ck6yagem if ck6yagem > 0	// Age in months (at time of interview)









capture log close



