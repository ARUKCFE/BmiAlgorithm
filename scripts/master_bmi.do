* Copyright (c) University of Manchester 2017. All rights reserved.
*=========================================================================================
*
* Script name:	master_bmi.do 
*
* Author:	Ruth Costello
*
* Date created: 20150713
*
* Purpose: 	Calculate body mass index (single measurement per person per date)
*               from raw weight (kg) and height (m) measurements (CPRD data).  
*
*=========================================================================================
/// User will need to update taskdir file path to personal directory
/// Base directory refers to primary folder that contains original data, saved data and log folders.
********************************************************************************

global basedir	"specify path to base directory"
global datadir	"specify path to original CPRD files in Stata format"
global dodir	"specify path to where scripts are saved"
global savedir	"specify path to where files will be saved to"
global logdir	"specify path to log files"


** Log
local date: display %dCYND date("`c(current_date)'", "DMY")
di `date'
local logname: display "BMIalgorithm_"`date'
di "`logname'"

capture log close
log using "$logdir/`logname'.log", append


* [1 & 2]  Creates files of height and weight with multiple weights/heights on the same date removed
* Does not include weights before practice was up to standard and weights for unacceptable patients
include $dodir/1_cleanweightdata.do
include $dodir/2_cleanheightdata.do

* [3] Derive Height Outcome (one per person per followup). 
include $dodir/3_deriveheightoutcome.do

* [4] Clean Weight Data using Standardised Residuals 
include $dodir/4_deriveweightoutcome.do

* [5] Derive BMI (one per person per date)
include $dodir/5_derivebmi.do

log close

