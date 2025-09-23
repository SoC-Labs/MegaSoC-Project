## Paths Please Edit for your system
set cln16fcll_tech_path         /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/arm_tech/r3p0
set tech_file         $cln16fcll_tech_path/ndm/9m_2xa1xd3xe2z_utrdl/sc9mcpp96c_tech.tf

set REPORT_DIR ../reports
set LOG_DIR ../logs
set OUT_DIR ../outputs

# megaSoC Specifics - don't edit
set file_tcl_list $env(SOCLABS_PROJECT_DIR)/imp/ASIC/CA53/flist/ca53_fc_flist.tcl
set top_level_verilog $env(SOCLABS_PROJECT_DIR)/megasoc_tech/logical/CortexA53_1/verilog/CORTEXA53.v

# Variables used in scripts
set lib_name cortexa53
set block_name CORTEXA53

set lib_path_list [list ../libs/cln16fcll ../libs/arm_pmk_lib ../libs/arm_hpk_lib ../libs/arm_ret_lib ../libs/CA53_L1_btac2 ../libs/CA53_L1_btac1 ../libs/CA53_L1_tlb ../libs/CA53_L1_dirty ../libs/CA53_L1_dtag ../libs/CA53_L1_ddata ../libs/CA53_L1_itag ../libs/CA53_L1_idata ../libs/CA53_L1_tag ../libs/CA53_L2_tag ../libs/CA53_L2_data ../libs/CA53_L2_vict ]
set lib_list {cln16fcll arm_pmk_lib arm_ret_lib arm_hpk_lib CA53_L1_btac2 CA53_L1_btac1 CA53_L1_tlb CA53_L1_dirty CA53_L1_dtag CA53_L1_ddata CA53_L1_itag CA53_L1_idata CA53_L1_tag CA53_L2_tag CA53_L2_data CA53_L2_vict  } 

set typical_scenario typ_power_tt