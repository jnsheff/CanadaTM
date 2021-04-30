* CA_TM_csvcleanup.do
* A script to convert .csv data files in the Canada Trademarks Dataset to .dta format
* and convert fields to more efficient data types
*
* NB: filepaths are based on the author's file structure; 
* other users should change the filepaths to point to the source and destination folders they wish to use.
* This may be done by performing a search-and-replace in this do-file, 
* replacing the partial path "/Volumes/TMData/Canada/csv" with the path of the folder where the user has stored their csv files,
* and replacing the partial path "/Volumes/TMData/Canada/" with the parent of that folder.

* CA_TM_main

	import delimited "/Volumes/TMData/Canada/csv/CA_TM_main.csv", ///
		case(preserve) stringcols(1 2 5 6) encoding(UTF-8)clear
		
	* Encode string dates as datetime variables
	foreach var in StatusDate AppDate PubDate AllowDate AbanDate RegDate RenewedDate TermDate {
		gen double tcode_`var' = date(`var', "YMD")
		format tcode_`var' %tdDD_Mon_CCYY
		order tcode_`var', after(`var')
		drop `var'
		rename tcode_`var' `var'
		}
	foreach var in CurrStatus MarkType {
		encode `var', gen(`var'_code)
		order `var'_code, after(`var')
		drop `var'
		rename `var'_code `var'
		}
		
	* Label categorical variables

	label define legislabel ///
		1 "Trade-marks Act (TMA)" ///
		2 "Unfair Competition Act (UCA)" ///
		3 "Trade Mark and Design Act (TMDA)" ///
		4 "Newfoundland Trade Marks (prior to joining Confederation) (NFLD)" ///
		5 "Act pertaining to Trade Marks (pre Confederation) (ATM)" ///
		6 "an Act to Incorporate the Canadian General Council of Boy Scouts" ///
		7 "an Act to Incorporate the Canadian General Council of Girl Guides" ///
		8 "Plant Breeder's Rights Act (PBRA)" ///
		9 "an Act respecting The Royal Canadian Legion"

	label values LegisCode legislabel
	drop LegisDesc
	rename LegisCode Legis

	label define markclasslabel ///
		1 "Trade-Mark" ///
		2 "Prohibited Mark; Official Mark" ///
		3 "Prohibited Mark; Arms, Crest or Flag" ///
		4 "Certification Mark" ///
		5 "Distinguishing Guise" ///
		6 "Prohibited Mark; Flag" ///
		7 "General Mark" ///
		8 "Prohibited Mark; Sign or Hallmark" ///
		9 "Prohibited Mark; Armorial Bearings" ///
		10 "Prohibited Mark; Abbreviation of the Name" ///
		11 "Prohibited Mark; Name" ///
		12 "Specific Mark" ///
		13 "Standardization Mark" ///
		14 "Union Label" ///
		15 "Denomination" ///
		16 "Geographical Indication" ///
		17 "Mark Protected by Federal Act of Incorporation" ///
		18 "Mark Protected by an Act Respecting the Royal Canadian Legion" ///
		19 "Prohibited Mark; Emblem" ///
		20 "Prohibited Mark; Arms, Crest or Emblem" ///
		21 "Prohibited Mark; Badge, Crest, Emblem or Mark"

	label values MarkClassCode markclasslabel
	drop MarkClassDesc
	rename MarkClassCode MarkClass

	label define Section9label ///
		1 "Paragraph 9(1)(e) - Government Flags" ///
		2 "Subparagraph 9(1)(n)(i) - Her Majesties Forces" ///
		3 "Subparagraph 9(1)(n)(ii) - Universities" ///
		4 "Subparagraph 9(1)(n)(iii) - Public Authorities in Canada for specific goods and services" ///
		5 "Paragraph 9(1)(n.1) - Armorial Emblems" ///
		6 "Paragraph 9(1)(i) - Foreign Government Flags and Symbols and 6ter applications" ///
		7 "Paragraph 9(1)(i.1) - 6ter - Official Sign or Hallmark" ///
		8 "Paragraph 9(1)(i.3) - 6ter - Armorial Bearing/Emblem or Abbreviation of Name" ///
		9 "Paragraph 9(1)(i.2) - 6ter - National Flag of a Country of the Union"

	label values Section9Code Section9label
	drop Section9Desc
	rename Section9Code Section9

	label define GIlabel ///
		1 "Wine" ///
		2 "Spirit" ///
		3 "Agricultural Product or Food"
		
	label values GICode GIlabel
	drop GIDesc
	rename GICode GI

	* Optimize variable types
	recast strL TMText OwnerName
	compress

	save "/Volumes/TMData/Canada/dta/CA_TM_main.dta", replace
	
* CA_TM_goods

	import delimited "/Volumes/TMData/Canada/csv/CA_TM_goods.csv", case(preserve) stringcols(1 2) encoding(UTF-8)clear
	compress
	save "/Volumes/TMData/Canada/dta/CA_TM_goods.dta", replace
	
* CA_TM_classes

	import delimited "/Volumes/TMData/Canada/csv/CA_TM_classes.csv", case(preserve) stringcols(1 2) encoding(UTF-8)clear
	compress
	save "/Volumes/TMData/Canada/dta/CA_TM_classes.dta", replace
	
* CA_TM_vienna

	import delimited "/Volumes/TMData/Canada/csv/CA_TM_vienna.csv", case(preserve) stringcols(1 2) encoding(UTF-8)clear
	compress
	save "/Volumes/TMData/Canada/dta/CA_TM_vienna.dta", replace

*CA_TM_parties

	import delimited "/Volumes/TMData/Canada/csv/CA_TM_parties.csv", case(preserve) stringcols(1 2) encoding(UTF-8)clear
	* Encode categorical variables to save memory
	foreach var in PartyType ProceedingType Province {
		encode `var', gen(`var'_code)
		order `var'_code, after(`var')
		drop `var'
		rename `var'_code `var'
		}
	* Combine French and English province labels, set to English (except Québec)
		replace Province = 2 if Province == 3
		replace Province = 5 if Province == 8
		replace Province = 6 if Province == 17
		replace Province = 10 if Province == 9
		replace Province = 13 if Province == 19
		replace Province = 15 if Province == 14
	compress		
	save "/Volumes/TMData/Canada/dta/CA_TM_parties.dta", replace

* CA_TM_allevents

	import delimited "/Volumes/TMData/Canada/csv/CA_TM_allevents.csv", case(preserve) stringcols(1 2) encoding(UTF-8)clear
	
	* Encode string dates as datetime variables
	foreach var in FilingDate EventDate {	
		gen double tcode_`var' = date(`var', "YMD")
		format tcode_`var' %tdDD_Mon_CCYY
		order tcode_`var', after(`var')
		drop `var'
		rename tcode_`var' `var'
		}

	* Encode categorical variables to save memory
	foreach var in EventType StageDesc EventDesc {
		encode `var', gen(`var'_code)
		order `var'_code, after(`var')
		drop `var'
		rename `var'_code `var'
		}
	compress
	save "/Volumes/TMData/Canada/dta/CA_TM_allevents.dta", replace

* CA_TM_priority

	import delimited "/Volumes/TMData/Canada/csv/CA_TM_priority.csv", case(preserve) stringcols(1 2) encoding(UTF-8)clear
	* Encode string dates as datetime variables
	gen double tcode_PriorityDate = date(PriorityDate, "YMD")
	format tcode_PriorityDate %tdDD_Mon_CCYY
	order tcode_PriorityDate, after(PriorityDate)
	drop PriorityDate
	rename tcode_PriorityDate PriorityDate
	compress
	save"/Volumes/TMData/Canada/dta/CA_TM_priority.dta", replace

* CA_TM_claims

	import delimited "/Volumes/TMData/Canada/csv/CA_TM_claims.csv", ///
		case(preserve) stringcols(1 2 8 9 10) encoding(UTF-8)clear
	* Clean up partial date formats, convert to datetime variables
	replace Month = "0" + Month if ustrlen(Month) == 1
	replace Month = Year + "/" + Month
	replace Date = Month + "/" + Date
	gen double claimYear = yearly(Year, "Y")
	format claimYear %tyCCYY
	gen double claimMonth = monthly(Month, "YM")
	format claimMonth %tmMon_CCYY
	gen double claimDate = date(Date, "YMD")
	format claimDate %tdDD_Mon_CCYY
	drop Year Month Date
	rename claimYear Year
	rename claimMonth Month
	rename claimDate Date
	order Year Month Date, after(ClaimDesc)
	* Encode categorical variables as labeled numeric variables
	tostring ClaimTypeCode, gen(ClaimTypeString)
	tostring ClaimCode, gen(ClaimCodeString)
	gen CompoundCode = ClaimTypeString + ClaimCodeString if ClaimCodeString != "."
	destring CompoundCode, replace
	order CompoundCode, after(ClaimCode)
	drop ClaimCode
	rename CompoundCode ClaimCode
	label define ClaimCodelabel ///
		101 "Date of Making Known in Canada" ///
		102 "Made Known in Canada since" ///
		103 "Made Known in Canada since at least as early as" ///
		104 "Made Known in Canada since as early as" ///
		105 "Made Known in Canada since at least" ///
		106 "entire text" ///
		107 "Made Known in Canada since before" ///
		111 "Used in Canada since" ///
		112 "Used in Canada since at least as early as" ///
		113 "Used in Canada since at least" ///
		114 "Used in Canada since as early as" ///
		115 "Date of first use in Canada" ///
		116 "entire text" ///
		117 "Used in Canada since before" ///
		171 "Registrability Recognized under Section 14 of the Trade-marks Act" ///
		172 "Registrability Recognized under Section 12(2) of the Trade-marks Act" ///
		173 "Registration is subject to the provisions of Section 67(1) of the Trade-marks Act, in view of Newfoundland Registration No." ///
		174 "Entire text" ///
		175 "Registrability Recognized under Rule 10 of the Trade Mark and Design Act" ///
		176 "Registrability Recognized under Section 28(1)(d) of the Unfair Competition Act" ///
		177 "Benefit of Section 14 of the Trade-marks Act is claimed"
	label values ClaimCode ClaimCodelabel
	label define ClaimTypeLabel ///
		10 "Made Known in Canada" ///
		11 "Used in Canada" ///
		12 "Priority Filing" ///
		13 "Foreign Use" ///
		14 "Foreign Registration" ///
		15 "Proposed Use in Canada" ///
		16 "Declaration of Use" ///
		17 "Registrability Recognized" ///
		18 "Foreign Application"
	label values ClaimTypeCode ClaimTypeLabel
	drop ClaimTypeDesc ClaimTypeString ClaimCodeString
	rename ClaimTypeCode ClaimType
	recast strL ClaimedGoods
	compress
	save "/Volumes/TMData/Canada/dta/CA_TM_claims.dta", replace


