*=============================================================================================================
* Copyright (c) Arthritis Research UK Centre for Epidemiology, University of Manchester (2016-2018)
*=========================================================================================
* 2 CLEAN HEIGHT DATA
*=============================================================================================================
*
* - Identify height measurement entries in the additional file (enttype = 14 -Examination
*   Findings - Height).
* - Merge in clinical, patient and practice files.
* - Drop observations before practice up to standard or patient unacceptable.
* - Heights < 1.21m or > 2.14 m set to missing.
* - Remove duplicate records.
* - Define height outcome (per date). As patients may have multiple height measurements on a single date, it
*   is necessary to calculate a single height per date. If only one height is given for a
*   specific date, that is used. Otherwise,the mean height of measurements on the same date is used
*   unless the maximum intraday difference in height is outside the range 0-0.05 m (set to missing).
*
*=============================================================================================================

** Preparing height data from the additional file
use $datadir/additional, clear
keep if enttype==14
label var data1 "Original height in metres (c)"
label var data2 "Original Height centile"
label values data2 centiles 
rename data1 hgt_mts
rename data2 hgt_centile
drop if hgt_mts==0 
drop data3 data4 data5 data6 data7

* Generates pracid from patid
tostring patid, generate(str_patid)
gen str_pracid = substr(str_patid,-3,3)
destring str_pracid, gen(pracid)
drop str_pracid str_patid

* Merging to clinical file
merge 1:m patid adid using $datadir/clinical, keepusing (patid eventdate sysdate) keep (1 3) nogenerate

* Merging to Patient file
merge m:1 patid using $datadir/patient, keepusing (accept) keep (1 3) nogenerate

* Merging to Practice file
merge m:1 pracid using $datadir/practice, keepusing (uts) keep (1 3) nogenerate
save $savedir/clin_hgt_all, replace

*Replace event date with system date if event date is missing
replace eventdate=sysdate if eventdate==""
gen eventdateA = date(eventdate,"DMY")
format eventdateA  %dD/N/CY
label var eventdateA "Date of measurement"
gen utsA = date(uts, "DMY")
format utsA %dD/N/CY
label var utsA "Formatted uts date"

* Drops observations before practice up to standard
gen bfr_uts = (eventdateA<utsA)
drop if (bfr_uts==1 | accept==0)
drop bfr_uts

* Heights less than 1.21 or above 2.14 set to missing
gen hgt_out=(hgt_mts<1.21 | hgt_mts>2.14)
drop if hgt_out==1
drop hgt_out

*Drops duplicates
duplicates drop patid eventdateA hgt_mts, force

*Identifies if more than one height per date
bys patid eventdateA: gen index=_n
bys patid eventdateA (index): gen indextot=index[_N]
drop index

* Calculates difference between multiple heights on the same date 
bys patid eventdateA (hgt_mts) : gen hgt_diff=(hgt_mts - hgt_mts[_n-1]) if indextot>1
bys patid eventdateA: egen min_diff=min(hgt_diff)
bys patid eventdateA: egen max_diff=max(hgt_diff)
bys patid eventdateA: egen mean_hgt=mean(hgt_mts)

* Creates new height variable with same height if only one height given, mean height on same date if the difference is less than 0.05m. 
gen hgt_mtsA = .
replace hgt_mtsA=hgt_mts if indextot==1
bys patid eventdateA: replace hgt_mtsA=mean_hgt if (indextot>1 & max_diff<0.05 & max_diff>0)
drop if hgt_mtsA==.
duplicates drop patid eventdateA hgt_mtsA, force
* user to check output below - should be only one copy of each observation by patient ID and date
duplicates report patid eventdateA

* Label variable and save dataset
label var hgt_mtsA "Height (c) one measure per date"
save $savedir/clin_hgt_all, replace
drop indextot hgt_diff mean_hgt min_diff max_diff eventdate sysdate accept pracid uts index enttype adid utsA
rename eventdateA start
save $savedir/clin_hgt, replace
