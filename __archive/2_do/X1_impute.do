 * ---------------------------------------- *
 * file:    0_impute.do               
 * author:  Christopher Boyer              
 * project: Maximum Diva Women's Condom    
 * date:    2017-10-20                     
 * ---------------------------------------- *
 
 /* this file imputes multiple values for missing survey
    responses using the chained equations estimator from
	the -mi- system. we impute 50 random data sets to increase
	stability of pooled estimates (caution takes a while to run).
 */
 
use "../Data/maximum_diva_baseline.dta", clear
append using "../Data/maximum_diva_endline.dta"

* ------------------------ Impute values for missing ------------------------ */

// set the random seed
set seed 504284217

ds, has(type numeric)
local numeric `r(varlist)'
recode `numeric' (.d = .)
recode `numeric' (.r = .)

// register the variables with missing values to be imputed
mi set wide
mi xtset, clear
mi register imputed              ///
            educ                 ///
			children             ///
			sex_age              ///
			sex_partners_ever    ///
			sex_partners_6mo     ///
			sex_freq_1mo		 ///	
			sex_sti_test         ///
			mc_z_opinion         ///
			cont_discussed       ///	
			cont_travel_30min			

mi misstable summarize 

// impute 50 data sets
mi impute chained                                              ///
    (mlogit)  educ                                             ///
    (logit)   children cont_discussed                          ///
	(poisson) sex_partners_ever sex_partners_6mo sex_freq_1mo  ///	                                    ///
	(regress) sex_age mc_z_opinion =                           ///
		female age married literacy employed survey_language ward, ///
		add(50) augment dots


* ------------------------------ Save results ------------------------------- */

preserve 
keep if endline
save "../Data/maximum_diva_endline_imputed.dta", replace
restore

preserve
keep if !endline
drop ipc_*
save "../Data/maximum_diva_baseline_imputed.dta", replace
restore

