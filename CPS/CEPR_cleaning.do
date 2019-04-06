* -----------------------------------
* Content: 		Clean CPS data 2017-2018
* Author:		Copyright 2016 CEPR, John Schmitt, Hye Jin Rho, Janelle Jones, Cherrie Bucknor
* Modified by: 	Michelle Rosenberger
* Date: 		November 15, 2018
* -----------------------------------

/* This file is composed by several parts from the cepr_march_master.do programs
which were created by CEPR. These files are distributed by CEPR under the GNU General
Public License (See copyright notice at end of program). See the following homepage
for all the relevant files:
http://ceprdata.org/cps-uniform-data-extracts/march-cps-supplement/march-cps-programs/
The relevenat code parts were inlcuded in this file to make the years 2017 and 2018
comparable with the previous years. */

/* Age */
gen age=a_age
replace age=. if age<0
replace age=. if age>85

lab var age "Age"
notes age: CPS: age a-age
notes age: Topcodes: 99(80-88), 90(89-01), 80(02-03), 85(04-on)
notes age: From 2004-on, 80=(80-84), 85=(85+)


/* Gender */
gen byte female=0 if a_sex==1 | a_sex==2
replace female=1 if a_sex==2

lab var female "Female"
notes female: CPS: derived: sex a-sex


/* Race and ethnicity */
gen byte wbho=.
replace wbho=1 if prdtrace==1 /* white only */
replace wbho=2 if prdtrace==2 /* black only */
replace wbho=2 if prdtrace==6 /* black-white */ | prdtrace==10 /*
*/ /* black-AI */ | prdtrace==11 /* black-asian */ | prdtrace==12 /*
*/ /* black-HP */ | prdtrace==16 /* W-B-AI */ | prdtrace==17 /* W-B-A */ /*
*/ | prdtrace==18 /* W-B-HP */ | prdtrace==22 /* B-AI-A */ | prdtrace==23 /*W-B-AI-A*/
replace wbho=4 if 3<=prdtrace & prdtrace<=5
replace wbho=4 if prdtrace==7 /* white-AI */ | prdtrace==8 /* white-asian */ /*
*/ | prdtrace==9 /* white-hawaiian */ | prdtrace==13 /* AI-asian */ /*
*/ | prdtrace==14 /* AI-HP */ | prdtrace==15 /*Asian-HP*/ /*
*/ | prdtrace==19 /* W-AI-A */ | prdtrace==20 /* W-AI-HP */ /*
*/ | prdtrace==21 /* W-A-HP */ | prdtrace==24 /* W-AI-Asian-HP */ /*
*/ | prdtrace==25 /* other 3 race combo */ | prdtrace==26 /* 4 or 5 races combo*/
replace wbho=3 if (1<=prdthsp & prdthsp<=8) /* hispanic */

lab var wbho "Race/ethnicity"
lab def wbho 1 "White" 2 "Black" 3 "Hispanic" 4 "Other"
lab val wbho wbho
notes wbho: Racial and ethnic categories are mutually exclusive
notes wbho: From 2003, black includes all respondents listing black; other /*
*/ includes all respondents listing non-white or non-black races, except /*
*/ those also listing black
notes wbho: CPS: derived: race a-race prdtrace ethncity a-reorgn prdthsp



/* Family Level */

	/* Primary family relationship (1989-on only) */
	/* Universe: Those in Primary family only */

gen byte pfrel=a_pfrel

lab var pfrel "Primary family relationship"

#delimit;
lab define pfrel
0 "NIU"
1 "Husband"
2 "Wife"
3 "Own child"
4 "Other relative"
5 "Unmarried head"
;
#delimit cr

label val pfrel pfrel
notes pfrel: Available 1989-on only
notes pfrel: CPS: derived: a-pfrel


/* Family ID within household */
rename a_famnum famno

lab var famno "family line number w/in HH"
notes famno: CPS: a-famnum famnumbr
notes famno: 1980-1988: 0 if primary family number or not in /*
*/subfamily (related/unrelated)
notes famno: 1980-1988: 1-6 if in subfamily (related/unrelated)
notes famno: 1989-on: 0 if not in subfamily (related/unrelated)
notes famno: 1989-on: 1 if primary family member
notes famno: 1989-on: 2-19 if in subfamily (related/unrelated)


/* hhseq */
rename h_seq hhseq

lab var hhseq "Household ID within file"
notes hhseq: Household unique numbers within a single file./*
*/ Not for matching across years.
notes hhseq: ph-seq ppseqnum
tostring hhseq, replace format(%06.0f)

/* Year */
rename h_year year


/* Income from wage and salary */

	/* NOTES: From UNICON, appendinx H: 
	incwag (89-09) = incwg1 + (incer1 if ernsrc=1) 
	"If both vars are topcoded in 88B-95, then the max value will range
	between 99999 and 199998" 
	Top code for both incwg1 and incer1 in 88B-95: 99999
	*/

gen incp_wag=wsal_val if (0<=wsal_val & wsal_val~=.)

lab var incp_wag "Income from wage and salary (nominal)"
notes incp_wag: March CPS: derived: wsal-val 151a
notes incp_wag: See incp_wag_tc for 80-88 topcode flag
notes incp_wag: Bottom/Top Code*(Value): 0/50000*(80-81) 0/75000*(82-84) /*
*/0/99999*(85-88) 0/199998*(89-95) 0/183748*(96-97) 0/481393*(98) /*
*/0/551958*(99) 0/598527*(2000) 0/413902*(2001) 0/543055*(2002) /*
*/0/686854*(2003) 0/516100*(2004) 0/790545*(2005) 0/649563*(2006) /*
*/0/859895*(2007) 0/769343*(2008) 0/635185*(2009) 0/662169*(2010) /*
*/0/9999999*(2011-on)

gen byte incp_wag_tc=.
replace incp_wag_tc=0 if incp_wag<662169 & incp_wag~=.
replace incp_wag_tc=1 if 662169<=incp_wag & incp_wag~=.
lab var incp_wag_tc "Topcode flag: Income from wage and salary"
notes incp_wag_tc: March CPS: derived: flag51a wsal-val
notes incp_wag_tc: Topcode flag for incp_wag 80-88


/* Income from unemployment compensation */
	/* Universe: 
	state or federal unemployment compensation
	supplemental unemployment benefits
	union unemployment or strike benefits 
	*/

gen byte incp_uc=.
replace incp_uc=uc_val if uc_val~=.

lab var incp_uc "Income from unemployment compensation (nominal)"
notes incp_uc: March CPS: derived: uc-val
notes incp_uc: Available 89-on only
notes incp_uc: Bottom/Top Code*(Value): 0/99999*(89-on)


/* Income from self-employment */

	/* Farm or nonincorporated */

gen incp_sefrm=frse_val if frse_val~=.

lab var incp_sefrm "Income from farm or noninc self-employment (nominal)"
notes incp_sefrm: March CPS: derived: frse-val i-51c
notes incp_sefrm: See incp_sefrm_tc for topcode flag
notes incp_sefrm: Bottom/Top Code*(Value): -9999*/50000*(80-81) -9999*/75000*/*
*/(82-84) -9999*/99999*(85-88) -19998*/199998*(89-95) -9999/629439*(96-97) /*
*/-9999/534641*(98) -9999/557994*(99) -389961/999999*(2000) -99999/521658*(01) /*
*/-99999/908907*(02) -99999/794820*(03) -99999/709131*(04) -99999/785694*(05) /*
*/-99999/832776*(06) -99999/599834*(07) -99999/230937*(08) -99999/621356*(2009) /*
*/-99999/629369*(2010) -99999/9999999*(2011-on)

gen byte incp_sefrm_tc=.

replace incp_sefrm_tc=0 if incp_sefrm<9999999 & incp_sefrm~=.
replace incp_sefrm_tc=1 if 9999999<=incp_sefrm & incp_sefrm~=.

lab var incp_sefrm_tc "Topcode flag: Income from farm or noninc self-employment"
notes incp_sefrm_tc: March CPS: derived: flag51c frse-val
notes incp_sefrm_tc: Topcode flag for incp_sefrm 80-88


	/* Nonfarm */

gen incp_senf=semp_val if semp_val~=.

lab var incp_senf "Income from nonfarm self-employment (nominal)"
notes incp_senf: March CPS: derived: semp-val i51b
notes incp_senf: See incp_senf_tc for topcode flag
notes incp_senf: Bottom/TopCode*(Value): -9999/50000(80-81) -9999/75000 (82-84) /*
*/-9999*/99999*(85-88) -19998*/199998*(89-95) -9999/760120*(96-97) /*
*/-9999/546375*(98) -9999/624176*(1999) -9999/481887*(2000) /*
*/-99999/456973*(2001) -99999/605159*(2002) -99999/789127*(2003) /*
*/-99999/661717*(2004) -99999/880089*(2005) -99999/730116*(2006) /*
*/-99999/766141*(2007) -99999/801198*(2008) -99999/736488*(2009) /*
*/-99999/702914*(2010) -99999/9999999*(2011-on)

gen byte incp_senf_tc=.

replace incp_senf_tc=0 if incp_senf<9999999 & incp_senf~=.
replace incp_senf_tc=1 if 9999999<=incp_senf & incp_senf~=.

lab var incp_senf_tc "Topcode flag: Income from nonfarm self-employment"
notes incp_senf_tc: March CPS: derived: flag51b semp-val
notes incp_senf_tc: Topcode flag for incp_senf 80-88


	/* Both farm or nonfarm */

egen incp_se=rsum(incp_sefrm incp_senf)

lab var incp_se "Income from self-employment (nominal)"
notes incp_se: derived: frse-val i-51c semp-val i51b
notes incp_se: See incp_se_tc for topcode flag
notes incp_se: See incp_sefrm incp_senf for bottom/top coding

gen byte incp_se_tc=.

replace incp_se_tc=0 if (incp_sefrm_tc==0 & incp_senf_tc==0)
replace incp_se_tc=1 if (incp_sefrm_tc==1 | incp_senf_tc==1)

lab var incp_se_tc "Topcode flag: Income from self-employment"
notes incp_se_tc: March CPS: derived: flag51b flag51c frse-val semp-val
notes incp_se_tc: Topcode flag for incp_se 80-88


/* Income from child support */

	/* From CPS (Unicon), child support: 
               "In 1999+ the top, nonrecoded value is $15,000.
               ABOVE this, the individuals are grouped by sex, race/origin,
               and worker status.  A mean income value is calculated within
               these groups and assigned to the individuals.  The largest mean
               value is shown as the 'Top value'."
	*/
	/* From CPS (Unicon), alimony: 
               "In 1999-2002 the top, nonrecoded value is $40,000. 
               In 2003 the top, nonrecoded value is $45,000. 
               ABOVE this, the individuals are grouped by sex, race/origin, 
               and worker status.  A mean income value is calculated within 
               these groups and assigned to the individuals.  The largest mean 
               value is shown as the 'Top value'."
	*/

gen incp_cs=.
gen incp_alm=.
gen incp_cs_tc=.

replace incp_cs=csp_val if csp_val~=.
/* incp_alm and incp_salm not available */
gen incp_csalm=.

replace incp_cs_tc=0 if tcsp_val==0
replace incp_cs_tc=1 if tcsp_val==1

lab var incp_cs "Income from child support (nominal)"
notes incp_cs: March CPS: derived: csp-val
notes incp_cs: Available 89-on only
notes incp_cs: Top, nonrecoded value 15000
notes incp_cs: Top value (largest mean of those grouped above 15,000) 99999
notes incp_cs: See incp_cs_tc for 99-on topcode flag

lab var incp_alm "Income from alimony (nominal)"
notes incp_alm: March CPS: derived: alm-val
notes incp_alm: Available 89-14 only
notes incp_alm: For 2014, alimony is included in the "other income" variable /*
*/ for the 3/8 research file with redesigned income questions
notes incp_alm: Top, nonrecoded value 50000, 40000, 45000 in 99, 00-02, 03,/*
*/ respectively.
notes incp_alm: Top value (largest mean of those grouped above top,/*
*/ nonrecoded values) 99999

lab var incp_csalm "Income from alimony and child support (nominal)"
notes incp_csalm: March CPS: derived: i53f csp-val alm-val
notes incp_csalm: Available 80-14 only
notes incp_csalm: For 2014, alimony is included in the "other income" variable /*
*/ for the 3/8 research file with redesigned income questions
notes incp_csalm: See incp_cs_tc for 99-13 topcode flag

lab var incp_cs_tc "Topcode flag: Income from alimony and child support"
notes incp_cs_tc: March CPS: derived: tcsp-val flag53f
notes incp_cs_tc: Topcode Flag for incp_cs incp_csalm, 80-88 99-on only


/* Health insurance, any, including children */

gen byte hins=0
replace hins=1 if (cov_hi==1 | mcaid==1 | mcare==1 | champ==1)
* cov_hi: private hi, includes employer hi (covgh) *

lab var hins "Health Insurance"
lab val hins noyes
notes hins: March CPS: derived: cov-hi mcaid mcare champ
notes hins: 1981 and 1982 is missing private insurance data (covhi)
notes hins: Major change in survey questions in 1988. Data prior to 1988 not /*
*/ directly comparable.

/* Health insurance, private (1983-on) */

gen byte hipriv=0
replace hipriv=1 if cov_hi==1
* covhi: private hi, includes employer hi (covgh) *

lab var hipriv "Health Insurance, private" 
lab val hipriv noyes
* both employer-provided and privately purchased
notes hipriv: March CPS: derived: cov-hi
notes hipriv: Missing in 1981, 1982
notes hipriv: Major change in survey questions in 1988. Data prior to 1988 not /*
*/ directly comparable.

/* Health insurance, public */

	/* Covered by Medicaid */

gen byte himcaid=0

replace himcaid=1 if mcaid==1 | ch_mc==1

lab var himcaid "Health Insurance, Medicaid"
lab val himcaid noyes
notes himcaid: March CPS: derived: mcaid ch-mc

	/* Covered by Medicare */

gen byte himcare=0
replace himcare=1 if mcare==1
replace himcare=0 if mcare==2

lab var himcare "Health Insurance, Medicare"
lab val himcare noyes
notes himcare: Children under 15 are not included for years 1980-1994.
notes himcare: March CPS: derived: mcare

	/* Covered by CHAMPUS or military health care */

gen byte hiothpub=0
replace hiothpub=1 if champ==1

lab var hiothpub "Health Insurance, provided by CHAMPUS or military hc"
lab val hiothpub noyes
notes hiothpub: March CPS: derived: champ covercp


/* Child covered by public health insurance */

	/* Child covered by Medicaid */

gen byte himcc=.

replace himcc=1 if ch_mc==1
replace himcc=0 if ch_mc==2


lab var himcc "Child covered by Medicaid"
lab val himcc noyes
notes himcc: Missing if not child under 15
notes himcc: Available 1989-on only
notes himcc: March CPS: derived: ch-mc
notes himcc: Census docs say ch-mc also covers medicare


	/* Child covered by S-CHIP */

gen byte hischip=.

replace hischip=1 if pchip==1
replace hischip=0 if pchip==2

lab var hischip "Child covered by S-CHIP, no Medicaid"
lab val hischip noyes
notes hischip: Missing if not child under 19
notes hischip: Available 2001-on only
notes hischip: March CPS: derived: i-pchip pchip

/* Total Public */
gen byte hipub=0
replace hipub=1 if (himcare==1 | himcaid==1 | hiothpub==1)

lab var hipub "Health Insurance, Public"
lab val hipub noyes
notes hipub: March CPS: derived: mcaid mcare champ

	/* Health insurance provided by employers */

	/* From CPS/Unicon:
	covgh:  Includes persons who are not enrolled in group health, 
		but are covered by another household member's policy.
	chhi: Defines children covered by private hi (1), group hi (2), and none (3).
	*/

gen byte hiep=0
replace hiep=1 if (cov_gh==1 | ch_hi==2)

lab var hiep "Health Insurance, employer-provided (private)"
lab val hiep noyes
notes hiep: March CPS: derived: cov-gh ch-hi
notes hiep: 80-88 data does not capture children's hi from outside the household.




/* FROM ORIGINAL FILES:

Copyright 2016 CEPR, John Schmitt, Hye Jin Rho, Janelle Jones, Cherrie Bucknor

This file is part of the cepr_march_master.do program. This file and all
programs referenced in it are free software. You can redistribute the
program or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
USA.
*/


