set lib_search_path_list [list \
    ../../libs/cln16fcll \
    ../../libs/cln16fcll_lvl \
    ../../libs/cln16fcll_mb \
    ../../libs/cln16fcll_pm \
    ../../libs/CA53_L1_btac1 \
    ../../libs/CA53_L1_btac2 \
    ../../libs/CA53_L1_ddata \
    ../../libs/CA53_L1_dirty \
    ../../libs/CA53_L1_dtag \
    ../../libs/CA53_L1_idata \
    ../../libs/CA53_L1_itag \
    ../../libs/CA53_L1_tag \
    ../../libs/CA53_L1_tlb \
    ../../libs/CA53_L2_data \
    ../../libs/CA53_L2_tag \
    ../../libs/CA53_L2_vict \
]

set lib_list [list \
    tcbn16ffcllbwp20p90ssgnp0p72v125c_ccs.db \
    tcbn16ffcllbwp20p90lvlssgnp0p72v0p72v125c_ccs.db \
    tcbn16ffcllbwp20p90mbssgnp0p72v125c_ccs.db \
    tcbn16ffcllbwp20p90pmssgnp0p72v125c_ccs.db \
    L1_btac1_ssgnp_0p72v_0p72v_125c.db \
    L1_btac1_ssgnp_0p72v_0p72v_125c.db \
    L1_ddirty_ssgnp_0p72v_0p72v_125c.db \
    L1_itag_ssgnp_0p72v_0p72v_125c.db \
    L2_data_ssgnp_0p72v_0p72v_125c.db \
    L1_btac2_ssgnp_0p72v_0p72v_125c.db \
    L1_dtag_ssgnp_0p72v_0p72v_125c.db \
    L1_tag_ssgnp_0p72v_0p72v_125c.db \
    L2_tag_ssgnp_0p72v_0p72v_125c.db \
    L1_ddata_ssgnp_0p72v_0p72v_125c.db \
    L1_idata_ssgnp_0p72v_0p72v_125c.db \
    L1_tlb_ssgnp_0p72v_0p72v_125c.db \
    L2_vict_ssgnp_0p72v_0p72v_125c.db \
]

set_host_options -max_cores 16


#####
# Set search_path
#
# List locations where your standard cell libraries may be located
#
#####
set search_path [list . $search_path $lib_search_path_list]

######
# Set Target Library
#
# Set a default target library for Design Compiler to target when compiling a design
#
######
set target_library $lib_list

######
# Set Link Library
#
# Set a default link library for Design Compiler to target when compiling a design
#
######
set link_library $lib_list

#####
# Read file list
#####

source ../../flist/ca53_fc_flist.tcl

redirect -tee -file ./logs/elaborate.log {elaborate CORTEXA53}
current_design CORTEXA53


# Link Design
link

read_sdc ../../scripts/initial_synthesis/ca53_constraints.sdc
# -----------------------------------------------------------------------------
# Define cycle percentage expressions
# -----------------------------------------------------------------------------

# Temporary variables used during constraint generation e.g. $cycle20, $cycle60
# reduce the i incr value to 1 to create a complete $cycle00 .. $cycle99 range
for {set i 0} {$i < 100} {incr i 5} {
  set cycle[format "%#02d" $i ] [expr 0.01 * ${i} * ${clock_period}]
}

set ports_clock_root [get_ports [all_fanout -flat -clock_tree -level 0]] 
set_input_delay  $cycle50 -clock VCLK -max [remove_from_collection [all_inputs] $ports_clock_root] 
set_output_delay $cycle50 -clock VCLK -max [all_outputs]
 
set_input_delay  0 -clock VCLK -min [remove_from_collection [all_inputs] $ports_clock_root] 
set_output_delay 0 -clock VCLK -min [all_outputs]

# Multicycle DFT
# The number of cycles is determined by test frequency vs. functional frequency
# For example this constraint assumes test is 4 times slower than functional frequency
set_multicycle_path 4 -setup -start -from [get_ports -regexp {DFTSE DFTRAMHOLD DFTRSTDISABLE DFTMCPHOLD DFTRAMBYP DFTSI[0-9]+}]
set_multicycle_path 3 -hold  -start -from [get_ports -regexp {DFTSE DFTRAMHOLD DFTRSTDISABLE DFTMCPHOLD DFTRAMBYP DFTSI[0-9]+}]
set_multicycle_path 4 -setup -end -to 		[get_ports -regexp {DFTSO[0-9]+}]
set_multicycle_path 3 -hold  -end -to 		[get_ports -regexp {DFTSO[0-9]+}]

# Multicycle scan I/O on cpu's
set_multicycle_path 4 -setup -end -through [get_pins -regexp {g_ca53_cpu[\[_]{1}[0-3]+[\]._]{2}u_ca53_cpu/DFTS[IO]+[0-9]+$}]
set_multicycle_path 3 -hold  -end -through [get_pins -regexp {g_ca53_cpu[\[_]{1}[0-3]+[\]._]{2}u_ca53_cpu/DFTS[IO]+[0-9]+$}]
# Implementation specific internal multicycle paths - SCU RAMs
set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53scu_l1d_tagrams*/SO[*]"]
set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53scu_l1d_tagrams*/SO[*]"]
set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53scu_l1d_tagrams*/SI[*]"]
set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53scu_l1d_tagrams*/SI[*]"]

# Implementation specific internal multicycle scan paths - L2 RAMs
set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_tagrams*/SO[*]"]
set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_tagrams*/SO[*]"]
set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_tagrams*/SI[*]"]
set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_tagrams*/SI[*]"]

# Implementation specific internal multicycle scan paths - L2 RAMs
set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_datarams*/SO[*]"]
set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_datarams*/SO[*]"]
set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_datarams*/SI[*]"]
set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_datarams*/SI[*]"]

# Implementation specific internal multicycle scan paths - CPU RAMs
set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_caches_tlb_rams*/SO[*]"]
set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_caches_tlb_rams*/SO[*]"]
set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_caches_tlb_rams*/SI[*]"]
set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_caches_tlb_rams*/SI[*]"]

  
# -----------------------------------------------------------------------------
# Multicycle L2 data ram clocks
# -----------------------------------------------------------------------------
# These multicycle values need to be consistent with RTL configuration.
# These example settings assume 1 cycle write, 2 cycle read.
# Any updates to these values need to be accompanied by RTL reconfiguration.

set_multicycle_path 2 -setup -end -from [get_pins -quiet -hierarchical -filter "full_name =~ *u_l2_dataram_*_high/CLK"] -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_l2_dataram_*_high/Q[*]"]
set_multicycle_path 1 -hold  -end -from [get_pins -quiet -hierarchical -filter "full_name =~ *u_l2_dataram_*_high/CLK"] -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_l2_dataram_*_high/Q[*]"]

set_multicycle_path 2 -setup -end -from [get_pins -quiet -hierarchical -filter "full_name =~ *u_l2_dataram_*_low/CLK"] -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_l2_dataram_*_low/Q[*]"]
set_multicycle_path 1 -hold  -end -from [get_pins -quiet -hierarchical -filter "full_name =~ *u_l2_dataram_*_low/CLK"] -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_l2_dataram_*_low/Q[*]"]


create_power_domain top

set_voltage -object_list {top.primary.power} 0.72
set_voltage -object_list {top.primary.ground} 0.00

set_operating_conditions -library tcbn16ffcllbwp20p90ssgnp0p72v125c_ccs ssgnp0p72v125c


compile_ultra 

change_names -rules verilog -hierarchy
write -hierarchy -format verilog -output $env(SOCLABS_PROJECT_DIR)/imp/ASIC/megasoc/netlist/ca53_netlist.v
write -hierarchy -format verilog -pg -output $env(SOCLABS_PROJECT_DIR)/imp/ASIC/megasoc/netlist/ca53_netlist.vp

redirect -tee -file ./reports/area.rep {report_area}
redirect -tee -file ./reports/timing.rep {report_timing}
redirect -tee -file ./reports/power.rep {report_power}