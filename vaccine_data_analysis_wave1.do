// net install asdoc, from(http://fintechprofessor.com) replace

// ideas:
// robustness check: to compare distrubution of answers for Ariadna data
// robustness check: to drop out 5% of the fastest subjects
// to remove participant with inconsistent justification of vax decision
// to remove all other categories if there is a category "just_yes" OR just_no

clear all
// install package to import spss file
// net from http://radyakin.org/transfer/usespss/beta
//import spss using "G:\Shared drives\Koronawirus\studies\3 szczepionka\20210310 data analysis (Arianda wave2)\archive\WNE2_N3000.sav", clear 
//import spss using "/Volumes/GoogleDrive/Shared drives/Koronawirus/studies/3 szczepionka/20210310 data analysis (
// > Arianda wave2)/archive/WNE2_N3000.sav"

//ssc install scheme-burd, replace
capture set scheme burd
//INTSALATION:
//capture ssc install tabstatmat
//ssc install mplotoffset
//ssc install coefplot 

clear all

//common data cleaning

capture cd "G:\Shared drives\Koronawirus\studies"
capture cd "G:\Dyski współdzielone\Koronawirus\studies"
capture cd "/Volumes/GoogleDrive/Shared drives/Koronawirus/studies"
capture cd "G:\Shared drives\Koronawirus\studies\"

use "5 common data cleaning (puzzles Study 3 and Vaccines wave 1)\wave1_final_refto.dta"
do "5 common data cleaning (puzzles Study 3 and Vaccines wave 1)\common_data_cleaning.do

// adding performance:

 cd "G:\Shared drives\Koronawirus\studies\4 puzzles Study 3 (actual full study- Ariadna)\data analysis"
capture cd "G:\Dyski współdzielone\Koronawirus\studies\4 puzzles (actual full study)\data analysis"
capture cd "/Volumes/GoogleDrive/Shared drives/Koronawirus/studies/4 puzzles (actual full study)/data analysis"

do puzzles_data_analysis.do

 cd "G:\Shared drives\Koronawirus\studies\3 szczepionka (Vaccines wave 1 and 2)\20210301 data analysis (Ariadna wave1)"
capture cd "G:\Dyski współdzielone\Koronawirus\studies\3 szczepionka\20210301 data analysis (Ariadna wave1)"
capture cd "/Volumes/GoogleDrive/Shared drives/Koronawirus/studies/3 szczepionka/20210301 data analysis (Ariadna wave1)"




//////////////////*************GLOBALS***************////////////
global wealth "wealth_low wealth_high" //included into demogr
global demogr "male age i.city_population secondary_edu higher_edu $wealth health_poor health_good $health_details tested_pos thinks_had covid_hospitalized covid_friends religious i.religious_freq status_unemployed status_pension status_student i.treatment performance" 
global demogr_no_ma "i.city_population $wealth health_poor health_good $health_details tested_pos thinks_had covid_hospitalized covid_friends religious i.religious_freq status_unemployed status_pension status_student"
global demogr_int "male age higher_edu" //RK: Michal, did you ommit secondary_edu?
global emotions "e_joy e_fear e_anger e_disgust e_sadness e_surprise"
global risk "risk_overall risk_work risk_health"
global worry "fear_covid fear_cold fear_unempl"
global control "control_covid control_cold control_unempl $explanations"
global informed "informed_covid informed_cold informed_unempl"
global conspiracy "conspiracy_general_info conspiracy_stats conspiracy_excuse" //we also have conspiracy_score
global voting "i.voting"
global voting_short "b2.voting_short" // makes the largest and centrist party (two of them really: PO+Hołownia) the base category 
global health_advice "mask_wearing distance"
//global order_effects "$g_order_emotions $order_trust $g_order_risk $g_order_worry $g_order_control $g_order_informed $g_order_estimations $g_order_conspiracy order_vaccine_persuasion"

pwcorr no_manips $vaccine_vars male age second higher $wealth health*, sig
tab no_manips voting, chi

foreach i in $health_advice{
tab `i'
}
global covid_impact "subj_est_cases_ln subj_est_death_l"
//global order_effects ""
// DEFINED (UND UPDATED TO NEW VERSION) BEFORE! global vaccine_vars "v_prod_reputation	v_efficiency	v_safety		v_other_want_it	v_scientific_authority	v_vax_passport	v_p_gets70	v_p_pays10	v_p_pays70" // i leave out scarcity -- sth that supposedly everybody knows. we can't estimate all because of ariadna's error anyway
// global vaccine_short "v_prod_reputation	v_efficiency	v_safety	v_scarcity	v_other_want_it	v_scientific_authority	v_vax_passport"
global prices "v_p_gets70	v_p_pays10	v_p_pays70"



/*

capture drop edu_short
gen edu_short=1*ele+2*sec+3*higher

logit vaxx_yes sex##c.age edu_short##voting_short [pweight=waga]
margins sex, at(age=(18(5)78))
marginsplot, recast(line) recastci(rarea) xtitle("Wiek") ytitle("szansa, że ktoś zdecyduje się zaszczepić") ylabel(0 "0%" 0.2 "20%"  0.4 "40%" 0.6 "60%" 0.8 "80%" ) title("")

margins edu_short#voting_short

marginsplot, recast(scatter) xtitle("wykształcenie") ytitle("szansa, że ktoś zdecyduje się zaszczepić") ylabel(0 "0%" 0.2 "20%"  0.4 "40%" 0.6 "60%" 0.8 "80%" ) title("") noci
*/


//////////**** DISTRIBUTION OF THE MAIN DEPENDENT VARIABLE

tabstat vaxx_yes [weight=waga], statistics( mean ) by(region_id)


// FOR THE PAPER -- TABLE 1

sum vaxx_def_yes [weight=waga]
sum vaxx_rather_yes [weight=waga]
sum vaxx_rather_no [weight=waga]
sum vaxx_def_no [weight=waga]

sum vaxx_yes [weight=waga]


//////////**** simple logit yes/no
logit vaxx_yes $vaccine_vars $demogr [pweight=waga], or
est store l_1
dis "$vaccine_vars $demogr"
// this global will later be changed!
global basic_for_int "$vaccine_vars $demogr $voting_short $emotions $risk fear_covid $trust_dummies control_covid $informed conspiracy_score $covid_impact $health_advice"

logit vaxx_yes  $basic_for_int [pweight=waga], or
test control_cov $informed conspiracy_score $covid_impact $health_advice

xi: logit vaxx_yes  $basic_for_int i.region infected_yesterday [pweight=waga], or
test _Iregion_2/_Iregion_16
 
xi: logit vaxx_yes  $basic_for_int i.region PL_infected_y [pweight=waga], or
xi: logit vaxx_yes  $basic_for_int i.region deceased_y_pc [pweight=waga], or

xi: logit vaxx_yes  $basic_for_int i.region infected_y_pc deceased_y_pc PL_infected_yesterday PL_deceased_yesterday [pweight=waga], or
test _Iregion_2/_Iregion_16
test infected_y_pc deceased_y_pc
test PL_infected_yesterday PL_deceased_yesterday
test _Iregion_2/_Iregion_16 infected_y_pc deceased_y_pc PL_infected_yesterday PL_deceased_yesterday

//to add to every model?
global cases_vars "i.region infected_y_pc deceased_y_pc PL_infected_yesterday PL_deceased_yesterday"
global basic_for_int "$basic_for_int $cases_vars"
xi: logit vaxx_yes  $basic_for_int [pweight=waga], or
test control_cov $informed conspiracy_score $covid_impact $health_advice _Iregion_2/_Iregion_16 infected_y_pc decea PL_infect PL_dec
est store l_2

xi: logit vaxx_yes sex##c.age edu_short##b2.voting_short $cases_vars $vaccine_vars $demogr_no_ma  $emotions $risk fear_covid $trust_dummies control_covid $informed conspiracy_score  $covid_impact $health_advice i.treatment performance [pweight=waga]
est store l_3

// MARGINS, plots
margins sex, at(age=(18(5)78))

marginsplot, recast(line) ciopt(color(%50)) recastci(rarea) xtitle("Age") ytitle("Probability that the responder is willing to get vaccinated") ylabel(0.4 "40%" 0.5 "50%" 0.6 "60%" 0.7 "70%" 0.8 "80%") title("")
//marginsplot, recast(line) recastci(rarea) 
graph save "margins-sex_age_eng1.gph", replace

//ssc describe mplotoffset

//margins edu_short#voting_short
//PL: 
//marginsplot, recast(scatter) xtitle("wykształcenie") ytitle("Odsetek badanych chcących się szczepić") ylabel(0 "0%" 0.2 "20%"  0.4 "40%" 0.6 "60%" 0.8 "80%" ) title("")
//marginsplot, recast(scatter) name(gr1,replace)
//graph save "margins-edu_voting_eng1.gph", replace

margins edu_short#voting_short
mplotoffset, recast(scatter)  offset(.1)  xtitle("Education") ytitle("Probability that the responder is willing to get vaccinated") ylabel(0 "0%" 0.2 "20%"  0.4 "40%" 0.6 "60%" 0.8 "80%" ) title("")
graph save Graph "margins-edu_voting_eng1.gph", replace


/// WHY AND WHO by decision
tabstat why_* [weight=waga], by(v_decision)
tabstat who_* [weight=waga], by(v_decision)
tab v_decision


/// correlation, factor analysis WHY AND WHO
global why_no "why_safety_concerns why_efficacy_concerns why_poorly_tested why_not_afraid_virus why_just_no why_vaccine_too_costly why_conspiracy why_contraindications why_antibodies why_doubts_no why_mistrust_no why_antivax"
factor $why_no if vaxx_yes==0

global why_yes "why_safety_general why_others_safety why_normality why_just_yes why_belief_science why_no_alternatives why_morbidity_factors why_convenience why_doubts_yes why_money why_already_vac why_obligation"
factor $why_yes if vaxx_yes

global who_no "who_dont_know who_nothing who_family who_doctor who_else who_more_info who_forced who_money who_more_evidence_efficacy who_more_evidence_safety who_time" 
factor $who_no if vaxx_yes==0

global who_yes " who_dont_know who_nothing who_family who_doctor who_else who_more_info who_own_health who_more_evidence_inefficacy who_side_effects"
factor $who_yes if vaxx_yes
// i don't find them fascinating


global who_no 
pwcorr $who_yes $why_yes if vaxx_yes, sig
pwcorr $who_no $why_no if vaxx_yes==0, sig

pwcorr why_safety_con why_poorly why_just_no why_mistrust_no who_don who_nothi if vaxx_yes==0,  sig
pwcorr why_safety_g why_others why_convenie why_normality who_dont who_nothing who_side, sig
sum why_* who_* if vaxx_yes
// factor why_safety_overall/why_doubts who_* if vaxx_yes


capture save "G:\Dyski współdzielone\Koronawirus\studies\3 szczepionka\20210301 data analysis (Ariadna wave1)\wave1_final_before_tuples.dta", replace
capture use "G:\Dyski współdzielone\Koronawirus\studies\3 szczepionka\20210301 data analysis (Ariadna wave1)\wave1_final_before_tuples.dta", replace

global vv_plus "$vaccine_vars v_p_pay0 v_scarcity"
dis "$vv_plus"

global interactions ""
foreach manipulation in $vv_plus {
	foreach demogr in $demogr_int {
	
	local abb=substr("`manipulation'",1,14)
	
	gen i_`abb'_`demogr'=`abb'*`demogr'	
	global interactions "$interactions i_`abb'_`demogr'" 	
}
}


dis "$interactions"
xi:logit vaxx_yes $basic_for_int  $interactions [pweight=waga], or 
est store l_4
test $interactions

est table l_1 l_2 l_3 l_4, b(%12.3f) var(20) star(.01 .05 .10) stats(N r2_p) eform // FOR THE PAPER
//to present regression results (which?) as in figure 3 in Heike's Kluever et al paper https://osf.io/ax6pw/ - in other words, to do forest plot
coefplot  l_1 ,  eform nolabels drop(_cons) xscale(log) xline(1)  xtitle("odds ratio") graphregion(fcolor(white)) levels(95)  //omitted 


local counter=0

global int_manips=""
capture drop vvi_*
foreach manipulation in $vv_plus {

	foreach m2 in $vaccine_vars {
	local counter=`counter'+1
	gen vvi_`counter'=`manipulation'*`m2'	
	label var vvi_`counter' "`manipulation'_`m2'"
	global int_manips="$int_manips vvi_`counter'" //  `vvi_`counter''"
}
}
dis "$int_manips"


xi: logit vaxx_yes $basic_for_int  $int_manips [pweight=waga], or
est store l_5
test $int_manips

//check for interactions: vaccine price + income
global price_wealth ""
foreach price in $prices {
	foreach level in $wealth {
	gen wp_`price'_`level'=`price'*`level'
	global price_wealth "$price_wealth wp_`price'_`level'" 	
}
}
dis "$price_wealth"
xi: logit vaxx_yes $basic_for_int  $price_wealth [pweight=waga], or
est store l_6
test $price_wealth


//check for interactions: vaccine persuasive messages set 1 + conspiracy score
global int_consp_manip ""
foreach manipulation in $vaccine_vars {
	local abb=substr("`manipulation'",1,14)
	gen `abb'_conspiracy=`abb'*conspiracy_score	
	global int_consp_manip "$int_consp_manip `abb'_conspiracy" 	
}
dis "$int_consp_manip"
xi: logit vaxx_yes $basic_for_int  $int_consp_manip [pweight=waga], or
est store l_7
test $int_consp_manip

drop v_*_conspiracy





//check for interactions: vaccine persuasive messages (prod from EU; vaccine safety + voting)
//gen int_voting_prod=voting*v_prod_reputation
//gen int_voting_safety=voting*v_safety
xi: quietly logit vaxx_yes $basic_for_int i.voting*v_prod_reputation i.voting*v_safety [pweight=waga]
est store l_8
test  _IvotXv_pro_2 _IvotXv_pro_3 _IvotXv_pro_4 _IvotXv_pro_7 _IvotXv_pro_8 _IvotXv_pro_9 _IvotXv_saf_2 _IvotXv_saf_3 _IvotXv_saf_4 _IvotXv_saf_7 _IvotXv_saf_8 _IvotXv_saf_9


xi: logit vaxx_yes $basic_for_int  $ifo_vaxshort $io_vaxshort [pweight=waga], or
est store l_9
test  $ifo_vaxshort $io_vaxshort


/*
capture drop i_v*emo_*
capture drop i_v*e_*
global int_emo_manip ""
foreach manipulation in $vaccine_vars {
	foreach emo in $emotions {
	local abb=substr("`manipulation'",1,14)
	gen i_`abb'_`emo'=`abb'*`emo'	
	global int_emo_manip "$int_emo_manip i_`abb'_`emo'" 	
}
}

dis "$int_emo_manip"
logit vaxx_yes $basic_for_int  $int_emo_manip [pweight=waga], or
est store l_10
test $int_emo_manip
*/


est table l_5 l_6 l_7 l_8 l_9, b(%12.3f) var(20) star(.01 .05 .10) stats(N r2_p) eform // FOR THE PAPER



// m_3 m_4 m_5 m_6 m_7, b(%12.3f) var(20) star(.01 .05 .10) stats(N)
//result:yes/no interactions detected
//result:yes/no order effects detected 
/////****END********************************/////////

// est table m_2 m_1 m_0, b(%12.3f) var(20) star(.01 .05 .10) stats(N)

// XXXXXXXXXXXXXXXXXXX ologit specs analogous to logit here pls once we finally decide on logit!

//////////**** now ologit
ologit v_decision $vaccine_vars $demogr [pweight=waga], or
est store o_1

xi: ologit v_decision  $basic_for_int [pweight=waga], or
est store o_2
test control_cov $informed conspiracy_score $covid_impact $health_advice
test _Iregion_2/_Iregion_16
test infected_y_pc deceased_y_pc
test PL_infected_yesterday PL_deceased_yesterday
test _Iregion_2/_Iregion_16 infected_y_pc deceased_y_pc PL_infected_yesterday PL_deceased_yesterday


xi: ologit v_decision sex##c.age edu_short##b2.voting_short $cases_vars $vaccine_vars $demogr_no_ma  $emotions $risk fear_covid $trust_dummies control_covid $informed conspiracy_score  $covid_impact $health_advice i.treatment performance [pweight=waga]
est store o_3
tab edu_short

quietly xi: ologit v_decision $basic_for_int  $interactions [pweight=waga], or 
est store o_4
test $interactions

est table o_1 o_2 o_2 o_3 o_4, b(%12.3f) var(20) star(.01 .05 .10) stats(N r2_p) eform // FOR THE PAPER
//to present regression results (which?) as in figure 3 in Heike's Kluever et al paper https://osf.io/ax6pw/ - in other words, to do forest plot
coefplot  o_1 ,  eform nolabels drop(_cons) xscale(log) xline(1)  xtitle("Odds ratio") graphregion(fcolor(white)) levels(95)  //omitted 


xi: ologit v_decision $basic_for_int  $int_manips [pweight=waga], or
est store o_5
test $int_manips

xi: ologit v_decision $basic_for_int  $price_wealth [pweight=waga], or
est store o_6
test $price_wealth


//check for interactions: vaccine persuasive messages set 1 + conspiracy score
global int_consp_manip ""
foreach manipulation in $vaccine_vars {
	local abb=substr("`manipulation'",1,14)
	gen `abb'_conspiracy=`abb'*conspiracy_score	
	global int_consp_manip "$int_consp_manip `abb'_conspiracy" 	
}
dis "$int_consp_manip"
xi: ologit v_decision $basic_for_int  $int_consp_manip [pweight=waga], or
est store o_7
test $int_consp_manip

drop v_*_conspiracy



//check for interactions: vaccine persuasive messages (prod from EU; vaccine safety + voting)
//gen int_voting_prod=voting*v_prod_reputation
//gen int_voting_safety=voting*v_safety
xi: quietly ologit v_decision $basic_for_int i.voting*v_prod_reputation i.voting*v_safety [pweight=waga]
est store o_8
test  _IvotXv_pro_2 _IvotXv_pro_3 _IvotXv_pro_4 _IvotXv_pro_7 _IvotXv_pro_8 _IvotXv_pro_9 _IvotXv_saf_2 _IvotXv_saf_3 _IvotXv_saf_4 _IvotXv_saf_7 _IvotXv_saf_8 _IvotXv_saf_9

/*
//old code from wave2
//check fgor order effects, added $ifo_vaxshort $io_vaxshort
dis "$ifo_vaxshort $io_vaxshort"
xi: ologit v_decision $basic_for_int  $ifo_vaxshort $io_vaxshort [pweight=waga], or
est store o_9
test $ifo_vaxshort $io_vaxshort
*/

est table o_5 o_6 o_7 o_8, b(%12.3f) var(20) star(.01 .05 .10) stats(N r2_p) eform // FOR THE PAPER


xi: ologit decision_change v_decision $basic_for_int [pweight=waga], or

// FIGURES ??
/////////**********************************************////////////////
/////////**********************************************////////////////
/////////**********************************************////////////////


// manipulation checks from why questions
prtest ref_to_referred_to_the_price, by(v_p_pay0) // ok
prtest why_vaccine_too, by(v_p_pays70) // ok

prtest ref_to_referred_to_the_e if vaxx_yes, by(v_efficiency) // right direction, but not sig
prtest why_conv if vaxx_yes, by(v_vax_passport) // ok
prtest why_conv, by(v_vax_passport) // ok

prtest why_norm if vaxx_yes, by(v_scientific_authority) // right direction, n.s.

// not clear which way it should go :):
//prtest why_poor if vaxx_yes==0, by(v_tested) 
//prtest why_poor, by(v_tested) 
prtest why_safety_gen if vaxx_yes, by(v_safety)

//no test for v_scarcity because we dont have such explanations

/*
//merge data (our main dependent variable and demographics vars) of wave1 with wave2 and run non-parametric test
keep v_decision vaxx_yes ID sex age_category city_population year region_id edu risk_overall risk_work risk_health  control_covid control_cold control_unempl informed_covid informed_cold informed_unempl mask_wearing conspiracy_general_info conspiracy_stats conspiracy_excuse had_covid covid_hospitalized covid_friends_hospital_initial income health_state religious_initial religious_freq empl_status voting waga region male age age2 elementary_edu secondary_edu higher_edu edu_short wealth_low wealth_high health_poor health_good tested_pos_covid thinks_had_covid covid_friends no_covid_friends covid_friends_hospital covid_friends_nohospital religious religious_often status_unemployed status_pension status_student conspiracy_score consp_stats_high 

gen wave=1

save "G:\Shared drives\Koronawirus\studies\3 szczepionka (Vaccines wave 1 and 2)\20210310 data analysis (Arianda wave2)\wave1_truncated_data_for_demogr_comparison.dta", replace
*/

///OLD CODE
/*
// ideas:
// robustness check: to compare distrubution of answers for Ariadna data
// robustness check: to drop out 5% of the fastest subjects

//ssc install tabstatmat
clear all 
capture cd "G:\Shared drives\Koronawirus\studies\5 common data cleaning (Ariadna data)"
capture cd "G:\Dyski współdzielone\Koronawirus\studies\5 common data cleaning (Ariadna data)"
capture cd "/Volumes/GoogleDrive/Shared drives/Koronawirus/studies/5 common data cleaning (Ariadna data)"
use data_stata_format.dta, clear
do common_data_cleaning.do

capture cd "G:\Shared drives\Koronawirus\studies\3 szczepionka\data analysis"
capture cd "G:\Dyski współdzielone\Koronawirus\studies\3 szczepionka\data analysis"
capture cd "/Volumes/GoogleDrive/Shared drives/Koronawirus/studies/3 szczepionka"

//[P40] Gdyby po pierwszych miesiącach szczepień potwierdziło się, że szczepionka jest skuteczna i bezpieczna, to byłbyś skłonny się zaszczepić? Zaznacz.
rename p40 decision_change
tab decision_change
//this variable will be included into analysis to see which factors (e.g. emotions) are assotiated with vaccination decision change

//RK:below code is from wave2, who put it here?:D
//health status details:
//rename M9_1 health_vaccine_side_effects
//rename M9_2 health_covid_serious
//"smoking categories consisted of “very light” (1–4 CPD), “light” (5–9 CPD), “moderate” (10–19 CPD), and “heavy” (20+ CPD) Rostron, Brian L., et al. "Changes in Cigarettes per Day and Biomarkers of Exposure Among US Adult Smokers in the Population Assessment of Tobacco and Health Study Waves 1 and 2 (2013–2015)." Nicotine and Tobacco Research 22.10 (2020): 1780-1787."
//rename M9_3a health_smoking_howmany_cig_perday
//base level, ommited
//gen health_smoking_vlight=health_smoking_howmany_cig_perday>0&health_smoking_howmany_cig_perday<5
//gen health_smoking_light=health_smoking_howmany_cig_perday>4&health_smoking_howmany_cig_perday<10
//gen health_smoking_moderate=health_smoking_howmany_cig_perday>9&health_smoking_howmany_cig_perday<20
//gen health_smoking_heavy=health_smoking_howmany_cig_perday>19
//global health_details "health_vaccine_side_effects health_covid_serious health_smoking_light health_smoking_moderate health_smoking_heavy"
//above global will be included into global demogr

//open ended question:
// [P38] Opisz poniżej główne powody swojej decyzji odnośnie zaszczepienia się na koronawirusa. 
// [P39] Kto lub co mogłoby zmienić Twoją decyzję odnośnie zaszczepienia się na koronawirusa? Opisz poniżej.
// [optional] [P21] Jakie czynniki mają główny wpływ na to, w jakiej mierze jesteś zaniepokojony/a pandemią koronawirusa? 
//will be classified and set of explanations will be produced.
//every explanation will be assosiated with a dummy variable
//pseudocode:
//global explanations "p38_1 p38_2 p39_1 p39_2 p21_1 p21_2"//included into "contol" global

//order effects check
gen row_nr=_n
sum row_nr
//lets assume that there was 7 weekdays and each day equal share of people populated survey
gen count=_N/7
gen day1=row_nr>(count-_N/7)&row_nr<count
replace count=count+_N/7
gen day2=row_nr>(count-_N/7)&row_nr<count
replace count=count+_N/7
gen day3=row_nr>(count-_N/7)&row_nr<count
replace count=count+_N/7
gen day4=row_nr>(count-_N/7)&row_nr<count
replace count=count+_N/7
gen day5=row_nr>(count-_N/7)&row_nr<count
replace count=count+_N/7
gen day6=row_nr>(count-_N/7)&row_nr<count
replace count=count+_N/7
gen day7=row_nr>(count-_N/7)&row_nr<count
replace count=count+_N/7

global wealth "wealth_low wealth_high" //included into demogr
//global trust "trust_gov, trust_neighbours, trust_doctors, trust_media, trust_family, trust_scientists"//included into demogr
global demogr "male age age2 i.city_population secondary_edu higher_edu $wealth health_poor health_good $health_details had_covid  covid_friends religious i.religious_freq status_unemployed status_pension status_student $trust"
global demogr_int "male age higher_edu"
global treatments "t_cold t_unempl"
global emotions "e_happiness e_fear e_anger e_disgust e_sadness e_surprise"
global risk "risk_overall risk_work risk_health"
global worry "fear_covid fear_cold fear_unempl"
global control "control_covid control_cold control_unempl $explanations"
global informed "informed_covid informed_cold informed_unempl"
global conspiracy "conspiracy_general_info conspiracy_stats conspiracy_excuse" //we also have conspiracy_score
global voting "i.voting"
global health_advice "mask_wearing distance"
global covid_impact "subj_est_cases_ln subj_est_death_l"
global order_effects1 "row_nr"
global order_effects2 "day1 day2 day3 day4 day5 day6 day7"
global vaccine_vars "v_producer_reputation	v_efficiency	v_safety		v_other_want_it	v_scientific_authority	v_vax_passport	v_p_gets70	v_p_pays10	v_p_pays70" // i leave out scarcity -- sth that supposedly everybody knows. we can't estimate all because of ariadna's error anyway
global vaccine_short "v_producer_reputation	v_efficiency	v_safety	v_scarcity	v_other_want_it	v_scientific_authority	v_vax_passport"
global prices "v_p_gets70	v_p_pays10	v_p_pays70"


//////////****order effects and interactions check**********/////
quietly ologit v_decision $vaccine_vars $demogr 
est store m_1

//RK:below code is from wave2, who put it here?:D
/*
// all vars beggining from test_... - these vars names are not known yet, it is a pseudo code
// robustness check: to add order effects for vaccine persuasive messages
rename test_kolejnosc_pytan_szczepionka order_vaccine_persuasion
replace order_vaccine_persuasion=subinstr(order_vaccine_persuasion,"p","",.)
split order_vaccine_persuasion, p("-")
global order_effects "order_vaccine_persuasion1 order_vaccine_persuasion2 order_vaccine_persuasion3 order_vaccine_persuasion4 order_vaccine_persuasion5 order_vaccine_persuasion6 order_vaccine_persuasion7 order_vaccine_persuasion8"
// robustness check: to add order effects for emotions
//[P17] Jak silnie odczuwasz w tej chwili (obecnie) poniższe emocje?
rename test_kolejnosc_pytan_emocje order_emotions
replace order_emotions=subinstr(order_emotions,"p","",.)
split order_emotions, p("-")
global order_effects "order_emotions1 order_emotions2 order_emotions3 order_emotions4 order_emotions5 order_emotions6 order_vaccine_persuasion1 order_vaccine_persuasion2 order_vaccine_persuasion3 order_vaccine_persuasion4 order_vaccine_persuasion5 order_vaccine_persuasion6 order_vaccine_persuasion7 order_vaccine_persuasion8"
// robustness check: to add order effects for trust question
//[trust_gov, trust_neighbours, trust_doctors, trust_media, trust_family, trust_scientists] Czy ma Pan zaufanie do?: 
rename test_kolejnosc_pytan_zaufanie order_trust
replace order_trust=subinstr(order_trust,"p","",.)
split order_trust, p("-")
global order_effects "order_trust1 order_trust2 order_trust3 order_trust4 order_trust5 order_trust6 order_trust7 order_emotions1 order_emotions2 order_emotions3 order_emotions4 order_emotions5 order_emotions6 order_vaccine_persuasion1 order_vaccine_persuasion2 order_vaccine_persuasion3 order_vaccine_persuasion4 order_vaccine_persuasion5 order_vaccine_persuasion6 order_vaccine_persuasion7 order_vaccine_persuasion8"
*/

quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting  $control $informed conspiracy_score $covid_impact $health_advice $order_effects
est store m_2
test $vaccine_vars

//check for interactions: vaccine persuasive messages set 1 + demographics
global interactions ""
foreach manipulation in $vaccine_vars {
	foreach demogr in $demogr_int {
	local abb=substr("`manipulation'",1,14)
	gen i_`abb'_`demogr'=`abb'*`demogr'	
	global interactions "$interactions i_`abb'_`demogr'" 	
}
}
dis "$interactions"
quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $health_advice $order_effects $interactions
est store m_3
test $interactions

//check for interactions: vaccine persuasive messages set 1 + vaccine persuasive messages set 2
global int_manips ""
foreach manipulation in $vaccine_short {
	foreach man2 in $vaccine_vars {
	local abb=substr("`manipulation'",1,14)
	local abb2=substr("`man2'",1,14)
	 gen vi_`abb'_`abb2'=`abb'*`abb2'	
	global int_manips "$int_manips vi_`abb'_`abb2'" 	
}
}
dis "$int_manips"
quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $health_advice $order_effects $int_manips
est store m_4
test $int_manips

//check for interactions: vaccine price + income
global price_wealth ""
foreach price in $prices {
	foreach level in $wealth {
	gen wp_`price'_`level'=`price'*`level'
	global price_wealth "$price_wealth wp_`price'_`level'" 	
}
}
dis "$price_wealth"
quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $health_advice $order_effects $price_wealth
est store m_5
test $price_wealth

//check for interactions: vaccine persuasive messages (producer from EU; vaccine safety + voting)
//gen int_voting_prod=voting*v_producer_reputation
//gen int_voting_safety=voting*v_safety
quietly xi:ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $health_advice $order_effects i.voting*v_producer_reputation i.voting*v_safety
est store m_6
test _IvotXv_pro_1 _IvotXv_pro_2 _IvotXv_pro_3 _IvotXv_pro_4 _IvotXv_pro_7 _IvotXv_pro_8 _IvotXv_pro_9 _IvotXv_saf_1 _IvotXv_saf_2 _IvotXv_saf_3 _IvotXv_saf_4 _IvotXv_saf_7 _IvotXv_saf_8 _IvotXv_saf_9

//check for interactions: vaccine persuasive messages set 1 + conspiracy score
global int_consp_manip ""
foreach manipulation in $vaccine_vars {
	local abb=substr("`manipulation'",1,14)
	gen `abb'_conspiracy=`abb'*conspiracy_score	
	global int_consp_manip "$int_consp_manip `abb'_conspiracy" 	
}
dis "$int_consp_manip"
quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $health_advice $order_effects $int_consp_manip
est store m_7
test $int_consp_manip

est table m_1 m_2 m_3 m_4 m_5 m_6 m_7, b(%12.3f) var(20) star(.01 .05 .10) stats(N)
//result:yes/no interactions detected

//ORDER EFFECTS
quietly ologit v_decision $vaccine_vars $order_effects1
est store m_0
quietly ologit v_decision $vaccine_vars $demogr $order_effects1
est store m_1
quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $health_advice $treatments $order_effects1
est store m_2
est table m_2 m_1 m_0, b(%12.3f) var(20) star(.01 .05 .10) stats(N)
//result: order effects detected only in the simplest model
test $order_effects1
kwallis male, by($order_effects1)
kwallis age, by($order_effects1)
kwallis higher_edu, by($order_effects1)
kwallis v_decision, by($order_effects1)

  
//result: no order effects detected

quietly ologit v_decision $vaccine_vars $order_effects2
est store m_0
quietly ologit v_decision $vaccine_vars $demogr $order_effects2
est store m_1
quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $health_advice $treatments $order_effects2
est store m_2
est table m_2 m_1 m_0, b(%12.3f) var(20) star(.01 .05 .10) stats(N)
//result: no order effects detected

 ologit male $order_effects2
test $order_effects2
 ologit age $order_effects2
test $order_effects2
 ologit higher_edu $order_effects2
test $order_effects2
 ologit v_decision $order_effects2
test $order_effects2
//result: order effects detected

/////****END********************************/////////

quietly ologit v_decision $vaccine_vars 
est store m_0
quietly ologit v_decision $vaccine_vars $demogr 
est store m_1
quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $health_advice $treatments
est store m_2

est table m_2 m_1 m_0, b(%12.3f) var(20) star(.01 .05 .10) stats(N)

// FIGURES
tab v_decision, generate(dec)
/////////**********************************************////////////////
/////////**********************************************////////////////
/////////**********************************************////////////////
