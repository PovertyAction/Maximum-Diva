 * ---------------------------------------- *
 * file:    1_balance.do               
 * author:  Christopher Boyer              
 * project: Maximum Diva Women's Condom    
 * date:    2018-03-15                     
 * ---------------------------------------- *

 /* This file... */

use "../Data/maximum_diva_baseline.dta", clear

* --------------------- Check balance of randomization ---------------------- */

/* Create a table comparing baseline covariates of treatment and control 
   groups to assess whether randomization was successful and save  */
   
preserve 

local balance_vars_cont $continuous_covariates

* calculate clustered p-values
foreach var in $covariates {
	local is_cont : list var in balance_vars_cont	
	
	if `is_cont' {
		qui reg $treatment `var', cluster(ward)
		local p = 2 * ttail(e(df_r), abs(_b[`var'] / _se[`var']))
		local p_str = "`p_str' `p'"
		local t1_str "`t1_str' `var' contn \"
	}
	else {
		qui logit $treatment `var', cluster(ward)
		local p = 2 * normal(-abs(_b[`var'] / _se[`var']))
		local p_str = "`p_str' `p'"
		qui summ `var'
		if `r(max)' == 1 {
			local t1_str "`t1_str' `var' bin \"
		}
		else {
			local t1_str "`t1_str' `var' cat \"
		}
	}
}

* create table
table1, by($treatment) vars(`t1_str') format(%4.2f) clear

* adjust p-values for clustering
forval i = 3/`=_N' {
	if !mi(factor[`i']) {
		gettoken p p_str : p_str
		local p : display %4.3f `p'
		replace pvalue = "`p'" in `i'
	}
}

export excel using "../Tables/t1_balance.xlsx", replace

restore 

* ---------------- Randomization inference test for balance ----------------- */

*local remove fc_recognize fc_z_opinion sex_partners_ever sex_partners_6mo sex_freq_1mo cont_travel_30min
*local covariates : list global(covariates) - remove
*summ `covariates'
*ritest $treatment e(F), cluster(ward) reps(1000): reg $treatment `covariates', cluster(ward)

* -------------------- Check balance across survey waves -------------------- */

/* Create a table comparing baseline covariates of treatment and control 
   groups to assess whether randomization was successful and save  */
   
preserve 

use "../Data/maximum_diva_endline.dta", clear

local balance_vars_cont $continuous_covariates
local t1_str
local p_str

* calculate clustered p-values
foreach var in $covariates {
	local is_cont : list var in balance_vars_cont	
	
	if `is_cont' {
		qui reg $treatment `var', cluster(ward)
		local p = 2 * ttail(e(df_r), abs(_b[`var'] / _se[`var']))
		local p_str = "`p_str' `p'"
		local t1_str "`t1_str' `var' contn \"
	}
	else {
		qui logit $treatment `var', cluster(ward)
		local p = 2 * normal(-abs(_b[`var'] / _se[`var']))
		local p_str = "`p_str' `p'"
		qui summ `var'
		if `r(max)' == 1 {
			local t1_str "`t1_str' `var' bin \"
		}
		else {
			local t1_str "`t1_str' `var' cat \"
		}
	}
}

* create table
table1, by($treatment) vars(`t1_str') format(%4.2f) clear

* adjust p-values for clustering
forval i = 3/`=_N' {
	if !mi(factor[`i']) {
		gettoken p p_str : p_str
		local p : display %4.3f `p'
		replace pvalue = "`p'" in `i'
	}
}

export excel using "../Tables/t1_balance_endline.xlsx", replace

restore 

* ------------ Create a dataset of ward-level baseline covariates ----------- */

/* Calculate mean ward-level values of baseline covariates, save them
   to a tempfile, and merge them in with endline data for use in 
   impact regressions. */

preserve 

collapse (mean) $covariates, by(ward)

ds ward, not
ren (`r(varlist)') pre_=

save "../Data/maximum_diva_baseline_pooled.dta", replace

restore

