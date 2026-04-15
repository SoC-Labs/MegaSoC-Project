
# Standard Cell libraries
set lvl_mw_libs                   $lvl_base_path/Back_End/milkyway/tcbn16ffcllbwp20p90lvl_110a/cell_frame_VHV_0_0/tcbn16ffcllbwp20p90lvl
set lvl_ffgnp_p88v_125C_db_file   $lvl_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90lvl_110a/tcbn16ffcllbwp20p90lvlffgnp0p88v0p88v125c_ccs.db
set lvl_ffgnp_p88v_m40C_db_file   $lvl_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90lvl_110a/tcbn16ffcllbwp20p90lvlffgnp0p88v0p88vm40c_ccs.db
set lvl_ssgnp_p72v_125C_db_file   $lvl_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90lvl_110a/tcbn16ffcllbwp20p90lvlssgnp0p72v0p72v125c_ccs.db
set lvl_ssgnp_p72v_m40C_db_file   $lvl_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90lvl_110a/tcbn16ffcllbwp20p90lvlssgnp0p72v0p72vm40c_ccs.db
set lvl_tt_p80v_85C_db_file       $lvl_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90lvl_110a/tcbn16ffcllbwp20p90lvltt0p8v0p8v85c_ccs.db
set lvl_tt_p75v_25C_db_file       $lvl_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90lvl_110a/tcbn16ffcllbwp20p90lvltt0p75v0p75v25c_ccs.db
set lvl_tt_p80_25C_db_file        $lvl_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90lvl_110a/tcbn16ffcllbwp20p90lvltt0p8v0p8v25c_ccs.db
set lvl_ffg_p825v_125c_db_file    $lvl_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90lvl_110a/tcbn16ffcllbwp20p90lvlffg0p825v0p825v125c_ccs.db

# Create standard cell fusion library
create_fusion_lib -dbs [list \
    $lvl_ffgnp_p88v_125C_db_file \
    $lvl_ffgnp_p88v_m40C_db_file \
    $lvl_ssgnp_p72v_125C_db_file \
    $lvl_ssgnp_p72v_m40C_db_file \
    $lvl_tt_p80v_85C_db_file \
    $lvl_tt_p75v_25C_db_file \
    $lvl_tt_p80_25C_db_file \
    $lvl_ffg_p825v_125c_db_file \
    ] -mw_libs $lvl_mw_libs cln16fcll_lvl
save_fusion_lib cln16fcll_lvl
redirect -tee -file ./cln16fcll_lvl.report {report_fusion_lib}
close_fusion_lib cln16fcll_lvl
