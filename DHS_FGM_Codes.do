/*******************************************************************************************************************************
Program: 				FGmain.do
Purpose: 				Main file for the Female Genital Cutting Chapter. 
						The main file will call other do files that will produce the FG indicators and produce tables.
Data outputs:			Coded variables and table output on screen and in excel tables.  
Author: 				Shireen Assaf
Date last modified:		October 22, 2020 by Shireen Assaf
Note:					This Chapter is a module and not part of the core questionnaire. 
						Please check if the survey you are interested in has included this module in the survey. 
*******************************************************************************************************************************/
set more off

*** User information for internal DHS use. Please disregard and adjust paths to your own. *** 

*change employee id number to personalize path
global user 33697

*working directory
cd "C:/Users/$user/ICF/Analysis - Shared Resources/Code/DHS-Indicators-Stata/Chap18_FG"

*data path where data files are stored
global datapath "C:/Users/$user/ICF/Analysis - Shared Resources/Data/DHSdata"


* select your survey

* IR Files
global irdata "ETIR71FL"

* BR Files
global brdata "ETBR71FL"

* MR Files
global mrdata "ETMR71FL"

****************************

* IR file variables

* open dataset
use "$datapath//$irdata.dta", clear

gen file=substr("$irdata", 3, 2)

do FG_CIRCUM.do
*Purpose: 	Calculate female circumcision indicators among women

do FG_tables.do
*Purpose: 	Produce tables for indicators computed from the above do files.
*/
*******************************************************************************************************************************
*******************************************************************************************************************************

* BR file variables

* To compute female circumcision among girls 0-14, we need to merge the IR and BR files
* The code below will reshape the IR file and merge with the BR file so we create a file for daughters. 
* The information on female circumcision of daughter is reported by the mother in the IR file

do FG_GIRLS.do
*Purpose: 	Calculate female circumcision indicators among girls age 0-14
*			This do file will also create the tables for these indicators
*This code only uses the BR file. Older surveys may not information about the daughter's cirucumcision in the BR file. 
*The information may instead be in the IR file. In that case please use the FG_GIRLS_merge.do file. 

*do FG_GIRLS_merge.do
*Purpose: 	Calculate female circumcision indicators among girls age 0-14
*			This do file will also create the tables for these indicators
*Use this do file if information about the daughter's circumcision status is not found in the BR file. 

*/
*******************************************************************************************************************************
*******************************************************************************************************************************

* MR file variables

* open dataset
use "$datapath//$mrdata.dta", clear

gen file=substr("$mrdata", 3, 2)

do FG_CIRCUM.do
*Purpose: 	Calculate female circumcision indicators among men (related to knowledge and opinion)

do FG_tables.do
*Purpose: 	Produce tables for indicators computed from the above do files.
*/
*******************************************************************************************************************************
*******************************************************************************************************************************
*****************************************************************************************************
Program: 			FG_CIRCUM.do
Purpose: 			Code  to compute female circumcision indicators indicators among women and knowledge and opinion on female circumcision among men
Data inputs: 		IR or MR survey list
Data outputs:		coded variables
Author:				Shireen Assaf
Date last modified: October 22, 2020 by Shireen Assaf 

Note:				Heard of female cirucumcision and opinions on female cirucumcision can be computed for men and women
					In older surveys there may be altnative variable names related to female circumcision. 
					Please check Chapter 18 in Guide to DHS Statistics and the section "Changes over Time" to find alternative names.
					Link:				https://www.dhsprogram.com/Data/Guide-to-DHS-Statistics/index.htm#t=Knowledge_of_Female_Circumcision.htm%23Percentage_of_women_and8bc-1&rhtocid=_21_0_0
					
*****************************************************************************************************/

/*----------------------------------------------------------------------------
Variables created in this file:

fg_heard			"Heard of female circumcision"
	
fg_fcircum_wm		"Circumcised among women age 15-49"
fg_type_wm			"Type of female circumcision among women age 15-49"
fg_age_wm			"Age at circumcision among women age 15-49"
fg_sewn_wm			"Female circumcision type is sewn closed among women age 15-49"	
fg_who_wm			"Person who performed the circumcision among women age 15-49"
	
fg_relig			"Opinion on whether female circumcision is required by their religion" 
fg_cont				"Opinion on whether female circumcision should continue" 

----------------------------------------------------------------------------*/


* indicators from IR file
if file=="IR" {

cap label define yesno 0"No" 1"Yes"

//Heard of female circumcision
gen fg_heard = g100 
replace fg_heard =1 if g101==1
label values fg_heard yesno
label var fg_heard "Heard of female circumcision"

//Circumcised women
gen fg_fcircum_wm = g102==1
replace fg_fcircum_wm=. if g100==.
label values fg_fcircum_wm yesno
label var fg_fcircum_wm	"Circumcised among women age 15-49"

//Type of circumcision
gen fg_type_wm = 9 if g102==1
replace fg_type_wm = 1 if g104==1 & g105!=1
replace fg_type_wm = 2 if g103==1 & g105!=1
replace fg_type_wm = 3 if g105==1 
label define fg_type 1"No flesh removed" 2"Flesh removed"  3"Sewn closed" 9"Don't know/missing"
label values fg_type_wm fg_type
label var fg_type_wm "Type of female circumcision among women age 15-49"

//Age at circumcision
gen fg_age_wm = 9 if g102==1
replace fg_age_wm = 1 if inrange(g106,0,4) | g106==95
replace fg_age_wm = 2 if inrange(g106,5,9) 
replace fg_age_wm = 3 if inrange(g106,10,14) 
replace fg_age_wm = 4 if inrange(g106,15,49) 
replace fg_age_wm = 9 if g106==98
label define fg_age 1"<5" 2"5-19" 3"10-14" 4"15+" 9"Don't know/missing"
label values fg_age_wm fg_age
label var fg_age_wm "Age at circumcision among women age 15-49"

//Sewn close
gen fg_sewn_wm = g105 if g102==1
label values fg_sewn_wm G105
label var fg_sewn_wm "Female circumcision type is sewn closed among women age 15-49"	

//Person performing the circumcision among women age 15-49
recode g107 (21=1 "traditional circumciser") (22=2 "traditional birth attendant") (26=3 "other traditional agent") ///
			(11=4 "doctor") (12=5 "nurse/midwife") (16=6 "other health professional") (96=7 "other") ///
			(98/99=9 "don't know/missing") if g102==1, gen(fg_who_wm)
label var fg_who_wm "Person who performed the circumcision among women age 15-49"

//Opinion on whether female circumcision is required by their religion
gen fg_relig = g118 if fg_heard==1
replace fg_relig =8 if g118==9
label values fg_relig G118
label var fg_relig "Opinion on whether female circumcision is required by their religion" 

//Opinion on whether female circumcision should continue
gen fg_cont = g119 if fg_heard==1
replace fg_cont =8 if g119==9
label values fg_cont G119
label var fg_cont "Opinion on whether female circumcision should continue" 
}


* indicators from MR file
if file=="MR" {

cap label define yesno 0"No" 1"Yes"

//Heard of female circumcision
gen fg_heard = mg100==1 | mg101==1
label values fg_heard yesno
label var fg_heard "Heard of female circumcision"

//Opinion on whether female circumcision is required by their religion
gen fg_relig = mg118 if fg_heard==1
replace fg_relig =8 if mg118==9
label values fg_relig MG118
label var fg_relig "Opinion on whether female circumcision is required by their religion" 

//Opinion on whether female circumcision should continue
gen fg_cont = mg119 if fg_heard==1
replace fg_cont =8 if mg119==9
label values fg_cont MG119
label var fg_cont "Opinion on whether female circumcision should continue" 
}
/*****************************************************************************************************
Program: 			FG_GIRLS.do
Purpose: 			Code to compute female circumcision indicators among girls 0-14
Data inputs: 		BR survey list
Data outputs:		coded variables
Author:				Shireen Assaf
Date last modified: November 12, 2020 by Shireen Assaf 
Note:				This code only uses the BR file. Older surveys may not information about the daughter's cirucumcision in the BR file. 
					The information may instead be in the IR file. In that case please use the FG_GIRLS_merge.do file. 
*****************************************************************************************************/

/*----------------------------------------------------------------------------
Variables created in this file:
	
fg_fcircum_gl	"Circumcised among girls age 0-14"	
fg_age_gl		"Age at circumcision among girls age 0-14"
fg_who_gl		"Person who performed the circumcision among girls age 0-14"
fg_sewn_gl		"Female circumcision type is sewn closed among girls age 0-14"
	
----------------------------------------------------------------------------*/

*select for girls age 0-14 
keep if b4==2 & b5==1 & b8<=14

*dropping cases where the mother never heard of circumcision
drop if g100==.

*yesno label
cap label define yesno 0"No" 1"Yes"

//Circumcised girls 0-14
gen fg_fcircum_gl = g121==1
label values fg_fcircum_gl yesno
label var fg_fcircum_gl	"Circumcised among girls age 0-14"	

//Age circumcision among girls 0-14
gen fg_age_gl = 0 
replace fg_age_gl = 1 if g122==0
replace fg_age_gl = 2 if inrange(g122,1,4) 
replace fg_age_gl = 3 if inrange(g122,5,9) 
replace fg_age_gl = 4 if inrange(g122,10,14) 
replace fg_age_gl = 9 if g122==98 | g122==99
replace fg_age_gl = 0 if g121==0
label define fg_age 0"not circumcised" 1"<1" 2"1-4" 3"5-9" 4"10-14" 9"Don't know/missing"
label values fg_age_gl fg_age
label var fg_age_gl "Age at circumcision among girls age 0-14"

//Person performing the circumcision among girls age 0-14
recode g124 (21=1 "traditional circumciser") (22=2 "traditional birth attendant") (26=3 "other traditional agent") ///
			(11=4 "doctor") (12=5 "nurse/midwife") (16=6 "other health professional") (96=7 "other") ///
			(98/99=9 "don't know/missing") if g121==1, gen(fg_who_gl)
label var fg_who_gl "Person who performed the circumcision among girls age 0-14"

//Type of circumcision among girls age 0-14
recode g123 (0=0 "not sewn close") (1=1 "sewn close") (8/9=9 "don't know/missing") if g121==1, gen(fg_sewn_gl)
label var fg_sewn_gl "Female circumcision type is sewn closed among girls age 0-14"

**************************************************************************************************
**************************************************************************************************

* Produce Tables_Circum_gl excel file which contains the tables for the indicators of female circumcision among girls age 0-14

gen wt=v005/1000000

*age groups for girls 
gen age5=1+int(b8/5)
label define age5 1 " 0-4" 2 " 5-9" 3 " 10-14"
label values age5 age5

//Prevalence of circumcision and age of circumcision

* Age of circumcision by current age
tab age5 fg_age_gl [iw=wt], row

* output to excel
tabout age5 fg_age_gl using Tables_Circum_gl.xls [iw=wt] , c(row) f(1) replace 

* Prevalence of circumcision by current age
tab age5 fg_fcircum_gl [iw=wt], row

* output to excel
tabout age5 fg_fcircum_gl using Tables_Circum_gl.xls [iw=wt] , c(row freq) f(1) append 

**************************************************************************************************

//Prevalence of circumcision by mother's background characteristics

*Circumcised mother
gen fg_fcircum_wm = g102
label values fg_fcircum_wm yesno
label var fg_fcircum_wm	"Circumcised among women age 15-49"

***** Among girls age 0-4 *****

*residence
tab v025 fg_fcircum_gl if age5==1 [iw=wt], row

*region
tab v024 fg_fcircum_gl if age5==1 [iw=wt], row

*education
tab v106 fg_fcircum_gl if age5==1 [iw=wt], row

*mother's circumcision status
tab fg_fcircum_wm fg_fcircum_gl if age5==1 [iw=wt], row

*wealth
tab v190 fg_fcircum_gl if age5==1 [iw=wt], row

* output to excel
tabout v025 v106 v024 fg_fcircum_wm v190 fg_fcircum_gl if age5==1 using Tables_Circum_gl.xls [iw=wt] , clab(Among_age_0_4) c(row) f(1) append 

***** Among girls age 5-9 *****

*residence
tab v025 fg_fcircum_gl if age5==2 [iw=wt], row

*region
tab v024 fg_fcircum_gl if age5==2 [iw=wt], row

*education
tab v106 fg_fcircum_gl if age5==2 [iw=wt], row

*mother's circumcision status
tab fg_fcircum_wm fg_fcircum_gl if age5==2 [iw=wt], row

*wealth
tab v190 fg_fcircum_gl if age5==2 [iw=wt], row

* output to excel
tabout v025 v106 v024 fg_fcircum_wm v190 fg_fcircum_gl if age5==2 using Tables_Circum_gl.xls [iw=wt] , clab(Among_age_5_9) c(row) f(1) append 

***** Among girls age 10-14 *****

*residence
tab v025 fg_fcircum_gl if age5==3 [iw=wt], row

*region
tab v024 fg_fcircum_gl if age5==3 [iw=wt], row

*education
tab v106 fg_fcircum_gl if age5==3 [iw=wt], row

*mother's circumcision status
tab fg_fcircum_wm fg_fcircum_gl if age5==3 [iw=wt], row

*wealth
tab v190 fg_fcircum_gl if age5==3 [iw=wt], row

* output to excel
tabout v025 v106 v024 fg_fcircum_wm v190 fg_fcircum_gl if age5==3 using Tables_Circum_gl.xls [iw=wt] , clab(Among_age_10_14) c(row) f(1) append 

***** Among girls age 0-14 : Total *****

*residence
tab v025 fg_fcircum_gl [iw=wt], row

*region
tab v024 fg_fcircum_gl [iw=wt], row

*education
tab v106 fg_fcircum_gl [iw=wt], row

*mother's circumcision status
tab fg_fcircum_wm fg_fcircum_gl [iw=wt], row

*wealth
tab v190 fg_fcircum_gl [iw=wt], row

* output to excel
tabout v025 v106 v024 fg_fcircum_wm v190 fg_fcircum_gl using Tables_Circum_gl.xls [iw=wt] , clab(Among_age_0_14) c(row) f(1) append 
**************************************************************************************************

//Person performing the circumcision among women girls 0-14 and type of cirucumcision

tab fg_who_gl age5  [iw=wt],col

* output to excel
tabout fg_who_gl age5 using Tables_Circum_gl.xls [iw=wt], c(col) f(1) append 
*/

****
//Sewn close
tab fg_sewn_gl age5  [iw=wt],col

* output to excel
tabout fg_sewn_gl age5 using Tables_Circum_gl.xls [iw=wt],  c(col) f(1) append 
/*****************************************************************************************************
Program: 			FG_GIRLS_merge.do
Purpose: 			Code to compute female circumcision indicators among girls 0-14
Data inputs: 		IR and BR survey list
Data outputs:		coded variables
Author:				Tom Pullum and Shireen Assaf
Date last modified: October 22, 2020 by Shireen Assaf 

Note:				Use this file only if information about the daughter's cirucumcision status is not in the BR file. 
					
					Women in the IR file are asked about the circumcision of their daughters.
					However, we need to reshape the file so that the data file uses daughters as the unit of analysis. 
					We also need to merge the IR and BR file to include all daughters 0-14 in the denominator.
					All the daughters age 0-14 must be in the denominator, including those whose mothers have
					g100=0; just those with g121=1 go into the numerator
*****************************************************************************************************/

/*----------------------------------------------------------------------------
Variables created in this file:
	
fg_fcircum_gl	"Circumcised among girls age 0-14"	
fg_age_gl		"Age at circumcision among girls age 0-14"
fg_who_gl		"Person who performed the circumcision among girls age 0-14"
fg_sewn_gl		"Female circumcision type is sewn closed among girls age 0-14"
	
----------------------------------------------------------------------------*/

***************** Creating a file for daughters age 0-14 *********************
* Prepare the IR file for merging
use v001 v002 v003 g* using "$datapath//$irdata.dta" , clear

rename *_0* *_*

* Reshape the IR file so there is one record per daughter 
reshape long gidx_ g121_ g122_ g123_ g124_ , i(v001 v002 v003) j(sequence)
drop sequence
rename *_ *
drop if gidx==.
rename gidx bidx
gen in_IR=1

sort v001 v002 v003 bidx
save IRtemp.dta, replace

* Prepare the BR file 
use "$datapath//$brdata.dta", clear
* Identify girls, living and age 0-14 (b15==1 is redundant)
keep if b4==2 & b5==1 & b8<=14

* Crucial line to drop the mothers and daughters who did not get the long questionnaire
* drop the girl if the g question were not asked of her mother
drop if g100==.

keep v001-v025 v106 v190 bidx b8
gen age5=1+int(b8/5)
label define age5 1 " 0-4" 2 " 5-9" 3 " 10-14"
label values age5 age5

* in_BR identifies a daughter who is eligible for a g121 code
gen in_BR=1

* MERGE THE BR FILE WITH THE RESHAPED IR FILE
sort v001 v002 v003 bidx
merge v001 v002 v003 bidx using  IRtemp.dta
drop _merge

* Some girls in the BR file do not have a value on g121 because their mothers had not heard of female circumcision.
* Crucial line to get the correct denominator
replace g121=0 if in_IR==. & in_BR==1

*drop if in_BR==.

erase IRtemp.dta
******************************************************************************

cap label define yesno 0"No" 1"Yes"

//Circumcised girls 0-14
gen fg_fcircum_gl = g121==1
label values fg_fcircum_gl yesno
label var fg_fcircum_gl	"Circumcised among girls age 0-14"	

//Age circumcision among girls 0-14
gen fg_age_gl = 0 
replace fg_age_gl = 1 if g122==0
replace fg_age_gl = 2 if inrange(g122,1,4) 
replace fg_age_gl = 3 if inrange(g122,5,9) 
replace fg_age_gl = 4 if inrange(g122,10,14) 
replace fg_age_gl = 9 if g122==98 | g122==99
replace fg_age_gl = 0 if g121==0
label define fg_age 0"not circumcised" 1"<1" 2"1-4" 3"5-9" 4"10-14" 9"Don't know/missing"
label values fg_age_gl fg_age
label var fg_age_gl "Age at circumcision among girls age 0-14"

//Person performing the circumcision among girls age 0-14
recode g124 (21=1 "traditional circumciser") (22=2 "traditional birth attendant") (26=3 "other traditional agent") ///
			(11=4 "doctor") (12=5 "nurse/midwife") (16=6 "other health professional") (96=7 "other") ///
			(98/99=9 "don't know/missing") if g121==1, gen(fg_who_gl)
label var fg_who_gl "Person who performed the circumcision among girls age 0-14"

//Type of circumcision among girls age 0-14
recode g123 (0=0 "not sewn close") (1=1 "sewn close") (8/9=9 "don't know/missing") if g121==1, gen(fg_sewn_gl)
label var fg_sewn_gl "Female circumcision type is sewn closed among girls age 0-14"

**************************************************************************************************
**************************************************************************************************

* Produce Tables_Circum_gl excel file which contains the tables for the indicators of female circumcision among girls age 0-14

gen wt=v005/1000000

//Prevalence of circumcision and age of circumcision

* Age of circumcision by current age
tab age5 fg_age_gl [iw=wt], row

* output to excel
tabout age5 fg_age_gl using Tables_Circum_gl.xls [iw=wt] , c(row) f(1) replace 

* Prevalence of circumcision by current age
tab age5 fg_fcircum_gl [iw=wt], row

* output to excel
tabout age5 fg_fcircum_gl using Tables_Circum_gl.xls [iw=wt] , c(row freq) f(1) append 

**************************************************************************************************

//Prevalence of circumcision by mother's background characteristics

*Circumcised mother
gen fg_fcircum_wm = g102==1
replace fg_fcircum_wm=. if g100==.
label values fg_fcircum_wm yesno
label var fg_fcircum_wm	"Circumcised among women age 15-49"

***** Among girls age 0-4 *****

*residence
tab v025 fg_fcircum_gl if age5==1 [iw=wt], row

*region
tab v024 fg_fcircum_gl if age5==1 [iw=wt], row

*education
tab v106 fg_fcircum_gl if age5==1 [iw=wt], row

*mother's circumcision status
tab fg_fcircum_wm fg_fcircum_gl if age5==1 [iw=wt], row

*wealth
tab v190 fg_fcircum_gl if age5==1 [iw=wt], row

* output to excel
tabout v025 v106 v024 fg_fcircum_wm v190 fg_fcircum_gl if age5==1 using Tables_Circum_gl.xls [iw=wt] , clab(Among_age_0_4) c(row) f(1) append 

***** Among girls age 5-9 *****

*residence
tab v025 fg_fcircum_gl if age5==2 [iw=wt], row

*region
tab v024 fg_fcircum_gl if age5==2 [iw=wt], row

*education
tab v106 fg_fcircum_gl if age5==2 [iw=wt], row

*mother's circumcision status
tab fg_fcircum_wm fg_fcircum_gl if age5==2 [iw=wt], row

*wealth
tab v190 fg_fcircum_gl if age5==2 [iw=wt], row

* output to excel
tabout v025 v106 v024 fg_fcircum_wm v190 fg_fcircum_gl if age5==2 using Tables_Circum_gl.xls [iw=wt] , clab(Among_age_5_9) c(row) f(1) append 

***** Among girls age 10-14 *****

*residence
tab v025 fg_fcircum_gl if age5==3 [iw=wt], row

*region
tab v024 fg_fcircum_gl if age5==3 [iw=wt], row

*education
tab v106 fg_fcircum_gl if age5==3 [iw=wt], row

*mother's circumcision status
tab fg_fcircum_wm fg_fcircum_gl if age5==3 [iw=wt], row

*wealth
tab v190 fg_fcircum_gl if age5==3 [iw=wt], row

* output to excel
tabout v025 v106 v024 fg_fcircum_wm v190 fg_fcircum_gl if age5==3 using Tables_Circum_gl.xls [iw=wt] , clab(Among_age_10_14) c(row) f(1) append 

***** Among girls age 0-14 : Total *****

*residence
tab v025 fg_fcircum_gl [iw=wt], row

*region
tab v024 fg_fcircum_gl [iw=wt], row

*education
tab v106 fg_fcircum_gl [iw=wt], row

*mother's circumcision status
tab fg_fcircum_wm fg_fcircum_gl [iw=wt], row

*wealth
tab v190 fg_fcircum_gl [iw=wt], row

* output to excel
tabout v025 v106 v024 fg_fcircum_wm v190 fg_fcircum_gl using Tables_Circum_gl.xls [iw=wt] , clab(Among_age_0_14) c(row) f(1) append 
**************************************************************************************************

//Person performing the circumcision among women girls 0-14 and type of cirucumcision

tab fg_who_gl age5  [iw=wt],col

* output to excel
tabout fg_who_gl age5 using Tables_Circum_gl.xls [iw=wt], c(col) f(1) append 
*/

****
//Sewn close
tab fg_sewn_gl age5  [iw=wt],col

* output to excel
tabout fg_sewn_gl age5 using Tables_Circum_gl.xls [iw=wt],  c(col) f(1) append 
/*****************************************************************************************************
Program: 			FG_tables.do
Purpose: 			produce tables for indicators
Author:				Shireen Assaf
Date last modified: October 23, 2020 by Shireen Assaf 

*Note this do file will produce the following tables in excel:
	1. 	Tables_Know:		Contains the tables for heard of female circumcision among women and men 
	2. 	Tables_Circum_wm:	Contains the tables for female circumcision prevalence, type, age of circumcision, and who performed the circumcision
	3.	Tables_Opinion:		Contains the tables for opinions related to female circumcision among women and men 


Notes: 	Tables_Circum_gl that show the indicators of female circumcision among girls 0-14 is produced in the FG_GIRLS.do file

		We select for the age groups 15-49 for both men and women. If you want older ages in men please change this selection in the code below (line 191). Most surveys for women are only for 15-49, but a few surveys have older surveys so this selection can be necessary (line 27). 
*****************************************************************************************************/

* the total will show on the last row of each table.
* comment out the tables or indicator section you do not want.
****************************************************

* indicators from IR file
if file=="IR" {

gen wt=v005/1000000

*select age group
drop if v012<15 | v012>49

**************************************************************************************************
//Heard of female circumcision

*age
tab v013 fg_heard [iw=wt], row nofreq 

*residence
tab v025 fg_heard [iw=wt], row nofreq 

*region
tab v024 fg_heard [iw=wt], row nofreq 

*education
tab v106 fg_heard [iw=wt], row nofreq 

*wealth
tab v190 fg_heard [iw=wt], row nofreq 

* output to excel
tabout v013 v025 v106 v024 v190 fg_heard using Tables_Know.xls [iw=wt] , clab(Among_women) c(row) f(1) replace 
*/

**************************************************************************************************
* Indicators for prevalence of female circumcision
**************************************************************************************************

//Circumcised women

*age
tab v013 fg_fcircum_wm [iw=wt], row nofreq 

*residence
tab v025 fg_fcircum_wm [iw=wt], row nofreq 

*region
tab v024 fg_fcircum_wm [iw=wt], row nofreq 

*education
tab v106 fg_fcircum_wm [iw=wt], row nofreq 

*wealth
tab v190 fg_fcircum_wm [iw=wt], row nofreq 

* output to excel
tabout v013 v025 v106 v024 v190 fg_fcircum_wm using Tables_Circum_wm.xls [iw=wt] , c(row) f(1) replace 

*/
****************************************************
//Type of circumcision

*age
tab v013 fg_type_wm [iw=wt], row nofreq 

*residence
tab v025 fg_type_wm [iw=wt], row nofreq 

*region
tab v024 fg_type_wm [iw=wt], row nofreq 

*education
tab v106 fg_type_wm [iw=wt], row nofreq 

*wealth
tab v190 fg_type_wm [iw=wt], row nofreq 

* output to excel
tabout v013 v025 v106 v024 v190 fg_type_wm using Tables_Circum_wm.xls [iw=wt] , c(row) f(1) append 
*/

****************************************************
//Age at circumcision

*age
tab v013 fg_age_wm [iw=wt], row nofreq 

*residence
tab v025 fg_age_wm [iw=wt], row nofreq 

*region
tab v024 fg_age_wm [iw=wt], row nofreq 

*education
tab v106 fg_age_wm [iw=wt], row nofreq 

*wealth
tab v190 fg_age_wm [iw=wt], row nofreq 

* output to excel
tabout v013 v025 v106 v024 v190 fg_age_wm using Tables_Circum_wm.xls [iw=wt] , c(row) f(1) append 
*/
****************************************************
//Person performing the circumcision among women age 15-49

* output to excel
tabout  fg_who_wm using Tables_Circum_wm.xls [iw=wt], oneway c(cell) f(1) append 
*/
****************************************************
//Sewn close

* output to excel
tabout fg_sewn_wm using Tables_Circum_wm.xls [iw=wt], oneway c(cell) f(1) append 
*/

**************************************************************************************************
* Indicators for opinions related to female circumcision
**************************************************************************************************
//Opinion on whether female circumcision is required by their religion

* female circumcision status
tab fg_fcircum_wm fg_relig [iw=wt], row nofreq 

*age
tab v013 fg_relig [iw=wt], row nofreq 

*residence
tab v025 fg_relig [iw=wt], row nofreq 

*region
tab v024 fg_relig [iw=wt], row nofreq 

*education
tab v106 fg_relig [iw=wt], row nofreq 

*wealth
tab v190 fg_relig [iw=wt], row nofreq 

* output to excel
tabout v013 v025 v106 v024 v190 fg_relig using Tables_Opinion.xls [iw=wt] , clab(Among_women) c(row) f(1) replace 
****************************************************
//Opinion on whether female circumcision should continue

* female circumcision status
tab fg_fcircum_wm fg_cont [iw=wt], row nofreq 

*age
tab v013 fg_cont [iw=wt], row nofreq 

*residence
tab v025 fg_cont [iw=wt], row nofreq 

*region
tab v024 fg_cont [iw=wt], row nofreq 

*education
tab v106 fg_cont [iw=wt], row nofreq 

*wealth
tab v190 fg_cont [iw=wt], row nofreq 

* output to excel
tabout v013 v025 v106 v024 v190 fg_cont using Tables_Opinion.xls [iw=wt] , clab(Among_women) c(row) f(1) append 
*/
}

****************************************************************************
****************************************************************************

* indicators from MR file
if file=="MR" {

gen wt=mv005/1000000

*select age group
drop if mv012<15 | mv012>49

****************************************************************************
//Heard of female circumcision

*age
tab mv013 fg_heard [iw=wt], row nofreq 

*residence
tab mv025 fg_heard [iw=wt], row nofreq 

*region
tab mv024 fg_heard [iw=wt], row nofreq 

*education
tab mv106 fg_heard [iw=wt], row nofreq 

*wealth
tab mv190 fg_heard [iw=wt], row nofreq 

* output to excel
tabout mv013 mv025 mv106 mv024 mv190 fg_heard using Tables_Know.xls [iw=wt] , clab(Among_men) c(row) f(1) append 
**************************************************************************************************
* Indicators for opinions related to female circumcision
**************************************************************************************************
//Opinion on whether female circumcision is required by their religion

*age
tab mv013 fg_relig [iw=wt], row nofreq 

*residence
tab mv025 fg_relig [iw=wt], row nofreq 

*region
tab mv024 fg_relig [iw=wt], row nofreq 

*education
tab mv106 fg_relig [iw=wt], row nofreq 

*wealth
tab mv190 fg_relig [iw=wt], row nofreq 

* output to excel
tabout mv013 mv025 mv106 mv024 mv190 fg_relig using Tables_Opinion.xls [iw=wt] , clab(Among_men) c(row) f(1) append 
****************************************************
//Opinion on whether female circumcision should continue

*age
tab mv013 fg_cont [iw=wt], row nofreq 

*residence
tab mv025 fg_cont [iw=wt], row nofreq 

*region
tab mv024 fg_cont [iw=wt], row nofreq 

*education
tab mv106 fg_cont [iw=wt], row nofreq 

*wealth
tab mv190 fg_cont [iw=wt], row nofreq 

* output to excel
tabout mv013 mv025 mv106 mv024 mv190 fg_cont using Tables_Opinion.xls [iw=wt] , clab(Among_men) c(row) f(1) append 
*/

}
