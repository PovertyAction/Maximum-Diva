 * ---------------------------------------- *
 * file:    5_robustness.do               
 * author:  Christopher Boyer              
 * project: Maximum Diva Women's Condom    
 * date:    2017-10-20                     
 * ---------------------------------------- *
 * outputs: 
 *   @Tables/t5_robust_diff.xlsx
 *	 @Tables/t5_robust_diff.dta
 *   @Tables/t5_robust_or.xlsx
 *	 @Tables/t5_robust_or.dta
 
use "../Data/maximum_diva_endline.dta", clear
merge m:1 ward using "../Data/maximum_diva_baseline_pooled.dta", nogen assert(3)
order $outcomes

* --------------- Define program for extracting relevant stats -------------- */ 

/* this program extracts and formats coefficient estimates and confidence
   interval after a regression. the parameters are:
   
   @variable - the name of the variable associated with the desired coef
   @format - the string format for nicely displaying the result
   @eform - flag to exponentiate the coeff/ci (optional) */
   
cap program drop get_stats
program define get_stats, rclass

	args variable format eform
	
	local b = _b[`variable']
	local se = _se[`variable']
	
	if e(cmd) == "regress" {
		local p = 2 * ttail(e(df_r), abs(`b' / `se'))
	}
	else {
		local p = 2 * normal(-abs(`b' / `se'))
	}
	
	local ci_low = `b' - 1.96 * `se'
	local ci_high = `b' + 1.96 * `se'
	
	if !mi("`eform'") {
		local b = exp(`b')
		local ci_low = exp(`ci_low')
		local ci_high = exp(`ci_high')
	}
	
	return local p = "`: display `format' `p''"
	return local b = trim(cond(`p' > 0.1, "`: display `format' `b''", ///
			cond(`p' <= 0.1 & `p' > 0.05, "`: display `format' `b''+", ///
			cond(`p' <= 0.05 & `p' > 0.01, "`: display `format' `b''*", ///
			cond(`p' <= 0.01 & `p' > 0.001, "`: display `format' `b''**", ///
			"`: display `format' `b''`r(b)'***")))))

	return local ci = "(" + trim("`: display `format' `ci_low''") + ", " + ///
		trim("`: display `format' `ci_high''") + ")"
end

* -------------------- Check robustness of results: ATE --------------------- */

/* Here we check the robustness of ITT results to different modeling 
   assumptions. Namely, we compare:
   
   OLS regression with clustered SEs (original specification)
   OLS regression with ward-level pooled estimates
   General Estimating Equations (GEE) 
   Hierarchical Linear Modeling (HLM) with ward-level intercepts */

xtset ward

tempname pf
tempfile tmp
postfile `pf' str60(var rd1 rd1_ci rd2 rd2_ci rd3 rd3_ci rd4 rd4_ci) using "`tmp'"
	
post `pf' ("") ("OLS, Clustered SEs") ("") ("OLS, Pooled") ("") ("GEE") ("") ///
	("HLM, Ward Intercepts") ("")
post `pf' ("Outcome") ("RD") ("95% CI") ("RD") ("95% CI") ("RD") ("95% CI") ///
	("RD") ("95% CI")


foreach outcome in $outcomes {
	local is_cont : list outcome in global(continuous_covariates)	

	reg `outcome' $treatment $controls pre_`outcome', cluster(ward)
	get_stats $treatment "%9.3f"
	local rd1 = "`r(b)'"
	local rd1_ci = "`r(ci)'"
	
	preserve
	local controls = subinstr("${controls}", "i.", "", .)
	collapse (mean) `outcome' $treatment `controls' pre_`outcome', by(ward)
	reg `outcome' $treatment `controls' pre_`outcome', robust
	get_stats $treatment "%9.3f"
	local rd2 = "`r(b)'"
	local rd2_ci = "`r(ci)'"
	restore
	
	xtgee `outcome' $treatment $controls pre_`outcome',
	get_stats $treatment "%9.3f"
	local rd3 = "`r(b)'"
	local rd3_ci = "`r(ci)'"
		
	mixed `outcome' $treatment $controls pre_`outcome' || ward:
	get_stats $treatment "%9.3f"
	local rd4 = "`r(b)'"
	local rd4_ci = "`r(ci)'"
	
	post `pf' ("`: variable label `outcome''") ("`rd1'") ("`rd1_ci'") ///
		("`rd2'") ("`rd2_ci'") ("`rd3'") ("`rd3_ci'") ("`rd4'") ("`rd4_ci'")

}

postclose `pf'

preserve
use "`tmp'", clear
export excel using "../Tables/t5_robust_diff.xlsx", replace
save "../Tables/t5_robust_diff.dta", replace
restore

* ------------------ Check robustness of results: ATE (OR) ------------------ */

/* Here we check the robustness of ITT results to different modeling 
   assumptions with the OR as our primary estimate of interest. This time
   we compare:
   
   Logistic regression with clustered SEs (original specification)
   General Estimating Equations (GEE) with logistic link function
   Logistic Hierarchical Linear Modeling (HLM) with ward-level intercepts */
   
tempname pf
tempfile tmp
postfile `pf' str60(var or1 or1_ci or2 or2_ci or3 or3_ci) using "`tmp'"
	
post `pf' ("") ("Logit, Clustered SEs") ("") ("GEE, Binomial") ("") ///
	("HLM Logit, Ward Intercepts") ("")
post `pf' ("Outcome") ("OR") ("95% CI") ("OR") ("95% CI") ("OR") ("95% CI")

local binary_outcomes : list global(outcomes) - global(continuous_covariates)	

foreach outcome in `binary_outcomes' {
	local is_cont : list outcome in global(continuous_covariates)	

	logit `outcome' $treatment $controls pre_`outcome', cluster(ward)
	get_stats $treatment "%9.2f" eform
	local or1 = "`r(b)'"
	local or1_ci = "`r(ci)'"
	
	xtgee `outcome' $treatment $controls pre_`outcome', family(binomial) link(logit)
	get_stats $treatment "%9.2f" eform
	local or2 = "`r(b)'"
	local or2_ci = "`r(ci)'"
		
	melogit `outcome' $treatment $controls pre_`outcome' || ward:
	get_stats $treatment "%9.2f" eform
	local or3 = "`r(b)'"
	local or3_ci = "`r(ci)'"
	
	post `pf' ("`: variable label `outcome''") ("`or1'") ("`or1_ci'") ///
		("`or2'") ("`or2_ci'") ("`or3'") ("`or3_ci'")
}

postclose `pf'

preserve
use "`tmp'", clear
export excel using "../Tables/t5_robust_or.xlsx", replace
save "../Tables/t5_robust_or.dta", replace
restore

* -------------------- Check robustness of results: CACE -------------------- */

/* Here we check the robustness of CACE results to different modeling 
   assumptions. Namely, we compare:
   
   Propensity score matched (IPW) baseline controls
   Propensity score matched (IPW) endline controls
   Propensity score matched (1:M) baseline controls
   Propensity score matched (1:M) endline controls
   Per protocol  */


 
* ------------------ Check robustness of results: CACE (OR) ----------------- */

/* Here we check the robustness of CACE results to different modeling 
   assumptions. Namely, we compare:
   
   Propensity score matched (IPW) baseline controls
   Propensity score matched (IPW) endline controls
   Propensity score matched (1:M) baseline controls
   Propensity score matched (1:M) endline controls
   Per protocol  */
