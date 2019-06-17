
* ----------------------------- SET WORKING DIRECTORIES & GLOBAL VARS
if "`c(username)'" == "michellerosenberger"  {
    global DATAPATH			"~/Development/MA/data"
	global CODEPATH			"~/Development/MA/code"
	global OUTPUTPATH		"~/Development/MA/output"
	*global DATAPATH		"/Volumes/g_econ_department$/econ/biroli/geighei/data/medicaidGxE/data"
	*global CODEPATH		"/Volumes/g_econ_department$/econ/biroli/geighei/code/medicaidGxE/thesis-code"
	*global OUTPUTPATH		"/Volumes/g_econ_department$/econ/biroli/geighei/data/medicaidGxE/output"
}

global CODEDIR                  "${CODEPATH}"

global CLEANDATADIR             "${DATAPATH}/clean"
global TEMPDATADIR              "${DATAPATH}/temp"
global RAWDATADIR               "${DATAPATH}/raw/FragileFamilies"
global RAWDATADIRCPS            "${DATAPATH}/raw/MarchCPS"
global RAWDATADIRFPL            "${DATAPATH}/raw/FPL"
global RAWDATADIRKFF            "${DATAPATH}/raw/KFF"
global RAWDATADIRTHOMPSON      	"${DATAPATH}/MedicaidDataPost/RawData"

global TABLEDIR                 "${OUTPUTPATH}/tables"
global FIGUREDIR                "${OUTPUTPATH}/figures"