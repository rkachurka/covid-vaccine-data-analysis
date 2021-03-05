// ideas:
// robustness check: to compare distrubution of answers for Ariadna data
// robustness check: to drop out 5% of the fastest subjects

ssc install tabstatmat
clear all 
capture cd "G:\Shared drives\Koronawirus\studies\5 common data cleaning (Ariadna data)"
capture cd "G:\Dyski współdzielone\Koronawirus\studies\5 common data cleaning (Ariadna data)"
use data_stata_format.dta, clear
do common_data_cleaning.do

capture cd "G:\Shared drives\Koronawirus\studies\3 szczepionka\data analysis"
capture cd "G:\Dyski współdzielone\Koronawirus\studies\3 szczepionka\data analysis"

//[P40] Gdyby po pierwszych miesiącach szczepień potwierdziło się, że szczepionka jest skuteczna i bezpieczna, to byłbyś skłonny się zaszczepić? Zaznacz.
rename p40 decision_change
tab decision_change
//this variable will be included into analysis to see which factors (e.g. emotions) are assotiated with vaccination decision change

//health status details:
rename M9_1 health_vaccine_side_effects
rename M9_2 health_covid_serious
//"smoking categories consisted of “very light” (1–4 CPD), “light” (5–9 CPD), “moderate” (10–19 CPD), and “heavy” (20+ CPD) Rostron, Brian L., et al. "Changes in Cigarettes per Day and Biomarkers of Exposure Among US Adult Smokers in the Population Assessment of Tobacco and Health Study Waves 1 and 2 (2013–2015)." Nicotine and Tobacco Research 22.10 (2020): 1780-1787."
rename M9_3a health_smoking_howmany_cig_perday
//base level, ommited
gen health_smoking_vlight=health_smoking_howmany_cig_perday>0&health_smoking_howmany_cig_perday<5
gen health_smoking_light=health_smoking_howmany_cig_perday>4&health_smoking_howmany_cig_perday<10
gen health_smoking_moderate=health_smoking_howmany_cig_perday>9&health_smoking_howmany_cig_perday<20
gen health_smoking_heavy=health_smoking_howmany_cig_perday>19
global health_details "health_vaccine_side_effects health_covid_serious health_smoking_light health_smoking_moderate health_smoking_heavy"
//above global will be included into global demogr

//open ended question:
// [P38] Opisz poniżej główne powody swojej decyzji odnośnie zaszczepienia się na koronawirusa. 
// [P39] Kto lub co mogłoby zmienić Twoją decyzję odnośnie zaszczepienia się na koronawirusa? Opisz poniżej.
// [optional] [P21] Jakie czynniki mają główny wpływ na to, w jakiej mierze jesteś zaniepokojony/a pandemią koronawirusa? 
//will be classified and set of explanations will be produced.
//every explanation will be assosiated with a dummy variable
//pseudocode:
global explanations "p38_1 p38_2 p39_1 p39_2 p21_1 p21_2"//included into "contol" global

global wealth "wealth_low wealth_high" //included into demogr
global trust "trust_gov, trust_neighbours, trust_doctors, trust_media, trust_family, trust_scientists"//included into demogr
global demogr "male age age2 i.city_population secondary_edu higher_edu $wealth health_poor health_good $health_details had_covid  covid_friends religious i.religious_freq status_unemployed status_pension status_student $trust"
global demogr_int "male age higher_edu"
global treatments "t_cold t_unempl"
global emotions "e_happiness e_fear e_anger e_disgust e_sadness e_surprise"
global risk "risk_overall risk_work risk_health"
global worry "worry_covid worry_cold worry_unempl"
global control "control_covid control_cold control_unempl $explanations"
global informed "informed_covid informed_cold informed_unempl"
global conspiracy "conspiracy_general_info conspiracy_stats conspiracy_excuse" //we also have conspiracy_score
global voting "i.voting"
global health_advice "mask_wearing distancing"
global covid_impact "subj_est_cases_ln subj_est_death_l"
global order_effects ""
global vaccine_vars "v_producer_reputation	v_efficiency	v_safety		v_other_want_it	v_scientific_authority	v_ease_personal_restrictions	v_p_gets70	v_p_pays10	v_p_pays70" // i leave out scarcity -- sth that supposedly everybody knows. we can't estimate all because of ariadna's error anyway
global vaccine_short "v_producer_reputation	v_efficiency	v_safety	v_scarcity	v_other_want_it	v_scientific_authority	v_ease_personal_restrictions"
global prices "v_p_gets70	v_p_pays10	v_p_pays70"


//////////****order effects and interactions check**********/////
quietly ologit v_decision $vaccine_vars $demogr 
est store m_1

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
//result:yes/no order effects detected 
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
