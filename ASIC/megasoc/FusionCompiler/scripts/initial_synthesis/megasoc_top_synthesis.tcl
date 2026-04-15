set lib_search_path_list [list \
    ../../libs/cln16fcll \
    ../../libs/cln16fcll_lvl \
    ../../libs/cln16fcll_mb \
    ../../libs/cln16fcll_pm \
    ../../libs/io_lib \
    ../../libs/megasoc_bootrom \
    ../../libs/megasoc_sram \
]

set lib_list [list \
    tcbn16ffcllbwp20p90ssgnp0p72v125c_ccs.db \
    tcbn16ffcllbwp20p90lvlssgnp0p72v0p72v125c_ccs.db \
    tcbn16ffcllbwp20p90mbssgnp0p72v125c_ccs.db \
    tcbn16ffcllbwp20p90pmssgnp0p72v125c_ccs.db \
    tphn16ffcllgv18e_univssgnp0p72v1p62v125c.db \
    bootrom_ssgnp_0p72v_0p72v_125c.db \
    sram_64b_16k_ssgnp_0p72v_0p72v_125c.db \
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

source ../../flist/megasoc_fc_flist_partial.tcl
analyze -format verilog $env(SOCLABS_PROJECT_DIR)/megasoc_chip/pads/cln16fcll/logical/megasoc_chip_pads.v

redirect -tee -file ./logs/elaborate.log {elaborate megasoc_chip_pads}
current_design megasoc_chip_pads


# Link Design
link

read_sdc ../../scripts/initial_synthesis/megasoc_chip_pads_constraints.sdc

create_power_domain top

set_voltage -object_list {top.primary.power} 0.72
set_voltage -object_list {top.primary.ground} 0.00

set_operating_conditions -library tcbn16ffcllbwp20p90ssgnp0p72v125c_ccs ssgnp0p72v125c


compile_ultra 

change_names -rules verilog -hierarchy
write -hierarchy -format verilog -output $env(SOCLABS_PROJECT_DIR)/imp/ASIC/megasoc/netlist/megasoc_chip_pads_netlist.v
write -hierarchy -format verilog -pg -output $env(SOCLABS_PROJECT_DIR)/imp/ASIC/megasoc/netlist/megasoc_chip_pads_netlist.vp

redirect -tee -file ./reports/area.rep {report_area}
redirect -tee -file ./reports/timing.rep {report_timing}
redirect -tee -file ./reports/power.rep {report_power}