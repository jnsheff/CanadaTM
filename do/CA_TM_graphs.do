* CA_TM_graphs.do
* A script to generate graphical representations of descriptive statistics of interest
* From the Canada Trademarks Dataset
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

use /Volumes/TMData/Canada/analyses/CA_TM_yearly_timeseries, clear

* Yearly Graph of Application Counts
preserve
replace App_Rate = App_Rate/1000
twoway ///
	(tsline App_Rate, lcolor(black)) ///
if (1977 < year_group & year_group < 2019), ///
title("Application Rates", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Number of Applications (Thousands)") ///
xtitle("Year") ///
xlabel(1975(5)2020, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
ylabel(0(5)65, angle(0) labsize(medsmall) grid) ymtick(##5, grid) ///
legend ( ///
	nocolfirst ///
	justification(center) ///
	label(1 "Number of Applications") ///
	)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_apprates_year, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_apprates_year.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_apprates_year.pdf, replace
restore

* Graph rates of publication and other milestones
preserve
foreach x in Allow_Rate Pub_Rate {
	replace `x' = . if year_group < 1985
	}
twoway ///
	(tsline Reg_Rate, lcolor(green) lwidth(thick)) ///
	(tsline Aban_Rate, lcolor(red) lwidth(thick) lpattern(_)) ///
	(tsline Allow_Rate, lcolor (orange) lpattern(_)) ///
	(tsline Renewed_Rate, lcolor(blue) lwidth(vthin)) ///
	(tsline Pub_Rate, lcolor(purple) lpattern(...-)) ///
if (1977 < year_group & year_group < 2017), /// 
title("Application Outcomes", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Rate (%)") ///
xtitle("Year of Application") ///
xlabel(1978(2)2018, angle(45) labsize(medsmall) grid) xmtick(##2, grid) ///
ylabel(0(10)100, angle(0) labsize(small) grid) ymtick(##2, grid) ///
legend ( ///
	nocolfirst ///
	justification(left) ///
		label(1 "Registration Rate") ///
		label(2 "Abandonment Rate") ///
		label(3 "Allowance Rate") ///
		label(4 "Renewal Rate") ///
		label(5 "Publication Rate") ///
	)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_outcomes, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_outcomes.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_outcomes.pdf, replace
restore

* Graph fraction of applications that fail to submit a declaration of use

preserve

twoway ///
	(tsline NoUseDecln_Rate, lcolor(black)) ///
if (1996 < year_group & year_group < 2016), /// 
title("Applications Deemed Abandoned due to" "Failure to Submit Declaration of Use", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Rate (%)") ///
xtitle("Year of Application") ///
xlabel(1997(2)2017, angle(45) labsize(medsmall) grid) xmtick(##2, grid) ///
ylabel(0(5)25, angle(0) labsize(small) grid) ymtick(##5, grid) ///

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_no_use_delcn, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_no_use_delcn.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_no_use_delcn.pdf, replace
restore

* Graph average pendency times
twoway ///
	(tsline Reglag, lcolor(green) lwidth(thick)) ///
	(tsline Allowlag, lcolor (orange) lpattern(_)) ///
	(tsline Publag, lcolor(purple) lpattern(...-)) ///
	(tsline Abanlag, lcolor(red) lwidth(thick) lpattern(_)) ///
	(tsline OfficeActionlag, lcolor(blue) lwidth(vthin)) ///
if (1986 < year_group & year_group < 2019), ///
title("Average Application Pendency", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Average Pendency (Days)") ///
xtitle("Year of Application") ///
xlabel(1987(2)2019, angle(45) labsize(medsmall) grid) xmtick(##2, grid) ///
ylabel(0(90)1200, angle(0) labsize(medsmall) grid) ymtick(##3, grid) ///
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
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_pendencies, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_pendencies.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_pendencies.pdf, replace

* Monthly Graph of Application Counts
use /Volumes/TMData/Canada/analyses/CA_TM_monthly_timeseries, clear
preserve
twoway ///
	(tsline App_Rate, lcolor(black)) ///
if (tm(2008-12) < month_group & month_group < tm(2019-09)), ///
title("Application Rates, Monthly", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Number of Applications") ///
xtitle("Month") ///
xlabel(588(6)720, angle(45) labsize(medsmall) grid) xmtick(##2, grid) ///
ylabel(0(1000)9000, angle(0) labsize(medsmall) grid) ymtick(##2, grid) ///
legend ( ///
	nocolfirst ///
	justification(center) ///
	label(1 "Number of Applications") ///
	)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_apprates_month, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_apprates_month.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_apprates_month.pdf, replace
restore

* Daily Graph of Application Counts, June 2019
use /Volumes/TMData/Canada/analyses/CA_TM_June2019Apps.dta, clear
preserve
tsfill
twoway ///
	(tsline Applications, cmissing(n) lcolor(black)), ///
tline(21717, lcolor(red) lpattern(-)) ///
title("Application Rates, June 2019", color(black)) ///
graphregion(fcolor(white)) ///
ttext(1850 21717 "Effective Date of Reforms", place(e)) ///
ytitle("Number of Applications") ///
xtitle("Date") ///
xlabel(21703(7)21733, angle(45) labsize(small) grid) xmtick(##7, grid) ///
ylabel(0(100)2000, angle(0) labsize(small) grid) ymtick(##1, grid) ///
legend ( ///
	nocolfirst ///
	justification(center) ///
	label(1 "Number of Applications") ///
	)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_apprates_June2019, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_apprates_June2019.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_apprates_June2019.pdf, replace
restore

* Daily Graph of Classes Claimed, June 2019

use /Volumes/TMData/Canada/analyses/CA_TM_June_2019_timeseries.dta, clear
preserve
tsfill
twoway ///
	(tsline ClassCount, lcolor(black) cmissing(no)), ///
tline(21717, lcolor(red) lpattern(-)) ///
title("Average Nice Class Claims" "Per Application, June 2019", color(black)) ///
graphregion(fcolor(white)) ///
ttext(9 21717 "Effective Date of Reforms", place(e)) ///
ytitle("Number of Nice" "Classes Claimed") ///
xtitle("Date") ///
xlabel(21703(7)21733, angle(45) labsize(small) grid) xmtick(##7, grid) ///
ylabel(0(1)10, angle(0) labsize(small) grid) ymtick(##1, grid) ///
legend ( ///
	nocolfirst ///
	justification(center) ///
	label(1 "Number of Applications") ///
	)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_classcounts_June2019, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_classcounts_June2019.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_classcounts_June2019.pdf, replace
restore

* Graph rates of Opposition against Application Cohorts
use /Volumes/TMData/Canada/analyses/CA_TM_yearly_timeseries, clear
preserve
tsfill
twoway ///
	(tsline Oppn_Rate, lcolor(black) cmissing(no)) ///
if (1965 < year_group & year_group < 2019), /// 
title("Opposition Rates" "(Against Published Applications)", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Rate (%)") ///
xtitle("Year of Application") ///
xlabel(1965(5)2020, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
ylabel(0(1)10, angle(0) labsize(small) grid) ymtick(##1, grid) ///

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_opp_rates, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_opp_rates.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_opp_rates.pdf, replace
restore

* Graph rates of Cancellations against Application Cohorts
use /Volumes/TMData/Canada/analyses/CA_TM_yearly_timeseries, clear
preserve
tsfill
twoway ///
	(tsline Canceln_Rate, lcolor(black) cmissing(no)) ///
if (1919 < year_group & year_group < 2019), /// 
title("Expungement Petition Rates" "(Against Registered Applications)", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Rate (%)") ///
xtitle("Year of Application") ///
xlabel(1920(10)2020, angle(45) labsize(medsmall) grid) xmtick(##10, grid) ///
ylabel(0(.5)4, angle(0) labsize(small) grid) ymtick(##1, grid) ///

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_canceln_rates, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_canceln_rates.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_canceln_rates.pdf, replace
restore

* Graph annual cancellation counts
use /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_yearly_timeseries, clear
preserve
twoway ///
	(tsline Cancel_Count, lcolor(black)) ///
if (1996 < proceeding_year_group & proceeding_year_group < 2019), ///
title("Expungement Proceeding Counts", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Number of Expungement Proceedings Instituted") ///
xtitle("Year Expungement Proceeding Instituted") ///
xlabel(1997(5)2019, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
ylabel(500(100)1000, angle(0) labsize(medsmall) grid) ymtick(##4, grid)

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_cancel_counts, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_cancel_counts.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_cancel_counts.pdf, replace
restore

* Graph average cancellation proceeding duration
use /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_yearly_timeseries, clear
preserve
twoway ///
	(tsline Cancel_proceeding_length, lcolor(black)) ///
	(tsline SuccessCancelLength, lcolor(green) lpattern(-)) ///
	(tsline FailCancelLength, lcolor(red) lwidth(thick) lpattern(dot)) ///
if (1996 < proceeding_year_group & proceeding_year_group < 2018), ///
title("Expungement Proceeding Duration", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Duration of Proceeding (in Days)", size(medsmall)) ///
xtitle("Year Expungement Proceeding Instituted", size(medsmall)) ///
xlabel(1997(5)2018, angle(45) labsize(small) grid) xmtick(##5, grid) ///
ylabel(150(90)780, angle(0) labsize(small) grid) ymtick(##3, grid) ///
legend ( ///
	size(small) ///
	nocolfirst ///
	justification(left) ///
	order(1 - " " 2 3) ///
		label(1 "Average Overall Duration") ///
		label(2 "Average Duration of" "Successful Expungements") ///
		label(3 "Average Duration of" "Failed Expungements") ///
	)

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_cancel_length, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_cancel_length.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_cancel_length.pdf, replace
restore

* Graph average cancellation success rate
use /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_yearly_timeseries, clear
preserve
twoway ///
	(tsline Cancel_Success_Rate, lcolor(black)) ///
if (1996 < proceeding_year_group & proceeding_year_group < 2019), ///
title("Expungement Proceeding Success Rates", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Rate (%)") ///
xtitle("Year Expungement Proceeding Instituted") ///
xlabel(1997(1)2018, angle(45) labsize(medsmall) grid) xmtick(##1, grid) ///
ylabel(0(10)80, angle(0) labsize(medsmall) grid) ymtick(##10, grid)

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_cancel_success, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_cancel_success.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_cancel_success.pdf, replace
restore

* Graph annual opposition counts
use /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_yearly_timeseries, clear

twoway ///
	(tsline Opp_Count, lcolor(black)) ///
if (1996 < proceeding_year_group & proceeding_year_group < 2020), ///
title("Opposition Counts", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Number of Oppositions") ///
xtitle("Year of Opposition Filing") ///
xlabel(1997(5)2019, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
ylabel(1000(500)3500, angle(0) labsize(medsmall) grid) ymtick(##5, grid)

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_opp_counts, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_opp_counts.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_opp_counts.pdf, replace

* Graph average opposition proceeding duration
use /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_yearly_timeseries, clear

twoway ///
	(tsline Opp_proceeding_length, lcolor(black)) ///
	(tsline SuccessOppLength, lcolor(green) lpattern(-)) ///
	(tsline FailOppLength, lcolor(red) lwidth(thick) lpattern(dot)) ///
if (1996 < proceeding_year_group & proceeding_year_group < 2018), ///
title("Opposition Proceeding Pendency", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Duration of Proceeding (in Days)") ///
xtitle("Year of Opposition Filing") ///
xlabel(1997(5)2017, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
ylabel(180(90)900, angle(0) labsize(medsmall) grid) ymtick(##3, grid) ///
legend ( ///
	nocolfirst ///
	justification(left) ///
	order(1 - " " 2 3) ///
		label(1 "Average Overall Duration") ///
		label(2 "Average Duration of" "Successful Oppositions") ///
		label(3 "Average Duration of" "Failed Oppositions") ///
	)
	
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_opp_length, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_opp_length.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_opp_length.pdf, replace

* Graph average opposition success rate
use /Volumes/TMData/Canada/analyses/CA_TM_allproceedings_yearly_timeseries, clear

twoway ///
	(tsline Opp_Success_Rate, lcolor(black)) ///
if (1996 < proceeding_year_group & proceeding_year_group < 2018), ///
title("Opposition Proceeding Success Rates", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Rate (%)") ///
xtitle("Year of Opposition Filing") ///
xlabel(1997(1)2018, angle(45) labsize(medsmall) grid) xmtick(##1, grid) ///
ylabel(25(5)40, angle(0) labsize(medsmall) grid) ymtick(##5, grid)

graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_opp_success, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_opp_success.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_opp_success.pdf, replace

* Graph average Nice Classes per application
use /Volumes/TMData/Canada/analyses/CA_TM_classes_yearly_timeseries.dta, clear

twoway ///
	(tsline ClassCount, lcolor(black)) ///
if (1974 < year_group & year_group < 2019), ///
title("Average Nice Classes Per Application", color(black)) ///
graphregion(fcolor(white)) ///
ytitle("Number of Classes") ///
xtitle("Application Year") ///
xlabel(1975(5)2020, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
ylabel(1(.5)5, angle(0) labsize(medsmall) grid) ymtick(##5, grid) ///
legend ( ///
	nocolfirst ///
	justification(center) ///
	label(1 "Number of Applications") ///
	)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_average_classcounts_year, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_average_classcounts_year.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_average_classcounts_year.pdf, replace

* Bar Graph of Nice Classes, by year

use /Volumes/TMData/Canada/analyses/CA_TM_classes_yearly_timeseries.dta, clear
preserve
forvalues x = 1/45 {
	replace IC`x' = IC`x'/1000
	label variable IC`x' `x'
	}
graph hbar (asis) ///
	IC1 ///
	IC2 ///
	IC3 ///
	IC4 ///
	IC5 ///
	IC6 ///
	IC7 ///
	IC8 ///
	IC9 ///
	IC10 ///
	IC11 ///
	IC12 ///
	IC13 ///
	IC14 ///
	IC15 ///
	IC16 ///
	IC17 ///
	IC18 ///
	IC19 ///
	IC20 ///
	IC21 ///
	IC22 ///
	IC23 ///
	IC24 ///
	IC25 ///
	IC26 ///
	IC27 ///
	IC28 ///
	IC29 ///
	IC30 ///
	IC31 ///
	IC32 ///
	IC33 ///
	IC34 ///
	IC35 ///
	IC36 ///
	IC37 ///
	IC38 ///
	IC39 ///
	IC40 ///
	IC41 ///
	IC42 ///
	IC43 ///
	IC44 ///
	IC45 ///
		if (1993 < year_group), ///
			bar(1, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(2, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(3, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(4, fcolor(white) lcolor(black) lwidth(vthin)) ///
				bar(5, fcolor(brown) lcolor(black) lwidth(vthin)) ///
			bar(6, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(7, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(8, fcolor(white) lcolor(black) lwidth(vthin)) ///
				bar(9, fcolor(red) lcolor(black) lwidth(vthin)) ///
			bar(10, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(11, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(12, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(13, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(14, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(15, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(16, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(17, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(18, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(19, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(20, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(21, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(22, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(23, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(24, fcolor(white) lcolor(black) lwidth(vthin)) ///
				bar(25, fcolor(orange) lcolor(black) lwidth(vthin)) ///
			bar(26, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(27, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(28, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(29, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(30, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(31, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(32, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(33, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(34, fcolor(white) lcolor(black) lwidth(vthin)) ///
				bar(35, fcolor(blue) lcolor(black) lwidth(vthin)) ///
			bar(36, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(37, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(38, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(39, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(40, fcolor(white) lcolor(black) lwidth(vthin)) ///
				bar(41, fcolor(purple) lcolor(black) lwidth(vthin)) ///
				bar(42, fcolor(green) lcolor(black) lwidth(vthin)) ///
			bar(43, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(44, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(45, fcolor(white) lcolor(black) lwidth(vthin)) ///
		over(year_group, label(labsize(vsmall))) ///
		blabel(name, position(center) size(half_tiny) alignment(middle) justification(center)) ///
		stack  ///
		xsize(12) ///
		ysize(7) ///
		title("Class Indications Per Year", color(black)) ///
		graphregion(fcolor(white)) ///
		ytitle("Total Class Indications (Thousands)") ///
		legend( ///
			nocolfirst ///
			rows(1) ///
			size(vsmall) ///
			justification(center) ///
			order(5 9 25 35 41 42) ///
			label(5 "Class 5") ///
			label(9 "Class 9") ///
			label(25 "Class 25") ///
			label(35 "Class 35") ///
			label(41 "Class 41") ///
			label(42 "Class 42") ///
		)
graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_all_classcounts_year, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_all_classcounts_year.png, replace
graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_all_classcounts_year.pdf, replace
			
restore

* Bar Graph of Nice Class Shares, by year

use /Volumes/TMData/Canada/analyses/CA_TM_classes_yearly_timeseries.dta, clear
preserve
gen total = 0
forvalues x = 1/45 {
	replace total = total + IC`x'
	}
forvalues x = 1/45 {
	replace IC`x' = (IC`x'/total) * 100
	label variable IC`x' `x'
	}
graph hbar (asis) ///
	IC1 ///
	IC2 ///
	IC3 ///
	IC4 ///
	IC5 ///
	IC6 ///
	IC7 ///
	IC8 ///
	IC9 ///
	IC10 ///
	IC11 ///
	IC12 ///
	IC13 ///
	IC14 ///
	IC15 ///
	IC16 ///
	IC17 ///
	IC18 ///
	IC19 ///
	IC20 ///
	IC21 ///
	IC22 ///
	IC23 ///
	IC24 ///
	IC25 ///
	IC26 ///
	IC27 ///
	IC28 ///
	IC29 ///
	IC30 ///
	IC31 ///
	IC32 ///
	IC33 ///
	IC34 ///
	IC35 ///
	IC36 ///
	IC37 ///
	IC38 ///
	IC39 ///
	IC40 ///
	IC41 ///
	IC42 ///
	IC43 ///
	IC44 ///
	IC45 ///
		if (1993 < year_group), ///
			bar(1, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(2, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(3, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(4, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(5, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(6, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(7, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(8, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(9, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(10, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(11, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(12, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(13, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(14, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(15, fcolor(white) lcolor(black) lwidth(vthin)) ///
				bar(16, fcolor(brown) lcolor(black) lwidth(vthin)) ///
			bar(17, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(18, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(19, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(20, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(21, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(22, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(23, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(24, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(25, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(26, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(27, fcolor(white) lcolor(black) lwidth(vthin)) ///
				bar(28, fcolor(red) lcolor(black) lwidth(vthin)) ///
			bar(29, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(30, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(31, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(32, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(33, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(34, fcolor(white) lcolor(black) lwidth(vthin)) ///
				bar(35, fcolor(blue) lcolor(black) lwidth(vthin)) ///
			bar(36, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(37, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(38, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(39, fcolor(white) lcolor(black) lwidth(vthin)) ///
			bar(40, fcolor(white) lcolor(black) lwidth(vthin)) ///
				bar(41, fcolor(purple) lcolor(black) lwidth(vthin)) ///
				bar(42, fcolor(green) lcolor(black) lwidth(vthin)) ///
			bar(43, fcolor(white) lcolor(black) lwidth(vthin)) ///
				bar(44, fcolor(orange) lcolor(black) lwidth(vthin)) ///
			bar(45, fcolor(white) lcolor(black) lwidth(vthin)) ///
		over(year_group, label(labsize(vsmall))) ///
		blabel(name, position(center) size(half_tiny) alignment(middle) justification(center)) ///
		stack  ///
		xsize(12) ///
		ysize(7) ///
		title("Class Indication Shares Per Year", color(black)) ///
		graphregion(fcolor(white)) ///
		ytitle("Percent of All Class Indications") ///
		legend( ///
			nocolfirst ///
			rows(1) ///
			size(vsmall) ///
			justification(center) ///
			order(16 28 35 41 42 44) ///
			label(16 "Class 16") ///
			label(28 "Class 28") ///
			label(35 "Class 35") ///
			label(41 "Class 41") ///
			label(42 "Class 42") ///
			label(44 "Class 44") ///
		)
	graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_percent_classcounts_year, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_percent_classcounts_year.png, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_percent_classcounts_year.pdf, replace
				
	restore

* Graph of Current Filing Bases by application year, based on CA_TM_main

	use /Volumes/TMData/Canada/analyses/CA_TM_basis_rates.dta, clear
	twoway ///
	(tsline UseBasis, lcolor(black)) ///
	(tsline ITUBasis, lcolor(green) lpattern(-)) ///
	(tsline ForeignRegBasis, lcolor(red) lwidth(thick) lpattern(dot)) ///
	(tsline ForeignAppBasis, lcolor(blue) lwidth(thin) lpattern(_._)) ///
	if (1977 < year_group & year_group < 2019), ///
	title("Current Filing Bases Claimed", color(black)) ///
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
		
	graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_filing_bases, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_filing_bases.png, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_filing_bases.pdf, replace
	
* Graph of Current Filing Bases by application year, based on CA_TM_claims

	use /Volumes/TMData/Canada/analyses/CA_TM_basis_timeseries.dta, clear
	twoway ///
	(tsline Used, lcolor(black)) ///
	(tsline ProposedUse, lcolor(green) lpattern(dash)) ///
	(tsline ForeignReg, lcolor(red) lwidth(thick) lpattern(dot)) ///
	(tsline Priority, lcolor(orange) lwidth(thin) lpattern(shortdash)) ///
	(tsline ForeignUse, lcolor(blue) lwidth(thin) lpattern(longdash_dot)) ///
	if (1977 < year_group & year_group < 2019), ///
	title("Filing Bases Claimed at Application", color(black)) ///
	graphregion(fcolor(white)) ///
	ytitle("Percent of Applications" "Claiming Filing Basis", size(small)) ///
	xtitle("Year of Application") ///
	xlabel(1978(5)2019, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
	ylabel(0(10)70, angle(0) labsize(medsmall) grid) ymtick(##4, grid) ///
	legend ( ///
		nocolfirst ///
		justification(left) ///
		order(1 2 3 4 5) ///
			label(1 "Use in Canada") ///
			label(2 "Proposed Use in Canada") ///
			label(3 "Foreign Registration") ///
			label(4 "Priority") ///
			label(5 "Foreign Use") ///
		)
		
	graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_filing_claims, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_filing_claims.png, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_filing_claims.pdf, replace
	
* Graph of Current Filing Bases by application year, based on CA_TM_claims, 
* assuming Declarations of Use were Proposed Use applications

	use /Volumes/TMData/Canada/analyses/CA_TM_basis_timeseries.dta, clear
	twoway ///
	(tsline Used, lcolor(black)) ///
	(tsline ImpliedProposedUse, lcolor(green) lpattern(dash)) ///
	(tsline ForeignReg, lcolor(red) lwidth(thick) lpattern(dot)) ///
	(tsline Priority, lcolor(orange) lwidth(thin) lpattern(shortdash)) ///
	(tsline ForeignUse, lcolor(blue) lwidth(thin) lpattern(longdash_dot)) ///
	if (1977 < year_group & year_group < 2019), ///
	title("Filing Bases Claimed at Application", color(black)) ///
	graphregion(fcolor(white)) ///
	ytitle("Percent of Applications" "Claiming Filing Basis", size(small)) ///
	xtitle("Year of Application") ///
	xlabel(1978(5)2019, angle(45) labsize(medsmall) grid) xmtick(##5, grid) ///
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
		
	graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_filing_claims_inferred, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_filing_claims_inferred.png, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_filing_claims_inferred.pdf, replace
	
* Bar Graph of Applicant Nationalities

use /Volumes/TMData/Canada/analyses/CA_TM_country_barchart_data.dta, clear
preserve
foreach x in CA US CH CN DE FR GB JP Other {
	replace `x' = `x'/1000
	}
graph bar (asis) CA US CH CN DE FR GB JP Other, ///
		bar(1, fcolor(red) fintensity(70) lcolor(black) lwidth(vthin)) ///
		bar(2, fcolor(blue) fintensity(70) lcolor(black) lwidth(vthin)) ///
		bar(3, fcolor(white) lcolor(black) lwidth(vthin)) ///
		bar(4, fcolor(yellow) fintensity(80) lcolor(black) lwidth(vthin)) ///
		bar(5, fcolor(black) lcolor(black) lwidth(vthin)) ///
		bar(6, fcolor(green) fintensity(50) lcolor(black) lwidth(vthin)) ///
		bar(7, fcolor(orange) fintensity(60) lcolor(black) lwidth(vthin)) ///
		bar(8, fcolor(purple) fintensity(20) lcolor(black) lwidth(vthin)) ///
		bar(9, fcolor(gray) fintensity(70) lcolor(black) lwidth(vthin)) ///
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
	title("Application Counts by Country", color(black)) ///
	graphregion(fcolor(white)) ///
	ytitle("Applications (Thousands)", size(small)) ///
	ylabel(#10, labsize(vsmall) angle(0)) ///
	legend( ///
		nocolfirst ///
		rows(2) ///
		size(vsmall) ///
		justification(center) ///
		label(1 "Canada") ///
		label(2 "United States") ///
		label(3 "Switzerland") ///
		label(4 "China") ///
		label(5 "Germany") ///
		label(6 "France") ///
		label(7 "United Kingdom") ///
		label(8 "Japan") ///
		label(9 "Other") ///
	)

	graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_owner_countries, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_owner_countries.png, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_owner_countries.pdf, replace
				
* Bar Graph of Foreign Claims

use /Volumes/TMData/Canada/analyses/CA_TM_filed_countries_barchart_data.dta, clear
preserve
foreach x in US EM DE FR GB CH AU ES IT Other {
	replace `x' = `x'/1000
	}
graph bar (asis) US EM DE FR GB CH AU IT Other, ///
		bar(1, fcolor(blue) fintensity(70) lcolor(black) lwidth(vthin)) ///
		bar(2, fcolor(brown) lcolor(black) lwidth(vthin)) ///
		bar(3, fcolor(black) lcolor(black) lwidth(vthin)) ///
		bar(4, fcolor(green) fintensity(50) lcolor(black) lwidth(vthin)) ///
		bar(5, fcolor(orange) fintensity(60) lcolor(black) lwidth(vthin)) ///
		bar(6, fcolor(white) lcolor(black) lwidth(vthin)) ///
		bar(7, fcolor(pink) fintensity(30) lcolor(black) lwidth(vthin)) ///
		bar(8, fcolor(red) fintensity(70) lcolor(black) lwidth(vthin)) ///
		bar(9, fcolor(gray) fintensity(70) lcolor(black) lwidth(vthin)) ///
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
	title("Application Counts by Country", color(black)) ///
	graphregion(fcolor(white)) ///
	ytitle("Applications (Thousands)", size(small)) ///
	ylabel(#10, labsize(vsmall) angle(0)) ///
	legend( ///
		nocolfirst ///
		rows(2) ///
		size(vsmall) ///
		justification(center) ///
		label(1 "United States") ///
		label(2 "European Union") ///
		label(3 "Germany") ///
		label(4 "France") ///
		label(5 "United Kingdom") ///
		label(6 "Switzerland") ///
		label(7 "Australia") ///
		label(8 "Italy") ///
		label(9 "Other") ///
	)

	graph save /Volumes/TMData/Canada/analyses/figures/CA_TM_claimed_countries, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_claimed_countries.png, replace
	graph export /Volumes/TMData/Canada/analyses/figures/CA_TM_claimed_countries.pdf, replace
