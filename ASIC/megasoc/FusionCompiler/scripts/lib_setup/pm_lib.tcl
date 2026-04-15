
# Standard Cell libraries
set pm_mw_libs $pm_base_path/Back_End/milkyway/tcbn16ffcllbwp20p90pm_100a/cell_frame_VHV_0_0/tcbn16ffcllbwp20p90pm
set pm_ffgnp_p88v_125C_db_file   $pm_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90pm_170b/tcbn16ffcllbwp20p90pmffgnp0p88v125c_ccs.db
set pm_ffgnp_p88v_m40C_db_file   $pm_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90pm_170b/tcbn16ffcllbwp20p90pmffgnp0p88vm40c_ccs.db
set pm_ssgnp_p72v_125C_db_file   $pm_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90pm_170b/tcbn16ffcllbwp20p90pmssgnp0p72v125c_ccs.db
set pm_ssgnp_p72v_m40C_db_file   $pm_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90pm_170b/tcbn16ffcllbwp20p90pmssgnp0p72vm40c_ccs.db
set pm_tt_p80v_85C_db_file       $pm_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90pm_170b/tcbn16ffcllbwp20p90pmtt0p8v85c_ccs.db
set pm_tt_p75v_25C_db_file       $pm_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90pm_170b/tcbn16ffcllbwp20p90pmtt0p75v25c_ccs.db
set pm_tt_p80_25C_db_file        $pm_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90pm_170b/tcbn16ffcllbwp20p90pmtt0p8v25c_ccs.db
set pm_ffg_p825v_125c_db_file    $pm_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90pm_170b/tcbn16ffcllbwp20p90pmffg0p825v125c_ccs.db

# Create standard cell fusion library
create_fusion_lib -dbs [list \
    $pm_ffgnp_p88v_125C_db_file \
    $pm_ffgnp_p88v_m40C_db_file \
    $pm_ssgnp_p72v_125C_db_file \
    $pm_ssgnp_p72v_m40C_db_file \
    $pm_tt_p80v_85C_db_file \
    $pm_tt_p75v_25C_db_file \
    $pm_tt_p80_25C_db_file \
    $pm_ffg_p825v_125c_db_file \
    ] -mw_libs $pm_mw_libs cln16fcll_pm
save_fusion_lib cln16fcll_pm
redirect -tee -file ./cln16fcll_pm.report {report_fusion_lib}
close_fusion_lib cln16fcll_pm
