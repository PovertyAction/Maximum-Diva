 * ---------------------------------------- *
 * file:    2_itt.do               
 * author:  Christopher Boyer              
 * project: Maximum Diva Women's Condom    
 * date:    2017-10-20                     
 * ---------------------------------------- *

 
use "../Data/maximum_diva_endline.dta", clear
merge m:1 ward using "../Data/maximum_diva_baseline_pooled.dta", nogen assert(3)

* --------------------------- Prepare output file --------------------------- */

tempname pf
tempfile tmp

* create post file
postfile `pf' str60(var mean0 mean1 crude_rd crude_rd_95 crude_or ///
	crude_or_95 adj_rd adj_rd_95 adj_or adj_or_95) using "`tmp'"
	
* create table header
post `pf' ("") ("") ("") ("Crude") ("") ("") ("") ("Adjusted") ("") ("") ("")
post `pf' ("Outcome") ("Control") ("Treatment") ("RD") ("95% CI") ("OR") ///
	("95% CI") ("RD") ("95% CI") ("OR") ("95% CI")

* ------------------------ Run ITT regressions of ATE ----------------------- */

/************
  Q1. At the ward level, are IPC events effective at improving knowledge 
  and use of contraception over and above PSI's advertising campaigns? 
*************/

foreach outcome in $outcomes {
	local is_cont : list outcome in global(continuous_covariates)	

	/************
	 Crude: y = b0 + b1 * treatment 
	*************/
	reg `outcome' $treatment, cluster(ward)
	local crude_rd = _b[${treatment}]
	local crude_rd_ci_low = _b[${treatment}] - 1.96 * _se[${treatment}]
	local crude_rd_ci_high = _b[${treatment}] + 1.96 * _se[${treatment}]
	local crude_rd_p = 2*ttail(e(df_r), abs(_b[${treatment}]/_se[${treatment}]))

	/************
	 Adjusted: y = b0 + b1 * treatment + b2 * controls + b3 * baseline
	*************/
	reg `outcome' $treatment $controls pre_`outcome', cluster(ward)
	local adj_rd = _b[${treatment}]
	local adj_rd_ci_low = _b[${treatment}] - 1.96 * _se[${treatment}]
	local adj_rd_ci_high = _b[${treatment}] + 1.96 * _se[${treatment}]
	local adj_rd_p = 2*ttail(e(df_r), abs(_b[${treatment}]/_se[${treatment}]))

	if !`is_cont' {
		/************
		 Crude: logit y = b0 + b1 * treatment 
		*************/
		logit `outcome' $treatment, cluster(ward) or
		local crude_or = exp(_b[${treatment}])
		local crude_or_ci_low = exp(_b[${treatment}] - 1.96 * _se[${treatment}])
		local crude_or_ci_high = exp(_b[${treatment}] + 1.96 * _se[${treatment}])
		local crude_or_p = 2 * normal(-abs(_b[${treatment}] / _se[${treatment}]))

		/************
		 Adjusted: logit y = b0 + b1 * treatment + b2 * controls + b3 * baseline
		*************/
		logit `outcome' $treatment $controls pre_`outcome', cluster(ward) or
		local adj_or = exp(_b[${treatment}])
		local adj_or_ci_low = exp(_b[${treatment}] - 1.96 * _se[${treatment}])
		local adj_or_ci_high = exp(_b[${treatment}] + 1.96 * _se[${treatment}])	
		local adj_or_p = 2 * normal(-abs(_b[${treatment}] / _se[${treatment}]))

	}
	
	* create formatted output for ATEs
	foreach est in crude_rd adj_rd {
		local f_`est' : display %9.3f ``est''
		local f_`est' = cond(``est'_p' > 0.1, "`f_`est''", ///
			cond(``est'_p' <= 0.1 & ``est'_p' > 0.05, "`f_`est''+", ///
			cond(``est'_p' <= 0.05 & ``est'_p' > 0.01, "`f_`est''*", ///
			cond(``est'_p' <= 0.01 & ``est'_p' > 0.001, "`f_`est''**", ///
			"`f_`est''***"))))
		local f_`est'_ci = "(" + trim("`: display %9.3f ``est'_ci_low''") + ///
			", " + trim("`: display %9.3f ``est'_ci_high''") + ")"
	}
	
	* create formatted output for ORs
	if !`is_cont' {
		foreach est in crude_or adj_or {
			local f_`est' : display %9.2f ``est''
			local f_`est' = cond(``est'_p' > 0.1, "`f_`est''", ///
				cond(``est'_p' <= 0.1 & ``est'_p' > 0.05, "`f_`est''+", ///
				cond(``est'_p' <= 0.05 & ``est'_p' > 0.01, "`f_`est''*", ///
				cond(``est'_p' <= 0.01 & ``est'_p' > 0.001, "`f_`est''**", ///
				"`f_`est''***")))) 
			local f_`est'_ci = "(" + trim("`: display %9.2f ``est'_ci_low''") + ///
				", " + trim("`: display %9.2f ``est'_ci_high''") + ")"
		}
	}
	else {
		local f_crude_or = ""
		local f_crude_or_ci = ""
		local f_adj_or = ""
		local f_adj_or_ci = ""
	}
	
	* outcome means
	if `is_cont' {
		summ `outcome' if ${treatment}
		local mean1 = trim("`:display %9.2f `r(mean)''") + " (" + ///
			trim("`:display %9.2f `r(sd)''") + ")"
		summ `outcome' if !${treatment}
		local mean0 = trim("`:display %9.2f `r(mean)''") + " (" + ///
			trim("`:display %9.2f `r(sd)''") + ")"	
	}
	else {
		tab ${treatment} `outcome', matcell(X)
		local mean1 = trim("`:display %9.0f `=X[2,2]''") + ///
			" (" + trim("`:display %9.2f `=100*X[2,2]/(X[2,1]+X[2,2])''") + "%)"
		local mean0 = trim("`:display %9.0f `=X[1,2]''") + ///
			" (" + trim("`:display %9.2f `=100*X[1,2]/(X[1,1]+X[1,2])''") + "%)"
	}
			
	post `pf' ("`: variable label `outcome''") ("`mean0'") ("`mean1'") ///
		("`f_crude_rd'") ("`f_crude_rd_ci'") ///
		("`f_crude_or'") ("`f_crude_or_ci'") ///
		("`f_adj_rd'") ("`f_adj_rd_ci'") ///
		("`f_adj_or'") ("`f_adj_or_ci'") 
}	

postclose `pf'
use "`tmp'", clear
export excel using "../Tables/t2_ITT.xlsx", replace
