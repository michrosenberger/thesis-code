************************************
* Extract information
************************************
local DIR "00_Baseline/" "01_One-Year Core/" "02_Three-Year Core/" "03_Five-Year Core/"
local DATASET ffmombspv3 ffdadbspv3 ffmom1ypv2 ffdad1ypv2 ffmom3ypv2 ffdad3ypv2 ffmom5ypv1 ffdad5ypv1

local i = 1
local s = 1
local n : word count `DIR'
local m : word count `DATASET'

while `i' <= `n' {
	local dire : word `i' of `DIR'
	local dataset : word `s' of `DATASET'
	di "DIR is `dire'"
	di "Dataset is `dataset'"
	local i = `i' + 1
	local s = `s' + 2
}	

foreach dire in $DIR {
	foreach dataset in $DATASET {
		use "${RAWDATADIR}/`dire'`dataset'.dta", clear
		cd "${RAWDATADIR}"
		descsave, list(order name varlab) saving("${INFODIR}/`dataset'.dta", replace)
		use "${INFODIR}/`dataset'.dta", clear
		keep order name varlab
		outsheet using "${INFODIR}/`dataset'.txt", replace
		//erase *.dta
}
}


04_Nine-Year Core/ff_y9_pub1 ///
				05_Fifteen-Year Core/FF_Y15_pub