 * ---------------------------------------- *
 * file:    3_heterogeneity.do               
 * author:  Christopher Boyer              
 * project: Maximum Diva Women's Condom    
 * date:    2017-10-20                     
 * ---------------------------------------- *
 * outputs: 
 *   @Tables/t3_hetero_${subgroup}.xlsx
 *	 @Tables/t3_hetero_${subgroup}.dta
 
use "../Data/maximum_diva_endline.dta", clear
merge m:1 ward using "../Data/maximum_diva_baseline_pooled.dta", nogen assert(3)
order $outcomes

* ---------------------- Define programs for formatting --------------------- */

cap program drop estimate_contrasts
program estimate_contrasts, rclass
	args treatment group
	
	if e(cmd) == "regress" {
		qui lincom 1.`treatment' 
		local est0 = `r(estimate)'
		local estf0 = "`: display %9.2f `=100*`est0'''" + "%"
		local est0_se = `r(se)'
		local est0_ci_lb = `r(estimate)' + invnorm(0.025) * `r(se)'
		local est0_ci_ub = `r(estimate)' + invnorm(0.975) * `r(se)'
		local est0_df = `r(df)'
		local est0_p = 2 * ttail(`est0_df', abs(`est0' / `est0_se'))
		
		qui lincom 1.`treatment' + 1.`treatment'#1.`group'
		local est1 = `r(estimate)'
		local estf1 = "`: display %9.2f `=100*`est1'''" + "%"
		local est1_se = `r(se)'
		local est1_ci_lb = `r(estimate)' + invnorm(0.025) * `r(se)'
		local est1_ci_ub = `r(estimate)' + invnorm(0.975) * `r(se)'
		local est1_df = `r(df)'
		local est1_p = 2 * ttail(`est1_df', abs(`est1' / `est1_se'))

		qui lincom 1.`treatment'#1.`group'
		local diff_p = 2 * ttail(`r(df)', abs(`r(estimate)' / `r(se)'))
		
		return local rd_g0 = cond(`est0_p' > 0.05, "`estf0'", ///
			cond(`est0_p' <= 0.05 & `est0_p' > 0.01, "`estf0'*", ///
			cond(`est0_p' <= 0.01 & `est0_p' > 0.001, "`estf0'**", "`estf0'***")))
			
		return local rd_g0_95 = "(" + trim("`: display %9.2f `=100*`est0_ci_lb'''") + ///
			"%, " + trim("`: display %9.2f `=100*`est0_ci_ub'''") + "%)"
		
		return local rd_g1 = cond(`est1_p' > 0.05, "`estf1'", ///
			cond(`est1_p' <= 0.05 & `est1_p' > 0.01, "`estf1'*", ///
			cond(`est1_p' <= 0.01 & `est1_p' > 0.001, "`estf1'**", "`est1f'***")))
			
		return local rd_g1_95 = "(" + trim("`: display %9.2f `=100*`est1_ci_lb'''") + ///
			"%, " + trim("`: display %9.2f `=100*`est1_ci_ub'''") + "%)"
			
		return local rd_p = "`: display %4.3f `diff_p''"
	}
	else if e(cmd) == "logit" {
		qui lincom 1.`treatment' 
		local est0 = `r(estimate)'
		local eform0 = `: display %9.2f `=exp(`est0')''
		local est0_se = `r(se)'
		local est0_ci_lb = exp(`r(estimate)' + invnorm(0.025) * `r(se)')
		local est0_ci_ub = exp(`r(estimate)' + invnorm(0.975) * `r(se)')
		local est0_p = 2 * normal(-abs(`est0' / `est0_se'))
		
		qui lincom 1.`treatment' + 1.`treatment'#1.`group'
		local est1 = `r(estimate)'
		local eform1 = `: display %9.2f `=exp(`est1')''
		local est1_se = `r(se)'
		local est1_ci_lb = exp(`r(estimate)' + invnorm(0.025) * `r(se)')
		local est1_ci_ub = exp(`r(estimate)' + invnorm(0.975) * `r(se)')
		local est1_p = 2 * normal(-abs(`est1' / `est1_se'))

		qui lincom 1.`treatment'#1.`group'
		local diff_p = 2 * normal(-abs(`r(estimate)' / `r(se)'))
		
		return local or_g0 = cond(`est0_p' > 0.05, "`eform0'", ///
			cond(`est0_p' <= 0.05 & `est0_p' > 0.01, "`eform0'*", ///
			cond(`est0_p' <= 0.01 & `est0_p' > 0.001, "`eform0'**", "`eform0'***")))
			
		return local or_g0_95 = "(" + trim("`: display %9.2f `est0_ci_lb''") + ///
			", " + trim("`: display %9.2f `est0_ci_ub''") + ")"
			
		return local or_g1 = cond(`est1_p' > 0.05, "`eform1'", ///
			cond(`est1_p' <= 0.05 & `est1_p' > 0.01, "`eform1'*", ///
			cond(`est1_p' <= 0.01 & `est1_p' > 0.001, "`eform1'**", "`eform1'***")))
		
		return local or_g1_95 = "(" + trim("`: display %9.2f `est1_ci_lb''") + ///
			", " + trim("`: display %9.2f `est1_ci_ub''") + ")"
			
		return local or_p = "`: display %4.3f `diff_p''"
	}
end

* --------------------- Check for heterogeneous effects --------------------- */

/************
  Q2. Are these IPC events more effective among certain subgroups or 
  subpopulations? 
*************/

foreach group in $subgroups {
	eststo clear
	local controls $controls
	local controls : list controls - group
	
	tempname pf
	tempfile tmp
	postfile `pf' str60(var) str17(grp0_rd grp0_rd_95 grp0_or grp0_or_95) ///
		str17(grp1_rd grp1_rd_95 grp1_or grp1_or_95 p) using "`tmp'"
	
	post `pf' ("") ("`: label (`group') 0'") ("") ("") ("") ("`: label (`group') 1'") ("") ("") ("") ("")
	post `pf' ("Outcome") ("RD") ("95% CI") ("OR") ("95% CI") ("RD") ("95% CI") ("OR") ("95% CI") ("P-value") 

	foreach outcome in $outcomes {
		local is_cont : list outcome in global(continuous_covariates)	
		
		reg `outcome' ${treatment}##`group' `controls' pre_`outcome' i.block, cluster(ward)
		estimate_contrasts $treatment `group'

		local rd_g0 = "`r(rd_g0)'"
		local rd_g0_95 = "`r(rd_g0_95)'"
		local rd_g1 = "`r(rd_g1)'"
		local rd_g1_95 = "`r(rd_g1_95)'"
		local p = "`r(rd_p)'"

		if !`is_cont' {
			logit `outcome' ${treatment}##`group' `controls' pre_`outcome' i.block, cluster(ward)
			estimate_contrasts $treatment `group'
			local p = "`r(or_p)'"
		}
		post `pf' ("`: variable label `outcome''") ("`rd_g0'") ("`rd_g0_95'") ///
			("`r(or_g0)'") ("`r(or_g0_95)'") ("`rd_g1'") ("`rd_g1_95'") ///
			("`r(or_g1)'") ("`r(or_g1_95)'") ("`p'")
	}
	postclose `pf'
	
	preserve
	use "`tmp'", clear
	export excel using "../Tables/t3_hetero_`group'.xlsx", replace
	save "../Tables/t3_hetero_`group'.dta", replace
	restore
}

