# Code for Master Thesis <!-- omit in toc -->

- [Overview](#Overview)
- [Data](#Data)
- [Order of Execution](#Order-of-Execution)
- [Directory Structure](#Directory-Structure)


## Overview
This code performs the data cleaning, as well as the data analysis for my master thesis.


## Data
Data from the following sources were used:

**Federal Poverty Line**  
Data for the years 1997 - 2018 were downloaded from:  
https://aspe.hhs.gov/prior-hhs-poverty-guidelines-and-federal-register-references

**Fragile Families Dataset**  
Downloaded from:  
https://fragilefamilies.princeton.edu/documentation

**KFF Reports**  
Reports for the years 2012 - 2018 were downloaded from:  
https://www.kff.org/medicaid/report/annual-updates-on-eligibility-rules-enrollment-and/

**March CPS Data**  
Data for the years 1980 - 2016 were downloaded from:  
http://ceprdata.org/cps-uniform-data-extracts/march-cps-supplement/march-cps-data/

Data for the years 2017 - 2018 were downloaded from:  
http://www.nber.org/data/cps.html

**Thompson Data**  
Data was downloaded from:  
https://sites.google.com/site/othompsonecon/home/publications


## Order of Execution
The files were written for a UNIX environment. You can just run the file listed below in STATA and all files will be automatically executed.

~~~
. run.do
~~~


## Directory Structure
~~~
├── code
│   │
│   ├── README.md                   <- General information about the project
│   │
│   ├── setDirectories.do           <- Set own working directories
│   │
│   ├── run.do                      <- Runs all the files
│   │
│   ├── analysis.do                 <- Performs the analysis
│   │
│   ├── CPS                         <- Files to clean the March CPS data
│   │
│   ├── FF                          <- Files to clean the FFCWS data
│   │
│   ├── Eligibility                 <- Files to construct eligibility
│   │
│   ├── output                      <- Files to construct the maps
│   │
│   ├── .gitignore                  <- Specifies which files to ignore
│   │
│   └── LICENSE
│
├── data
│   │
│   ├── clean
│   │
│   ├── temp
│   │
│   ├── raw
│   │
│   └── references
│
├── output
│   │
│   ├── figures
│   │
│   ├── tables
│   │
│   └── other
│
├── writeup
│
├── literature
│
└── archive

~~~

