*=================================================================================
* Copyright (c) Arthritis Research UK Centre for Epidemiology, University of Manchester (2016-2018)
*=========================================================================================
* 5 Derive BMI  
*=================================================================================
*
* - calculate BMI (weight/height^2)
* - remove BMI values outside the range (10-65).
* - categorises BMIs by standard BMI categories and the WHO BMI categories
* 
*=================================================================================

* Calculates BMI - uses weight updated variable
gen bmi_updated = wgt_updated/(hgt_median*hgt_median)
sum bmi_updated, det

* Identifies BMI less than 10 or greater than 65
gen idbmiup = (bmi_updated!=.)
gen bmiup10 = (bmi_updated<=10) if idbmiup==1
gen bmiup65 = (bmi_updated>65 & bmi_update!=.) if idbmiup==1

* Sets BMIs less than 10 to missing
replace bmi_updated=. if bmiup10==1
replace idbmiup=. if bmiup10==1
label var bmi_updated "BMI (c)"
label var idbmiup "Identifies BMI (Updated) measurement"
drop if bmi_updated==.
drop bmiup10 bmiup65

* BMI - WHO classifications (WHO technical report, 2000)
gen bmiup_cat = .
replace bmiup_cat = 1 if (bmi_updated<18.5)
replace bmiup_cat = 2 if (bmi_updated>=18.5 & bmi_updated<25)
replace bmiup_cat = 3 if (bmi_updated>=25 & bmi_updated<30)
replace bmiup_cat = 4 if (bmi_updated>=30 & bmi_updated!=.)
replace bmiup_cat = 5 if (bmi_updated>=40 & bmi_updated!=.)
label define bmicat 1 "Underweight" 2 "Normal" 3 "Overweight" 4 "Obese" 5 "Morbidly obese"
label values bmiup_cat bmicat
label var bmiup_cat "Categories of BMI (updated weight)"
label var patid "Patient ID"

save $savedir/clean_bmi_measures, replace
keep patid bmi_updated bmiup_cat
save $savedir/clean_bmi_short, replace
