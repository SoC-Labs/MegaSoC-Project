remove_modes -all
remove_corners -all
remove_scenarios -all

set TLU_cbest_CCbest    $TLU_dir/cbest_CCbest.tluplus
set TLU_cbest_CCbest_T  $TLU_dir/cbest_CCbest_T.tluplus
set TLU_cbest           $TLU_dir/cbest.tluplus
set TLU_cworst_CCworst  $TLU_dir/cworst_CCworst.tluplus
set TLU_cworst_CCworst_T $TLU_dir/cworst_CCworst_T.tluplus
set TLU_cworst          $TLU_dir/cworst.tluplus
set TLU_rcbest_CCbest   $TLU_dir/rcbest_CCbest.tluplus
set TLU_rcbest_CCbest_T $TLU_dir/rcbest_CCbest_T.tluplus
set TLU_rcbest          $TLU_dir/rcbest.tluplus
set TLU_rcworst_CCworst $TLU_dir/rcworst_CCworst.tluplus
set TLU_rcworst_CCworst_T $TLU_dir/rcworst_CCworst_T.tluplus
set TLU_rcworst         $TLU_dir/rcworst.tluplus
set TLU_typical_CCbest  $TLU_dir/typical_CCbest.tluplus
set TLU_typical_CCworst $TLU_dir/typical_CCworst.tluplus
set TLU_typical         $TLU_dir/typical.tluplus
set TLU_map $TLU_dir/tluplus.map

read_parasitic_tech -name cbest_CCbest      -tlup $TLU_cbest_CCbest     -layermap $TLU_map
read_parasitic_tech -name cbest_CCbest_T    -tlup $TLU_cbest_CCbest_T   -layermap $TLU_map
read_parasitic_tech -name cbest             -tlup $TLU_cbest            -layermap $TLU_map
read_parasitic_tech -name cworst_CCworst    -tlup $TLU_cworst_CCworst   -layermap $TLU_map
read_parasitic_tech -name cworst_CCworst_T  -tlup $TLU_cworst_CCworst_T -layermap $TLU_map
read_parasitic_tech -name cworst            -tlup $TLU_cworst           -layermap $TLU_map
read_parasitic_tech -name rcbest_CCbest     -tlup $TLU_rcbest_CCbest    -layermap $TLU_map
read_parasitic_tech -name rcbest_CCbest_T   -tlup $TLU_rcbest_CCbest_T  -layermap $TLU_map
read_parasitic_tech -name rcbest            -tlup $TLU_rcbest           -layermap $TLU_map
read_parasitic_tech -name rcworst_CCworst   -tlup $TLU_rcworst_CCworst  -layermap $TLU_map
read_parasitic_tech -name rcworst_CCworst_T -tlup $TLU_rcworst_CCworst_T -layermap $TLU_map
read_parasitic_tech -name rcworst           -tlup $TLU_rcworst          -layermap $TLU_map
read_parasitic_tech -name typical_CCbest    -tlup $TLU_typical_CCbest   -layermap $TLU_map
read_parasitic_tech -name typical_CCworst   -tlup $TLU_typical_CCworst  -layermap $TLU_map
read_parasitic_tech -name typical           -tlup $TLU_typical          -layermap $TLU_map

set_technology -node 16

## Setup Scenarios as below
create_corner ffgnp_0p88
create_corner ssgnp_0p72
create_corner tt_0p80
create_corner tt_0p72
create_corner ffg_0p80

create_mode hold
create_mode setup
create_mode max_tran
create_mode typ_power
create_mode max_IR
create_mode em

create_scenario -name hold_ffgnp -mode hold -corner ffgnp_0p88
create_scenario -name hold_ssgnp -mode hold -corner ssgnp_0p72
create_scenario -name setup_ssgnp -mode setup -corner ssgnp_0p72
create_scenario -name setup_tt -mode setup -corner tt_0p72
create_scenario -name max_tran_ssgnp -mode max_tran -corner ssgnp_0p72
create_scenario -name typ_power_tt -mode typ_power -corner tt_0p80
create_scenario -name max_IR_ffg -mode max_IR -corner ffg_0p80
create_scenario -name em_ffg -mode em -corner ffg_0p80

set_scenario_status setup_ssgnp    -none -setup true  -hold false -leakage_power true -dynamic_power true  -max_transition true -max_capacitance true  -min_capacitance false -active true
set_scenario_status setup_tt       -none -setup true  -hold false -leakage_power true -dynamic_power true  -max_transition true -max_capacitance true  -min_capacitance false -active true 
set_scenario_status hold_ffgnp     -none -setup false -hold true  -leakage_power true -dynamic_power false -max_transition true -max_capacitance false -min_capacitance true  -active true
set_scenario_status hold_ssgnp     -none -setup false -hold true  -leakage_power true -dynamic_power false -max_transition true -max_capacitance false -min_capacitance true  -active true

set_scenario_status max_tran_ssgnp -none -setup false -hold false -leakage_power true -dynamic_power false -max_transition true -max_capacitance false -min_capacitance true  -cell_em false -signal_em false -active true
set_scenario_status typ_power_tt   -none -setup false -hold false -leakage_power true -dynamic_power false -max_transition true -max_capacitance false -min_capacitance true  -cell_em false -signal_em false -active true
set_scenario_status max_IR_ffg     -none -setup false -hold false -leakage_power true -dynamic_power true  -max_transition true -max_capacitance false -min_capacitance true  -cell_em false -signal_em false -active true
set_scenario_status em_ffg         -none -setup false -hold false -leakage_power true -dynamic_power false -max_transition true -max_capacitance false -min_capacitance true  -cell_em true  -signal_em true  -active true

# ---------------------------------------------------------------
# Purporse      Hold            Hold            Setup               Setup               Max Transition      Typical Power   Max IR Drop     Signal EM
# Process       FFGNP           SSGNP           SSGNP               TT                  SSGNP               TT              FFG             FFG
# Voltage       0.88V           0.72V           0.72V               0.72V               0.72V               0.8V            0.8V            0.8V
# Temperature   -40 & 125C      -40 & 125C      -40C                85C                 -40                 85C             125C            125C
# Parasitics    Cworst_Ccworst  Cworst_Ccworst  Cworst_Ccworst_T    Cworst_Ccworst_T    Cworst_Ccworst_T    typical         typical         Cworst_Ccworst_T
#               Cbest_Ccbest    Rcworst_Ccworst Rcworst_Ccworst_T   Rcworst_Ccworst_T   Rcworst_Ccworst_T
#               Rcworst_Ccworst 
#               Rcbest_Ccbest
# Max clk trans 87      96      90      101     90
# V Derate      9.1     8.5     8.6     6.5     8.6
# max dyn V drp 0.123           0.05            0.05
# W derate      (r)cworst,-10%  early,-10%      +/-7%               +/-7%     
#               (r)cbest, +10%
# W Uncertainty 3ps             3ps             5ps                 5ps
# Log Uncertain 4ps             10ps            0ps                 0ps
# Jitter        0               0               Consult PLL Spec    Consult PLL Spec

current_scenario hold_ffgnp
current_corner ffgnp_0p88
set_parasitic_parameters -early_spec rcbest_CCbest -early_temperature 125 -late_spec rcworst_CCworst -late_temperature -40 -library cortexa53.dlib
set_voltage 0.88 -corners ffgnp_0p88
read_sdc ../inputs/constraints_hold_ffgnp.sdc

current_scenario hold_ssgnp
current_corner ssgnp_0p72
set_parasitic_parameters -early_spec cworst_CCworst -early_temperature 125 -late_spec rcworst_CCworst -late_temperature -40 -library cortexa53.dlib
set_voltage 0.72 -corners ssgnp_0p72
read_sdc ../inputs/constraints_hold_ssgnp.sdc 

current_scenario setup_ssgnp
current_corner ssgnp_0p72
set_parasitic_parameters -early_spec cworst_CCworst_T -early_temperature -40 -late_spec rcworst_CCworst_T -late_temperature -40 -library cortexa53.dlib
set_voltage 0.72 -corners ssgnp_0p72
read_sdc ../inputs/constraints_setup_ssgnp.sdc

current_scenario setup_tt
current_corner tt_0p72
set_parasitic_parameters -early_spec cworst_CCworst_T -early_temperature 0 -late_spec rcworst_CCworst_T -late_temperature 0 -library cortexa53.dlib
set_voltage 0.72 -corners tt_0p72
read_sdc ../inputs/constraints_setup_tt.sdc

current_scenario max_tran_ssgnp
current_corner ssgnp_0p72
set_parasitic_parameters -early_spec cworst_CCworst_T -early_temperature -40 -late_spec rcworst_CCworst_T -late_temperature -40 -library cortexa53.dlib
set_voltage 0.72 -corners ssgnp_0p72
read_sdc ../inputs/constraints_setup_ssgnp.sdc

current_scenario typ_power_tt
current_corner tt_0p80
set_parasitic_parameters -early_spec typical -early_temperature 85 -late_spec typical -late_temperature 85 -library cortexa53.dlib
set_voltage 0.80 -corners tt_0p80
read_sdc ../inputs/constraints_setup_tt.sdc

current_scenario max_IR_ffg
current_corner ffg_0p80
set_parasitic_parameters -early_spec typical -early_temperature 125 -late_spec typical -late_temperature 125 -library cortexa53.dlib
set_voltage 0.80 -corners ffg_0p80
read_sdc ../inputs/constraints_ffg.sdc

current_scenario em_ffg
current_corner ffg_0p80
set_parasitic_parameters -early_spec cworst_CCworst_T -early_temperature 125 -late_spec cworst_CCworst_T -late_temperature 125 -library cortexa53.dlib
set_voltage 0.80 -corners ffg_0p80
read_sdc ../inputs/constraints_ffg.sdc


# Set Supply voltages
 
set_voltage -corners ffgnp_0p88 -object_list [get_supply_nets VDD] 0.88 
set_voltage -corners ffgnp_0p88 -object_list [get_supply_nets VSS] 0.0 

set_voltage -corners ssgnp_0p72 -object_list [get_supply_nets VDD] 0.72
set_voltage -corners ssgnp_0p72 -object_list [get_supply_nets VSS] 0.0

set_voltage -corners tt_0p80 -object_list [get_supply_nets VDD] 0.80
set_voltage -corners tt_0p80 -object_list [get_supply_nets VSS] 0.0

set_voltage -corners tt_0p72 -object_list [get_supply_nets VDD] 0.72 
set_voltage -corners tt_0p72 -object_list [get_supply_nets VSS] 0.0 

set_voltage -corners ffg_0p80 -object_list [get_supply_nets VDD] 0.80 
set_voltage -corners ffg_0p80 -object_list [get_supply_nets VSS] 0.0