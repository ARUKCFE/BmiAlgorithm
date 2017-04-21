# Body Mass Index algorithm (BmiAlgorithm)
Defines body mass index (BMI) for patients of the UK Clinical Practice Research Data Link (CPRD) data, and categorises BMI into the World Health Organisation (WHO) international classification of underweight, normal weight, overweight and obesity.[1]

This algorithm was created by Ruth Costello, School of Biological Sciences, The University of Manchester.

# Introduction
The BMI algorithm takes height and weight data from the additional file, cleans the height and weight data, calculates BMI and categorises BMI into the standard BMI categories. 
Using the algorithm

*	Open master_bmi.do
* Specify paths to algorithm folder by updating macros “basedir”, “datadir”, “dodir”, “savedir” and “logdir” as indicated in the script. 
* Run the algorithm by running master_bmi.do.
* Inspect the log file.
* The final script creates two files: 1) clean_bmi_measures, which contains most variables created throughout the algorithm, and 2) clean_bmi_short which contains just the patient ID and the BMI variables created.

# Requirements
Software
The files are written in Stata 12.1, and have been tested using Stata 13. Other backwards compatibility has not been checked.

# Data
The algorithm uses the following CPRD datasets:
*	Additional
*	Clinical
*	Patient
*	Practice


| File name                | Description                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|--------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| master_bmi               | Master file: runs the algorithm                                                                                                                                                                                                                                                                                                                                                                                                               |
| 1_cleanweightdata.do     | Identifies weight measurements from the additional file. Removes weights before the practice is up to standard date and measurements for people who CPRD indicates are unacceptable. Removes weights less than 20kg and above 450kg. Removes duplicates and defines weight per date, for a person with multiple weights per date the mean is used if there is a difference of 5kg or less. Otherwise the multiple weights are set to missing. |
| 2_cleanheightdata.do     | Identifies height measurements from the additional file, removes heights before the up to standard date and measurements from people who are deemed unacceptable, removes heights less than 1.21m and above 2.14m, removes duplicates and defines heights per date, for people with multiple heights per date the mean is used if there is a difference of 0.05m or less, otherwise the multiple heights are set to missing.                  |
| 3_deriveheightoutcome.do | Defines median height, age at the time of BMI measurement and the degree of height and weight missingness.                                                                                                                                                                                                                                                                                                                                    |
| 4_deriveweightoutcome.do | Fits a random effects model regressing weight on time, adjusting for age and gender, weights where the residual is 10 or more are judged to be outliers and are removed, the model is rerun with the new weight variable, and the same process is repeated until there are no additional outliers identified. Weights with an inter-date change of more than 5kg per day are further removed.                                                 |
| 5_deriveBMI.do           | BMI is calculated using the standard formula of weight/height2. BMI is categorised using the standard World Health Organisation BMI categories. [1]                                                                                                                                                                                                                                                                                           |

# Additional notes
* The algorithm does not take into account follow-up dates, therefore the data will need to be trimmed to meet individual study dates after the algorithm is run.
* The algorithm uses the standardised residuals method to remove within person outliers which was proposed by Welch et al, 2012.[2] 
* Variable labels with (c) indicate a continuous variable.

# References
1.	Obesity: Preventing and managing the global epidemic.  WHO Technical Report Series: World Health Organization 2000.
2.	Welch C, Petersen I, Walters K, Morris RW, Nazareth I, Kalaitzaki E, et al. Two-stage method to remove population- and individual-level outliers from longitudinal data in a primary care database. Pharmacoepidemiology and drug safety. 2012 Jul; 21(7):725-732.




