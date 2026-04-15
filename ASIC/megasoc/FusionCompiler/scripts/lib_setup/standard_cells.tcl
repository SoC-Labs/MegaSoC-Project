
# Standard Cell libraries
set standard_cell_mw_libs $standard_cell_base_path/Back_End/milkyway/tcbn16ffcllbwp20p90_100a/cell_frame_VHV_0_0/tcbn16ffcllbwp20p90
set standard_cell_ffgnp_p88v_125C_db_file   $standard_cell_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90_100a/tcbn16ffcllbwp20p90ffgnp0p88v125c_ccs.db
set standard_cell_ffgnp_p88v_m40C_db_file   $standard_cell_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90_100a/tcbn16ffcllbwp20p90ffgnp0p88vm40c_ccs.db
set standard_cell_ssgnp_p72v_125C_db_file   $standard_cell_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90_100a/tcbn16ffcllbwp20p90ssgnp0p72v125c_ccs.db
set standard_cell_ssgnp_p72v_m40C_db_file   $standard_cell_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90_100a/tcbn16ffcllbwp20p90ssgnp0p72vm40c_ccs.db
set standard_cell_tt_p80v_85C_db_file       $standard_cell_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90_100a/tcbn16ffcllbwp20p90tt0p8v85c_ccs.db
set standard_cell_tt_p75v_25C_db_file       $standard_cell_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90_100a/tcbn16ffcllbwp20p90tt0p75v25c_ccs.db
set standard_cell_tt_p80_25C_db_file        $standard_cell_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90_100a/tcbn16ffcllbwp20p90tt0p8v25c_ccs.db
set standard_cell_ffg_p825v_125c_db_file    $standard_cell_base_path/Front_End/timing_power_noise/CCS/tcbn16ffcllbwp20p90_100a/tcbn16ffcllbwp20p90ffg0p825v125c_ccs.db

# Create standard cell fusion library
create_fusion_lib -dbs [list \
    $standard_cell_ffgnp_p88v_125C_db_file \
    $standard_cell_ffgnp_p88v_m40C_db_file \
    $standard_cell_ssgnp_p72v_125C_db_file \
    $standard_cell_ssgnp_p72v_m40C_db_file \
    $standard_cell_tt_p80v_85C_db_file \
    $standard_cell_tt_p75v_25C_db_file \
    $standard_cell_tt_p80_25C_db_file \
    $standard_cell_ffg_p825v_125c_db_file \
    ] -mw_libs $standard_cell_mw_libs cln16fcll
save_fusion_lib cln16fcll
redirect -tee -file ./cln16fcll.report {report_fusion_lib}
close_fusion_lib cln16fcll
