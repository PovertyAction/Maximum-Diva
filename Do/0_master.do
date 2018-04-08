 * ---------------------------------------- *
 * file:    0_master.do               
 * author:  Christopher Boyer              
 * project: Maximum Diva Women's Condom    
 * date:    2018-03-15                     
 * ---------------------------------------- *

 clear all
 set more off
 macro drop _all
 version 15

 * -------------------------- Global analysis flags ------------------------- */

* NOTE: RUNNING SIMULATION TAKES AT LEAST 2 HOURS
global run_balance_simulation = 0 // (0/1) flag to run randomization inference

 * -------------------------- Define variable lists ------------------------- */

/* The following variable lists are defined as a convenience to make the analysis 
   more easily replicated, repeated and/or extended:
     covariates            - baseline covariates which are to be checked for balance
     continuous_covariates - identifies continuous covariates 
	 outcomes              - program outcomes to be assessed for impact
	 treatment             - variable identifying treatment status of obs 
	 tot                   - variable capturing treatment obs who received treatment
	 subgroups             - variables identify relevant subgroups for heterogeneity
	 controls              - controls to be adjusted for in all regressions */
   
global covariates ///
	female age educ literacy married children employed survey_language ///
	ward_poverty ward_pop_density ///
	sex_age sex_partners_ever sex_partners_6mo sex_freq_1mo sex_sti_test ///
	mc_broke mc_z_opinion mc_use_last ///
	cont_z_know cont_know_modern cont_discussed cont_travel_30min ///
	fc_recognize fc_try fc_z_opinion fc_use_ever fc_use_6mo fc_use_last ///
	
global continuous_covariates ///
    age ward_pop_density sex_age sex_partners_ever sex_partners_6mo sex_freq_1mo ///
	cont_z_know cont_know_modern mc_z_opinion fc_z_opinion

global outcomes ///
    mc_use_last mc_z_opinion fc_recognize fc_try fc_z_opinion fc_use_ever ///
	fc_use_6mo fc_use_last cont_z_know cont_know_modern cont_discussed 
	/*pill_use_last iud_use_last inject_use_last implant_use_last /// 
	diaphragm_use_last modern_use_last*/

global treatment ///
    treatment

global endline ///
    endline

global partial_treatment ///
    ipc_attendance_local
	
global tot ///
	ipc_attend 

global subgroups ///
    female married

global controls ///
    female age i.educ married literacy employed i.survey_language i.ward_poverty

 * -------------------------- Run analysis code -------------------------- */

do "1_balance.do"       // check baseline balance
do "2_itt.do"           // perform ITT regressions
do "3_heterogeneity.do" // assess effect heterogeneity 
do "4_tot.do"           // perform TOT/CACE regressions
do "5_robustness.do"    // check robustness of results
do "6_figures.do"       // create figures 
do "7_make_document.do" // create document 
do "8_make_appendix.do" // create appendix
