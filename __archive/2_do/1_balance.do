 * ---------------------------------------- *
 * file:    1_balance.do               
 * author:  Christopher Boyer              
 * project: Maximum Diva Women's Condom    
 * date:    2018-03-15                     
 * ---------------------------------------- *
 * outputs: 
 *   @Tables/t1_balance.xlsx
 *	 @Tables/t1_balance.dta
 *	 @Data/maximum_diva_baseline_pooled.dta 
 
use "../Data/maximum_diva_baseline.dta", clear

* --------------------- Check balance of randomization ---------------------- */

/* Create a table comparing baseline covariates of treatment and control 
   groups to assess whether randomization was successful and save  */
   
   
 /************
  PART 1: INDIVIDUAL CHARACTERISTICS 
 *************/
 
preserve 

unab ward_level_covariates : ward_poverty ward_pop_density
local covariates : list global(covariates) - ward_level_covariates

* calculate clustered p-values
foreach var in `covariates' {
	local is_cont : list var in global(continuous_covariates)	
	
	if `is_cont' {
		qui reg $treatment `var', cluster(ward)
		
		local p = 2 * ttail(e(df_r), abs(_b[`var'] / _se[`var']))
		local f_p = trim( ///
			cond(`p' > 0.1, "`: display %4.3f `p''", ///
			cond(`p' <= 0.1 & `p' > 0.05, "`: display %4.3f `p''+", ///
			cond(`p' <= 0.05 & `p' > 0.01, "`: display %4.3f `p''*", ///
			cond(`p' <= 0.01 & `p' > 0.001, "`: display %4.3f `p''**", ///
				"`: display %4.3f `p''***")))))
		
		local p_str = "`p_str' `f_p'"
		local t1_str "`t1_str' `var' contn \"
	}
	
	else {
		qui logit $treatment `var', cluster(ward)
		
		local p = 2 * normal(-abs(_b[`var'] / _se[`var']))
		local f_p = trim( ///
			cond(`p' > 0.1, "`: display %4.3f `p''", ///
			cond(`p' <= 0.1 & `p' > 0.05, "`: display %4.3f `p''+", ///
			cond(`p' <= 0.05 & `p' > 0.01, "`: display %4.3f `p''*", ///
			cond(`p' <= 0.01 & `p' > 0.001, "`: display %4.3f `p''**", ///
				"`: display %4.3f `p''***")))))
		
		local p_str = "`p_str' `f_p'"
		
		qui summ `var'
		if `r(max)' == 1 {
			local t1_str "`t1_str' `var' bin \"
		}
		else {
			local t1_str "`t1_str' `var' cat \"
		}
	}
}

* this variable just reverses the order of treatment and control in the 
* output table so treatment is the first column.
g reverse_treatment = -(${treatment} - 1)

* create table
table1, by(reverse_treatment) vars(`t1_str') format(%4.2f) clear onecol

* adjust p-values for clustering
forval i = 3/`=_N' {
	if substr(factor[`i'], 1, 1) != " " {
		gettoken p p_str : p_str
		replace pvalue = "`p'" in `i'
	}
}

tempfile tmp1
save "`tmp1'"

restore 

 /************
  PART 2: WARD-LEVEL CHARACTERISTICS 
 *************/

preserve
keep `ward_level_covariates' $treatment ward
bys ward : keep if _n == 1

* this variable just reverses the order of treatment and control in the 
* output table so treatment is the first column.
g reverse_treatment = -(${treatment} - 1)

foreach var in `ward_level_covariates' {
	local is_cont : list var in global(continuous_covariates)	

	if `is_cont' {
		local t1b_str "`t1b_str' `var' contn \"
	}
	else {
		qui summ `var'
		if `r(max)' == 1 {
			local t1b_str "`t1b_str' `var' bin \"
		}
		else {
			local t1b_str "`t1b_str' `var' cat \"
		}
	}
}

* create table
table1, by(reverse_treatment) vars(`t1b_str') format(%4.2f) clear onecol

drop if _n == 1
tempfile tmp2
save "`tmp2'"

restore 

 /************
  MERGE AND FORMAT 
 *************/

preserve
use "`tmp1'", clear
append using "`tmp2'"

replace factor = "Baseline Individual Characteristics" in 2
replace reverse_treatment0 = "Treatment" in 1
replace reverse_treatment1 = "Control" in 1
replace reverse_treatment0 = "N = " + reverse_treatment0 in 2
replace reverse_treatment1 = "N = " + reverse_treatment1 in 2
replace factor = "Ward-Level Characteristics" in 35
replace reverse_treatment0 = "N = " + reverse_treatment0 in 35
replace reverse_treatment1 = "N = " + reverse_treatment1 in 35

save "`tmp1'", replace
restore

* ---------------- Randomization inference test for balance ----------------- */

/* This section uses randomization inference methods to test for balanced 
   cluster-randomization. It simulates 100,000 random ward-level treatment 
   assignments and regresses a vector of covariates on the treatment
   indicator. For each regression the F-statistic comparing the fitted model
   to the null model (just the treatment and intecept terms) is computed. We 
   use these to simulate the exact sampling distribution of F and test the null 
   hypothesis that the covariates predict the observed treatment assignment no
   better than would be expected by chance. For reference see:
       
     Hansen & Bowers (2008). "Covariate Balance in Simple, Stratified and
	   Clustered Comparative Studies". Statistical Science. 23:2:219-236 */
  
preserve 

* We remove a few variables with missing values that dramatically reduce the 
* number of observations in the full model.
local remove ///     
	fc_recognize /// 
	fc_z_opinion ///
	sex_partners_ever ///
	sex_partners_6mo ///
	sex_freq_1mo ///
	cont_travel_30min
	
local covariates : list global(covariates) - remove

* NOTE: THIS SIMULATION TAKES A WHILE TO RUN
if $run_balance_simulation {
	set rmsg on
	ritest $treatment e(F), cluster(ward) reps(100000) seed(152844): ///
		reg $treatment `covariates', cluster(ward)
	set rmsg off
	* save formatted results
	matrix ri_p = r(p)
	matrix ri_F = r(b)
	
	local p = ri_p[1,1]
	local F = ri_F[1,1]
	
	local ri_p = trim( ///
		cond(`p' > 0.1, "`: display %4.3f `p''", ///
		cond(`p' <= 0.1 & `p' > 0.05, "`: display %4.3f `p''+", ///
		cond(`p' <= 0.05 & `p' > 0.01, "`: display %4.3f `p''*", ///
		cond(`p' <= 0.01 & `p' > 0.001, "`: display %4.3f `p''**", ///
			"`: display %4.3f `p''***")))))
		
	local ri_F = trim("`: display %4.2f `F''")
}


 /************
  ADD TO TABLE
 *************/
 
use "`tmp1'", clear
local rows = _N
set obs `=`rows' + 2'

replace factor = "Joint Test for Balance" in `=`rows' + 1'
replace factor = "F-statistic" in `=`rows' + 2'
replace reverse_treatment1 = "`ri_F'" in `=`rows' + 2'
replace pvalue = "`ri_p'" in `=`rows' + 2'

export excel using "../Tables/t1_balance.xlsx", replace
save "../Tables/t1_balance.dta", replace

restore

* -------------------- Check balance across survey waves -------------------- */

/* Create a table comparing baseline covariates of treatment and control 
   groups to assess whether randomization was successful and save  
   
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
*/

* ------------ Create a dataset of ward-level baseline covariates ----------- */

/* Calculate mean ward-level values of baseline covariates, save them
   to a file so that they may be merged in with endline data for use in
   subsequent impact regressions to control for baseline characteristics 
   at the ward level. */

preserve 

collapse (mean) $covariates, by(ward)

ds ward, not
ren (`r(varlist)') pre_=

save "../Data/maximum_diva_baseline_pooled.dta", replace

restore

