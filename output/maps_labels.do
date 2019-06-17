* -----------------------------------
* Project:  MA Thesis
* Content:  Add lines + state labels
* Author: 	Michelle Rosenberger
* Date:     Nov 19, 2018
* -----------------------------------

* ----------------------------- PREPARE DATA
use "${MAPTILEPATH}/state_coords_clean", clear

bysort _ID: egen xcoord = median(_X)
bysort _ID: egen ycoord = median(_Y)
collapse (lastnm) xcoord ycoord, by(_ID)
    
preserve
    use "${MAPTILEPATH}/state_database_clean", clear
    keep statefips _polygonid state
    rename _polygonid _ID
    save "${MAPTILEPATH}/state_id_fips", replace
restore
    
merge 1:1 _ID using "${MAPTILEPATH}/state_id_fips", update replace nogen

* ----------------------------- LINES STATES ON MAP
preserve
    rename xcoord _X
    rename ycoord _Y 
    keep if state == "HI" | state == "VT" | state == "NH" | state == "DC" | state == "MD" | state == "DE" | state == "NJ" | state == "CT" | state == "RI" | state == "MA"
    expand 3
    sort state
    by state: gen id = _n

    replace _X = . if id == 1 
    replace _Y = . if id == 1

    replace _X = _X - 1     if state == "MD" & id == 2
    replace _Y = _Y + 1     if state == "MD" & id == 2
    replace _Y = _Y - 0.5   if state == "DE" & id == 2
    replace _X = _X + 0.5   if state == "NJ" & id == 2
    replace _Y = _Y + 0.5   if state == "CT" & id == 2
    replace _X = _X - 1     if state == "MA" & id == 2
    replace _Y = _Y + 1     if state == "MA" & id == 2
    replace _Y = _Y + 0.75  if state == "VT" & id == 2
    replace _Y = _Y - 1.5   if state == "HI" & id == 2
    replace _X = _X + 1.25  if state == "HI" & id == 2

    replace _X = _X + 2.25  if state == "HI" & id == 3
    replace _Y = _Y - 0.75  if state == "HI" & id == 3
    replace _Y = _Y + 2	    if state == "VT" & id == 3
    replace _X = _X + 1.5   if state == "NH" & id == 3
    replace _Y = _Y - 0.5   if state == "NH" & id == 3
    replace _X = _X + 3     if state == "DC" & id == 3
    replace _Y = _Y - 2.25  if state == "DC" & id == 3
    replace _X = _X + 2.25  if state == "MD" & id == 3
    replace _Y = _Y - 1     if state == "MD" & id == 3
    replace _X = _X + 2     if state == "DE" & id == 3
    replace _Y = _Y - 0.75  if state == "DE" & id == 3
    replace _X = _X + 1.25  if state == "NJ" & id == 3
    replace _Y = _Y - 1     if state == "NJ" & id == 3
    replace _X = _X + 0.75  if state == "CT" & id == 3
    replace _Y = _Y - 1.25  if state == "CT" & id == 3
    replace _X = _X + 0.75  if state == "RI" & id == 3
    replace _Y = _Y - 0.75  if state == "RI" & id == 3
    replace _X = _X + 1     if state == "MA" & id == 3
    replace _Y = _Y + 0.5   if state == "MA" & id == 3

    save "${MAPTILEPATH}/line_data.dta", replace
restore

* ----------------------------- CENTER ALL STATE LABELS
replace xcoord = xcoord + 0.75 	if state == "AL"
replace ycoord = ycoord + 2.5 	if state == "AL"
replace xcoord = xcoord + 0.5	if state == "AK"
replace ycoord = ycoord + 3.25 	if state == "AK"
replace xcoord = xcoord + 2.5	if state == "OR"
replace ycoord = ycoord - 1 	if state == "OR"
replace xcoord = xcoord + 2.25	if state == "WA"
replace ycoord = ycoord - 1 	if state == "WA"
replace xcoord = xcoord + 0.25	if state == "ID"
replace ycoord = ycoord - 1 	if state == "ID"
replace xcoord = xcoord + 2.75	if state == "MT"
replace xcoord = xcoord + 1.25	if state == "ND"
replace ycoord = ycoord + 1.75 	if state == "ND"
replace xcoord = xcoord - 1		if state == "SD"
replace ycoord = ycoord - 0.25 	if state == "SD"
replace xcoord = xcoord + 1.5	if state == "CA"
replace xcoord = xcoord + 2.5	if state == "AZ"
replace xcoord = xcoord - 2		if state == "NV"
replace ycoord = ycoord + 1.75 	if state == "NV"
replace ycoord = ycoord + 0.5 	if state == "UT"
replace xcoord = xcoord - 2.5	if state == "CO"
replace xcoord = xcoord - 0.75	if state == "NM"
replace ycoord = ycoord + 1.5	if state == "NM"
replace xcoord = xcoord - 1.75	if state == "WY"
replace xcoord = xcoord - 0.5	if state == "NE"
replace ycoord = ycoord + 0.5	if state == "NE"
replace xcoord = xcoord - 0.75	if state == "KS"
replace ycoord = ycoord + 0.25	if state == "KS"
replace ycoord = ycoord - 1.25	if state == "OK"
replace xcoord = xcoord - 1.25	if state == "TX"
replace ycoord = ycoord + 2.5	if state == "TX"
replace xcoord = xcoord - 2	    if state == "LA"
replace ycoord = ycoord + 3	    if state == "LA"
replace xcoord = xcoord + 0.5   if state == "MS"
replace ycoord = ycoord + 2	    if state == "MS"
replace xcoord = xcoord - 0.5   if state == "AR"
replace ycoord = ycoord - 0.5	if state == "AR"
replace xcoord = xcoord - 0.5   if state == "GA"
replace ycoord = ycoord + 1	    if state == "GA"
replace xcoord = xcoord + 0.75  if state == "FL"
replace ycoord = ycoord - 0.25  if state == "TN"
replace xcoord = xcoord + 0.25  if state == "TN"
replace xcoord = xcoord - 2.25  if state == "NC"
replace xcoord = xcoord - 1.5   if state == "NY"
replace ycoord = ycoord + 2	    if state == "NY"
replace xcoord = xcoord - 1.75  if state == "WI"
replace ycoord = ycoord - 0.75	if state == "WI"
replace xcoord = xcoord - 1.5   if state == "MN"
replace xcoord = xcoord + 1.25  if state == "MI"
replace ycoord = ycoord - 3	    if state == "MI"
replace xcoord = xcoord + 0.5   if state == "IN"
replace ycoord = ycoord + 1	    if state == "IN"
replace xcoord = xcoord - 0.5   if state == "OH"
replace ycoord = ycoord - 1.75	if state == "OH"
replace xcoord = xcoord + 1.5   if state == "KY"
replace xcoord = xcoord - 1.5   if state == "VA"
replace ycoord = ycoord + 0.25	if state == "VA"
replace xcoord = xcoord - 0.25  if state == "ME"
replace ycoord = ycoord + 1.25	if state == "ME"
replace xcoord = xcoord + 3	    if state == "HI"
replace ycoord = ycoord - 0.5	if state == "HI"
replace ycoord = ycoord + 2.5	if state == "VT"
replace xcoord = xcoord + 2.25  if state == "NH"
replace ycoord = ycoord - 0.5   if state == "NH"
replace xcoord = xcoord + 3.25  if state == "DC"
replace ycoord = ycoord - 2.75  if state == "DC"
replace xcoord = xcoord + 3.25  if state == "MD"
replace ycoord = ycoord - 1.25  if state == "MD"
replace xcoord = xcoord + 2.75  if state == "DE"
replace ycoord = ycoord - 1     if state == "DE"
replace xcoord = xcoord + 2.25  if state == "NJ"
replace ycoord = ycoord - 1     if state == "NJ"
replace xcoord = xcoord + 1.25  if state == "CT"
replace ycoord = ycoord - 1.75  if state == "CT"
replace xcoord = xcoord + 1     if state == "RI"
replace ycoord = ycoord - 1.25  if state == "RI"
replace xcoord = xcoord + 1.75  if state == "MA"
replace ycoord = ycoord + 0.5   if state == "MA"


