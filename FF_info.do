




capture log close
clear all
macro drop _all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

if "`c(username)'" == "michellerosenberger"  {
	global MYPATH		"~/Development/MA"
}

global RAWDATADIR	    "${MYPATH}/data/raw/FragileFamilies"
global CLEANDATADIR  	"${MYPATH}/data/clean"		// general
global TEMPDATADIR  	"${MYPATH}/data/temp"		// general
global INFODIR			"${MYPATH}/data/references/FF_references/codebook"
cd ${INFODIR}

* DEFINE PROGRAM

************************************
* Extract information
************************************
foreach dire in "00_Baseline" {
	foreach dataset in ffmombspv3 ffdadbspv3 {
		use "${RAWDATADIR}/`dire'/`dataset'.dta", clear
		cd "${RAWDATADIR}"
		descsave, list(order name varlab) saving("${INFODIR}/`dataset'.dta", replace)
		use "${INFODIR}/`dataset'.dta", clear
		keep order name varlab
		outsheet using "${INFODIR}/`dataset'.txt", replace
		erase "${INFODIR}/`dataset'.dta"
	}
}

foreach dire in "01_One-Year Core" {
	foreach dataset in ffmom1ypv2 ffdad1ypv2 {
		use "${RAWDATADIR}/`dire'/`dataset'.dta", clear
		cd "${RAWDATADIR}"
		descsave, list(order name varlab) saving("${INFODIR}/`dataset'.dta", replace)
		use "${INFODIR}/`dataset'.dta", clear
		keep order name varlab
		outsheet using "${INFODIR}/`dataset'.txt", replace
		erase "${INFODIR}/`dataset'.dta"
	}
}

foreach dire in "02_Three-Year Core" {
	foreach dataset in ffmom3ypv2 ffdad3ypv2 {
		use "${RAWDATADIR}/`dire'/`dataset'.dta", clear
		cd "${RAWDATADIR}"
		descsave, list(order name varlab) saving("${INFODIR}/`dataset'.dta", replace)
		use "${INFODIR}/`dataset'.dta", clear
		keep order name varlab
		outsheet using "${INFODIR}/`dataset'.txt", replace
		erase "${INFODIR}/`dataset'.dta"
	}
}

foreach dire in "03_Five-Year Core" {
	foreach dataset in ffmom5ypv1 ffdad5ypv1 {
		use "${RAWDATADIR}/`dire'/`dataset'.dta", clear
		cd "${RAWDATADIR}"
		descsave, list(order name varlab) saving("${INFODIR}/`dataset'.dta", replace)
		use "${INFODIR}/`dataset'.dta", clear
		keep order name varlab
		outsheet using "${INFODIR}/`dataset'.txt", replace
		erase "${INFODIR}/`dataset'.dta"
	}
}

use "${RAWDATADIR}/04_Nine-Year Core/ff_y9_pub1.dta", clear
cd "${RAWDATADIR}"
descsave, list(order name varlab) saving("${INFODIR}/ff_y9_pub1.dta", replace)
use "${INFODIR}/ff_y9_pub1.dta", clear
keep order name varlab
outsheet using "${INFODIR}/ff_y9_pub1.txt", replace
erase "${INFODIR}/ff_y9_pub1.dta"


use "${RAWDATADIR}/05_Fifteen-Year Core/FF_Y15_pub.dta", clear
cd "${RAWDATADIR}"
descsave, list(order name varlab) saving("${INFODIR}/FF_Y15_pub.dta", replace)
use "${INFODIR}/FF_Y15_pub.dta", clear
keep order name varlab
outsheet using "${INFODIR}/FF_Y15_pub.txt", replace
erase "${INFODIR}/FF_Y15_pub.dta"

