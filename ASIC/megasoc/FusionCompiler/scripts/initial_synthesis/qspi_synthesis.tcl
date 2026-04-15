set lib_search_path_list [list \
    ../../libs/cln16fcll \
    ../../libs/cln16fcll_lvl \
    ../../libs/cln16fcll_mb \
    ../../libs/cln16fcll_pm \
    ../../libs/flash_cache_data \
    ../../libs/flash_cache_tag \
]

set lib_list [list \
    tcbn16ffcllbwp20p90ssgnp0p72v125c_ccs.db \
    tcbn16ffcllbwp20p90lvlssgnp0p72v0p72v125c_ccs.db \
    tcbn16ffcllbwp20p90mbssgnp0p72v125c_ccs.db \
    tcbn16ffcllbwp20p90pmssgnp0p72v125c_ccs.db \
    flash_cache_data_ssgnp_0p72v_0p72v_125c.db \
    flash_cache_tag_ssgnp_0p72v_0p72v_125c.db \
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

source ../../flist/qspi_fc_flist.tcl

redirect -tee -file ./logs/elaborate.log {elaborate top_ahb_qspi}
current_design top_ahb_qspi


# Link Design
link

read_sdc ../../scripts/initial_synthesis/qspi_constraints.sdc

create_power_domain top

set_voltage -object_list {top.primary.power} 0.72
set_voltage -object_list {top.primary.ground} 0.00

set_operating_conditions -library tcbn16ffcllbwp20p90ssgnp0p72v125c_ccs ssgnp0p72v125c


compile_ultra 

change_names -rules verilog -hierarchy
write -hierarchy -format verilog -output $env(SOCLABS_PROJECT_DIR)/imp/ASIC/megasoc/netlist/qspi_netlist.v
write -hierarchy -format verilog -pg -output $env(SOCLABS_PROJECT_DIR)/imp/ASIC/megasoc/netlist/qspi_netlist.vp

redirect -tee -file ./reports/area.rep {report_area}
redirect -tee -file ./reports/timing.rep {report_timing}
redirect -tee -file ./reports/power.rep {report_power}