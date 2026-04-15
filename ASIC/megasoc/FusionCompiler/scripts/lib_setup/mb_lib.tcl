
# Standard Cell libraries
set mb_mw_libs $mb_base_path/Back_End/milkyway/tcbn16ffcllbwp20p90mb_110a/cell_frame_VHV_0_0/tcbn16ffcllbwp20p90mb
set mb_ffgnp_p88v_125C_db_file   $mb_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90mb_110a/tcbn16ffcllbwp20p90mbffg0p6v125c_ccs.db
set mb_ffgnp_p88v_m40C_db_file   $mb_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90mb_110a/tcbn16ffcllbwp20p90mbffgnp0p88vm40c_ccs.db
set mb_ssgnp_p72v_125C_db_file   $mb_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90mb_110a/tcbn16ffcllbwp20p90mbssgnp0p72v125c_ccs.db
set mb_ssgnp_p72v_m40C_db_file   $mb_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90mb_110a/tcbn16ffcllbwp20p90mbssgnp0p72vm40c_ccs.db
set mb_tt_p80v_85C_db_file       $mb_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90mb_110a/tcbn16ffcllbwp20p90mbtt0p8v85c_ccs.db
set mb_tt_p75v_25C_db_file       $mb_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90mb_110a/tcbn16ffcllbwp20p90mbtt0p75v25c_ccs.db
set mb_tt_p80_25C_db_file        $mb_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90mb_110a/tcbn16ffcllbwp20p90mbtt0p8v25c_ccs.db
set mb_ffg_p825v_125c_db_file    $mb_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90mb_110a/tcbn16ffcllbwp20p90mbffg0p825v125c_ccs.db

# Create standard cell fusion library
create_fusion_lib -dbs [list \
    $mb_ffgnp_p88v_125C_db_file \
    $mb_ffgnp_p88v_m40C_db_file \
    $mb_ssgnp_p72v_125C_db_file \
    $mb_ssgnp_p72v_m40C_db_file \
    $mb_tt_p80v_85C_db_file \
    $mb_tt_p75v_25C_db_file \
    $mb_tt_p80_25C_db_file \
    $mb_ffg_p825v_125c_db_file \
    ] -mw_libs $mb_mw_libs cln16fcll_mb
save_fusion_lib cln16fcll_mb
redirect -tee -file ./cln16fcll_mb.report {report_fusion_lib}
close_fusion_lib cln16fcll_mb
