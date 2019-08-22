 * ---------------------------------------- *
 * file:    0_clean.do               
 * author:  Christopher Boyer              
 * project: Maximum Diva Women's Condom    
 * date:    2018-03-15                     
 * ---------------------------------------- *

 /* This file... 
    
    TO DO:
        1. Split baseline and endline datasets
        2. Split the monitoring information
        3. Deidentify by: 
            a. Anonymize the survey ID
            b. Drop and/or scramble gps points
            c. Drop unnecessary variables
        4. Rename analysis variables */

 * -------------------------- Define variable lists -------------------------- */

local keeplist ///
	id ///
	gender age educ literacy married r7_nchildren d4_employmt lang ///
	sexage2 numsexpartners r3_sexpartner6mo sexpartner1mo sti_test_ever ///
	s11_condbroke mc_z_opinion  MC_Last_Use ///
	c9b_contuse2_a c9b_contuse2_b c9b_contuse2_c c9b_contuse2_d c9b_contuse2_g modern_use_last ///
	z_cont_knowl know_modern contspkpartner c19_conttravel ///
	correct_FC_ID tryfc fc_z_opinion fc5_ever fc6_last6 fc7_lastsex ///
	intervention endline en4_ipcattend ward_no
	
local renamelist ///
	id ///
	female age educ literacy married children employed survey_language ///
	sex_age sex_partners_ever sex_partners_6mo sex_freq_1mo sex_sti_test ///
	mc_broke mc_z_opinion mc_use_last ///
	pill_use_last iud_use_last inject_use_last implant_use_last diaphragm_use_last modern_use_last ///
	cont_z_know cont_know_modern cont_discussed cont_travel_30min ///
	fc_recognize fc_try fc_z_opinion fc_use_ever fc_use_6mo fc_use_last ///
	treatment endline ipc_attend ward
	
local surveylist 

local monitorlist 

* ------------ Create a dataset of ward-level baseline covariates ----------- */

use "../Data/maximum_diva.dta", clear

isid qnum_b qnum_e KEY, missok
sort qnum_b qnum_e KEY

g id = _n

preserve
keep id qnum_b qnum_e KEY submissiondate
save "../Data/maximum_diva_crosswalk.dta", replace
restore

replace tryfc = 0 if mi(tryfc)
replace contspkpartner = 0 if contspkpartner == .
replace s11_condbroke = 0 if s11_condbroke == .

replace sexpartner1mo = r3_sexpartnernow if endline
replace intervention=0 if (ward_no==1 | ward_no==2 | ward_no==3| ward_no==5 | ward_no==6 | ward_no==8 | ward_no==10 | ward_no==11 | ward_no==13 | ward_no==14 | ward_no==21 | ward_no==23 | ward_no==25 | ward_no==26 | ward_no==28 | ward_no==29 | ward_no==36 | ward_no==37 | ward_no==38 | ward_no==40) 
replace intervention=1 if (ward_no==4 | ward_no==7 | ward_no==9 | ward_no==12 | ward_no==15 | ward_no==16 | ward_no==17 | ward_no==18 | ward_no==19 | ward_no==20 | ward_no==22 | ward_no==24 | ward_no==27 | ward_no==30| ward_no==31 |ward_no==32| ward_no==33| ward_no==34 | ward_no==35 | ward_no==39)
replace correct_FC_ID = 0 if mi(correct_FC_ID)

replace fc5_ever = 0 if mi(fc5_ever)
replace fc6_last6 = 0 if fc5_ever == 0 
replace fc7_lastsex = 0 if fc5_ever == 0 | fc6_last6 == 0
replace c19_conttravel = 0 if c19_conttravel < 30
replace c19_conttravel = 1 if c19_conttravel >= 30 & !mi(c19_conttravel)
replace en4_ipcattend = 0 if mi(en4_ipcattend) & endline

mca s12_condop_c-s12_condop_m
predict mc_z_opinion
replace mc_z_opinion = -mc_z_opinion

mca fc4_op_c-fc4_op_j
predict fc_z_opinion
replace fc_z_opinion = -fc_z_opinion

/* contknow - number of contraceptive options known. The first 
   component of the principal components seems like a good weight 
   for thise. */
drop contknow
mca contknow_a-contknow_i contknow_m
predict cont_z_know

/* condknow - knowledge about condom use. Let's again score them
   on the */
   
mca s12_condop_a s12_condop_b s12_condop_n-s12_condop_q
predict mc_z_know

mca fc4_op_a-fc4_op_b fc4_op_h fc4_op_i fc4_op_j
predict fc_z_know

/* fcident - can identify the female condom correctly using photo. */

g fcident = fc2_photo == 2

foreach var in c9b_contuse2_a c9b_contuse2_b c9b_contuse2_c c9b_contuse2_d c9b_contuse2_g {
	replace `var' = 0 if mi(`var')
}

egen modern_use_last = rowmax(c9b_contuse2_a-c9b_contuse2_g)

* ------------ Create a dataset of ward-level baseline covariates ----------- */
st
keep `keeplist'
rename (`keeplist') (`renamelist')
order `renamelist'

merge m:1 ward using "../Data/maximum_diva_monitoring.dta", nogen 
merge m:1 ward using "../Data/maximum_diva_wards.dta", nogen assert(3)

replace ward_poverty = 1 if ward_poverty <.10
replace ward_poverty = 2 if ward_poverty >=.10 & ward_poverty <.20
replace ward_poverty = 3 if ward_poverty >=.20 & !inlist(ward_poverty, 1, 2, .)
label define ward_poverty 1 "Less than 10%" 2 "10%-20%" 3 "More than 20%"
label values ward_poverty ward_poverty

* clean variable labels
label variable id "Survey ID variable (deidentified)"
label variable female "Female gender (0/1)"
label variable age "Age"
label variable educ "Education level"
label variable literacy "Literacy (0/1)"
label variable married "Married (0/1)"
label variable children "Has children (0/1)"
label variable employed "Is currently employed (0/1)"
label variable survey_language "Language survey was conducted in"
label variable sex_age "Age at first sex"
label variable sex_partners_ever "Lifetime sex partners (n)"
label variable sex_partners_6mo "Sex partners in last 6 months (n)"
label variable sex_freq_1mo "Frequency of sex in last month (n)"
label variable sex_sti_test "Has been tested for STIs (0/1)"
label variable mc_broke "Has experienced a male condom break (0/1)"
label variable mc_z_opinion "Male condom attitudes index"
label variable mc_use_last "Used male condom at most recent sex (0/1)"
label variable pill_use_last "Used contraceptive pill at most recent sex (0/1)"
label variable iud_use_last "Used IUD at most recent sex (0/1)"
label variable inject_use_last "Used injectable at most recent sex (0/1)"
label variable implant_use_last "Used an implant at most recent sex (0/1)"
label variable diaphragm_use_last "Used diaphragm at most recent sex (0/1)"
label variable modern_use_last "Used a modern method at most recent sex (0/1)"
label variable cont_z_know "Contraceptive knowledge index"
label variable cont_know_modern "Modern contraceptive methods known (n)"
label variable cont_discussed "Discussed contraceptive use with recent partner (0/1)"
label variable cont_travel_30min "Must travel more than 30 min to get contraceptives (0/1)"
label variable fc_recognize "Can identify a female condom (0/1)"
label variable fc_try "Would be willing to try a female condom (0/1)"
label variable fc_z_opinion "Female condom attitudes index"
label variable fc_use_ever "Has ever used a female condom (0/1)"
label variable fc_use_6mo "Used a female condom in last 6 months (0/1)"
label variable fc_use_last "Used a female condom at most recent sex (0/1)"
label variable treatment "Treatment indicator (0/1)"
label variable endline "Endline survey indicator (0/1)"
label variable ipc_attend "Attended an IPC event (0/1)"
label variable ward "Ward of Lusaka"

foreach var in sex_sti_test mc_use_last cont_discussed cont_travel_30min fc_recognize fc_try {
	label values `var' yesno
}

* ------------ Create a dataset of ward-level baseline covariates ----------- */

preserve 
keep if endline
save "../Data/maximum_diva_endline.dta", replace
restore

preserve
keep if !endline
drop ipc_*
save "../Data/maximum_diva_baseline.dta", replace
restore


