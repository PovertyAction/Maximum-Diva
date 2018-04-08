 * ---------------------------------------- *
 * file:    7_make_document.do               
 * author:  Christopher Boyer              
 * project: Maximum Diva Women's Condom    
 * date:    2018-03-15                     
 * ---------------------------------------- *
 * outputs: 
 *   @Documents/Maximum_Diva_Replication.docx
 
 
 /* This file compiles all tables to a word document */

putdocx clear
putdocx begin, font("Calibri", 8) 
putdocx paragraph 
 
local i = 0
local tables : dir "../Tables" files "t*.dta"

foreach table in `tables' {
	use "../Tables/`table'", clear
	putdocx table t`++i' = data(_all), ///
		layout(autofitcontents) ///
		halign(center) ///
		cellmargin(left, 0.04 in) ///
		cellmargin(right, 0.04 in) ///
		border(insideH, nil) ///
		border(insideV, nil) ///
		border(start, nil) ///
		border(end, nil) 
	
	forval j = 2/`c(k)' {
		putdocx table t`i'(., `j'), halign(center)
	}
	
	putdocx table t`i'(1, .), bold
	if `i' > 1 	putdocx table t`i'(2, .), bold border(bottom)
	
	if `i' == 1 {
		putdocx table t`i'(1, .), border(bottom)
		putdocx table t`i'(2, .), italic
		putdocx table t`i'(35, .), italic
		putdocx table t`i'(41, .), italic border(top)
	}
	
	putdocx pagebreak
}

putdocx save "../Documents/Maximum_Diva_Replication.docx", replace
