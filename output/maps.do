* -----------------------------------
* Project:	MA Thesis
* Content:      
* Author:	Michelle Rosenberger
* Date: 	Nov 1, 2018
* -----------------------------------


* ---------------------------------------------------------------------------- *
* --------------------------------- PREAMBLE --------------------------------- *
* ---------------------------------------------------------------------------- *
capture log close
clear all
set more off
set emptycells drop
set matsize 10000
set maxvar 10000

* ----------------------------- SET WORKING DIRECTORIES
if "`c(username)'" == "michellerosenberger"  {
	global CODEDIR		"~/Development/MA/code"
	*global CODEDIR		"/Volumes/g_econ_department$/econ/biroli/geighei/code/medicaidGxE/thesis-code"
}

do "${CODEDIR}/setDirectories.do"

* ----------------------------- SET SWITCHES
global PROGRAMS		= 0			// install the packages
global USMAP		= 0			// download map

* ----------------------------- INSTALL PACKAGES
if ${PROGRAMS} == 1 {
	ssc install spmap
	ssc install shp2dta
	ssc install mif2dta
	ssc install geo2xy
	ssc install maptile
	ssc install grstyle
}

* ---------------------------------------------------------------------------- *
* ------------------------- MAPS SIMULATED ELIGIBILITY ----------------------- *
* ---------------------------------------------------------------------------- *

* ----- DOWNLOAD US MAP
* Download US map
if ${USMAP} == 1 {
	* WILL INSTALL IN THE PERSONAL/maptile_geographies FOLDER
	maptile_install using "http://files.michaelstepner.com/geo_state.zip" , replace
}

* ----------------------------- % OF ELIGIBLE CHILDREN PER STATE
* ----- PREPARE SIMLUATED ELIGIBILITY DATA
foreach year in 1998 2018 {
	use "${CLEANDATADIR}/simulatedEligbility.dta", clear
	keep if year == `year'
	collapse simulatedElig, by(statefip)			// mean (highest?)
	replace simulatedElig = simulatedElig * 100		// in percent
	rename simulatedElig simulatedElig`year'
	rename statefip statefips
	save "${TEMPDATADIR}/Elig`year'.dta", replace
}

merge 1:1 statefips using "${TEMPDATADIR}/Elig1998.dta", nogen
save  "${TEMPDATADIR}/Elig1998_2018.dta", replace

* ----- MAP
do "${CODEDIR}/output/maps_labels.do"	// center state names

merge 1:1 statefips using "${TEMPDATADIR}/Elig1998_2018.dta", nogen // simulated Elig. data

* ----- GENERATE BREAK DATA
// clmethod(custom) does not work
gen break2 = .
replace break2 = 25 if _ID == 26
replace break2 = 30 if _ID == 27
replace break2 = 40 if _ID == 1
replace break2 = 50 if _ID == 2
replace break2 = 60 if _ID == 3
replace break2 = 70 if _ID == 4
replace break2 = 71 if _ID == 5

foreach year in 1998 2018 {
	maptile simulatedElig`year', geo(state) geoid(statefips) fcolor( Blues2) ///
	spopt( label(xcoord(xcoord) ycoord(ycoord) label(state) ) legstyle(2) ///
	legjunction(" to ") ///
	legend(pos(5)) legtitle("% of children") line(data("${MAPTILEPATH}/line_data"))) ///
	legformat(%4.0f) cutp(break2) 
	graph export "${FIGUREDIR}/MapElig`year'.${EXTENSION}", replace
}

/*
* With labels for legend and state count
maptile simulatedElig2018, geo(state) geoid(statefips) fcolor(YlOrRd) ///
spopt( label(xcoord(xcoord) ycoord(ycoord) label(state)) legstyle(2) ///
legend( pos(5) label(2 "34.2-40.6% (9 states)") label(3 "40.6-42.1% (8 states)")) ///
line(data(line_data)) legtitle("% of children") legcount) legformat(%4.1f) 
*/

* ----- DELETE ELIGIBILITY FILES
cd ${TEMPDATADIR}
erase Elig1998_2018.dta
erase Elig1998.dta
erase Elig2018.dta


* ----------------------------- % OF FPL THRESHOLD PER STATE
* ----- PREPARE FPL DATA
foreach year in 1998 2018 {
	use "${CLEANDATADIR}/cutscombined.dta", clear

	gen cut = .
	replace cut = medicut 	if medicut >= schipcut
	replace cut = schipcut 	if schipcut >= medicut
	replace cut = cut * 100 				// in percentage of FPL

	keep if year == `year'
	collapse (min) cut, by(statefip)		// min % covered
	rename statefip statefips
	rename cut cut`year'

	save "${TEMPDATADIR}/maxFPL`year'.dta", replace
}

merge 1:1 statefips using "${TEMPDATADIR}/maxFPL1998.dta", nogen
save "${TEMPDATADIR}/maxFPL1998_2018.dta", replace

* ----- MAP
do "${CODEDIR}/output/maps_labels.do"	// center state names

merge 1:1 statefips using "${TEMPDATADIR}/maxFPL1998_2018.dta", nogen // data

* ----- GENERATE BREAK DATA
// clmethod(custom) does not work
gen break2 = .
replace break2 = 150 if _ID == 26
replace break2 = 200 if _ID == 27
replace break2 = 250 if _ID == 1
replace break2 = 300 if _ID == 2
replace break2 = 350 if _ID == 3
replace break2 = 400 if _ID == 4

foreach year in 1998 2018 {
	maptile cut`year', geo(state) geoid(statefips) fcolor(Blues2) ///
	spopt( label(xcoord(xcoord) ycoord(ycoord) label(state) ) legstyle(2) ///
	legjunction(" to ") ///
	legend(pos(5)) legtitle("% of FPL") line(data("${MAPTILEPATH}/line_data")) ) ///
	legformat(%4.0f) cutp(break2) 
	graph export "${FIGUREDIR}/MapFPL`year'.${EXTENSION}", replace
}

* ----- DELETE ELIGIBILITY FILES
cd ${TEMPDATADIR}
erase maxFPL1998_2018.dta
erase maxFPL1998.dta
erase maxFPL2018.dta


* ---------------------------------------------------------------------------- *
* ------------------------ MEDIAN SIMULATED ELIGIBILITY ---------------------- *
* ---------------------------------------------------------------------------- *
use "${CLEANDATADIR}/simulatedEligbility.dta", clear
order statefip year age
sort statefip year age
label var year "Year"

gen Elig0 = simulatedElig if ( age == 0 )
gen Elig1 = simulatedElig if ( age == 1 | age == 2 | age == 3 | age == 4 | age == 5 )
gen Elig6 = simulatedElig if ( age > 5 )

* ----- MEAN FOR EACH AGE GROUP
bysort year: egen mean_Elig0 = mean(Elig0)
bysort year: egen mean_Elig1 = mean(Elig1)
bysort year: egen mean_Elig6 = mean(Elig6)
label var mean_Elig0 "Age 0"
label var mean_Elig1 "Ages 1 - 5"
label var mean_Elig6 "Ages 6 - 8"

* ----- DEFINE GRAPH STYLE
grstyle clear
grstyle init
grstyle color background white
grstyle color major_grid dimgray
grstyle linewidth major_grid thin
grstyle yesno draw_major_hgrid yes
grstyle yesno grid_draw_min yes
grstyle yesno grid_draw_max yes
grstyle linestyle legend none

* ----- GRAPH
two (scatter mean_Elig0 year, connect(L) msymbol(X) mlcolor(emidblue) lcolor(emidblue) ///
ytitle("Fraction") xlabel(1998 (4) 2018)) ///
(connected mean_Elig1 year, msymbol(X) mlcolor(ebblue) lcolor(ebblue)) ///
(connected mean_Elig6 year, msymbol(X) mlcolor(navy) lcolor(navy))
graph export "${FIGUREDIR}/ChangeEligibility.${EXTENSION}", replace





