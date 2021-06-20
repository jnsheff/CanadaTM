* CA_TM_comparative.do
* A script to import other countries' trademarks datasets and perform comparative analyses
*
* NB: filepaths are based on the author's file structure; 
* other users should change the filepaths to point to the source and destination folders they wish to use.
* This may be done by performing a search-and-replace in this do-file, 
* replacing the partial path "/Volumes/TMData/Canada/dta" with the path of the folder where the user has stored their dta files,
* and replacing the partial path "/Volumes/TMData/Canada" with the parent of that folder.

* Create folder to store analyses if not already created
	capture confirm file "/Volumes/TMData/Canada/intl"
	if _rc {
		mkdir "/Volumes/TMData/Canada/intl"
		}
	cd /Volumes/TMData/Canada/intl
	
*	Import and clean up Australian and US application and events datasets

	* Australia: Applications
		copy /// 
			https://data.gov.au/data/dataset/5ddbf57c-94c3-4dd2-b41c-c1e90b9a3841/resource/a397aee4-3a3a-49cd-b82e-b16127d6e012/download/trade-mark-application.csv ///
			/Volumes/TMData/Canada/intl/AUS_TM_applications.csv, ///
			replace
		import delimited ///
			"/Volumes/TMData/Canada/intl/AUS_TM_applications.csv", ///
			case(preserve) ///
			stringcols(2) ///
			encoding(UTF-8) ///
			clear
		drop ip_right_type gained_enforceable_status_date
		rename application_number AppNo
		rename earliest_filed_date AppDate
		rename priority_date PriorityDate
		rename gained_registration_status_date RegDate
		rename enforceable_from_date EnforceableDate
		rename deemed_retired_date TermDate
		foreach var in AppDate PriorityDate RegDate EnforceableDate TermDate {
			gen double tcode_`var' = date(`var', "YMD")
			format tcode_`var' %tdDD_Mon_CCYY
			order tcode_`var', after(`var')
			drop `var'
			rename tcode_`var' `var'
			}
		foreach var in status ip_right_sub_type {
			encode `var', gen(`var'_code)
			order `var'_code, after(`var')
			drop `var'
			rename `var'_code `var'
			}
		compress
		save "/Volumes/TMData/Canada/intl/AUS_TM_applications.dta", replace
		
	* Australia: Events
		copy ///
			https://data.gov.au/data/dataset/5ddbf57c-94c3-4dd2-b41c-c1e90b9a3841/resource/69ce7ae5-17cc-413b-8d01-27c95ee8dd7a/download/trade-mark-application-events.csv ///
			/Volumes/TMData/Canada/intl/AUS_TM_events.csv, ///
			replace
		import delimited ///
			"/Volumes/TMData/Canada/intl/AUS_TM_events.csv", ///
			case(preserve) ///
			stringcols(1 2) ///
			encoding(UTF-8) ///
			clear
		drop ip_right_type
		foreach var in event_effective_date event_declared_date {
			gen double tcode_`var' = date(`var', "YMD")
			format tcode_`var' %tdDD_Mon_CCYY
			order tcode_`var', after(`var')
			drop `var'
			rename tcode_`var' `var'
			}
		rename application_number AppNo
		rename event_effective_date EventDate
		rename event_declared_date FiledDate
		foreach var in event_type event_category is_standing {
			encode `var', gen(`var'_code)
			order `var'_code, after(`var')
			drop `var'
			rename `var'_code `var'
			}
		sort AppNo EventDate
		compress
		save "/Volumes/TMData/Canada/intl/AUS_TM_events.dta", replace
		
	* USA: Applications
		copy ///
			https://bulkdata.uspto.gov/data/trademark/casefile/economics/2019/case_file.dta.zip ///
			/Volumes/TMData/Canada/intl/US_TM_applications.zip, ///
			replace
		unzipfile /Volumes/TMData/Canada/intl/US_TM_applications, replace
		erase /Volumes/TMData/Canada/intl/US_TM_applications.zip
		
* Create Time Series Files for Application Counts, Pendencies, and Outcomes

	* USA
		use /Volumes/TMData/Canada/intl/case_file, clear
		keep serial_no abandon_dt reg_cancel_dt filing_dt publication_dt registration_dt
		rename serial_no AppNo
		rename abandon_dt AbanDate
		rename reg_cancel_dt TermDate
		rename filing_dt AppDate
		rename publication_dt PubDate
		rename registration_dt RegDate
		
		gen year_group = yofd(AppDate) //creates a new variable coding each observation into yearly cohorts by filing date, to be used to generate a frequency time-series
		format %tyCCYY year_group //formats the new yearly cohort variable.

		gen Publag = PubDate - AppDate
		gen Reglag = RegDate - AppDate
		gen Abanlag = AbanDate - AppDate if (missing(RegDate) & (AbanDate < RegDate))
		gen Applications = 1
		gen Published = 0
		replace Published = 1 if !missing(PubDate)
		gen Registered = 0
		replace Registered = 1 if !missing(RegDate)
		gen Abandoned = 0
		replace Abandoned = 1 if !missing(AbanDate)
		save /Volumes/TMData/Canada/analyses/US_TM_tsdata, replace
		
		collapse ///
			(count) Applications ///
			(mean) Published Registered Abandoned Publag Reglag Abanlag, ///
			by(year_group)
		replace Published = Published * 100
		rename Published Pub_Rate
		replace Registered = Registered * 100
		rename Registered Reg_Rate
		replace Abandoned = Abandoned * 100
		rename Abandoned Aban_Rate
		gen country = "United States"
		tsset year_group
		save /Volumes/TMData/Canada/analyses/US_TM_yearly_timeseries, replace
		
	* AUS
	
		use /Volumes/TMData/Canada/intl/AUS_TM_applications.dta, clear
		keep AppNo AppDate RegDate TermDate
		save /Volumes/TMData/Canada/analyses/AUS_TM_tsdata, replace
		use "/Volumes/TMData/Canada/intl/AUS_TM_events.dta", clear
		drop if is_standing == 1
		drop is_standing
		gen keepit = 0
		foreach x in protected lapsed {
			replace keepit = 1 if event_type == "`x'":event_type_code
			}
		drop if keepit == 0
		foreach x in protected lapsed {
			gen `x'Event = FiledDate if event_type == "`x'":event_type_code
			egen `x'Date = max(`x'Event), by(AppNo)
			drop `x'Event
			format `x'Date %tdDD_Mon_CCYY
			}
		drop event_type event_category EventDate FiledDate keepit
		duplicates drop
		merge 1:1 AppNo using /Volumes/TMData/Canada/analyses/AUS_TM_tsdata, nogen
		replace RegDate = protectedDate if missing(protectedDate)
		drop protectedDate
		rename lapsedDate AbanDate
		order AppNo AppDate AbanDate RegDate TermDate
		gen Reglag = RegDate - AppDate
		gen Abanlag = AbanDate - AppDate if missing(RegDate)
		gen Applications = 1
		gen Registered = 0
		replace Registered = 1 if !missing(RegDate)
		gen Abandoned = 0
		replace Abandoned = 1 if !missing(AbanDate)
		gen year_group = yofd(AppDate) //creates a new variable coding each observation into yearly cohorts by filing date, to be used to generate a frequency time-series
		format %tyCCYY year_group //formats the new yearly cohort variable
		save /Volumes/TMData/Canada/analyses/AUS_TM_tsdata, replace
		collapse ///
			(count) Applications ///
			(mean) Registered Abandoned Reglag Abanlag, ///
			by(year_group)
		replace Registered = Registered * 100
		rename Registered Reg_Rate
		replace Abandoned = Abandoned * 100
		rename Abandoned Aban_Rate
		gen country = "Australia"
		tsset year_group
		save /Volumes/TMData/Canada/analyses/AUS_TM_yearly_timeseries, replace
		
	* Merge Panel Data
	
		use /Volumes/TMData/Canada/analyses/CA_TM_yearly_timeseries, clear
		keep year_group Reg_Rate Pub_Rate Aban_Rate Reglag Publag Abanlag App_Rate
		gen country = "Canada"
		rename App_Rate Applications
		append using /Volumes/TMData/Canada/analyses/AUS_TM_yearly_timeseries
		append using /Volumes/TMData/Canada/analyses/US_TM_yearly_timeseries
		encode country, gen(Country)
		drop country
		order Country, after(year_group)
		xtset Country year_group
		sort year_group Country
		keep if year_group > 1989
		keep if year_group < 2020
		keep if !missing(year_group)
		save /Volumes/TMData/Canada/analyses/CA_TM_intl_panels, replace
