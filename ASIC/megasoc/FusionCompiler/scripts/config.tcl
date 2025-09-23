## Paths Please Edit for your system
set cln16fcll_tech_path         /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/arm_tech/r3p0
set tech_file         $cln16fcll_tech_path/ndm/9m_2xa1xd3xe2z_utrdl/sc9mcpp96c_tech.tf


set REPORT_DIR ../reports
set LOG_DIR ../logs
set OUT_DIR ../outputs

# megaSoC Specifics - don't edit
set file_tcl_list $env(SOCLABS_PROJECT_DIR)/imp/ASIC/megasoc/flist/megasoc_fc_flist.tcl
set top_level_verilog $env(SOCLABS_PROJECT_DIR)/megasoc_chip/pads/cln16fcll/logical/megasoc_chip_pads.v
# Variables used in scripts
set lib_name megasoc_chip_pads
set block_name megasoc_chip_pads

set lib_path_list [list ../libs/cln16fcll/ ../libs/arm_io/ ../libs/arm_pmk_lib/ ../libs/arm_ret_lib/ ../../CA53/work/cortexA53.dlib/  ]
set lib_list {cln16fcll  } 

# Libary files for formality

