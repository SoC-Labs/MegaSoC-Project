## Paths Please Edit for your system
set cln16fcll_tech_path         /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/arm_tech/r3p0
set standard_cell_base_path     /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/sc9mcpp96c_base_svt_c24/r2p0
set pmk_base_path               /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/sc9mcpp96c_pmk_svt_c24/r2p0
set ret_base_path               /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/sc9mcpp96c_rklo_lvt_svt_c20_c24/r1p0
set arm_io_base_path            /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/io_gppr_t18_mv08_fs18_rvt_dr/r1p3

# Technology files
set cln16fcll_tech_file         $cln16fcll_tech_path/ndm/9m_2xa1xd3xe2z_utrdl/sc9mcpp96c_tech.tf

# Standard Cell libraries
set standard_cell_lef_file                  $standard_cell_base_path/lef/sc9mcpp96c_cln16fcll001_base_svt_c24.lef
set standard_cell_gds_file                  $standard_cell_base_path/gds2/sc9mcpp96c_cln16fcll001_base_svt_c24.gds2
set standard_cell_ffgnp_p88v_125C_db_file   $standard_cell_base_path/db/sc9mcpp96c_cln16fcll001_base_svt_c24_ffgnp_cbestccbestt_min_0p88v_125c.db
set standard_cell_ffgnp_p88v_m40C_db_file   $standard_cell_base_path/db/sc9mcpp96c_cln16fcll001_base_svt_c24_ffgnp_cbestccbestt_min_0p88v_m40c.db
set standard_cell_ssgnp_p72v_125C_db_file   $standard_cell_base_path/db/sc9mcpp96c_cln16fcll001_base_svt_c24_ssgnp_cworstccworstt_max_0p72v_125c.db
set standard_cell_ssgnp_p72v_m40C_db_file   $standard_cell_base_path/db/sc9mcpp96c_cln16fcll001_base_svt_c24_ssgnp_cworstccworstt_max_0p72v_m40c.db
set standard_cell_tt_p80v_85C_db_file       $standard_cell_base_path/db/sc9mcpp96c_cln16fcll001_base_svt_c24_tt_typical_max_0p80v_85c.db
set standard_cell_tt_p72v_0C_db_file        $standard_cell_base_path/db/sc9mcpp96c_cln16fcll001_base_svt_c24_tt_typical_max_0p72v_0c.db
set standard_cell_tt_p80_25C_db_file        $standard_cell_base_path/db/sc9mcpp96c_cln16fcll001_base_svt_c24_tt_typical_max_0p80v_25c.db
set standard_cell_ffg_p80v_125c_db_file     $standard_cell_base_path/db/sc9mcpp96c_cln16fcll001_base_svt_c24_ffg_typical_max_0p80v_125c.db

# Arm Power management Kit
set pmk_lef_file                $pmk_base_path/lef/sc9mcpp96c_cln16fcll001_pmk_svt_c24.lef
set pmk_gds_file                $pmk_base_path/gds2/sc9mcpp96c_cln16fcll001_pmk_svt_c24.gds2
set pmk_ffgnp_p88v_125C_db_file $pmk_base_path/db/sc9mcpp96c_cln16fcll001_pmk_svt_c24_ffgnp_cbestccbestt_min_0p88v_0p88v_125c.db
set pmk_ffgnp_p88v_m40C_db_file $pmk_base_path/db/sc9mcpp96c_cln16fcll001_pmk_svt_c24_ffgnp_cbestccbestt_min_0p88v_0p88v_m40c.db
set pmk_ssgnp_p72v_125C_db_file $pmk_base_path/db/sc9mcpp96c_cln16fcll001_pmk_svt_c24_ssgnp_cworstccworstt_max_0p72v_0p72v_125c.db
set pmk_ssgnp_p72v_m40C_db_file $pmk_base_path/db/sc9mcpp96c_cln16fcll001_pmk_svt_c24_ssgnp_cworstccworstt_max_0p72v_0p72v_m40c.db
set pmk_tt_p80v_85C_db_file     $pmk_base_path/db/sc9mcpp96c_cln16fcll001_pmk_svt_c24_tt_typical_max_0p80v_0p80v_85c.db
set pmk_tt_p72v_0C_db_file      $pmk_base_path/db/sc9mcpp96c_cln16fcll001_pmk_svt_c24_tt_typical_max_0p72v_0p72v_0c.db
set pmk_tt_p80_25C_db_file      $pmk_base_path/db/sc9mcpp96c_cln16fcll001_pmk_svt_c24_tt_typical_max_0p80v_0p80v_25c.db
set pmk_ffg_p80v_125c_db_file   $pmk_base_path/db/sc9mcpp96c_cln16fcll001_pmk_svt_c24_ffg_typical_max_0p80v_0p80v_125c.db

# Arm Retention Library
set ret_lef_file                $ret_base_path/lef/sc9mcpp96c_cln16fcll001_rklo_lvt_svt_c20_c24.lef
set ret_gds_path                $ret_base_path/gds2/sc9mcpp96c_cln16fcll001_rklo_lvt_svt_c20_c24.gds2
set ret_ffgnp_p88v_125C_db_file $ret_base_path/db/sc9mcpp96c_cln16fcll001_rklo_lvt_svt_c20_c24_ffgnp_cbestccbestt_min_0p88v_125c.db
set ret_ffgnp_p88v_m40C_db_file $ret_base_path/db/sc9mcpp96c_cln16fcll001_rklo_lvt_svt_c20_c24_ffgnp_cbestccbestt_min_0p88v_m40c.db
set ret_ssgnp_p72v_125C_db_file $ret_base_path/db/sc9mcpp96c_cln16fcll001_rklo_lvt_svt_c20_c24_ssgnp_cworstccworstt_max_0p72v_125c.db
set ret_ssgnp_p72v_m40C_db_file $ret_base_path/db/sc9mcpp96c_cln16fcll001_rklo_lvt_svt_c20_c24_ssgnp_cworstccworstt_max_0p72v_m40c.db
set ret_tt_p80v_85C_db_file     $ret_base_path/db/sc9mcpp96c_cln16fcll001_rklo_lvt_svt_c20_c24_tt_typical_max_0p80v_85c.db
set ret_tt_p72v_0C_db_file      $ret_base_path/db/sc9mcpp96c_cln16fcll001_rklo_lvt_svt_c20_c24_tt_typical_max_0p72v_0c.db
set ret_tt_p80_25C_db_file      $ret_base_path/db/sc9mcpp96c_cln16fcll001_rklo_lvt_svt_c20_c24_tt_typical_max_0p80v_25c.db
set ret_ffg_p80v_125c_db_file   $ret_base_path/db/sc9mcpp96c_cln16fcll001_rklo_lvt_svt_c20_c24_ffg_typical_max_0p80v_125c.db

# Arm IO Library
set arm_io_lef_file                 $arm_io_base_path/lef/io_gppr_cln16fcll001_t18_mv08_fs18_rvt_dr_9m_2xa1xd3xe2z_fc.lef
set arm_io_gds_file                 $arm_io_base_path/gds2/io_gppr_cln16fcll001_t18_mv08_fs18_rvt_dr_9m_2xa1xd3xe2z_fc.gds2
set arm_io_ffgnp_p80v_125C_db_file  $arm_io_base_path/db/io_gppr_cln16fcll001_t18_mv08_fs18_rvt_dr_ffgnp_cbestccbestt_0p88v_1p98v_125c.db
set arm_io_ffgnp_p80v_m40C_db_file  $arm_io_base_path/db/io_gppr_cln16fcll001_t18_mv08_fs18_rvt_dr_ffgnp_cbestccbestt_0p88v_1p98v_m40c.db
set arm_io_ssgnp_p72v_125C_db_file  $arm_io_base_path/db/io_gppr_cln16fcll001_t18_mv08_fs18_rvt_dr_ssgnp_cworstccworstt_0p72v_1p62v_125c.db
set arm_io_ssgnp_p72v_m40C_db_file  $arm_io_base_path/db/io_gppr_cln16fcll001_t18_mv08_fs18_rvt_dr_ssgnp_cworstccworstt_0p72v_1p62v_m40c.db
set arm_io_tt_p80v_85C_db_file      $arm_io_base_path/db/io_gppr_cln16fcll001_t18_mv08_fs18_rvt_dr_tt_typical_0p80v_1p80v_85c.db
set arm_io_tt_p72v_0C_db_file       $arm_io_base_path/db/io_gppr_cln16fcll001_t18_mv08_fs18_rvt_dr_tt_typical_0p72v_1p62v_0c.db
set arm_io_tt_p80_25C_db_file       $arm_io_base_path/db/io_gppr_cln16fcll001_t18_mv08_fs18_rvt_dr_tt_typical_0p80v_1p80v_25c.db
set arm_io_ffg_p80v_125c_db_file    $arm_io_base_path/db/io_gppr_cln16fcll001_t18_mv08_fs18_rvt_dr_ffg_typical_0p80v_1p80v_125c.db

# Create standard cell fusion library
create_fusion_lib -dbs [list \
    $standard_cell_ffgnp_p88v_125C_db_file \
    $standard_cell_ffgnp_p88v_m40C_db_file \
    $standard_cell_ssgnp_p72v_125C_db_file \
    $standard_cell_ssgnp_p72v_m40C_db_file \
    $standard_cell_tt_p80v_85C_db_file \
    $standard_cell_tt_p72v_0C_db_file \
    $standard_cell_tt_p80_25C_db_file \
    $standard_cell_ffg_p80v_125c_db_file \
    ] -lefs $standard_cell_lef_file -technology $cln16fcll_tech_file cln16fcll
save_fusion_lib cln16fcll
close_fusion_lib cln16fcll

# Create PMK fusion library
create_fusion_lib -dbs [list \
    $pmk_ffgnp_p88v_125C_db_file \
    $pmk_ffgnp_p88v_m40C_db_file \
    $pmk_ssgnp_p72v_125C_db_file \
    $pmk_ssgnp_p72v_m40C_db_file \
    $pmk_tt_p80v_85C_db_file \
    $pmk_tt_p72v_0C_db_file \
    $pmk_tt_p80_25C_db_file \
    $pmk_ffg_p80v_125c_db_file \
    ] -lefs $pmk_lef_file -technology $cln16fcll_tech_file arm_pmk_lib
save_fusion_lib arm_pmk_lib
close_fusion_lib arm_pmk_lib

create_fusion_lib -dbs [list \
    $ret_ffgnp_p88v_125C_db_file \
    $ret_ffgnp_p88v_m40C_db_file \
    $ret_ssgnp_p72v_125C_db_file \
    $ret_ssgnp_p72v_m40C_db_file \
    $ret_tt_p80v_85C_db_file \
    $ret_tt_p72v_0C_db_file \
    $ret_tt_p80_25C_db_file \
    $ret_ffg_p80v_125c_db_file \
    ] -lefs $ret_lef_file -technology $cln16fcll_tech_file arm_ret_lib
save_fusion_lib arm_ret_lib
close_fusion_lib arm_ret_lib

# Create Arm IO fusion library
create_fusion_lib -dbs [list \
    $arm_io_ffgnp_p80v_125C_db_file \
    $arm_io_ffgnp_p80v_m40C_db_file \
    $arm_io_ssgnp_p72v_125C_db_file \
    $arm_io_ssgnp_p72v_m40C_db_file \
    $arm_io_tt_p80v_85C_db_file \
    $arm_io_tt_p72v_0C_db_file \
    $arm_io_tt_p80_25C_db_file \
    $arm_io_ffg_p80v_125c_db_file \
    ] -lefs $arm_io_lef_file -technology $cln16fcll_tech_file arm_io
save_fusion_lib arm_io
close_fusion_lib arm_io


exit