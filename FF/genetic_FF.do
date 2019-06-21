* -----------------------------------
* Project:      MA Thesis
* Content:      Prepare genetic data
* Author:       Michelle Rosenberger
* Date:         May 10, 2019
* -----------------------------------
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
	*global CODEDIR		"/Volumes/g_econ_department$/econ/biroli/geighei/code/medicaidGxE/thesis-code"
}

do "${CODEDIR}/setDirectories.do"

* ----------------------------- LOG FILE
log using "${CODEDIR}/FF/genetic_FF.log", replace
    
* ----------------------------- DATA
use "${RAWDATADIR}/rawData/ff_gen_9y_pub4.dta", clear

* ----- MISSING VALUES (NUMERIC)
mvdecode g*5telo gk5flag, mv(-9 = .a \ -7 = .b \ -5 = .c \ -3 = .d \ -1 = .e)

* ----- MISSING VALUES (STRING)
ds, has(type string)
global ALLVARIABLES = r(varlist)

foreach variable in $ALLVARIABLES {
    replace `variable' = "." if `variable' == "-9 Not in wave"
    replace `variable' = "." if `variable' == "-7 N/A PCG not Bio Mother"
    replace `variable' = "." if `variable' == "-5 Not collected"
    replace `variable' = "." if `variable' == "-3 Missing"
    replace `variable' = "." if `variable' == "-1 Refused"
}

* ----- COPY VALUES FOR EACH WAVE
expand 	6
bysort idnum : gen num = _n

gen wave = .
replace wave = 0 if num == 1
replace wave = 1 if num == 2
replace wave = 3 if num == 3
replace wave = 5 if num == 4
replace wave = 9 if num == 5
replace wave = 15 if num == 6

* ----- HEALTH BEHAVIORS
* NOTE: alcohol, obesity, smoking
gen DRD2rs18 = .
replace DRD2rs18 = 1 if gk5drd2rs1800497 == "CT" | gk5drd2rs1800497 == "TT" // 1+ risky allels
replace DRD2rs18 = 0 if gk5drd2rs1800497 == "CC"
label define DRD2rs18 1 "1 CT/TT" 0 "0 CC"
label values DRD2rs18 DRD2rs18
label var DRD2rs18 "Risky DRD2 $^{1}$"

* ----- BMI
gen FTO = .
replace FTO = 1 if gk5ftors9939609 == "AA" | gk5ftors9939609 == "AT" // 1+ risky allels
replace FTO = 0 if gk5ftors9939609 == "TT" // normal
label define FTO 0 "0 TT" 1 "1 AA/AT"
label values FTO FTO
label var FTO "Risky FTO $^{1}$"

    gen FTOIndex = .
    replace FTOIndex = 2 if gk5ftors9939609 == "AA" // A risky
    replace FTOIndex = 1 if gk5ftors9939609 == "AT"
    replace FTOIndex = 0 if gk5ftors9939609 == "TT"

    // Child 9-year FTO |
    //        rs9939609 |
    //          genetic |
    //        component |      Freq.     Percent        Cum.
    // -----------------+-----------------------------------
    //                . |      2,017       41.18       41.18
    //               AA |        484        9.88       51.06
    //               AT |      1,340       27.36       78.42
    //               TT |      1,057       21.58      100.00
    // -----------------+-----------------------------------
    //            Total |      4,898      100.00

gen MC4Rrs17 = .
replace MC4Rrs17 = 1 if gk5mc4rrs17782313 == "CC" | gk5mc4rrs17782313 == "CT" // 1+ risky allels
replace MC4Rrs17 = 0 if gk5mc4rrs17782313 == "TT" // normal
label define MC4Rrs17 0 "0 TT" 1 "1 CC/CT"
label values MC4Rrs17 MC4Rrs17
label var MC4Rrs17 "Risky MC4R $^{3}$"

    gen MC4RIndex = .
    replace MC4RIndex = 2 if gk5mc4rrs17782313 == "CC" // C risky
    replace MC4RIndex = 1 if gk5mc4rrs17782313 == "CT"
    replace MC4RIndex = 0 if gk5mc4rrs17782313 == "TT"

    // Child 9-year |
    // MC4R rs17782313 |
    //         genetic |
    //       component |      Freq.     Percent        Cum.
    // -----------------+-----------------------------------
    //               . |      2,033       41.51       41.51
    //              CC |        165        3.37       44.88
    //              CT |        937       19.13       64.01
    //              TT |      1,763       35.99      100.00
    // -----------------+-----------------------------------
    //           Total |      4,898      100.00

gen TMEM18rs65 = .
replace TMEM18rs65 = 1 if gk5tmem18rs6548238 == "CC"                    // 2 risky allels
replace TMEM18rs65 = 0 if gk5tmem18rs6548238 == "CT" | gk5tmem18rs6548238 == "TT"
label define TMEM18rs65 0 "0 CT/TT" 1 "1 CC"
label values TMEM18rs65 TMEM18rs65
label var TMEM18rs65 "Risky TMEM18 $^{2}$"

    gen TMEM18Index = .
    replace TMEM18Index = 2 if gk5tmem18rs6548238 == "CC" // C risky
    replace TMEM18Index = 1 if gk5tmem18rs6548238 == "CT"
    replace TMEM18Index = 0 if gk5tmem18rs6548238 == "TT"

    // Child 9-year |
    // TMEM18 rs6548238 |
    //          genetic |
    //        component |      Freq.     Percent        Cum.
    // -----------------+-----------------------------------
    //                . |      2,021       41.26       41.26
    //               CC |      2,185       44.61       85.87
    //               CT |        636       12.98       98.86
    //               TT |         56        1.14      100.00
    // -----------------+-----------------------------------
    //            Total |      4,898      100.00

egen riskScoreBMI = rowtotal(FTOIndex TMEM18Index MC4RIndex)
replace riskScoreBMI = . if FTOIndex == . & TMEM18Index == . & MC4RIndex == .

gen riskIndexBMI = .
replace riskIndexBMI = 1 if riskScoreBMI >= 3 & riskScoreBMI <= 6
replace riskIndexBMI = 0 if riskScoreBMI >= 0 & riskScoreBMI <= 2
label var riskIndexBMI "Risk Index"


* ----- PREPARE DATA FOR MERGE
rename gk5saliva chGenetic
label define chGenetic	0 "0 No"	1 "1 Yes"
label values chGenetic chGenetic
label var chGenetic "Child has genetic information"

* ----- SAVE
drop num
save "${TEMPDATADIR}/genetic.dta", replace


    // * ----- DEPRESSION      NOT SURE
    // gen TPH2rs45 = .
    // replace TPH2rs45 = 1 if gk5tph2rs4570625 == "GG" // risky
    // replace TPH2rs45 = 0 if gk5tph2rs4570625 == "GT" | gk5tph2rs4570625 == "TT" // normal
    // label define TPH2rs45 0 "0 GT/TT" 1 "1 GG"
    // label values TPH2rs45 TPH2rs45


    // * NOTE: novelty seeking
    // gen DRD4rs18 = .
    // replace DRD4rs18 = 1 if gk5drd4rs1800955 == "CC" | gk5drd4rs1800955 == "CT" // risky
    // replace DRD4rs18 = 0 if gk5drd4rs1800955 == "TT"
    // label define DRD4rs18 1 "1 CC/CT" 0 "0 TT"
    // label values DRD4rs18 DRD4rs18


    // * ----- ANXIETY / DEPRESSION
    // gen COMTrs4680 = .
    // replace COMTrs4680 = 1 if gk5comtrs4680 == "AA" | gk5comtrs4680 == "AG" // risky
    // replace COMTrs4680 = 0 if gk5comtrs4680 == "GG"
    // label define COMTrs4680 1 "1 AA/AG" 0 "0 GG"
    // label values COMTrs4680 COMTrs4680



* ----- NOT USED
// gen BDNFrs65 = .
// replace BDNFrs65 = 1 if gk5bdnfrs4074134 == "CC" // risky
// replace BDNFrs65 = 0 if gk5bdnfrs4074134 == "TT" | gk5bdnfrs4074134 == "CT"  // normal
// label define BDNFrs65 0 "0 TT/CT" 1 "1 CC"
// label values BDNFrs65 BDNFrs65

    /*    Child 9-year |
    BDNF rs4074134  |
            genetic |
        component   |      Freq.     Percent        Cum.
    -----------------+-----------------------------------
                .   |      2,022       41.28       41.28
                CC  |      1,905       38.89       80.18
                CT  |        883       18.03       98.20
                TT  |         88        1.80      100.00
    -----------------+-----------------------------------
            Total   |      4,898      100.00          */



* BDNFrs65 C risky
// gen BDNFIndex = .
// replace BDNFIndex = 2 if gk5bdnfrs4074134 == "CC"
// replace BDNFIndex = 1 if gk5bdnfrs4074134 == "CT"
// replace BDNFIndex = 0 if gk5bdnfrs4074134 == "TT"


