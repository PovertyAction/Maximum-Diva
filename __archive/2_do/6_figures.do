 * ---------------------------------------- *
 * file:    6_figures.do               
 * author:  Christopher Boyer              
 * project: Maximum Diva Women's Condom    
 * date:    2017-10-20                     
 * ---------------------------------------- *
 * outputs: 
 *   @Figures/t3_hetero_${subgroup}.png
 
use "../Data/maximum_diva_endline.dta", clear
merge m:1 ward using "../Data/maximum_diva_baseline_pooled.dta", nogen assert(3)
order $outcomes

local drop fc_use_last

global outcomes : list global(outcomes) - drop

foreach group in $subgroups {
	estimates clear
	local controls $controls
	local controls : list controls - group

	foreach outcome in $outcomes {
		local is_cont : list outcome in global(continuous_covariates)	
		
		levelsof `group', local(levels)
		foreach level in `levels' {
			reg `outcome' ${treatment} `controls' pre_`outcome' if `group' == `level', cluster(ward)
			estimates store rd_`outcome'_`level'
			
			if !`is_cont' {
				logit `outcome' ${treatment} `controls' pre_`outcome' if `group' == `level', cluster(ward)
				estimates store or_`outcome'_`level'
			}
		}
		
		local lab_`outcome' : variable label `outcome'
		local coef_labels = `"`coef_labels'rd_`outcome' = "`lab_`outcome''" "'
	}

	local lab0 : label (`group') 0
	local lab1 : label (`group') 1

	coefplot ///
		(or_*_0, keep(${treatment}) label("`lab0'")) ///
		(or_*_1, keep(${treatment}) label("`lab1'")), ///
		mlabel format(%9.1f) mlabposition(12) mlabgap(*2) mlabsize(vsmall) ///
		eform xline(1) swapnames xlabel(1 `" " " " "OR"' 1 "1", add) ///
		coeflabels(, labsize(small)) ///
		title("{bf: Heterogeneous effects, `lab0' vs `lab1'}")
		
	graph export "../Figures/f1_`group'_or.png", replace
	
	coefplot ///
		(rd_*_0, keep(${treatment}) label("`lab0'") eqrename(^rd_(.*)_0$ = rd_\1, regex)) ///
		(rd_*_1, keep(${treatment}) label("`lab1'") eqrename(^rd_(.*)_1$ = rd_\1, regex)), ///
		mlabel format(%9.1f) mlabposition(12) mlabgap(*2) mlabsize(vsmall) ///		
		swapnames aseq xline(0) coeflabels(`coef_labels', labsize(vsmall)) xlabel(0 `" " "RD"' 0 "0", add) ///
		title("{bf: Heterogeneous effects, `lab0' vs `lab1'}")
		
		graph export "../Figures/f1_`group'_rd.png", replace

}
