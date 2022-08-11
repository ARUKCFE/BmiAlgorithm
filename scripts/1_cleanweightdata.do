*============================================================================================================
*  Copyright (c) Arthritis Research UK Centre for Epidemiology, University of Manchester (2016-2018)
*=========================================================================================
* 1 CLEAN WEIGHT DATA
*============================================================================================================
*
* - Identify weight measurement entries in the additional file (enttype = 13 -Examination
*   Findings - Weight).
* - Merge in clinical, patient and practice files.
* - Drop observations before practice up to standard or patient unacceptable.
* - Remove weights < 20kg or > 450kg.
* - Remove duplicate records
* - Define weight outcome (per date). As patients may have multiple weight measurements on a single date, it
*   is necessary to calculate a single weight per date. If only one weight is given for a
*   specific date, that is used. Otherwise,the mean weight of measurements on the same date is used
*   unless the maximum intraday difference in weight is outside the range 0-5Kg (set to missing)
*
*==============================================================================================================

** Preparing weight data from additional file
use $datadir/additional, clear
keep if enttype==13
label var data1 "Original weight in kgs (c)"
label var data2 "Weight centile"
label var data3 "BMI - additional file"
rename data1 wgt_kg
rename data2 wgt_centile
rename data3 bmi
label define centiles 1 "<3" 2 "3-9" 3 "10 - 24" 4 "25 - 49" 5	"50 - 74" 6 "75 - 89" 7	"90 - 97" 8 "> 97"
label values wgt_centile centiles
drop if wgt_kg==0 
drop data4 data5 data6 data7

* Generates practice ID from patid
tostring patid, generate(str_patid)
gen str_pracid = substr(str_patid,-5,5)
destring str_pracid, gen(pracid)
drop str_pracid str_patid

** merging to clinical file **
merge 1:m patid adid using $datadir/clinical, keepusing (patid eventdate sysdate) keep(1 3) nogenerate
duplicates drop

* Merging to patient file
merge m:1 patid using $datadir/patient, keepusing (accept) keep(1 3) nogenerate

*Merging to practice file
merge m:1 pracid using $datadir/practice, keepusing (uts) keep(1 3) nogenerate

* Updates event date to system date if event date is missing
replace eventdate=sysdate if eventdate==""

*Formatting dates to Stata date format and labelling
gen eventdateA = date(eventdate,"DMY")
format eventdateA  %dD/N/CY
label var eventdateA "Date of measurement"
gen utsA = date(uts, "DMY")
format utsA %dD/N/CY
label var utsA "Formatted uts date"

*Drops observations before practice is up to standard or patients who are unacceptable
gen bfr_uts = (eventdateA<utsA)
tab bfr_uts
drop if (bfr_uts==1 | accept==0)
drop bfr_uts

*Weights less than 20kg or greater than 450kg set to missing
gen wgt_kgO=wgt_kg
label var wgt_kgO "Weight (c) before amendments"
gen wgtout = (wgt_kg<20 | wgt_kg>450)
bys patid: gen sumwgtout = sum(wgtout)
bys patid (sumwgtout): gen sumout = sumwgtout[_N]

save $savedir/fulldata, replace
drop if wgtout==1

*Duplicates dropped
duplicates drop patid eventdateA wgt_kg, force

*Identifies if more than one weight per date
bys patid eventdateA: gen index=_n
bys patid eventdateA (index): gen indextot=index[_N]
label var indextot "Original number of weight measurements per day"

* Calculates difference between multiple weights on the same date 
bys patid eventdateA (wgt_kg): gen wgt_diff=(wgt_kg - wgt_kg[_n-1]) if indextot>1
bys patid eventdateA: egen min_diff=min(wgt_diff) 
bys patid eventdateA: egen max_diff=max(wgt_diff) 

* Calculates mean weight by date
bys patid eventdateA: egen wgt_mean=mean(wgt_kg)

*Creates new weight variable with same weight if only one weight given, mean weight on same date if the difference is less than 5. 
gen wgt_kgA=.
bys patid eventdateA: replace wgt_kgA=wgt_kg if indextot==1
count if (max_diff<5 & max_diff>0) & indextot!=1
bys patid eventdateA: replace wgt_kgA=wgt_mean if (max_diff<5 & max_diff>0) & indextot!=1
drop if wgt_kgA==.
duplicates drop patid eventdateA wgt_kgA, force

* User to check output below - should be only 1 copy of each observation by patient ID and date
duplicates report patid eventdateA

* Label variable and save dataset
label var wgt_kgA "Weight (c) one measure per date"
save $savedir/clin_wgt_all, replace
drop indextot index wgt_diff wgt_mean min_diff max_diff index wgt_kgO eventdate sysdate accept pracid uts utsA wgt_centile wgtout sumwgtout sumout enttype adid
rename eventdateA start
save $savedir/clin_wgt, replace

