*=====================================================================================================================
* Copyright (c) University of Manchester 2017. All rights reserved.
*=========================================================================================
* 4 Derive Weight Outcome 
*=====================================================================================================================
*
* - fit random intercepts model regressing weight on time, adjusting for age and gender (grouping: patient) and calculate standardised residuals
* - drop weight measurements where the residuals are outliers unless the data point is within 10 kg
*   of the preceding (n-1) or subsequent (n+1) measurement by date.
* - repeat the modelling process using the cleaned data (once or twice more until no extras are removed) to ensure outlier residuals are removed.
* - remove measurements with an inter-date weight change of > 5 kg per day if patient only has weight measurements for
*   two visits.
*
*=====================================================================================================================

* Calculates weight difference between visits
use $savedir/hgt_and_wgt, clear
bys patid (idwgt start): gen wgt_diff = (wgt_kgA - wgt_kgA[_n-1])
gen wgt_diff10 = (wgt_diff>-10 & wgt_diff<10)
replace wgt_diff10=. if wgt_diff==.
bys patid: egen noofwgts=sum(idwgt)
label var wgt_diff "Weight difference compared to previous weight - original variable"
label var wgt_diff10 "Weight difference of 10 or less compared to previous weight - original variable"
label var noofwgts "Total number of weight measurements"

* Standardised residuals - runs the number of models until the model no more outliers are identified
* The standardised residual of 10 is as advised by Welch et al (2012)
set more off
xtmixed wgt_kgA start age gender || patid:
predict rs1, rstandard
gen idrs1 = (rs1>-10 & rs1<10)
replace idrs1=. if rs1==.
replace idrs1 = 1 if wgt_diff10==1
bys patid (idwgt start): replace idrs1 = 1 if wgt_diff10[_n+1]==1
replace idrs1 = 1 if noofwgts==2
gen wgt_rsA1 = wgt_kgA if idrs1==1 

xtmixed wgt_rsA1 start age gender || patid:
predict rs2, rstandard
gen idrs2 = (rs2>-10 & rs2<10)
replace idrs2=. if rs2==.
replace idrs2 = 1 if wgt_diff10==1
bys patid (idwgt start): replace idrs2 = 1 if wgt_diff10[_n+1]==1
replace idrs2 = 1 if noofwgts==2
gen wgt_rsA2 = wgt_rsA1 if idrs2==1 

local i = 1
local j = `i'+1
sum idrs1
local num1 = r(N)
sum idrs2
local num2 = r(N)

while `num`i'' !=`num`j'' {
	local i = `i'+1
	local j = `j'+1
	xtmixed wgt_rsA`i' start age gender || patid:
	predict rs`j', rstandard
	gen idrs`j' = (rs`j'>-10 & rs`j'<10)
	replace idrs`j'=. if rs`j'==.
	replace idrs`j' = 1 if wgt_diff10==1
	bys patid (idwgt start): replace idrs`j' = 1 if wgt_diff10[_n+1]==1
	replace idrs`j' = 1 if noofwgts==2
	gen wgt_rsA`j' = wgt_rsA`i' if idrs1==1 
	sum idrs`i'
	local num`i' = r(N)
	sum idrs`j'
	local num`j' = r(N)
}

* Generates new variable with weight after outliers removed
gen wgt_rs = wgt_rsA`j' if `num`i'' == `num`j''
gen idnewwgt = (wgt_rs!=.)
label var wgt_rs "Weights after standardised residuals"

* Identifies weight difference for new weight variable
bys patid (idnewwgt start): gen wgt_diff_u = (wgt_rs - wgt_rs[_n-1])

* Identifies number of days between weight measurements
bys patid (idnewwgt start): gen gapbtwgts = (start - start[_n-1])

* Identifies weight change per day
bys patid (idnewwgt start): gen wgtchnge = wgt_diff_u/gapbtwgts
label var wgt_diff_u "Weight difference compared to previous weight - rs weight variable"
label var gapbtwgts "Number of days from previous weight measurements - rs weight variable"
label var wgtchnge "Change in weight per day (kg)"

* Identifies if weight changes by more than 5kg per day
gen chge5pd = (wgtchnge>5 & wgtchnge!=.) | (wgtchnge<-5)
tab chge5pd
label var chge5pd "Weight changes by more than 5kg per day"
gen wgt_updated = wgt_rs if chge5pd==0
bys patid (start): replace wgt_updated=. if noofwgts==2 & (chge5pd[_n-1]==1 | chge5pd[_n+1]==1)

* Labels variable and saves dataset
label var wgt_updated "Final weight variable (kg)"
drop idnewwgt wgt_rsA* idrs* rs*
save $savedir/hgt_wgt_cleaned, replace

