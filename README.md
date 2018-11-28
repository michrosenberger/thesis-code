# Code for Master Thesis <!-- omit in toc -->

- [Overview](#overview)
- [Data](#data)
- [Order of Execution](#order-of-execution)
- [Directory Structure](#directory-structure)
- [Variable naming convention](#variable-naming-convention)


## Overview
This code performs the data cleaning and analysis for my master thesis.


## Data
Data from the following sources were used:

**Federal Poverty Line**  
Data for the years 1997 - 2018 were downloaded from:  
https://aspe.hhs.gov/prior-hhs-poverty-guidelines-and-federal-register-references

**Fragile Families Dataset**  
Downloaded from:  
[Link here]

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
├── LICENSE
│
├── README.md                       <- General information about the project
│
├── .gitignore                      <- Specifies files to ignore
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
├── code
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



## Variable naming convention
* Variables: lowerCamelCase
* Global variables (constant): UPPERCASE
* Path names: UPPERCASE