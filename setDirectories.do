
* ----------------------------- SET WORKING DIRECTORIES & GLOBAL VARS
if "`c(username)'" == "michellerosenberger"  {
	global CODEPATH			"~/Development/MA/code"
	global DATAPATH			"/Volumes/g_econ_department$/econ/biroli/geighei/data/medicaidGxE/data"
	global OUTPUTPATH		"/Volumes/g_econ_department$/econ/biroli/geighei/data/medicaidGxE/output"

	// global CODEPATH			"/Volumes/g_econ_department$/econ/biroli/geighei/code/medicaidGxE/thesis-code"
    // global DATAPATH			"~/Development/MA/data"
	// global OUTPUTPATH		"~/Development/MA/output"
}

global CODEDIR                  "${CODEPATH}"

global CLEANDATADIR             "${DATAPATH}/clean"
global TEMPDATADIR              "${DATAPATH}/temp"
global RAWDATADIR               "${DATAPATH}/raw/FragileFamilies"
global RAWDATADIRCPS            "${DATAPATH}/raw/MarchCPS"
global RAWDATADIRFPL            "${DATAPATH}/raw/FPL"
global RAWDATADIRKFF            "${DATAPATH}/raw/KFF"
global RAWDATADIRTHOMPSON      	"${DATAPATH}/dataThompson/RawData"

global MAPTILEPATH 				"~/Library/Application Support/Stata/ado/personal/maptile_geographies"

global TABLEDIR                 "${OUTPUTPATH}/tables"
global FIGUREDIR                "${OUTPUTPATH}/figures"


* ----------------------------- EXTENSION GRAPHS
if "`c(console)'" == "console" {
	global EXTENSION pdf	// in UNIX console (.png not possible)
}
else {
	global EXTENSION png	// in STATA (directly output .png)
}
di "${EXTENSION}"


