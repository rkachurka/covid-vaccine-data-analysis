
clear all
// install package to import spss file
// net from http://radyakin.org/transfer/usespss/beta
//usespss "data.sav"
//saveold "G:\Shared drives\Koronawirus\studies\5 data analysis (Ariadna data)\data_stata_format.dta", version(13)
use data_stata_format.dta, clear

// ideas for the new wave:
// allow loss seeking: 27% is willing to take a +5000 -5000 50/50 gamble
// idea: to compare distrubution of answers for 2 versions of Ariadna data

capture cd "G:\Shared drives\Koronawirus\studies\5 data analysis (Ariadna data)"
capture cd "G:\Dyski współdzielone\Koronawirus\studies\5 data analysis (Ariadna data)"

do universal_data_cleaning.do




//VACCINE PART DATA CLEANING
rename (p37_1_r1	p37_1_r2	p37_1_r3	p37_1_r4	p37_1_r5	p37_1_r6	p37_1_r7	p37_8_r1	p37_8_r2	p37_8_r3	p37_8_r4	p37) (v_producer_reputation	v_efficiency	v_safety	v_scarcity	v_other_want_it	v_scientific_authority	v_ease_personal_restrictions	v_p_pay0	v_p_gets70	v_p_pays10	v_p_pays70	v_decision) 
global vaccine_vars "v_producer_reputation	v_efficiency	v_safety		v_other_want_it	v_scientific_authority	v_ease_personal_restrictions	v_p_gets70	v_p_pays10	v_p_pays70" // i leave out scarcity -- sth that supposedly everybody knows. we can't estimate all because of ariadna's error anyway
global vaccine_short "v_producer_reputation	v_efficiency	v_safety	v_scarcity	v_other_want_it	v_scientific_authority	v_ease_personal_restrictions"
global prices "v_p_gets70	v_p_pays10	v_p_pays70"

egen check_vs=rowmean($vaccine_short)
sum check_vs

//info in wrong columns, pls check for more such cases!
//what about mean? which wrong columns?
//replace v_decision=P390 if v_decision==""
//RK: pls elaborate on above in details, I dont undesrtand these lines. I double checked, all is fine with columns

global uwagi "p1_uwagi p2_uwagi p5_uwagi p6_uwagi p9_uwagi p10_uwagi p13_uwagi p14_uwagi"

foreach uw in $uwagi {
list `uw' if `uw'!=""
}


//DEMOGRAPHICS DATA CLEANING
//wojewodstwo is ommited, because of no theoretical reason to include it
gen male=sex==2

rename (age year) (age_category age)
rename (miasta wyksztalcenie) (city_population edu)

capture drop elementary_edu
gen elementary_edu=edu==1|edu==2
gen secondary_edu=edu==3|edu==4
gen higher_edu=edu==5|edu==6|edu==7

rename m8 income
gen wealth_low=income==1|income==2
gen wealth_high=income==4|income==5
global wealth "wealth_low wealth_high"

global price_wealth ""
foreach price in $prices {
	foreach level in $wealth {
	gen wp_`price'_`level'=`price'*`level'
	global price_wealth "$price_wealth wp_`price'_`level'" 	
}
}
dis "$price_wealth"


rename m9 health_state

gen health_poor=health_state==1|health_state==2
gen health_good=health_state==4|health_state==5

gen had_covid=(5-p31)

gen covid_friends=p33==1
gen covid_friends_hospital=p34==1

gen no_covid_friends=covid_friends==0
gen covid_friends_nohospital=covid_friends==1&covid_friends_hospital==0

//to create 3 variables know+hospitalizaed, not hospitalized and etc


gen religious=m10==2|m10==3
gen religious_often=m11==4|m11==5|m11==6 //often = more than once a month
rename m11 religious_freq


//use it later during the robustness check, when results will be ready

gen status_unemployed=m12==5
gen status_pension=m12==6
gen status_student=m12==7

global demogr "male age i.city_population secondary_edu higher_edu $wealth health_poor health_good had_covid  covid_friends religious i.religious_freq status_unemployed status_pension status_student"
global demogr_int "male age higher_edu"
global health_advice "p26 p30_r1"
//********************************************//
//OTHER DATA CLEANING
rename warunek treatment //1.COVID 2.Cold, 3.Unemployment
gen t_covid=treatment==1
gen t_cold=treatment==2
gen t_unempl=treatment==3
global treatments "t_cold t_unempl"
global order_effects "i.treatment"
label define treats 1 "COVID" 2 "Cold" 3 "Unemployment"
label values treatment treats
//to add later into puzzles regression
rename kolejnosc_pytan order_puzzles
replace order_puzzles=subinstr(order_puzzles,"p","",.)
split order_puzzles, p("-")
global order_puzzles "order_puzzles1 order_puzzles2 order_puzzles3 order_puzzles4 order_puzzles5 order_puzzles6 order_puzzles7 order_puzzles8"
foreach x in $order_puzzles {
destring `x', replace
}

//EMOTIONS

ren (p17_r1 p17_r2 p17_r3 p17_r4 p17_r5 p17_r6) (e_happiness e_fear e_anger e_disgust e_sadness e_surprise)
global emotions "e_happiness e_fear e_anger e_disgust e_sadness e_surprise"

//RISK ATTITUDES
ren (p18_r1 p19_r1 p19_r2) (risk_overall risk_work risk_health)
global risk "risk_overall risk_work risk_health"

//WORRY
ren (p20_r1 p20_r2 p20_r3) (worry_covid worry_cold worry_unempl)
global worry "worry_covid worry_cold worry_unempl"

//SUBJECTIVE CONTROL
rename (p22_r1 p22_r2 p22_r3) (control_covid control_cold control_unempl)
global control "control_covid control_cold control_unempl"

//INFORMED ABOUT:
rename (p23_r1 p23_r2 p23_r3) (inf_covid inf_cold inf_unempl)
global informed "inf_covid inf_cold inf_unempl"

//CONSPIRACY
rename (p30cd_r1 p30cd_r2 p30cd_r3) (conspiracy_general_info conspiracy_stats conspiracy_excuse)
global conspiracy "conspiracy_general_info conspiracy_stats conspiracy_excuse"
egen conspiracy_score=rowmean($conspiracy)
//lets do general conspiracy score?

//VOTING
rename m20 voting

replace voting=0 if voting==.a
replace voting=8 if voting==5|voting==6

global voting "i.voting"

//covid impact estimations
rename (p24 p25) (cases death)
replace cases=. if death>cases*100
gen ln_cases=ln(cases+1)
replace ln_cases=0 if ln_cases==.
gen ln_death=ln(death+1)
replace ln_death=0 if ln_death==.

global covid_impact "ln_cases ln_death"

//pls add comments in the code, especially such code:
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

//
global interactions ""
foreach manipulation in $vaccine_vars {
	foreach demogr in $demogr_int {
	local abb=substr("`manipulation'",1,14)
	gen i_`abb'_`demogr'=`abb'*`demogr'	
	global interactions "$interactions i_`abb'_`demogr'" 	
}
}
dis "$interactions"

global int_consp_manip ""
foreach manipulation in $vaccine_vars {
	local abb=substr("`manipulation'",1,14)
	gen `abb'_conspiracy=`abb'*conspiracy_score	
	global int_consp_manip "$int_consp_manip `abb'_conspiracy" 	
}
dis "$int_consp_manip"

//gen int_voting_prod=voting*v_producer_reputation

//gen int_voting_safety=voting*v_safety

quietly ologit v_decision $vaccine_vars $demogr 
est store m_1
quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting  $control $informed conspiracy_score $covid_impact $order_effects
est store m_2
test $vaccine_vars

quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $order_effects $interactions
est store m_3
test $interactions
quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $order_effects $int_manips
est store m_4
test $int_manips
quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $order_effects $price_wealth
est store m_5
test $price_wealth
quietly xi:ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $order_effects i.voting*v_producer_reputation i.voting*v_safety
est store m_6
test _IvotXv_pro_1 _IvotXv_pro_2 _IvotXv_pro_3 _IvotXv_pro_4 _IvotXv_pro_7 _IvotXv_pro_8 _IvotXv_pro_9 _IvotXv_saf_1 _IvotXv_saf_2 _IvotXv_saf_3 _IvotXv_saf_4 _IvotXv_saf_7 _IvotXv_saf_8 _IvotXv_saf_9
quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $order_effects $int_consp_manip
est store m_7
test $int_consp_manip

est table m_1 m_2 m_3 m_4 m_5 m_6 m_7, b(%12.3f) var(20) star(.01 .05 .10) stats(N)
//no interactions detected

quietly ologit v_decision $vaccine_vars 
est store m_0
quietly ologit v_decision $vaccine_vars $demogr 
est store m_1
quietly ologit v_decision $vaccine_vars $demogr $emotions $risk $worry $voting $control $informed conspiracy_score $covid_impact $treatments
est store m_2

est table m_0 m_1 m_2, b(%12.3f) var(20) star(.01 .05 .10) stats(N)
// XXX or m_2 m_1 m_0? easier to see which line is which? 

// FIGURES
tab v_decision, generate(dec)
/////////**********************************************////////////////
/////////**********************************************////////////////
/////////**********************************************////////////////
//PUZZLES DATA CLEANING
// [P1] Przypuśćmy, że 15% obywateli Polski jest zakażonych koronawirusem, a 85% jest zdrowych. Test mający wykryć koronawirusa na wczesnym etapie ma skuteczność 80%, tzn., gdy zbada się osobę faktycznie zakażoną, to jest 80% szans na to, że test wykaże, że jest zakażona, a 20% że zdrowa. Gdy zbada się osobę faktycznie zdrową, jest 80% szans, że test wykaże, że jest zdrowa, a 20% że zakażona.
gen base_rate_negl_normative=p1>=19& p1<=51 // much more lenient than initially
tab base_rate_negl_normative
 
tab p1_uwagi
/* p2 is about 10 000 confirmed cases, p13 is about 10 confirmed cases
p2 Załóżmy, że przebadano losową próbę Polaków i okazało się, że wśród badanych było 10 000 osób aktualnie zakażonych koronawirusem. Stanowi to 1% badanej próby.
Czy ta informacja sprawiłaby, że był(a)byś mniej czy bardziej zaniepokojony pandemią niż jesteś obecnie? 
[rotacja]
bardziej zaniepokojona(-y)
mniej zaniepokojona(-y)

gen beliefs_update_normative=...?
*/
capture drop beliefs_update_normative
gen beliefs_update_normative=0
replace beliefs_update_normative=1 if p2==2 & p13==2 //current rate of infection is 3-4% so 1% should make us less worried
tab beliefs_update_normative
tab p2_uwagi
tab p13_uwagi
/*
Władze pewnego miasta przygotowują się do konfrontacji z nową falą pandemii. Można się spodziewać, że zabije ona ok. 600 mieszkańców. Rozważane są dwa programy prewencyjne. Epidemiolodzy szacują, że ich skutki dla tych statystycznych 600 osób będą następujące:
Program A: 200 osób zostanie uratowanych
Program B: z prawdopodobieństwem 1/3 zostanie uratowanych 600 osób, z prawdopodobieństwem 2/3 nikt nie zostanie uratowany
Który program powinno się wdrożyć? Zaznacz
[rotacja]
Program A
Program B
-----------------------------------
[P5 - opcja 2] Władze pewnego miasta przygotowują się do konfrontacji z nową falą pandemii. Można się spodziewać, że zabije ona ok. 600 mieszkańców. Rozważane są dwa programy prewencyjne. Epidemiolodzy szacują, że ich skutki dla tych statystycznych 600 osób będą następujące:
Program A: 400 osób umrze
Program B: z prawdopodobieństwem 1/3 nikt nie umrze, z prawdopodobieństwem 2/3 umrą wszyscy
Który program powinno się wdrożyć? Zaznacz
[rotacja]
Program A
Program B
*/
rename  p5_losowanie asian_disease_option
gen asian_disease_pos_framing=asian_disease_option==1
gen asian_disease_neg_framing=asian_disease_option==2
gen asian_disease_sure_option=p5==1
gen asian_disease_unsure_option=p5==2
tab asian_disease_pos_framing asian_disease_sure_option
ttest asian_disease_sure_option, by(asian_disease_pos_framing)

//Śmiertelność wśród pacjentów z koronawirusem zależy od ich wieku. Załóżmy, że oszacowane prawdopodobieństwo śmierci w ciągu miesiąca od zakażenia dla mężczyzn w poszczególnych grupach wiekowych kształtuje się następująco:
//Jan ma 61 lat. Jak myślisz, jakie jest prawdopodobieństwo, że Jan umrze w ciągu miesiąca od zakażenia? 
gen death_prob_normative=p6<1.9&p6>0.5
tab p6_uwagi

//[P9] W skali kraju można się spodziewać jeszcze około 20 000 śmiertelnych ofiar koronawirusa. Zaproponowano zmianę procedury postępowania z chorymi w szpitalach zakaźnych. Zmiana może okazać się dobra lub zła. 
//Spodziewane skutki i ich prawdopodobieństwa przedstawiono w tabeli. Dla każdego z wierszy wskaż, czy w danej sytuacji uważasz, że taka zmiana powinna zostać wprowadzona czy też nie. 
capture drop p9_consistent_answer
gen p9_consistent_answer=0
replace p9_consistent_answer=1 if p9_h1_r1==1 & p9_h1_r2==1 & p9_h1_r3==1 & p9_h1_r4==1 & p9_h1_r5==1 & p9_h1_r6==1
replace p9_consistent_answer=1 if p9_h1_r1==1 & p9_h1_r2==1 & p9_h1_r3==1 & p9_h1_r4==1 & p9_h1_r5==1 & p9_h1_r6==2
replace p9_consistent_answer=1 if p9_h1_r1==1 & p9_h1_r2==1 & p9_h1_r3==1 & p9_h1_r4==1 & p9_h1_r5==2 & p9_h1_r6==2
replace p9_consistent_answer=1 if p9_h1_r1==1 & p9_h1_r2==1 & p9_h1_r3==1 & p9_h1_r4==2 & p9_h1_r5==2 & p9_h1_r6==2
replace p9_consistent_answer=1 if p9_h1_r1==1 & p9_h1_r2==1 & p9_h1_r3==2 & p9_h1_r4==2 & p9_h1_r5==2 & p9_h1_r6==2
replace p9_consistent_answer=1 if p9_h1_r1==1 & p9_h1_r2==2 & p9_h1_r3==2 & p9_h1_r4==2 & p9_h1_r5==2 & p9_h1_r6==2
replace p9_consistent_answer=1 if p9_h1_r1==2 & p9_h1_r2==2 & p9_h1_r3==2 & p9_h1_r4==2 & p9_h1_r5==2 & p9_h1_r6==2
replace p9_consistent_answer=1 if p9_h1_r1==2 & p9_h1_r2==2 & p9_h1_r3==2 & p9_h1_r4==2 & p9_h1_r5==2 & p9_h1_r6==1 // how is this consistent if you switch from no to yes? it makes no sense
replace p9_consistent_answer=1 if p9_h1_r1==2 & p9_h1_r2==2 & p9_h1_r3==2 & p9_h1_r4==2 & p9_h1_r5==1 & p9_h1_r6==1
replace p9_consistent_answer=1 if p9_h1_r1==2 & p9_h1_r2==2 & p9_h1_r3==2 & p9_h1_r4==1 & p9_h1_r5==1 & p9_h1_r6==1
replace p9_consistent_answer=1 if p9_h1_r1==2 & p9_h1_r2==2 & p9_h1_r3==1 & p9_h1_r4==1 & p9_h1_r5==1 & p9_h1_r6==1
replace p9_consistent_answer=1 if p9_h1_r1==2 & p9_h1_r2==1 & p9_h1_r3==1 & p9_h1_r4==1 & p9_h1_r5==1 & p9_h1_r6==1
tab p9_consistent_answer
gen p9_do_nothing=p9_h1_r1==2 & p9_h1_r2==2 & p9_h1_r3==2 & p9_h1_r4==2 & p9_h1_r5==2 & p9_h1_r6==2
tab p9_do_nothing

egen loss_aversion=rsum(p9_h1_r*)
replace loss_aversion=((loss_aversion-6)*1000+4500)/5000 
//how to title this var?
gen p9_normative=0
replace p9_normative=1 if p9_h1_r1==1 & p9_consistent_answer==1
replace p9_normative=1 if p9_h1_r1==2 & p9_h1_r2==1 & p9_h1_r3==1 & p9_h1_r4==1 & p9_h1_r5==1 & p9_h1_r6==1
tab p9_normative

//[P11] Załóżmy, że jesteś teraz zdrowy/a- nie masz koronawirusa. Spotykasz 100 osób. Przy każdym spotkaniu, które rozpoczynasz będąc zdrowy/a, masz 99,5% szans na to, że pozostaniesz zdrowy/a (nie zostaniesz zakażony/a koronawirusem). 
//Jakie jest prawdopodobieństwo, że pozostaniesz zdrowy/a po ostatnim ze 100 spotkań?
gen compound_prob_normative=p10>=60& p10<=66
replace compound_prob_normative=1 if p10>=0.60& p10<=0.66
tab compound_prob_normative
capture drop compound_nonsense
gen compound_nonsense = p10==99.5
sum compound_nonse
gen compound_non_nonsense=1-compound_nonsense
tab p10_uwagi

//[P15] W Braniewie odsetek zakażonych koronawirusem codziennie się podwaja. Po 12 dniach zakażeni są wszyscy. 
//Po ilu dniach zakażona była połowa mieszkańców?
gen lilypad_normative=p14==11
tab lilypad_normative
tab p14_uwagi

//generating performance
sum *_normative
global normative "base_rate_negl_normative death_prob_normative beliefs_update_normative compound_non_nonsense lilypad_normative"
gen performance = 0
foreach x in $normative {
 replace performance=performance+`x' // MK: what is that? why not egen performance=rsum($normative)? also, wouldn't be more informative to look at mean, not sum?
}
sum performance 


foreach x in $normative {
kwallis `x', by(treatment)
 }

 
tabstat $normative loss_ave, statistics( mean ) by(treatment)


//short answer if want to be vaccinated or not
gen v_decision_yes=v_decision==3|v_decision==4

//performance determinants
ologit performance $demogr
est store m_0
ologit performance $demogr $treatments $emotions 
est store m_1
ologit performance $demogr $treatments $emotions v_decision_yes $risk $worry $voting $control $informed conspiracy_score $covid_impact 

est store m_2
est table m_0 m_1 m_2, b(%12.3f) var(20) star(.01 .05 .10) stats(N)
//no order effect of var "order_puzzles1"

//fear determinants
ologit e_fear $demogr 
est store m_0
ologit e_fear $demogr $treatments 
est store m_1
ologit e_fear $demogr $health_advice $treatments v_decision_yes $risk $worry $voting $control $informed conspiracy_score $covid_impact
est store m_2
est table m_0 m_1 m_2, b(%12.3f) var(20) star(.01 .05 .10) stats(N)

//several vars to be encoded - e.g. wearing masks

