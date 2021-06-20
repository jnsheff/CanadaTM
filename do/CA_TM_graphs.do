* CA_TM_pubgraphs.do
* A script to generate graphical representations of descriptive statistics of interest
* From the Canada Trademarks Dataset for inclusion in the descriptive paper announcing the dataset
*
* NB: filepaths are based on the author's file structure; 
* other users should change the filepaths to point to the source and destination folders they wish to use.
* This may be done by performing a search-and-replace in this do-file, 
* replacing the partial path "/Volumes/TMData/Canada/csv" with the path of the folder where the user has stored their csv files,
* and replacing the partial path "/Volumes/TMData/Canada/" with the parent of that folder.

* create folder to store analyses if not already created
	capture confirm file "/Volumes/TMData/Canada/analyses/figures"
	if _rc {
		mkdir "/Volumes/TMData/Canada/analyses/figures"
		}


set scheme s2mono

* Yearly Graph of Application and Registration Counts (Figure 2)
use /Volumes/TMData/Canada/analyses/CA_TM_yearly_timeseries, clear
preserve
replace App_Rate = App_Rate/1000
replace netRegistered = netRegistered/1000
twoway ///
	(tsline App_Rate, yaxis(1)) ///
	(tsline netRegistered, yaxis(2)) ///
if (1977 < year_group & year_group < 2019), ///
graphregion(fcolor(white)) ///
ytitle("Number of Applications (Thousands)", axis(1)) ///
ytitle("Total Active Registrations (Thousands)", axis(2)) ///
xtitle("Year") ///
xlabel(1978(5)2018, angle(45) grid) xmtick(##5, grid) ///
ylabel(0(5)65, angle(0) grid axis(1)) ///
ylabel(0(50)650, angle(0) axis(2)) ///
legend ( ///
	nocolfirst ///
	justification(center) ///
	label(1 "Number of Applications" "(left axis)") ///
	label(2 "Total Active Registrations" "(right axis)") ///
	)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig2, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig2.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig2.pdf, replace
restore

* Monthly Graph of Application Counts (Figure 4)
use /Volumes/TMData/Canada/analyses/CA_TM_monthly_timeseries, clear
preserve
twoway ///
	(tsline App_Rate) ///
if (tm(2008-12) < month_group & month_group < tm(2019-09)), ///
graphregion(fcolor(white)) ///
ytitle("Number of Applications") ///
xtitle("Month") ///
xlabel(588(6)720, angle(45) grid) xmtick(##2, grid) ///
ylabel(0(1000)9000, angle(0) grid) ymtick(##2, grid) ///
legend ( ///
	nocolfirst ///
	justification(center) ///
	label(1 "Number of Applications") ///
	)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig4, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig4.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig4.pdf, replace
restore

* Daily Graph of Application Counts, June 2019 (Figure 5)
use /Volumes/TMData/Canada/analyses/CA_TM_June_2019_timeseries.dta, clear
preserve
tsfill
replace Applications = 0 if missing(Applications)
twoway ///
	(tsline Applications, cmissing(n)), ///
tline(21717, lpattern(-)) ///
ttext(1850 21717 "Effective Date of Reforms", place(e)) ///
graphregion(fcolor(white)) ///
ytitle("Number of Applications") ///
xtitle("Date") ///
xlabel(21703(7)21733, angle(45) grid) xmtick(##7, grid) ///
ylabel(0(100)2000, angle(0) grid) ymtick(##1, grid) ///
legend ( ///
	nocolfirst ///
	justification(center) ///
	label(1 "Number of Applications") ///
	)
	
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig5, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig5.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig5.pdf, replace
restore

* Daily Graph of Classes Claimed, June 2019 (Figure 6)

use /Volumes/TMData/Canada/analyses/CA_TM_June_2019_timeseries.dta, clear
preserve
tsfill
replace ClassCount = 0 if missing(ClassCount)
twoway ///
	(tsline ClassCount, cmissing(no)), ///
tline(21717, lpattern(-)) ///
ttext(9 21717 "Effective Date of Reforms", place(e)) ///
graphregion(fcolor(white)) ///
ytitle("Number of Nice" "Classes Claimed") ///
xtitle("Date") ///
xlabel(21703(7)21733, angle(45) grid) xmtick(##7, grid) ///
ylabel(0(1)10, angle(0) grid) ymtick(##1, grid) ///
legend ( ///
	nocolfirst ///
	justification(center) ///
	label(1 "Number of Applications") ///
	)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig6, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig6.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig6.pdf, replace
restore

* Graph rates of publication and other milestones (Figure 7)

use /Volumes/TMData/Canada/analyses/CA_TM_yearly_timeseries, clear
preserve
foreach x in Allow_Rate Pub_Rate {
	replace `x' = . if year_group < 1985
	}
twoway ///
	(tsline Reg_Rate) ///
	(tsline Aban_Rate) ///
	(tsline Allow_Rate) ///
	(tsline Renewed_Rate) ///
	(tsline Pub_Rate) ///
if (1977 < year_group & year_group < 2017), /// 
graphregion(fcolor(white)) ///
ytitle("Rate (%)") ///
xtitle("Year of Application") ///
xlabel(1978(2)2016, angle(45) grid) xmtick(##2, grid) ///
ylabel(0(10)100, angle(0) grid) ymtick(##2, grid) ///
legend ( ///
	nocolfirst ///
	justification(left) ///
		label(1 "Registration Rate") ///
		label(2 "Abandonment Rate") ///
		label(3 "Allowance Rate") ///
		label(4 "Renewal Rate") ///
		label(5 "Publication Rate") ///
	)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig7, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig7.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig7.pdf, replace
restore

* Graph fraction of applications that fail to submit a declaration of use (Figure 8)

use /Volumes/TMData/Canada/analyses/CA_TM_yearly_timeseries, clear
preserve
twoway ///
	(tsline NoUseDecln_Rate) ///
if (1996 < year_group & year_group < 2016), /// 
graphregion(fcolor(white)) ///
graphregion(fcolor(white)) ///
ytitle("Rate (%)") ///
xtitle("Year of Application") ///
xlabel(1997(2)2015, angle(45) grid) xmtick(##2, grid) ///
ylabel(0(5)25, angle(0) grid) ymtick(##5, grid) ///

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig8, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig8.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig8.pdf, replace
restore

* Graph average pendency times (Figure 9)
use /Volumes/TMData/Canada/analyses/CA_TM_yearly_timeseries, clear
preserve
twoway ///
	(tsline Reglag) ///
	(tsline Allowlag) ///
	(tsline Publag) ///
	(tsline Abanlag) ///
	(tsline OfficeActionlag) ///
if (1986 < year_group & year_group < 2019), ///
graphregion(fcolor(white)) ///
ytitle("Average Pendency (Days)") ///
xtitle("Year of Application") ///
xlabel(1987(2)2019, angle(45) grid) xmtick(##2, grid) ///
ylabel(0(90)1200, angle(0) grid) ymtick(##3, grid) ///
legend ( ///
	nocolfirst ///
	justification(left) ///
	order(1 4 2 5 3 ) ///
		label(1 "Time to Registration") ///
		label(2 "Time to Allowance") ///
		label(3 "Time to Publication") ///
		label(4 "Time to Abandonment") ///
		label(5 "Time to First Office Action") ///
	)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig9, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig9.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig9.pdf, replace
restore

* Graph rates of Opposition against Application Cohorts (Figure 10)
use /Volumes/TMData/Canada/analyses/CA_TM_yearly_timeseries, clear
preserve
tsfill
twoway ///
	(tsline Oppn_Rate, lcolor(black) cmissing(no)) ///
if (1965 < year_group & year_group < 2019), /// 
graphregion(fcolor(white)) ///
ytitle("Rate (%)") ///
xtitle("Year of Application") ///
xlabel(1965(5)2020, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
ylabel(0(1)10, angle(0) labsize(small) grid) ymtick(##1, grid) ///

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig10, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig10.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig10.pdf, replace
restore

* Graph Average Time from Advertisement to Filing of Opposition (Figure 11)
use /Volumes/TMData/Canada/analyses/CA_TM_yearly_timeseries, clear
preserve
twoway ///
	(tsline OppLag) ///
if (1996 < year_group & year_group < 2018), ///
graphregion(fcolor(white)) ///
ytitle("Days") ///
xtitle("Year of Application") ///
xlabel(1997(5)2017, angle(45) grid) xmtick(##5, grid) ///
ylabel(50(10)80, angle(0) grid) ymtick(##2, grid)

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig11, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig11.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig11.pdf, replace
restore

* Graph average opposition success rate (Figure 12)
use /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_yearly_timeseries, clear

twoway ///
	(tsline Opp_Success_Rate) ///
if (1996 < proceeding_year_group & proceeding_year_group < 2018), ///
graphregion(fcolor(white)) ///
ytitle("Rate (%)") ///
xtitle("Year of Opposition Filing") ///
xlabel(1997(2)2017, angle(45) grid) xmtick(##2, grid) ///
ylabel(25(5)40, angle(0) grid) ymtick(##5, grid)

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig12, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig12.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig12.pdf, replace

* Graph annual opposition counts (Figure 13)
use /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_yearly_timeseries, clear

twoway ///
	(tsline Opp_Count) ///
if (1996 < proceeding_year_group & proceeding_year_group < 2019), ///
graphregion(fcolor(white)) ///
ytitle("Number of Oppositions") ///
xtitle("Year of Opposition Filing") ///
xlabel(1997(5)2018, angle(45) grid) xmtick(##5, grid) ///
ylabel(0(500)3500, angle(0) grid) ymtick(##5, grid)

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig13, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig13.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig13.pdf, replace

* Graph average opposition proceeding duration (Figure 14)
use /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_yearly_timeseries, clear

twoway ///
	(tsline Opp_proceeding_length) ///
	(tsline SuccessOppLength) ///
	(tsline FailOppLength) ///
if (1996 < proceeding_year_group & proceeding_year_group < 2018), ///
graphregion(fcolor(white)) ///
ytitle("Duration of Proceeding (in Days)") ///
xtitle("Year of Opposition Filing") ///
xlabel(1997(5)2017, angle(45) grid) xmtick(##5, grid) ///
ylabel(180(90)900, angle(0) grid) ymtick(##3, grid) ///
legend ( ///
	nocolfirst ///
	justification(left) ///
	order(1 - " " 2 3) ///
		label(1 "Average Overall Duration") ///
		label(2 "Average Duration of" "Successful Oppositions") ///
		label(3 "Average Duration of" "Failed Oppositions") ///
	)
	
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig14, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig14.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig14.pdf, replace

* Graph rates of Expungement proceedings instituted against Application Cohorts (Figure 15)
use /Volumes/TMData/Canada/analyses/CA_TM_yearly_timeseries, clear
preserve
tsfill
twoway ///
	(tsline Canceln_Rate, cmissing(no)) ///
if (1919 < year_group & year_group < 2019), /// 
graphregion(fcolor(white)) ///
ytitle("Rate (%)") ///
xtitle("Year of Application") ///
xlabel(1920(10)2020, angle(45) grid) xmtick(##10, grid) ///
ylabel(0(.5)4, angle(0) grid) ymtick(##1, grid) ///

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig15, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig15.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig15.pdf, replace
restore

* Graph annual expungement proceeding counts (Figure 16)
use /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_yearly_timeseries, clear
preserve
twoway ///
	(tsline Cancel_Count) ///
if (1996 < proceeding_year_group & proceeding_year_group < 2019), ///
graphregion(fcolor(white)) ///
ytitle("Number of Expungement Proceedings Instituted") ///
xtitle("Year Expungement Proceeding Instituted") ///
xlabel(1997(5)2019, angle(45) grid) xmtick(##5, grid) ///
ylabel(500(100)1000, angle(0) grid) ymtick(##4, grid)

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig16, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig16.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig16.pdf, replace
restore

* Graph average Expungement Proceeding success rate (Figure 17)
use /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_yearly_timeseries, clear
preserve
twoway ///
	(tsline Cancel_Success_Rate) ///
if (1996 < proceeding_year_group & proceeding_year_group < 2019), ///
graphregion(fcolor(white)) ///
ytitle("Rate (%)") ///
xtitle("Year Expungement Proceeding Instituted") ///
xlabel(1997(1)2018, angle(45) grid) xmtick(##1, grid) ///
ylabel(35(5)75, angle(0) grid) ymtick(##5, grid)

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig17, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig17.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig17.pdf, replace
restore

* Graph average cancellation proceeding duration (Figure 18)
use /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_yearly_timeseries, clear
twoway ///
	(tsline Cancel_proceeding_length) ///
	(tsline SuccessCancelLength) ///
	(tsline FailCancelLength) ///
if (1996 < proceeding_year_group & proceeding_year_group < 2018), ///
graphregion(fcolor(white)) ///
ytitle("Duration of Proceeding (in Days)") ///
xtitle("Year Expungement Proceeding Instituted") ///
xlabel(1997(5)2018, angle(45) grid) xmtick(##5, grid) ///
ylabel(150(90)780, angle(0) grid) ymtick(##3, grid) ///
legend ( ///
	size(small) ///
	nocolfirst ///
	justification(left) ///
	order(1 - " " 2 3) ///
		label(1 "Average Overall Duration") ///
		label(2 "Average Duration of" "Successful Expungements") ///
		label(3 "Average Duration of" "Failed Expungements") ///
	)

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig18, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig18.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig18.pdf, replace

* Graph average Nice Classes per application (Figure 19)
use /Volumes/TMData/Canada/analyses/CA_TM_classes_yearly_timeseries.dta, clear

twoway ///
	(tsline ClassCount) ///
if (1974 < year_group & year_group < 2019), ///
graphregion(fcolor(white)) ///
ytitle("Number of Classes") ///
xtitle("Application Year") ///
xlabel(1975(5)2020, angle(45) grid) xmtick(##5, grid) ///
ylabel(1(.5)5, angle(0) grid) ymtick(##5, grid)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig19, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig19.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig19.pdf, replace

* Graph of Current Filing Bases by application year, based on CA_TM_main (Figure 20)

	use /Volumes/TMData/Canada/analyses/CA_TM_basis_rates.dta, clear
	twoway ///
	(tsline UseBasis) ///
	(tsline ITUBasis) ///
	(tsline ForeignRegBasis) ///
	(tsline ForeignAppBasis) ///
	if (1977 < year_group & year_group < 2019), ///
	graphregion(fcolor(white)) ///
	ytitle("Percent of Applications" "Claiming Filing Basis", size(small)) ///
	xtitle("Year of Application") ///
	xlabel(1978(5)2018, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
	ylabel(0(10)80, angle(0) labsize(medsmall) grid) ymtick(##4, grid) ///
	legend ( ///
		nocolfirst ///
		justification(left) ///
		order(1 2 3 4) ///
			label(1 "Use in Canada") ///
			label(2 "Proposed Use in Canada") ///
			label(3 "Foreign Registration") ///
			label(4 "Foreign Application") ///
		)
		
	graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig20, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig20.png, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig20.pdf, replace
	
* Graph of Current Filing Bases by application year, based on CA_TM_claims, 
* assuming Declarations of Use were Proposed Use applications (Figure 21)

	use /Volumes/TMData/Canada/analyses/CA_TM_basis_timeseries.dta, clear
	twoway ///
	(tsline Used) ///
	(tsline ImpliedProposedUse, lwidth(medthick) lpattern(dash)) ///
	(tsline ForeignReg, lwidth(thick) lpattern(dot)) ///
	(tsline Priority, lwidth(thin) lpattern(shortdash)) ///
	(tsline ForeignUse, lwidth(thin) lpattern(longdash_dot)) ///
	if (1977 < year_group & year_group < 2019), ///
	graphregion(fcolor(white)) ///
	ytitle("Percent of Applications" "Claiming Filing Basis", size(small)) ///
	xtitle("Year of Application") ///
	xlabel(1978(5)2018, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
	ylabel(0(10)70, angle(0) labsize(medsmall) grid) ymtick(##4, grid) ///
	legend ( ///
		nocolfirst ///
		justification(left) ///
		order(1 2 3 4 5) ///
			label(1 "Use in Canada") ///
			label(2 "Proposed Use in Canada (Inferred)") ///
			label(3 "Foreign Registration") ///
			label(4 "Priority") ///
			label(5 "Foreign Use") ///
		)
	graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig21, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig21.png, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig21.pdf, replace
	
* Bar Graph of Applicant Nationalities: Canada-US-Other (Figure 22)

use /Volumes/TMData/Canada/analyses/CA_TM_country_barchart_data.dta, clear
preserve
foreach x in CA US Non_CA_US_Combined {
	replace `x' = `x'/1000
	}
graph bar (asis) CA US Non_CA_US_Combined ///
	if (year_group < 2019), ///
	bar(1, fcolor(black) lcolor(black) lwidth(vthin)) ///
	bar(2, fcolor(white) lcolor(black) lwidth(vthin)) ///
	bar(3, fcolor(gray) lcolor(black) lwidth(vthin)) ///
	over(year_group, ///
		label( ///
			labsize(vsmall) ///
			angle(90) ///
			) ///
		) ///
	stack ///
	nofill ///
	graphregion(fcolor(white)) ///
	ytitle("Applications (Thousands)") ///
	ylabel(0(10)60) ymtick(##2, grid) ///
	legend( ///
		nocolfirst ///
		justification(center) ///
		label(1 "Canada") ///
		label(2 "United States") ///
		label(3 "All Others") ///
	)
	graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig22, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig22.png, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig22.pdf, replace
restore
	
* Bar Graph of Applicant Nationalities Ex-Canada/US, Application Counts (Figure 23)

use /Volumes/TMData/Canada/analyses/CA_TM_country_barchart_data.dta, clear
preserve
drop if year_group == 2019
foreach x in CN JP CH GB DE FR IT Other {
	replace `x' = `x'/1000
	}
graph bar (asis) CN JP CH GB DE FR IT Other, ///
		bar(1, fcolor(black) fintensity(100) lcolor(black) lwidth(vthin)) ///
		bar(2, fcolor(black) fintensity(0) lcolor(black) lwidth(vthin)) ///
		bar(3, fcolor(black) fintensity(65) lcolor(black) lwidth(vthin)) ///
		bar(4, fcolor(black) fintensity(15) lcolor(black) lwidth(vthin)) ///
		bar(5, fcolor(black) fintensity(85) lcolor(black) lwidth(vthin)) ///
		bar(6, fcolor(black) fintensity(25) lcolor(black) lwidth(vthin)) ///
		bar(7, fcolor(black) fintensity(75) lcolor(black) lwidth(vthin)) ///
		bar(8, fcolor(black) fintensity(45) lcolor(black) lwidth(vthin)) ///
	over(year_group, ///
		label( ///
			labsize(vsmall) ///
			angle(90) ///
			) ///
		) ///
	stack ///
	nofill ///
	xsize(12) ///
	ysize(6) ///
	graphregion(fcolor(white)) ///
	ytitle("Applications (Thousands)", size(small)) ///
	ylabel(0(1)18, angle(0) labsize(small) grid) ymtick(##2, grid) ///
	legend( ///
		region(lstyle(none) lcolor(white)) ///
		order (8 7 6 5 4 3 2 1) ///
		position (3) ///
		nocolfirst ///
		col(1) ///
		rows(19) ///
		holes(1 2 3 4 5 7 8 9 16) ///
		rowgap(3) ///
		symxsize(3) ///
		size(small) ///
		justification(center) ///
		label(1 "China") ///
		label(2 "Japan") ///
		label(3 "Switzerland") ///
		label(4 "United Kingdom") ///
		label(5 "Germany") ///
		label(6 "France") ///
		label(7 "Italy") ///
		label(8 "Other") ///
	)
	graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig23, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig23.png, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig23.pdf, replace
	restore
	
* Bar Graph of Foreign Claims, US vs. All Others (Fig. 24) 

use /Volumes/TMData/Canada/analyses/CA_TM_filed_countries_barchart_data.dta, clear
preserve
drop if year_group == 2019
foreach x in US All_But_US {
	replace `x' = `x'/1000
	}
graph bar (asis) US All_But_US, ///
	bar(1, fcolor(black) lcolor(black) lwidth(vthin)) ///
	bar(2, fcolor(white) lcolor(black) lwidth(vthin)) ///
	over(year_group, ///
		label( ///
			labsize(vsmall) ///
			angle(90) ///
			) ///
		) ///
	stack ///
	nofill ///
	xsize(12) ///
	ysize(8) ///
	graphregion(fcolor(white)) ///
	ytitle("Applications (Thousands)", size(small)) ///
	ylabel(0(1)20, labsize(vsmall) angle(0) grid) ymtick(##2, grid) ///
	legend( ///
		nocolfirst ///
		justification(center) ///
		label(1 "United States") ///
		label(2 "All Others") ///
	)

	graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig24, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig24.png, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig24.pdf, replace
restore
	
* Bar Graph of Foreign Claims, Ex-US (Fig. 25) 

use /Volumes/TMData/Canada/analyses/CA_TM_filed_countries_barchart_data.dta, clear
preserve
drop if year_group == 2019
graph bar (asis) EM AU FR GB DE CH ES IT Other , ///
		bar(1, fcolor(black) fintensity(90) lcolor(black) lwidth(vthin)) ///
		bar(2, fcolor(black) fintensity(10) lcolor(black) lwidth(vthin)) ///
		bar(3, fcolor(black) fintensity(60) lcolor(black) lwidth(vthin)) ///
		bar(4, fcolor(black) fintensity(20) lcolor(black) lwidth(vthin)) ///
		bar(5, fcolor(black) fintensity(80) lcolor(black) lwidth(vthin)) ///
		bar(6, fcolor(black) fintensity(30) lcolor(black) lwidth(vthin)) ///
		bar(7, fcolor(black) fintensity(70) lcolor(black) lwidth(vthin)) ///
		bar(8, fcolor(black) fintensity(40) lcolor(black) lwidth(vthin)) ///
		bar(9, fcolor(black) fintensity(100) lcolor(black) lwidth(vthin)) ///
	over(year_group, ///
		label( ///
			labsize(vsmall) ///
			angle(90) ///
			) ///
		) ///
	stack ///
	nofill ///
	xsize(12) ///
	ysize(6) ///
	graphregion(fcolor(white)) ///
	ytitle("Applications", size(small)) ///
	ylabel(0(1000)8500, angle(0) labsize(small) grid) ymtick(##4, grid) ///
	legend( ///
		region(lstyle(none) lcolor(white)) ///
		order (9 8 7 6 5 4 3 2 1) ///
		position (3) ///
		nocolfirst ///
		col(1) ///
		rows(19) ///
		holes(2 3 7 9 11 13 14 15 17) ///
		rowgap(1.75) ///
		symysize(2) ///
		symxsize(2) ///
		size(small) ///
		justification(center) ///
		label(1 "European Union") ///
		label(2 "Australia") ///
		label(3 "France") ///
		label(4 "United Kingdom") ///
		label(5 "Germany") ///
		label(6 "Switzerland") ///
		label(7 "Spain") ///
		label(8 "Italy") ///
		label(9 "Other") ///
	)
	
	graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig25, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig25.png, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig25.pdf, replace
restore

* Comparative Graphs

	* Comparative Applications (Figure 26)

		use /Volumes/TMData/Canada/analyses/CA_TM_intl_panels, clear
		preserve
		drop if year_group > 2019
		drop if year_group < 1995
		replace Applications = Applications/1000
		xtline Applications, ///
		overlay ///
		graphregion(fcolor(white)) ///
		ytitle("Applications (Thousands)") ///
		xtitle("Application Year") ///
		xlabel(1995(5)2020, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
 		ylabel(0(50)450, angle(0) labsize(medsmall) grid) ymtick(##5, grid) ///
		legend ( ///
			order (2 3 1) ///
			nocolfirst ///
			justification(left) ///
			size(small) ///
			)

		save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig26, replace
		graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig26.png, replace
		graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig26.pdf, replace

		restore
		
	* Pendency Times (Figure 27)

		use /Volumes/TMData/Canada/analyses/CA_TM_intl_panels, clear
		preserve
		drop if year_group > 2018
		drop if year_group < 1995
		xtline Reglag, ///
		overlay ///
		graphregion(fcolor(white)) ///
		ytitle("Days") ///
		xtitle("Application Year") ///
		xlabel(1995(5)2018, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
		ylabel(180(90)1080, angle(0) labsize(medsmall) grid) ymtick(##3, grid) ///
		legend ( ///
			order (2 3 1) ///
			nocolfirst ///
			justification(left) ///
			size(small) ///
			)

		save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig27, replace
		graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig27.png, replace
		graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig27.pdf, replace

		restore
		
	* Times to abandonment (Figure 28)

		use /Volumes/TMData/Canada/analyses/CA_TM_intl_panels, clear
		preserve
		drop if year_group > 2018
		drop if year_group < 1995
		xtline Abanlag, ///
		overlay ///
		graphregion(fcolor(white)) ///
		ytitle("Days") ///
		xtitle("Application Year") ///
		xlabel(1995(5)2020, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
 		ylabel(310(90)1080, angle(0) labsize(medsmall) grid) ymtick(##3, grid) ///
		legend ( ///
			order (2 3 1) ///
			nocolfirst ///
			justification(left) ///
			size(small) ///
			)

		save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig28, replace
		graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig28.png, replace
		graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig28.pdf, replace

		restore
		
	* Registration and Publication Rates (Figure 29)
	
		use /Volumes/TMData/Canada/analyses/CA_TM_intl_panels, clear
		preserve
		drop if year_group > 2016
		drop if year_group < 1995
		xtline Reg_Rate, ///
		overlay ///
		plot1opts(lwidth(medthick) lpattern(dot)) /// Australia Registration Rate
		plot2opts(lwidth(medthick) lpattern(none)) /// Canada Registration Rate
		plot3opts(lwidth(medthick) lpattern(dash)) /// US Registration Rate
		addplot(tsline Pub_Rate if Country == "United States":Country, lpattern(---.) || tsline Pub_Rate if Country == "Canada":Country, lpattern(...-)) ///
		graphregion(fcolor(white)) ///
		ytitle("Rate (%)") ///
		xtitle("Application Year") ///
		xlabel(1995(5)2016, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
		ylabel(40(10)90, angle(0) labsize(medsmall) grid) ymtick(##4, grid) ///
		legend ( ///
			nocolfirst ///
			justification(left) ///
			size(small) ///
			order(3 4 2 5 1) ///
			label(1 "Registration Rates," "Australia") ///
			label(2 "Registration Rates," "Canada") ///
			label(3 "Registration Rates," "United States") ///
			label(4 "Publication Rates," "United States") ///
			label(5 "Publication Rates," "Canada") ///
			)

		save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig29, replace
		graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig29.png, replace
		graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig29.pdf, replace

		restore
		
	* Abandonment Rates (Figure 30)

		use /Volumes/TMData/Canada/analyses/CA_TM_intl_panels, clear
		preserve
		drop if year_group > 2018
		drop if year_group < 1995
		xtline Aban_Rate, ///
		overlay ///
		graphregion(fcolor(white)) ///
		ytitle("Rate (%)") ///
		xtitle("Application Year") ///
		xlabel(1995(5)2015, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
 		ylabel(20(5)60, angle(0) labsize(medsmall) grid) ymtick(##5, grid) ///
		legend ( ///
			order (2 3 1) ///
			nocolfirst ///
			justification(left) ///
			size(small) ///
			)

		save /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig30, replace
		graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig30.png, replace
		graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_Fig30.pdf, replace

		restore
