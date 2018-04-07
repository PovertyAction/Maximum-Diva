 * ---------------------------------------- *
 * file:    4_tot.do               
 * author:  Christopher Boyer              
 * project: Maximum Diva Women's Condom    
 * date:    2017-10-20                     
 * ---------------------------------------- *


/* TO DO: Change the TOT effect analysis to use IV regressions to handle 
   non compliance in presence of selection bias. */

use "../Data/maximum_diva_endline.dta", clear
append using "../Data/maximum_diva_baseline.dta"
merge m:1 ward using "../Data/maximum_diva_baseline_pooled.dta", nogen assert(3)

local balance_vars_cont $continuous_covariates

* --------------------------- Run TOT regressions -------------------------- */
/*
/************
  Q3. Did wards with more sessions perform better than wards with less sessions
  in improving knowledge and use of contraception (i.e. dose-response)? 
*************/

replace $partial_treatment = 0 if !$treatment

foreach outcome in $outcomes {
	eststo clear
	local is_cont : list outcome in balance_vars_cont	

	if `is_cont' {
		eststo: reg `outcome' $partial_treatment $controls pre_`outcome', cluster(ward)
		outreg2 [*] using "../Tables/t4_Dose.xls", ///
			excel label ctitle("`outcome'", "OLS")
	}
	else {
		eststo: logit `outcome' $partial_treatment $controls pre_`outcome', cluster(ward)
		outreg2 [*] using "../Tables/t4_Dose.xls", ///
			excel label ctitle("`outcome'", "Logit") eform
	}
}
*/

/************
  Q4. Among those who actually attended an IPC event, were they effective at 
  improving knowledge and use of contraception? 
*************/

/* method 1 - Instrumental Variables 
foreach outcome in $outcomes {
	ivregress liml fc_use_last ($tot = $treatment), ///
		vce(cluster ward) 
}

can't use because the correlation between random assignment and attendance 
variable isn't sufficiently strong. 
*/

/* method 2 - Propensity Score Matching 

   TO DO: could possibly improve this by using Random Forest to predict 
   treatment and then run IPW regression. */

keep if !endline | $tot
replace $tot = 0 if mi($tot)

tempname pf
tempfile tmp
postfile `pf' str60(var mean0 mean1 rd rd_95 or or_95) using "`tmp'"
	
post `pf' ("") ("Control") ("Treatment") ("CACE") ("") ("") ("")
post `pf' ("Outcome") ("") ("") ("RD") ("95% CI") ("OR") ("95% CI")

set seed 82749
local remove fc_use_last // too few obs
local outcomes : list global(outcomes) - remove
foreach outcome in `outcomes' {
	local is_cont : list outcome in global(continuous_covariates)	

	teffects ipwra (`outcome') ($tot $controls ward), ///
		vce(robust) atet

	local p = 2 * normal(-abs(_b[r1vs0.${tot}] / _se[r1vs0.${tot}]))
	local rd = "`: display %9.2f `=_b[r1vs0.${tot}]''"
	
	local rd_ci_low = "`: display %9.2f `=_b[r1vs0.${tot}] - 1.96 * _se[r1vs0.${tot}]''"
	local rd_ci_high = "`: display %9.2f `=_b[r1vs0.${tot}] + 1.96 * _se[r1vs0.${tot}]''"
	
	local f_rd = cond(`p' > 0.05, "`rd'", ///
		cond(`p' <= 0.05 & `p' > 0.01, "`rd'*", ///
		cond(`p' <= 0.01 & `p' > 0.001, "`rd'**", "`rd'***"))) 
		
	local f_rd_ci = ///
		"(" + trim("`rd_ci_low'") + ", " + trim("`rd_ci_high'") + ")"
				
	if !`is_cont' {
		teffects ipwra (`outcome', logit) ($tot $controls ward), ///
			vce(robust) atet
			
		local p = 2 * normal(-abs(_b[r1vs0.${tot}] / _se[r1vs0.${tot}]))
		local or =  ///
			(_b[r1vs0.${tot}] + _b[POmean:0.${tot}]) / ///
			(1 - (_b[r1vs0.${tot}] + _b[POmean:0.${tot}])) /  ///
			(_b[POmean:0.${tot}] / (1 - _b[POmean:0.${tot}]))
			
		local or_ci_low = ///
			(_b[r1vs0.${tot}] - 1.96 * _se[r1vs0.${tot}] + _b[POmean:0.${tot}]) / ///
			(1 - (_b[r1vs0.${tot}] - 1.96 * _se[r1vs0.${tot}] + _b[POmean:0.${tot}])) /  ///
			(_b[POmean:0.${tot}] / (1 - _b[POmean:0.${tot}]))

		local or_ci_high = ///
			(_b[r1vs0.${tot}] + 1.96 * _se[r1vs0.${tot}] + _b[POmean:0.${tot}]) / ///
			(1 - (_b[r1vs0.${tot}] + 1.96 * _se[r1vs0.${tot}] + _b[POmean:0.${tot}])) /  ///
			(_b[POmean:0.${tot}] / (1 - _b[POmean:0.${tot}]))	
		
		local f_or = cond(`p' > 0.05, "`: display %9.2f `or''", ///
			cond(`p' <= 0.05 & `p' > 0.01, "`: display %9.2f `or''*", ///
			cond(`p' <= 0.01 & `p' > 0.001, "`: display %9.2f `or''**", ///
			"`: display %9.2f `or''***")))
			
		local f_or_ci = ///			
			"(" + trim("`: display %9.2f `or_ci_low''") + ", " +  ///
			trim("`: display %9.2f `or_ci_high''") + ")"
	}
	else {
		local f_or = ""
		local f_or_ci = ""
	}
	
	tebalance summarize `outcome', baseline
	matrix table = r(table)
	local mean0 = "`: display %9.2f `=table[1,1]''"
	local mean1 = "`: display %9.2f `=table[1,2]''"
	post `pf' ("`: variable label `outcome''") ("`mean0'") ("`mean1'") ///
		("`f_rd'") ("`f_rd_ci'") ("`f_or'") ("`f_or_ci'")
		
}
postclose `pf'
use "`tmp'", clear
export excel using "../Tables/t4_ToT.xlsx", replace
