# MASTER THESIS GENERAL <!-- omit in toc -->

- [Overview](#overview)
    - [Data](#data)
        - [Data structure](#data-structure)
    - [Order of execution](#order-of-execution)
    - [Directory structure](#directory-structure)
    - [Variable naming convention](#variable-naming-convention)


# Overview
This code ...


## Data
Data from the following sources were used:

**Add Health dataset**  
Downloaded from:

**Federal Poverty line**  
Data for the years XXXX - XXXX were downloaded from: https://aspe.hhs.gov/prior-hhs-poverty-guidelines-and-federal-register-references

**Fragile Families dataset**  
Downloaded from:

**KFF reports**  
Reports for the years 2012 - 2018 were downloaded from: https://www.kff.org/medicaid/report/annual-updates-on-eligibility-rules-enrollment-and/

**March CPS data**  
Data for the years 1980 - 2016 were downloaded from: http://ceprdata.org/cps-uniform-data-extracts/march-cps-supplement/march-cps-data/

**Thompson data**  
Data was downloaded from: https://sites.google.com/site/othompsonecon/home/publications


### Data structure
~~~
├── data
│   │
│   ├── AddHealth
│   │   │
│   │   ├── raw
│   │   │
│   │   ├── temp1
│   │   │
│   │   ├── clean
│   │   │
│   │   └── references
│   │
│   ├── FPL
│   │   │
│   │   ├── raw
│   │   │
│   │   ├── temp1
│   │   │
│   │   └── clean
│   │
│   ├── FragileFamilies
│   │   │
│   │   ├── raw
│   │   │
│   │   ├── temp1
│   │   │
│   │   ├── clean
│   │   │
│   │   └── references
│   │
│   ├── KFF
│   │   │
│   │   ├── raw
│   │   │
│   │   ├── temp1
│   │   │
│   │   ├── clean
│   │   │
│   │   └── references
│   │
│   ├── MarchCPS
│   │   │
│   │   ├── raw
│   │   │
│   │   ├── temp1
│   │   │
│   │   ├── clean
│   │   │
│   │   └── references
│   │
│   ├── MedicaidDataPost
│   │   │
│   │   ├── DoFiles
│   │   │
│   │   ├── RawData
│   │   │
└── └── └── ReadME.pdf

~~~


## Order of execution
The files were written for a UNIX environment. You can just run the file listed below and all other files will be automatically executed.

~~~
bash ./INSERT.sh
~~~

## Directory structure

~~~
├── LICENSE
│
├── README.md                       <- General information about the project
│
├── .gitignore                      <- Specifies files to ignore
│
├── data
│
├── code
│   │
│   ├── INSERT.sh                   <- Script runs all the other files
│   │
│   ├── INSERT.do                   <- Programs needed to run the other .do files
│   │
│   ├── INSERT.do                   <- Extracts, cleans and merges the data
│   │
│   └── INSERT.do                   <- Constructs variables needed for the analysis
│
├── output                          <- PDF, LaTex, etc.
│   │
│   ├── figures
│   │
│   ├── tables
│   │
└── └── other
~~~


## Variable naming convention
* Variables: lowerCamelCase
* Global variables (constant): UPPERCASE
* Path names: UPPERCASE