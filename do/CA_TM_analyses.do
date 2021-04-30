* CA_TM_analyses.do
* A script to build timeseries and other data structures from the Canada Trademarks Dataset .dta files for descriptive analysis
*
* NB: filepaths are based on the author's file structure; 
* other users should change the filepaths to point to the source and destination folders they wish to use.
* This may be done by performing a search-and-replace in this do-file, 
* replacing the partial path "/Volumes/TMData/Canada/dta" with the path of the folder where the user has stored their dta files,
* and replacing the partial path "/Volumes/TMData/Canada/" with the parent of that folder.

	
* create folder to store analyses if not already created
	capture confirm file "/Volumes/TMData/Canada/analyses"
	if _rc {
		mkdir "/Volumes/TMData/Canada/analyses"
		}

* create monthly and yearly application date cohort variables for generating panels and time series
	
	use /Volumes/TMData/Canada/dta/CA_TM_main.dta, clear
	
	gen month_group = mofd(AppDate) //creates a new variable coding each observation into monthly cohorts by filing date, to be used to generate a frequency time-series
	format %tmMonth_CCYY month_group //formats the new monthly cohort variable.
	
	gen year_group = yofd(AppDate) //creates a new variable coding each observation into yearly cohorts by filing date, to be used to generate a frequency time-series
	format %tyCCYY year_group //formats the new yearly cohort variable.
	
	keep AppNo ExtNo month_group year_group
	
	save /Volumes/TMData/Canada/analyses/CA_TM_cohorts.dta, replace
	
* Generate pendency lag calculations for events of interest

	use /Volumes/TMData/Canada/dta/CA_TM_allevents.dta, clear
	keep if EventType == 2 & EventCode == 20 // identify records of first examiner report events
	keep AppNo ExtNo EventDate
	by AppNo ExtNo, sort: egen newdate = min(EventDate) // for applications with multiple first examiner report events, keep only the earliest
	drop EventDate
	format %tdDD_Mon_CCYY newdate
	rename newdate OfficeActionDate
	duplicates drop
	sort AppNo ExtNo
	merge 1:1 /// collate first office action dates with other lifecycle milestone dates
		AppNo ExtNo ///           
		using /Volumes/TMData/Canada/dta/CA_TM_main.dta, ///
		keepusing(AppDate AbanDate RegDate PubDate AllowDate Oppn Canceln RenewedDate RegNo CurrStatus) ///
		keep(match using) ///
		nogen
	foreach x in Allow Pub Aban OfficeAction { // calculate pendencies from application filing dates for prosecution milestones with date information
		gen `x'lag = `x'Date - AppDate if (!missing(`x'Date) & `x'Date > AppDate & !missing(AppDate)) // exclude date information that seems erroneous
		replace `x'lag = . if `x'Date > RegDate // clear entries where data entry errors seem probable (registration after other prosecution milestones)
		}
	gen Reglag = RegDate - AppDate if (!missing(RegDate) & !missing(AppDate))
	foreach x in Reg Allow Pub Aban OfficeAction App { // create indicator values for prosecution milestones
		gen `x'_indic = 1 if !missing(`x'Date)
		replace `x'_indic = 0 if `x'_indic != 1
		}
	replace Reg_indic = 1 if !missing(RegNo) // set registration indicator to 1 for early records with reg #s but no dates
	drop RegNo
	gen Renewed_indic = 0 if Reg_indic == 1 // renewal indicator only for applications that have proceeded to registration
	gen NoUseDecln_indic = 0
	replace NoUseDecln_indic = 1 if (CurrStatus == "Abandoned Section 40(3)":CurrStatus_code | CurrStatus == "Cancelled - Subsection 16(3)":CurrStatus_code)
	replace Renewed_indic = 1 if !missing(RenewedDate)
	
	save /Volumes/TMData/Canada/analyses/CA_TM_tsdata.dta, replace
	
* Perform separate calculations for Oppositions and Cancellations
	use /Volumes/TMData/Canada/dta/CA_TM_allevents.dta, clear
	keep if (EventType > 2 | missing(EventType)) // isolate proceedings events
	egen InitDate = min(EventDate), by (AppNo ExtNo EventType ProceedingSeq) // identify earliest proceeding event for each proceeding
	egen ClosureDate = max(EventDate), by (AppNo ExtNo EventType ProceedingSeq) // identify latest proceeding event for each proceeding
	gen ProceedingLength = ClosureDate - InitDate
	replace InitDate = FilingDate if FilingDate < InitDate // compare earliest docketed event with proceeding "Effective Date" per CIPO, keep earliest
	* distinguish start and end dates between oppositions and cancellations
		gen OppStartDate = InitDate if EventType == 3
		gen CancelStartDate = InitDate if EventType > 3
		gen OppEndDate = ClosureDate if EventType == 3
		gen CancelEndDate = ClosureDate if EventType > 3
		foreach x in Opp Cancel {
			format %tdDD_Mon_CCYY `x'StartDate `x'EndDate
			}
	* merge with other lifecycle data
	merge m:1 AppNo ExtNo using /Volumes/TMData/Canada/dta/CA_TM_main.dta, keepusing(PubDate RegDate RegNo TermDate NonUse CurrStatus AbanDate RenewedDate NonUse) keep(match) nogen // collate with other milestones
	
	* Create indicator variable encoding successful oppositions as those abandoned during opposition proceedings or coded by CIPO as abandoned during the opposition stage
		gen OppSuccess_indic = 0 if EventType == 3
		replace OppSuccess_indic = 1 if (!missing(OppSuccess_indic) & (AbanDate >= OppStartDate & AbanDate <= OppEndDate) | CurrStatus == "Abandoned - Section 38(7)":CurrStatus_code)

	* Create indicator variable encoding successful cancellation petitions as those which were either:
		* 1 terminated during cancellation proceedings, or
		* 2 satisfies the criteria:
			* a) terminated less than 15 years after the most recent renewal date (or registration date if less than 15 years old), and
			* b) terminated less than 1 year after the end of the cancellation proceeding
		* or 
		* 3 encoded with a status indicating they were expunged by CIPO during expungement proceedings, or
		
		gen CancelSuccess_indic = 0 if EventType > 3
		
		replace CancelSuccess_indic = 1 if ///
			(!missing(CancelSuccess_indic) & ((TermDate <= CancelEndDate) & (TermDate >= CancelStartDate))) // Condition 1
			
		replace CancelSuccess_indic = 1 if ///
			(!missing(CancelSuccess_indic) & /// condition 2
				( ///
					((TermDate - CancelEndDate) < 120) & ///
						( ///
							(!missing(RenewedDate) & ((TermDate - RenewedDate) < (15*365))) | /// termination within 15 years of most recent renewal, or
							(missing(RenewedDate) & ((TermDate - RegDate) < (15*365))) /// termination within 15 years of registration not yet renewed
						) ///
				) ///
			)
			
		replace CancelSuccess_indic = 1 if (CurrStatus == "Expunged Section 45(3)":CurrStatus_code) // condition 3


	* Generate pendency calculations for:
		* Time from publication to first opposition
			gen OppLag = OppStartDate - PubDate if (EventType == 3 & !missing(PubDate)) // calculate time from publication/advertisement to opposition
		* Time from registration to first cancellation proceeding
			gen CancelLag = CancelStartDate - RegDate if (EventType > 3 & !missing(RegDate)) // calculate time from registration to cancellation petition
	* clear entries with negative pendencies (likely attributable to data entry errors)
		foreach x in Opp Cancel {
			replace `x'Lag = . if `x'Lag < 0 // 
			}
	* identify earliest proceeding institution date for each application (where multiple proceedings of one type are present), keep only the earliest
		foreach x in OppLag CancelLag { // 
			gsort AppNo ExtNo -`x'
			by AppNo ExtNo: replace `x' = `x'[_N]
			}
	
	keep AppNo ExtNo EventType ProceedingSeq ProceedingLength OppLag CancelLag CancelSuccess_indic OppSuccess_indic InitDate OppStartDate OppEndDate AbanDate RenewedDate CancelStartDate CancelEndDate TermDate CurrStatus // clean up
	duplicates drop
	* generate and format proceeding cohort variables
		gen proceeding_year_group = yofd(InitDate)
		gen proceeding_month_group = mofd(InitDate)
		format %tmMonth_CCYY proceeding_month_group
		format %tyCCYY proceeding_year_group
	drop InitDate
	order AppNo ExtNo EventType ProceedingSeq OppStartDate OppEndDate AbanDate CancelStartDate CancelEndDate TermDate OppSuccess_indic CancelSuccess_indic OppLag CancelLag ProceedingLength proceeding_year_group proceeding_month_group
	
	save /Volumes/TMData/Canada/analyses/CA_TM_proceedings_tsdata.dta, replace
	
* merge pendency data and lifecycle indicator data into a single file for timeseries analysis
	
	use /Volumes/TMData/Canada/analyses/CA_TM_proceedings_tsdata.dta, clear
	keep AppNo ExtNo CancelLag OppLag
	duplicates drop
	merge 1:1 AppNo ExtNo using /Volumes/TMData/Canada/analyses/CA_TM_tsdata.dta, keep(match using) nogen
	merge 1:1 AppNo ExtNo using /Volumes/TMData/Canada/analyses/CA_TM_cohorts.dta, keep(match using) nogen
	save /Volumes/TMData/Canada/analyses/CA_TM_tsdata.dta, replace
	
* generate yearly and monthly time series datasets

	use /Volumes/TMData/Canada/analyses/CA_TM_tsdata.dta, clear
	foreach y in year month {

		preserve
		collapse /// calculate means of rates and pendencies and application counts per period
			(mean) Reg_indic Allow_indic Pub_indic Aban_indic OfficeAction_indic Renewed_indic NoUseDecln_indic ///
			(mean) Reglag Allowlag Publag OfficeActionlag Abanlag OppLag CancelLag ///
			(count) App_indic, ///
			by(`y'_group)
		foreach x in Reg Allow Pub Aban OfficeAction Renewed App NoUseDecln {
			rename `x'_indic `x'_Rate
			}
		foreach x in Reg Allow Pub Aban OfficeAction Renewed NoUseDecln {
			replace `x'_Rate = `x'_Rate*100
			}
		save /Volumes/TMData/Canada/analyses/CA_TM_`y'ly_timeseries, replace
		restore
		preserve
		collapse /// calculate means of cancellation petition rates per period, against registered applications
			(mean) Canceln if Reg_indic == 1, ///
			by(`y'_group)
		rename Canceln Canceln_Rate
		replace Canceln_Rate = Canceln_Rate *100
		save /Volumes/TMData/Canada/analyses/CA_TM_`y'ly_canceln, replace
		restore
		preserve
		collapse /// calculate means of opposition rates per period, against published or registered applications
			(mean) Oppn if (Pub_indic == 1 | Reg_indic == 1), ///
			by(`y'_group)
		rename Oppn Oppn_Rate
		replace Oppn_Rate = Oppn_Rate *100
		save /Volumes/TMData/Canada/analyses/CA_TM_`y'ly_oppn, replace
		restore
		preserve
		use /Volumes/TMData/Canada/analyses/CA_TM_`y'ly_timeseries, clear
		merge 1:1 `y'_group using /Volumes/TMData/Canada/analyses/CA_TM_`y'ly_oppn, nogen
		merge 1:1 `y'_group using /Volumes/TMData/Canada/analyses/CA_TM_`y'ly_canceln, nogen
		tsset `y'_group
		save /Volumes/TMData/Canada/analyses/CA_TM_`y'ly_timeseries, replace
		restore
		}

* generate daily application, Nice Class, Applicant, and attorney data for June 2019

	use /Volumes/TMData/Canada/analyses/CA_TM_tsdata.dta, clear
	keep if month_group == tm(2019-06) // identify relevant applications
	merge 1:m AppNo ExtNo using /Volumes/TMData/Canada/dta/CA_TM_parties.dta, keepusing(PartyType PartyName) keep(match) nogen // merge with parties data
	keep if (PartyType == 1 | PartyType == 3) // identify applicants and their representatives
	gen Applicant = PartyName if PartyType == 1
	gen Attorney = PartyName if PartyType == 3
	foreach x in Applicant Attorney { // duplicate applicant and representative names across all observations for each application, then deduplicate observations
		sort AppNo ExtNo `x'
		by AppNo ExtNo: replace `x' = `x'[_N]
		}
	drop PartyName PartyType
	duplicates drop
	merge 1:1 AppNo ExtNo using /Volumes/TMData/Canada/dta/CA_TM_classes.dta, keep(match) nogen // merge with Nice class data
	egen ClassCount = /// count classes claimed per application
		anycount(IC1 IC2 IC3 IC4 IC5 IC6 IC7 IC8 IC9 IC10 IC11 IC12 IC13 IC14 IC15 IC16 IC17 IC18 IC19 IC20 IC21 IC22 IC23 IC24 IC25 IC26 IC27 IC28 IC29 IC30 IC31 IC32 IC33 IC34 IC35 IC36 IC37 IC38 IC39 IC40 IC41 IC42 IC43 IC44 IC45), ///
		values(1)
	drop(IC1 IC2 IC3 IC4 IC5 IC6 IC7 IC8 IC9 IC10 IC11 IC12 IC13 IC14 IC15 IC16 IC17 IC18 IC19 IC20 IC21 IC22 IC23 IC24 IC25 IC26 IC27 IC28 IC29 IC30 IC31 IC32 IC33 IC34 IC35 IC36 IC37 IC38 IC39 IC40 IC41 IC42 IC43 IC44 IC45)
	save /Volumes/TMData/Canada/analyses/CA_TM_June_2019_apps.dta, replace
	preserve
	collapse /// calculate average application counts and class claims per application
		(mean) ClassCount ///
		(count) App_indic, ///
		by(AppDate)
	tsset AppDate
	rename App_indic Applications
	save /Volumes/TMData/Canada/analyses/CA_TM_June_2019_timeseries.dta, replace
	restore
	foreach x in Attorney Applicant {
		preserve
		keep if AppDate == td(12june2019)
		contract `x', freq(Applications)
		gsort -Applications
		save /Volumes/TMData/Canada/analyses/CA_TM_June_12_2019_`x's.dta, replace
		restore
		}
	foreach x in Attorney Applicant {
		preserve
		contract `x', freq(Applications)
		gsort -Applications
		save /Volumes/TMData/Canada/analyses/CA_TM_June_2019_`x's.dta, replace
		restore
		}

* Generate yearly and monthly timeseries for proceedings data
	
	foreach y in year month {
		use /Volumes/TMData/Canada/analyses/CA_TM_proceedings_tsdata.dta, clear
		preserve
		collapse ///
			(mean) CancelSuccess_indic ProceedingLength ///
			(count) ProceedingSeq ///
			if EventType > 3, ///
			by(proceeding_`y'_group)
		rename CancelSuccess_indic Cancel_Success_Rate
		replace Cancel_Success_Rate = Cancel_Success_Rate * 100
		rename ProceedingLength Cancel_proceeding_length
		rename ProceedingSeq Cancel_Count
		save /Volumes/TMData/Canada/analyses/CA_TM_cancel_proceedings_`y'ly_timeseries, replace
		restore	
		preserve
		collapse ///
			(mean) ProceedingLength ///
			(count) ProceedingSeq ///
			if EventType > 3, ///
			by(proceeding_`y'_group CancelSuccess_indic)
		gen SuccessCancelCount = ProceedingSeq if CancelSuccess_indic == 1
		gen FailCancelCount = ProceedingSeq if CancelSuccess_indic == 0
		gen SuccessCancelLength = ProceedingLength if CancelSuccess_indic == 1
		gen FailCancelLength = ProceedingLength if CancelSuccess_indic == 0
		foreach x in SuccessCancelCount FailCancelCount SuccessCancelLength FailCancelLength {
			egen temp`x' = max(`x'), by(proceeding_`y'_group)
			order temp`x', after (`x')
			drop `x'
			rename temp`x' `x'
			}
		drop CancelSuccess_indic ProceedingLength ProceedingSeq
		duplicates drop
		merge 1:1 proceeding_`y'_group using /Volumes/TMData/Canada/analyses/CA_TM_cancel_proceedings_`y'ly_timeseries, nogen
		tsset proceeding_`y'_group
		save /Volumes/TMData/Canada/analyses/CA_TM_cancel_proceedings_`y'ly_timeseries, replace
		restore
		preserve
		collapse ///
			(mean) OppSuccess_indic ProceedingLength ///
			(count) ProceedingSeq ///
			if EventType == 3, ///
			by(proceeding_`y'_group)
		rename OppSuccess_indic Opp_Success_Rate
		replace Opp_Success_Rate = Opp_Success_Rate * 100
		rename ProceedingLength Opp_proceeding_length
		rename ProceedingSeq Opp_Count
		save /Volumes/TMData/Canada/analyses/CA_TM_opp_proceedings_`y'ly_timeseries, replace
		restore
		collapse ///
			(mean) ProceedingLength ///
			(count) ProceedingSeq ///
			if EventType == 3, ///
			by(proceeding_`y'_group OppSuccess_indic)
		gen SuccessOppCount = ProceedingSeq if OppSuccess_indic == 1
		gen FailOppCount = ProceedingSeq if OppSuccess_indic == 0
		gen SuccessOppLength = ProceedingLength if OppSuccess_indic == 1
		gen FailOppLength = ProceedingLength if OppSuccess_indic == 0
		foreach x in SuccessOppCount FailOppCount SuccessOppLength FailOppLength {
			egen temp`x' = max(`x'), by(proceeding_`y'_group)
			order temp`x', after (`x')
			drop `x'
			rename temp`x' `x'
			}
		drop OppSuccess_indic ProceedingLength ProceedingSeq
		duplicates drop
		merge 1:1 proceeding_`y'_group using /Volumes/TMData/Canada/analyses/CA_TM_opp_proceedings_`y'ly_timeseries, nogen
		tsset proceeding_`y'_group
		save /Volumes/TMData/Canada/analyses/CA_TM_opp_proceedings_`y'ly_timeseries, replace
		merge 1:1 proceeding_`y'_group using /Volumes/TMData/Canada/analyses/CA_TM_cancel_proceedings_`y'ly_timeseries, nogen
		tsset proceeding_`y'_group
		save /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_`y'ly_timeseries, replace
		}
		
* Nice Classes
	
	use /Volumes/TMData/Canada/dta/CA_TM_classes.dta, clear
	preserve
	egen ClassCount = /// count classes claimed per application
		anycount(IC1 IC2 IC3 IC4 IC5 IC6 IC7 IC8 IC9 IC10 IC11 IC12 IC13 IC14 IC15 IC16 IC17 IC18 IC19 IC20 IC21 IC22 IC23 IC24 IC25 IC26 IC27 IC28 IC29 IC30 IC31 IC32 IC33 IC34 IC35 IC36 IC37 IC38 IC39 IC40 IC41 IC42 IC43 IC44 IC45), ///
		values(1)
	drop(IC1 IC2 IC3 IC4 IC5 IC6 IC7 IC8 IC9 IC10 IC11 IC12 IC13 IC14 IC15 IC16 IC17 IC18 IC19 IC20 IC21 IC22 IC23 IC24 IC25 IC26 IC27 IC28 IC29 IC30 IC31 IC32 IC33 IC34 IC35 IC36 IC37 IC38 IC39 IC40 IC41 IC42 IC43 IC44 IC45)
	merge 1:1 AppNo ExtNo using /Volumes/TMData/Canada/analyses/CA_TM_cohorts.dta, nogen
	collapse (mean) ClassCount, by(year_group)
	save /Volumes/TMData/Canada/analyses/CA_TM_classcounts.dta, replace
	restore
	merge 1:1 AppNo ExtNo using /Volumes/TMData/Canada/analyses/CA_TM_cohorts.dta, nogen
	preserve
	collapse (sum) IC1 IC2 IC3 IC4 IC5 IC6 IC7 IC8 IC9 IC10 IC11 IC12 IC13 IC14 IC15 IC16 IC17 IC18 IC19 IC20 IC21 IC22 IC23 IC24 IC25 IC26 IC27 IC28 IC29 IC30 IC31 IC32 IC33 IC34 IC35 IC36 IC37 IC38 IC39 IC40 IC41 IC42 IC43 IC44 IC45, by(year_group)
	save /Volumes/TMData/Canada/analyses/CA_TM_classbars.dta, replace
	restore
	
* Filing Bases, based on CA_TM_main indicator variables

	use /Volumes/TMData/Canada/dta/CA_TM_main.dta, clear
	merge 1:1 AppNo ExtNo using /Volumes/TMData/Canada/analyses/CA_TM_cohorts.dta, nogen
	preserve
	collapse (sum) ForeignAppBasis ForeignRegBasis UseBasis ITUBasis NoBasis, by (year_group)
	tsset year_group
	save /Volumes/TMData/Canada/analyses/CA_TM_basis_counts.dta, replace
	restore
	collapse (mean) ForeignAppBasis ForeignRegBasis UseBasis ITUBasis NoBasis, by (year_group)
	foreach x in ForeignAppBasis ForeignRegBasis UseBasis ITUBasis NoBasis {
		replace `x' = `x' * 100
		}
	tsset year_group
	save /Volumes/TMData/Canada/analyses/CA_TM_basis_rates.dta, replace
	
* Filing Bases, based on CA_TM_claims

	use /Volumes/TMData/Canada/dta/CA_TM_claims.dta, clear
	merge m:1 AppNo ExtNo using /Volumes/TMData/Canada/dta/CA_TM_main.dta, keepusing(AppDate) nogen
	foreach x in Year Month Date {
		egen min`x' = min(`x'), by (AppNo ExtNo ClaimType)
		}
	format %tdDD_Mon_CCYY minDate
	format %tyCCYY minYear
	format %tmMonth_CCYY minMonth
	gen AppYear = yofd(AppDate)
	format %tyCCYY AppYear
	gen AppMonth = mofd(AppDate)
	format %tmMonth_CCYY AppMonth
	drop ClaimSerialNo ClaimCode ClaimDesc Country ForeignDocNo ClaimedGoods Year Month Date
	duplicates drop
	gen byte atFiling = . 
	replace atFiling = 1 if ((AppYear >= minYear) & !missing(minYear))
		replace atFiling = 0 if AppMonth < minMonth & !missing(minMonth)
	replace atFiling = 1 if ((AppMonth >= minMonth) & !missing(minMonth))
		replace atFiling = 0 if AppDate < minDate & !missing(minDate)
	replace atFiling = 1 if ((AppDate >= minDate) & !missing(minDate))
	replace atFiling = 0 if missing(AppDate)
	order AppNo ExtNo ClaimType atFiling AppDate minDate AppMonth minMonth AppYear minYear
	forvalues x = 10/18 {
		gen byte v_`x' = 0
		replace v_`x' = 1 if ClaimType == `x'
		}
	replace v_11 = 0 if atFiling == 0
	egen MadeKnown = max(v_10), by(AppNo ExtNo)
	egen Used = max(v_11), by(AppNo ExtNo)
	egen Priority = max(v_12), by(AppNo ExtNo)
	egen ForeignUse = max(v_13), by(AppNo ExtNo)
	egen ForeignReg = max(v_14), by(AppNo ExtNo)
	egen ProposedUse = max(v_15), by(AppNo ExtNo)
	egen DeclnUse = max(v_16), by(AppNo ExtNo)
	egen RegRecg = max(v_17), by(AppNo ExtNo)
	egen ForeignApp = max(v_18), by(AppNo ExtNo)
	gen  ImpliedProposedUse = 0
	replace ImpliedProposedUse = 1 if ProposedUse == 1
	replace ImpliedProposedUse = 1 if DeclnUse == 1
	forvalues x = 10/18 {
		drop v_`x'
		}
	keep AppNo ExtNo MadeKnown Used Priority ForeignUse ForeignReg ProposedUse DeclnUse RegRecg ForeignApp ImpliedProposedUse
	duplicates drop
	merge 1:1 AppNo ExtNo using /Volumes/TMData/Canada/analyses/CA_TM_cohorts.dta, keepusing(year_group) nogen
	save /Volumes/TMData/Canada/analyses/CA_TM_basis_types.dta, replace
	collapse (mean) MadeKnown Used Priority ForeignUse ForeignReg ProposedUse DeclnUse RegRecg ForeignApp ImpliedProposedUse, ///
		by(year_group)
	foreach x in MadeKnown Used Priority ForeignUse ForeignReg ProposedUse DeclnUse RegRecg ForeignApp ImpliedProposedUse {
		replace `x' = `x' * 100
		}
	tsset year_group
	save /Volumes/TMData/Canada/analyses/CA_TM_basis_timeseries.dta, replace
	
* Country of Origin

	use /Volumes/TMData/Canada/dta/CA_TM_parties.dta, clear
	keep if PartyType < 3 // keep only applicant and current owner data
	keep AppNo ExtNo PartyType Province Country
	duplicates drop
	foreach x in Country Province { // create separate variables for applicant and current owner nationality
		gen applicant`x' = `x' if PartyType == 1
		gen owner`x' = `x' if PartyType == 2
		foreach y in applicant owner { // 
			sort AppNo ExtNo `y'`x'
			by AppNo ExtNo: replace `y'`x' = `y'`x'[_N]
			}
		}
	label values applicantProvince Province_code
	label values ownerProvince Province_code
	drop PartyType Province Country
	foreach x in Province Country { // set province and country values to applicant value if present, otherwise to current owner value
		gen `x' = owner`x'
		replace `x' = applicant`x' if !missing(applicant`x')
		drop owner`x' applicant`x'
		}
	label values Province Province_code
	duplicates drop
	merge 1:1 AppNo ExtNo using /Volumes/TMData/Canada/analyses/CA_TM_cohorts.dta, nogen // add application-year cohorts and save
	save /Volumes/TMData/Canada/analyses/CA_TM_filer_nationalities.dta, replace
	
	* Create yearly country and province panels from individual application records
		by year_group Country, sort: gen Country_count = [_N]
		by year_group Province, sort: gen Province_count = [_N] if Country == "CA"
		preserve
		keep year_group Country Country_count
		duplicates drop
		encode Country, gen(ctry)
		xtset ctry year_group
		save /Volumes/TMData/Canada/analyses/CA_TM_country_app_panels.dta, replace
		restore
		keep if Country == "CA"
		keep year_group Province Province_count
		duplicates drop
		xtset Province year_group
		save /Volumes/TMData/Canada/analyses/CA_TM_province_app_panels.dta, replace
	
	* Create summary yearly country panels with top 5 countries and all others added together, for graphing clarity
		use /Volumes/TMData/Canada/analyses/CA_TM_country_app_panels.dta, clear
		sort year_group Country_count
		keep if year_group > 1978
		drop if missing(year_group)
		by year_group: gen other_count = sum(Country_count)
		by year_group: replace other_count = 0 if [_n] > ([_N]-5)
		egen other = max(other_count), by(year_group)
		replace ctry = . if other == other_count
		by year_group: keep if [_n] > ([_N]-6)
		order year_group ctry Country_count
		keep year_group ctry Country_count
		rename ctry Country
		rename Country_count Applications
		xtset Country year_group
		sort year_group Applications
		save /Volumes/TMData/Canada/analyses/CA_TM_country_app_yearly_summary.dta, replace
		
	* Reshape for better bar chart presentation
		use /Volumes/TMData/Canada/analyses/CA_TM_country_app_yearly_summary.dta, clear
		decode Country, gen(country)
		drop(Country)
		replace country = "Other" if missing(country)
		reshape wide Applications, i(year_group) j(country, string)
		foreach x in CA CH CN DE FR GB JP Other US {
			rename Applications`x' `x'
			label variable `x'
			}
		save /Volumes/TMData/Canada/analyses/CA_TM_country_barchart_data.dta, replace
		
	* Create summary yearly province panels grouping less populated provinces by region, for graphing clarity
		use /Volumes/TMData/Canada/analyses/CA_TM_province_app_panels.dta, clear
		sort year_group Province_count
		keep if year_group > 1978
		drop if missing(year_group)
				
		* Generate regional grouping for less populous provinces, calculate application totals by region
		gen Region = Province
		label values Region Province_code
		decode Region, generate(region_text)
		
		replace region_text = "North" if ///
			(region_text == "NORTHWEST TERRITORIES") | ///
			(region_text == "YUKON") | /// 
			(region_text == "NUNAVUT") 
			
		replace region_text = "Atlantic" if ///
			(region_text == "NEWFOUNDLAND AND LABRADOR") | ///
			(region_text == "PRINCE EDWARD ISLAND") | /// 
			(region_text == "NEW BRUNSWICK") | ///
			(region_text == "NOVA SCOTIA") 
			
		replace region_text = "Prairie" if ///
			(region_text == "ALBERTA") | ///
			(region_text == "MANITOBA") | /// 
			(region_text == "SASKATCHEWAN") 
			
		* Encode most populous Provinces as their own regions
		replace region_text = "Ontario" if region_text == "ONTARIO"
		replace region_text = "Québec" if region_text == "QUÉBEC"
		replace region_text = "British Columbia" if region_text == "BRITISH COLUMBIA"
		
		* Clean up; generate regional panels
		drop Region
		encode region_text, gen(Region)
		sort year_group Province_count
		egen region_count = sum(Province_count), by(year_group Region)		
		keep year_group Region region_count
		rename region_count Applications
		duplicates drop
		xtset Region year_group
		sort year_group Applications
		save /Volumes/TMData/Canada/analyses/CA_TM_region_app_yearly_summary.dta, replace
		
	* Foreign Priority and Foreign Claim Analysis
		use /Volumes/TMData/Canada/dta/CA_TM_claims.dta, clear
		keep if !missing(Country)
		keep if Country != "XX"
		keep AppNo ExtNo Country
		duplicates drop
		save /Volumes/TMData/Canada/analyses/CA_TM_claim_countries.dta, replace
		use /Volumes/TMData/Canada/dta/CA_TM_priority.dta, clear
		keep if !missing(PriorityCountry)
		keep if PriorityCountry != "XX"
		keep AppNo ExtNo PriorityCountry
		rename PriorityCountry Country
		save /Volumes/TMData/Canada/analyses/CA_TM_priority_countries.dta, replace
		append using /Volumes/TMData/Canada/analyses/CA_TM_claim_countries.dta
		duplicates drop
		merge m:1 AppNo ExtNo using /Volumes/TMData/Canada/analyses/CA_TM_cohorts.dta, keep(match master) nogen
		save /Volumes/TMData/Canada/analyses/CA_TM_all_filed_countries.dta, replace
		
		* Generate Panel Data and summary for bar chart presentation
			use /Volumes/TMData/Canada/analyses/CA_TM_all_filed_countries.dta, clear
			by year_group Country, sort: gen Applications = [_N]
			keep year_group Country Applications
			duplicates drop
			order year_group Country Applications
			sort year_group Applications
			save /Volumes/TMData/Canada/analyses/CA_TM_priority_claim_panel.dta, replace
			keep if year_group > 1978
			by year_group: gen CumulativeApplications = sum(Applications)
			by year_group: replace CumulativeApplications = 0 if [_n] > ([_N]-5)
			egen lowrank = max(CumulativeApplications), by(year_group)
			replace Country = "Other" if CumulativeApplications == lowrank
			replace Applications = lowrank if Country == "Other"
			by year_group: keep if [_n] > ([_N]-6)
			keep year_group Country Applications
			reshape wide Applications, i(year_group) j(Country, string)
				foreach x in AU CH DE EM ES FR GB IT Other US {
					rename Applications`x' `x'
					label variable `x'
					}
			tsset year_group
			save /Volumes/TMData/Canada/analyses/CA_TM_filed_countries_barchart_data.dta, replace
		
* Nice Classification Analysis

	use /Volumes/TMData/Canada/analyses/CA_TM_cohorts.dta, clear
	merge 1:1 AppNo ExtNo using /Volumes/TMData/Canada/dta/CA_TM_classes.dta, nogen // merge with Nice class data
	egen ClassCount = /// count classes claimed per application
		anycount(IC1 IC2 IC3 IC4 IC5 IC6 IC7 IC8 IC9 IC10 IC11 IC12 IC13 IC14 IC15 IC16 IC17 IC18 IC19 IC20 IC21 IC22 IC23 IC24 IC25 IC26 IC27 IC28 IC29 IC30 IC31 IC32 IC33 IC34 IC35 IC36 IC37 IC38 IC39 IC40 IC41 IC42 IC43 IC44 IC45), ///
		values(1)
	save /Volumes/TMData/Canada/analyses/CA_TM_class_counts.dta, replace
	drop month_group
	collapse /// calculate average application counts and class claims per application
		(mean) ClassCount ///
		(sum) IC1 IC2 IC3 IC4 IC5 IC6 IC7 IC8 IC9 IC10 IC11 IC12 IC13 IC14 IC15 IC16 IC17 IC18 IC19 IC20 IC21 IC22 IC23 IC24 IC25 IC26 IC27 IC28 IC29 IC30 IC31 IC32 IC33 IC34 IC35 IC36 IC37 IC38 IC39 IC40 IC41 IC42 IC43 IC44 IC45, ///
		by(year_group)
	tsset year_group
	save /Volumes/TMData/Canada/analyses/CA_TM_classes_yearly_timeseries.dta, replace
	
	* Identify classes with greatest variability since 1993
	use /Volumes/TMData/Canada/analyses/CA_TM_classes_yearly_timeseries.dta, clear
	keep if year_group > 1993
	drop if missing(year_group)
	foreach x in min max {
		preserve
		collapse ///
			(`x') IC1 IC2 IC3 IC4 IC5 IC6 IC7 IC8 IC9 IC10 IC11 IC12 IC13 IC14 IC15 IC16 IC17 IC18 IC19 IC20 IC21 IC22 IC23 IC24 IC25 IC26 IC27 IC28 IC29 IC30 IC31 IC32 IC33 IC34 IC35 IC36 IC37 IC38 IC39 IC40 IC41 IC42 IC43 IC44 IC45
		xpose, clear varname
		rename v1 `x'
		rename _varname class
		order class
		save /Volumes/TMData/Canada/analyses/CA_TM_classes_`x'.dta, replace
		restore
		}
	use /Volumes/TMData/Canada/analyses/CA_TM_classes_max.dta, clear
	merge 1:1 class using /Volumes/TMData/Canada/analyses/CA_TM_classes_min.dta, nogen
	gen range = max - min
	gsort -range
	save /Volumes/TMData/Canada/analyses/CA_TM_classes_range.dta, replace
	
	* Variability by percentage share
	use /Volumes/TMData/Canada/analyses/CA_TM_classes_yearly_timeseries.dta, clear
	keep if year_group > 1993
	drop if missing(year_group)
	gen total = 0
	forvalues x = 1/45 {
		replace total = total + IC`x'
		}
	forvalues x = 1/45 {
		replace IC`x' = (IC`x'/total) * 100
		label variable IC`x' `x'
		}
	save /Volumes/TMData/Canada/analyses/CA_TM_class_percentages.dta, replace
	preserve
	xpose, clear varname
	gen delta = v26-v1
	keep _varname delta
	drop if _varname == "year_group" | _varname == "total"
	gen abs_delta = abs(delta)
	sort abs_delta
	save /Volumes/TMData/Canada/analyses/CA_TM_class_shares_delta.dta, replace
	restore
	foreach x in min max {
		preserve
		collapse ///
			(`x') IC1 IC2 IC3 IC4 IC5 IC6 IC7 IC8 IC9 IC10 IC11 IC12 IC13 IC14 IC15 IC16 IC17 IC18 IC19 IC20 IC21 IC22 IC23 IC24 IC25 IC26 IC27 IC28 IC29 IC30 IC31 IC32 IC33 IC34 IC35 IC36 IC37 IC38 IC39 IC40 IC41 IC42 IC43 IC44 IC45
		xpose, clear varname
		rename v1 `x'
		rename _varname class
		order class
		save /Volumes/TMData/Canada/analyses/CA_TM_class_shares_`x'.dta, replace
		restore
		}
	use /Volumes/TMData/Canada/analyses/CA_TM_class_shares_max.dta, clear
	merge 1:1 class using /Volumes/TMData/Canada/analyses/CA_TM_class_shares_min.dta, nogen
	gen range = max - min
	gsort -range
	save /Volumes/TMData/Canada/analyses/CA_TM_class_shares_range.dta, replace
