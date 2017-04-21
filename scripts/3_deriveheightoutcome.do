*=====================================================================================
* Copyright (c) University of Manchester 2017. All rights reserved.
*=========================================================================================
* 3 Derive Height Outcome
*=====================================================================================
* - define median height (across time)
* - define age at time of BMI measurement
* - quantify degree of missingness in heights and weights.
*======================================================================================

use $savedir/clin_hgt, clear
* Use median height as least affected by outliers.
bys patid: egen hgt_median = median(hgt_mtsA)
label var hgt_median "Median height in metres"
duplicates drop patid hgt_median, force
keep patid hgt_median

merge 1:m patid using $savedir/clin_wgt, nogenerate
merge m:1 patid using $datadir/patient, keepusing(gender yob) keep (1 3) nogenerate

*Identifies whether any height and weight measurements
gen whmeas = (wgt_kgA!=. & hgt_median!=.)
gen idwgt = (wgt_kgA>0 & wgt_kgA!=.)
gen idhgt = (hgt_median>0 & hgt_median!=.)
label var whmeas "Has both height and weight measure at timepoint"
label var idwgt "Weight measurement"
label var idhgt "Height measurement"

* Identifies if patient has any height and weight measurements
bys patid (idwgt): gen anywgt=idwgt[_N]
bys patid (idhgt): gen anyhgt=idhgt[_N]
bys patid (whmeas): gen anywhmeas = whmeas[_N]
bys patid: gen nomeas = (anywgt==. & anyhgt==.)
label var anywgt "Has at least one weight measurement"
label var anyhgt "Has at least one height measurement"
label var anywhmeas "Has both height and weight measurement at least once"
label var nomeas "Has no height or weight measurements"
label var gender "Gender"

* Calculates age
gen year = year(start)
gen age = year-(yob+1800)
sum age, det
label var age "Age in years (c)"
drop yob year
save $savedir/hgt_and_wgt, replace

