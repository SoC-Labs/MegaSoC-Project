## Paths Please Edit for your system
set cln16fcll_tech_path         /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/arm_tech/r3p0
set standard_cell_base_path     /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/sc9mcpp96c_base_svt_c24/r2p0
set pmk_base_path               /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/sc9mcpp96c_pmk_svt_c24/r2p0
set ret_base_path               /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/sc9mcpp96c_rklo_lvt_svt_c20_c24/r1p0

# Technology files
set cln16fcll_tech_file                       $cln16fcll_tech_path/ndm/9m_2xa1xd3xe2z_utrdl/sc9mcpp96c_tech.tf
set cln16fcll_lef_file                        $cln16fcll_tech_path/lef/9m_2xa1xd3xe2z_utrdl/sc9mcpp96c_tech.lef

# Standard Cell libraries
set standard_cell_lef_file                  $standard_cell_base_path/lef/sc9mcpp96c_cln16fcll001_base_svt_c24.lef
set standard_cell_gds_file                  $standard_cell_base_path/gds2/sc9mcpp96c_cln16fcll001_base_svt_c24.gds2
set standard_cell_db_file_ss_0p72v_125C     $standard_cell_base_path/db/sc9mcpp96c_cln16fcll001_base_svt_c24_ssgnp_cworstccworstt_max_0p72v_125c.db
set standard_cell_db_file_tt_0p80v_25C      $standard_cell_base_path/db/sc9mcpp96c_cln16fcll001_base_svt_c24_tt_typical_max_0p80v_25c.db
set standard_cell_db_file_ff_0p88v_m40C     $standard_cell_base_path/db/sc9mcpp96c_cln16fcll001_base_svt_c24_ffgnp_cbestccbestt_min_0p88v_m40c.db
set standard_cell_antenna_file              $standard_cell_base_path/milkyway/9m_2xa1xd3xe2z_utrdl/sc9mcpp96c_cln16fcll001_base_svt_c24_antenna.clf

# SRAM files (using Arm compiler)
set CA53_L2_DATA_PATH           $env(SOCLABS_PROJECT_DIR)/memories/A53/L2_DATA
set CA53_L2_Data_lef_file       $CA53_L2_DATA_PATH/L2_data.lef
set CA53_L2_Data_gds_file       $CA53_L2_DATA_PATH/L2_data.gds2
set CA53_L2_Data_lib_file_ss    $CA53_L2_DATA_PATH/L2_data_ssgnp_0p72v_0p72v_125c.lib
set CA53_L2_Data_lib_file_tt    $CA53_L2_DATA_PATH/L2_data_tt_0p80v_0p80v_25c.lib
set CA53_L2_Data_lib_file_ff    $CA53_L2_DATA_PATH/L2_data_ffgnp_0p88v_0p88v_m40c.lib
set CA53_L2_Data_db_file_ss     $CA53_L2_DATA_PATH/L2_data_ssgnp_0p72v_0p72v_125c.db
set CA53_L2_Data_db_file_tt     $CA53_L2_DATA_PATH/L2_data_tt_0p80v_0p80v_25c.db
set CA53_L2_Data_db_file_ff     $CA53_L2_DATA_PATH/L2_data_ffgnp_0p88v_0p88v_m40c.db

set CA53_L2_TAG_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L2_TAG
set CA53_L2_TAG_lef_file        $CA53_L2_TAG_PATH/L2_tag.lef
set CA53_L2_TAG_gds_file        $CA53_L2_TAG_PATH/L2_tag.gds2
set CA53_L2_TAG_lib_file_ss     $CA53_L2_TAG_PATH/L2_tag_ssgnp_0p72v_0p72v_125c.lib
set CA53_L2_TAG_lib_file_tt     $CA53_L2_TAG_PATH/L2_tag_tt_0p80v_0p80v_25c.lib
set CA53_L2_TAG_lib_file_ff     $CA53_L2_TAG_PATH/L2_tag_ffgnp_0p88v_0p88v_m40c.lib
set CA53_L2_TAG_db_file_ss      $CA53_L2_TAG_PATH/L2_tag_ssgnp_0p72v_0p72v_125c.db
set CA53_L2_TAG_db_file_tt      $CA53_L2_TAG_PATH/L2_tag_tt_0p80v_0p80v_25c.db
set CA53_L2_TAG_db_file_ff      $CA53_L2_TAG_PATH/L2_tag_ffgnp_0p88v_0p88v_m40c.db

set CA53_L2_VICT_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L2_VICTIM
set CA53_L2_VICT_lef_file        $CA53_L2_VICT_PATH/L2_vict.lef
set CA53_L2_VICT_gds_file        $CA53_L2_VICT_PATH/L2_vict.gds2
set CA53_L2_VICT_lib_file_ss     $CA53_L2_VICT_PATH/L2_vict_ssgnp_0p72v_0p72v_125c.lib
set CA53_L2_VICT_lib_file_tt     $CA53_L2_VICT_PATH/L2_vict_tt_0p80v_0p80v_25c.lib
set CA53_L2_VICT_lib_file_ff     $CA53_L2_VICT_PATH/L2_vict_ffgnp_0p88v_0p88v_m40c.lib
set CA53_L2_VICT_db_file_ss      $CA53_L2_VICT_PATH/L2_vict_ssgnp_0p72v_0p72v_125c.db
set CA53_L2_VICT_db_file_tt      $CA53_L2_VICT_PATH/L2_vict_tt_0p80v_0p80v_25c.db
set CA53_L2_VICT_db_file_ff      $CA53_L2_VICT_PATH/L2_vict_ffgnp_0p88v_0p88v_m40c.db

set CA53_L1_TAG_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_TAG
set CA53_L1_TAG_lef_file        $CA53_L1_TAG_PATH/L1_tag.lef
set CA53_L1_TAG_gds_file        $CA53_L1_TAG_PATH/L1_tag.gds2
set CA53_L1_TAG_lib_file_ss     $CA53_L1_TAG_PATH/L1_tag_ssgnp_0p72v_0p72v_125c.lib
set CA53_L1_TAG_lib_file_tt     $CA53_L1_TAG_PATH/L1_tag_tt_0p80v_0p80v_25c.lib
set CA53_L1_TAG_lib_file_ff     $CA53_L1_TAG_PATH/L1_tag_ffgnp_0p88v_0p88v_m40c.lib
set CA53_L1_TAG_db_file_ss      $CA53_L1_TAG_PATH/L1_tag_ssgnp_0p72v_0p72v_125c.db
set CA53_L1_TAG_db_file_tt      $CA53_L1_TAG_PATH/L1_tag_tt_0p80v_0p80v_25c.db
set CA53_L1_TAG_db_file_ff      $CA53_L1_TAG_PATH/L1_tag_ffgnp_0p88v_0p88v_m40c.db

set CA53_L1_iDATA_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_iDATA
set CA53_L1_iDATA_lef_file        $CA53_L1_iDATA_PATH/L1_idata.lef
set CA53_L1_iDATA_gds_file        $CA53_L1_iDATA_PATH/L1_idata.gds2
set CA53_L1_iDATA_lib_file_ss     $CA53_L1_iDATA_PATH/L1_idata_ssgnp_0p72v_0p72v_125c.lib
set CA53_L1_iDATA_lib_file_tt     $CA53_L1_iDATA_PATH/L1_idata_tt_0p80v_0p80v_25c.lib
set CA53_L1_iDATA_lib_file_ff     $CA53_L1_iDATA_PATH/L1_idata_ffgnp_0p88v_0p88v_m40c.lib
set CA53_L1_iDATA_db_file_ss      $CA53_L1_iDATA_PATH/L1_idata_ssgnp_0p72v_0p72v_125c.db
set CA53_L1_iDATA_db_file_tt      $CA53_L1_iDATA_PATH/L1_idata_tt_0p80v_0p80v_25c.db
set CA53_L1_iDATA_db_file_ff      $CA53_L1_iDATA_PATH/L1_idata_ffgnp_0p88v_0p88v_m40c.db

set CA53_L1_iTAG_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_iTAG
set CA53_L1_iTAG_lef_file        $CA53_L1_iTAG_PATH/L1_itag.lef
set CA53_L1_iTAG_gds_file        $CA53_L1_iTAG_PATH/L1_itag.gds2
set CA53_L1_iTAG_lib_file_ss     $CA53_L1_iTAG_PATH/L1_itag_ssgnp_0p72v_0p72v_125c.lib
set CA53_L1_iTAG_lib_file_tt     $CA53_L1_iTAG_PATH/L1_itag_tt_0p80v_0p80v_25c.lib
set CA53_L1_iTAG_lib_file_ff     $CA53_L1_iTAG_PATH/L1_itag_ffgnp_0p88v_0p88v_m40c.lib
set CA53_L1_iTAG_db_file_ss      $CA53_L1_iTAG_PATH/L1_itag_ssgnp_0p72v_0p72v_125c.db
set CA53_L1_iTAG_db_file_tt      $CA53_L1_iTAG_PATH/L1_itag_tt_0p80v_0p80v_25c.db
set CA53_L1_iTAG_db_file_ff      $CA53_L1_iTAG_PATH/L1_itag_ffgnp_0p88v_0p88v_m40c.db

set CA53_L1_dDATA_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_dDATA
set CA53_L1_dDATA_lef_file        $CA53_L1_dDATA_PATH/L1_ddata.lef
set CA53_L1_dDATA_gds_file        $CA53_L1_dDATA_PATH/L1_ddata.gds2
set CA53_L1_dDATA_lib_file_ss     $CA53_L1_dDATA_PATH/L1_ddata_ssgnp_0p72v_0p72v_125c.lib
set CA53_L1_dDATA_lib_file_tt     $CA53_L1_dDATA_PATH/L1_ddata_tt_0p80v_0p80v_25c.lib
set CA53_L1_dDATA_lib_file_ff     $CA53_L1_dDATA_PATH/L1_ddata_ffgnp_0p88v_0p88v_m40c.lib
set CA53_L1_dDATA_db_file_ss      $CA53_L1_dDATA_PATH/L1_ddata_ssgnp_0p72v_0p72v_125c.db
set CA53_L1_dDATA_db_file_tt      $CA53_L1_dDATA_PATH/L1_ddata_tt_0p80v_0p80v_25c.db
set CA53_L1_dDATA_db_file_ff      $CA53_L1_dDATA_PATH/L1_ddata_ffgnp_0p88v_0p88v_m40c.db

set CA53_L1_dTAG_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_dTAG
set CA53_L1_dTAG_lef_file        $CA53_L1_dTAG_PATH/L1_dtag.lef
set CA53_L1_dTAG_gds_file        $CA53_L1_dTAG_PATH/L1_dtag.gds2
set CA53_L1_dTAG_lib_file_ss     $CA53_L1_dTAG_PATH/L1_dtag_ssgnp_0p72v_0p72v_125c.lib
set CA53_L1_dTAG_lib_file_tt     $CA53_L1_dTAG_PATH/L1_dtag_tt_0p80v_0p80v_25c.lib
set CA53_L1_dTAG_lib_file_ff     $CA53_L1_dTAG_PATH/L1_dtag_ffgnp_0p88v_0p88v_m40c.lib
set CA53_L1_dTAG_db_file_ss      $CA53_L1_dTAG_PATH/L1_dtag_ssgnp_0p72v_0p72v_125c.db
set CA53_L1_dTAG_db_file_tt      $CA53_L1_dTAG_PATH/L1_dtag_tt_0p80v_0p80v_25c.db
set CA53_L1_dTAG_db_file_ff      $CA53_L1_dTAG_PATH/L1_dtag_ffgnp_0p88v_0p88v_m40c.db

set CA53_L1_dDIRTY_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_dDIRTY
set CA53_L1_dDIRTY_lef_file        $CA53_L1_dDIRTY_PATH/L1_ddirty.lef
set CA53_L1_dDIRTY_gds_file        $CA53_L1_dDIRTY_PATH/L1_ddirty.gds2
set CA53_L1_dDIRTY_lib_file_ss     $CA53_L1_dDIRTY_PATH/L1_ddirty_ssgnp_0p72v_0p72v_125c.lib
set CA53_L1_dDIRTY_lib_file_tt     $CA53_L1_dDIRTY_PATH/L1_ddirty_tt_0p80v_0p80v_25c.lib
set CA53_L1_dDIRTY_lib_file_ff     $CA53_L1_dDIRTY_PATH/L1_ddirty_ffgnp_0p88v_0p88v_m40c.lib
set CA53_L1_dDIRTY_db_file_ss      $CA53_L1_dDIRTY_PATH/L1_ddirty_ssgnp_0p72v_0p72v_125c.db
set CA53_L1_dDIRTY_db_file_tt      $CA53_L1_dDIRTY_PATH/L1_ddirty_tt_0p80v_0p80v_25c.db
set CA53_L1_dDIRTY_db_file_ff      $CA53_L1_dDIRTY_PATH/L1_ddirty_ffgnp_0p88v_0p88v_m40c.db

set CA53_L1_TLB_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_TLB
set CA53_L1_TLB_lef_file        $CA53_L1_TLB_PATH/L1_tlb.lef
set CA53_L1_TLB_gds_file        $CA53_L1_TLB_PATH/L1_tlb.gds2
set CA53_L1_TLB_lib_file_ss     $CA53_L1_TLB_PATH/L1_tlb_ssgnp_0p72v_0p72v_125c.lib
set CA53_L1_TLB_lib_file_tt     $CA53_L1_TLB_PATH/L1_tlb_tt_0p80v_0p80v_25c.lib
set CA53_L1_TLB_lib_file_ff     $CA53_L1_TLB_PATH/L1_tlb_ffgnp_0p88v_0p88v_m40c.lib
set CA53_L1_TLB_db_file_ss      $CA53_L1_TLB_PATH/L1_tlb_ssgnp_0p72v_0p72v_125c.db
set CA53_L1_TLB_db_file_tt      $CA53_L1_TLB_PATH/L1_tlb_tt_0p80v_0p80v_25c.db
set CA53_L1_TLB_db_file_ff      $CA53_L1_TLB_PATH/L1_tlb_ffgnp_0p88v_0p88v_m40c.db

set CA53_L1_BTAC1_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_BTAC1
set CA53_L1_BTAC1_lef_file        $CA53_L1_BTAC1_PATH/L1_btac1.lef
set CA53_L1_BTAC1_gds_file        $CA53_L1_BTAC1_PATH/L1_btac1.gds2
set CA53_L1_BTAC1_lib_file_ss     $CA53_L1_BTAC1_PATH/L1_btac1_ssgnp_0p72v_0p72v_125c.lib
set CA53_L1_BTAC1_lib_file_tt     $CA53_L1_BTAC1_PATH/L1_btac1_tt_0p80v_0p80v_25c.lib
set CA53_L1_BTAC1_lib_file_ff     $CA53_L1_BTAC1_PATH/L1_btac1_ffgnp_0p88v_0p88v_m40c.lib
set CA53_L1_BTAC1_db_file_ss      $CA53_L1_BTAC1_PATH/L1_btac1_ssgnp_0p72v_0p72v_125c.db
set CA53_L1_BTAC1_db_file_tt      $CA53_L1_BTAC1_PATH/L1_btac1_tt_0p80v_0p80v_25c.db
set CA53_L1_BTAC1_db_file_ff      $CA53_L1_BTAC1_PATH/L1_btac1_ffgnp_0p88v_0p88v_m40c.db

set CA53_L1_BTAC2_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_BTAC2
set CA53_L1_BTAC2_lef_file        $CA53_L1_BTAC2_PATH/L1_btac2.lef
set CA53_L1_BTAC2_gds_file        $CA53_L1_BTAC2_PATH/L1_btac2.gds2
set CA53_L1_BTAC2_lib_file_ss     $CA53_L1_BTAC2_PATH/L1_btac2_ssgnp_0p72v_0p72v_125c.lib
set CA53_L1_BTAC2_lib_file_tt     $CA53_L1_BTAC2_PATH/L1_btac2_tt_0p80v_0p80v_25c.lib
set CA53_L1_BTAC2_lib_file_ff     $CA53_L1_BTAC2_PATH/L1_btac2_ffgnp_0p88v_0p88v_m40c.lib
set CA53_L1_BTAC2_db_file_ss      $CA53_L1_BTAC2_PATH/L1_btac2_ssgnp_0p72v_0p72v_125c.db
set CA53_L1_BTAC2_db_file_tt      $CA53_L1_BTAC2_PATH/L1_btac2_tt_0p80v_0p80v_25c.db
set CA53_L1_BTAC2_db_file_ff      $CA53_L1_BTAC2_PATH/L1_btac2_ffgnp_0p88v_0p88v_m40c.db

# Create standard cell fusion library
create_fusion_lib -dbs [list $standard_cell_db_file_ss_0p72v_125C $standard_cell_db_file_tt_0p80v_25C $standard_cell_db_file_ff_0p88v_m40C]  -lefs [list $cln16fcll_lef_file $standard_cell_lef_file] -technology $cln16fcll_tech_file cln16fcll
save_fusion_lib cln16fcll
close_fusion_lib cln16fcll

# L1 BTAC 2 RF SRAM
read_lib $CA53_L1_BTAC2_lib_file_ss 
write_lib -output $CA53_L1_BTAC2_db_file_ss -format db L1_btac2_rf_ssgnp_0p72v_0p72v_125c
close_lib -all

read_lib $CA53_L1_BTAC2_lib_file_tt 
write_lib -output $CA53_L1_BTAC2_db_file_tt -format db L1_btac2_rf_tt_0p80v_0p80v_25c
close_lib -all

read_lib $CA53_L1_BTAC2_lib_file_ff 
write_lib -output $CA53_L1_BTAC2_db_file_ff -format db L1_btac2_rf_ffgnp_0p88v_0p88v_m40c
close_lib -all

create_fusion_lib -dbs [list $CA53_L1_BTAC2_db_file_ss $CA53_L1_BTAC2_db_file_tt $CA53_L1_BTAC2_db_file_ff] -lefs $CA53_L1_BTAC2_lef_file -technology $cln16fcll_tech_file CA53_L1_btac2
save_fusion_lib CA53_L1_btac2
close_fusion_lib CA53_L1_btac2

# L1 BTAC 1 RF SRAM
read_lib $CA53_L1_BTAC1_lib_file_ss 
write_lib -output $CA53_L1_BTAC1_db_file_ss -format db L1_btac1_rf_ssgnp_0p72v_0p72v_125c
close_lib -all

read_lib $CA53_L1_BTAC1_lib_file_tt 
write_lib -output $CA53_L1_BTAC1_db_file_tt -format db L1_btac1_rf_tt_0p80v_0p80v_25c
close_lib -all

read_lib $CA53_L1_BTAC1_lib_file_ff 
write_lib -output $CA53_L1_BTAC1_db_file_ff -format db L1_btac1_rf_ffgnp_0p88v_0p88v_m40c
close_lib -all

create_fusion_lib -dbs [list $CA53_L1_BTAC1_db_file_ss $CA53_L1_BTAC1_db_file_tt $CA53_L1_BTAC1_db_file_ff] -lefs $CA53_L1_BTAC1_lef_file -technology $cln16fcll_tech_file CA53_L1_btac1
save_fusion_lib CA53_L1_btac1
close_fusion_lib CA53_L1_btac1

# L1 TLB RF SRAM
read_lib $CA53_L1_TLB_lib_file_ss 
write_lib -output $CA53_L1_TLB_db_file_ss -format db L1_tlb_rf_ssgnp_0p72v_0p72v_125c
close_lib -all

read_lib $CA53_L1_TLB_lib_file_tt 
write_lib -output $CA53_L1_TLB_db_file_tt -format db L1_tlb_rf_tt_0p80v_0p80v_25c
close_lib -all

read_lib $CA53_L1_TLB_lib_file_ff 
write_lib -output $CA53_L1_TLB_db_file_ff -format db L1_tlb_rf_ffgnp_0p88v_0p88v_m40c
close_lib -all

create_fusion_lib -dbs [list $CA53_L1_TLB_db_file_ss $CA53_L1_TLB_db_file_tt $CA53_L1_TLB_db_file_ff] -lefs $CA53_L1_TLB_lef_file -technology $cln16fcll_tech_file CA53_L1_tlb
save_fusion_lib CA53_L1_tlb
close_fusion_lib CA53_L1_tlb

# L1 Data DIRTY RF SRAM
read_lib $CA53_L1_dDIRTY_lib_file_ss 
write_lib -output $CA53_L1_dDIRTY_db_file_ss -format db L1_ddirty_rf_ssgnp_0p72v_0p72v_125c
close_lib -all

read_lib $CA53_L1_dDIRTY_lib_file_tt 
write_lib -output $CA53_L1_dDIRTY_db_file_tt -format db L1_ddirty_rf_tt_0p80v_0p80v_25c
close_lib -all

read_lib $CA53_L1_dDIRTY_lib_file_ff 
write_lib -output $CA53_L1_dDIRTY_db_file_ff -format db L1_ddirty_rf_ffgnp_0p88v_0p88v_m40c
close_lib -all

create_fusion_lib -dbs [list $CA53_L1_dDIRTY_db_file_ss $CA53_L1_dDIRTY_db_file_tt $CA53_L1_dDIRTY_db_file_ff] -lefs $CA53_L1_dDIRTY_lef_file -technology $cln16fcll_tech_file CA53_L1_dirty
save_fusion_lib CA53_L1_dirty
close_fusion_lib CA53_L1_dirty

# L1 Data TAG RF SRAM
read_lib $CA53_L1_dTAG_lib_file_ss 
write_lib -output $CA53_L1_dTAG_db_file_ss -format db L1_dtag_rf_ssgnp_0p72v_0p72v_125c
close_lib -all

read_lib $CA53_L1_dTAG_lib_file_tt 
write_lib -output $CA53_L1_dTAG_db_file_tt -format db L1_dtag_rf_tt_0p80v_0p80v_25c
close_lib -all

read_lib $CA53_L1_dTAG_lib_file_ff 
write_lib -output $CA53_L1_dTAG_db_file_ff -format db L1_dtag_rf_ffgnp_0p88v_0p88v_m40c
close_lib -all

create_fusion_lib -dbs [list $CA53_L1_dTAG_db_file_ss $CA53_L1_dTAG_db_file_tt $CA53_L1_dTAG_db_file_ff] -lefs $CA53_L1_dTAG_lef_file -technology $cln16fcll_tech_file CA53_L1_dtag
save_fusion_lib CA53_L1_dtag
close_fusion_lib CA53_L1_dtag


# L1 Data DATA RF SRAM
read_lib $CA53_L1_dDATA_lib_file_ss 
write_lib -output $CA53_L1_dDATA_db_file_ss -format db L1_ddata_rf_ssgnp_0p72v_0p72v_125c
close_lib -all

read_lib $CA53_L1_dDATA_lib_file_tt 
write_lib -output $CA53_L1_dDATA_db_file_tt -format db L1_ddata_rf_tt_0p80v_0p80v_25c
close_lib -all

read_lib $CA53_L1_dDATA_lib_file_ff 
write_lib -output $CA53_L1_dDATA_db_file_ff -format db L1_ddata_rf_ffgnp_0p88v_0p88v_m40c
close_lib -all

create_fusion_lib -dbs [list $CA53_L1_dDATA_db_file_ss $CA53_L1_dDATA_db_file_tt $CA53_L1_dDATA_db_file_ff] -lefs $CA53_L1_dDATA_lef_file -technology $cln16fcll_tech_file CA53_L1_ddata
save_fusion_lib CA53_L1_ddata
close_fusion_lib CA53_L1_ddata


# L1 Instruction TAG RF SRAM
read_lib $CA53_L1_iTAG_lib_file_ss 
write_lib -output $CA53_L1_iTAG_db_file_ss -format db L1_itag_rf_ssgnp_0p72v_0p72v_125c
close_lib -all

read_lib $CA53_L1_iTAG_lib_file_tt 
write_lib -output $CA53_L1_iTAG_db_file_tt -format db L1_itag_rf_tt_0p80v_0p80v_25c
close_lib -all

read_lib $CA53_L1_iTAG_lib_file_ff 
write_lib -output $CA53_L1_iTAG_db_file_ff -format db L1_itag_rf_ffgnp_0p88v_0p88v_m40c
close_lib -all

create_fusion_lib -dbs [list $CA53_L1_iTAG_db_file_ss $CA53_L1_iTAG_db_file_tt $CA53_L1_iTAG_db_file_ff] -lefs $CA53_L1_iTAG_lef_file -technology $cln16fcll_tech_file CA53_L1_itag
save_fusion_lib CA53_L1_itag
close_fusion_lib CA53_L1_itag

# L1 Instruction Data RF SRAM
read_lib $CA53_L1_iDATA_lib_file_ss 
write_lib -output $CA53_L1_iDATA_db_file_ss -format db L1_idata_rf_ssgnp_0p72v_0p72v_125c
close_lib -all

read_lib $CA53_L1_iDATA_lib_file_tt 
write_lib -output $CA53_L1_iDATA_db_file_tt -format db L1_idata_rf_tt_0p80v_0p80v_25c
close_lib -all

read_lib $CA53_L1_iDATA_lib_file_ff 
write_lib -output $CA53_L1_iDATA_db_file_ff -format db L1_idata_rf_ffgnp_0p88v_0p88v_m40c
close_lib -all

create_fusion_lib -dbs [list $CA53_L1_iDATA_db_file_ss $CA53_L1_iDATA_db_file_tt $CA53_L1_iDATA_db_file_ff] -lefs $CA53_L1_iDATA_lef_file -technology $cln16fcll_tech_file CA53_L1_idata
save_fusion_lib CA53_L1_idata
close_fusion_lib CA53_L1_idata

# L1 TAG RF SRAM
read_lib $CA53_L1_TAG_lib_file_ss 
write_lib -output $CA53_L1_TAG_db_file_ss -format db L1_tag_rf_ssgnp_0p72v_0p72v_125c
close_lib -all

read_lib $CA53_L1_TAG_lib_file_tt 
write_lib -output $CA53_L1_TAG_db_file_tt -format db L1_tag_rf_tt_0p80v_0p80v_25c
close_lib -all

read_lib $CA53_L1_TAG_lib_file_ff 
write_lib -output $CA53_L1_TAG_db_file_ff -format db L1_tag_rf_ffgnp_0p88v_0p88v_m40c
close_lib -all

create_fusion_lib -dbs [list $CA53_L1_TAG_db_file_ss $CA53_L1_TAG_db_file_tt $CA53_L1_TAG_db_file_ff] -lefs $CA53_L1_TAG_lef_file -technology $cln16fcll_tech_file CA53_L1_tag
save_fusion_lib CA53_L1_tag
close_fusion_lib CA53_L1_tag



# L2 Victim SRAM
read_lib $CA53_L2_VICT_lib_file_ss 
write_lib -output $CA53_L2_VICT_db_file_ss -format db L2_vict_rf_ssgnp_0p72v_0p72v_125c
close_lib -all

read_lib $CA53_L2_VICT_lib_file_tt 
write_lib -output $CA53_L2_VICT_db_file_tt -format db L2_vict_rf_tt_0p80v_0p80v_25c
close_lib -all

read_lib $CA53_L2_VICT_lib_file_ff 
write_lib -output $CA53_L2_VICT_db_file_ff -format db L2_vict_rf_ffgnp_0p88v_0p88v_m40c
close_lib -all

create_fusion_lib -dbs [list $CA53_L2_VICT_db_file_ss $CA53_L2_VICT_db_file_tt $CA53_L2_VICT_db_file_ff] -lefs $CA53_L2_VICT_lef_file -technology $cln16fcll_tech_file CA53_L2_vict
save_fusion_lib CA53_L2_vict
close_fusion_lib CA53_L2_vict


# L2 Tag SRAM
read_lib $CA53_L2_TAG_lib_file_ss 
write_lib -output $CA53_L2_TAG_db_file_ss -format db L2_tag_rf_ssgnp_0p72v_0p72v_125c
close_lib -all

read_lib $CA53_L2_TAG_lib_file_tt 
write_lib -output $CA53_L2_TAG_db_file_tt -format db L2_tag_rf_tt_0p80v_0p80v_25c
close_lib -all

read_lib $CA53_L2_TAG_lib_file_ff 
write_lib -output $CA53_L2_TAG_db_file_ff -format db L2_tag_rf_ffgnp_0p88v_0p88v_m40c
close_lib -all

create_fusion_lib -dbs [list $CA53_L2_TAG_db_file_ss $CA53_L2_TAG_db_file_tt $CA53_L2_TAG_db_file_ff] -lefs $CA53_L2_TAG_lef_file -technology $cln16fcll_tech_file CA53_L2_tag
save_fusion_lib CA53_L2_tag
close_fusion_lib CA53_L2_tag

# L2 Data SRAM
read_lib $CA53_L2_Data_lib_file_ss 
write_lib -output $CA53_L2_Data_db_file_ss -format db L2_data_sram_ssgnp_0p72v_0p72v_125c
close_lib -all

read_lib $CA53_L2_Data_lib_file_tt 
write_lib -output $CA53_L2_Data_db_file_tt -format db L2_data_sram_tt_0p80v_0p80v_25c
close_lib -all

read_lib $CA53_L2_Data_lib_file_ff 
write_lib -output $CA53_L2_Data_db_file_ff -format db L2_data_sram_ffgnp_0p88v_0p88v_m40c
close_lib -all

create_fusion_lib -dbs [list $CA53_L2_Data_db_file_ss $CA53_L2_Data_db_file_tt $CA53_L2_Data_db_file_ff] -lefs $CA53_L2_Data_lef_file -technology $cln16fcll_tech_file CA53_L2_data
save_fusion_lib CA53_L2_data
close_fusion_lib CA53_L2_data

