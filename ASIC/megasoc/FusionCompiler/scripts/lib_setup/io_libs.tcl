set io_base_path    $env(TSMC_16_HOME)/CMOS/FFC_UNIV/iolib/tphn16ffcllgv18e_univ_170b/TSMCHOME/digital
set pad_base_path   $env(TSMC_16_HOME)/CMOS/FFC_UNIV/iolib/tpbn16ffc_univ_100a/TSMCHOME/digital


# IO libraries
set io_mw_libs $io_base_path/Back_End/milkyway/tphn16ffcllgv18e_univ_170a/mt/10m/10M_2XA1XD_H_4XE_VHVH_2Z/cell_frame/tphn16ffcllgv18e_univ
set io_ffgnp_p88v_125C_db_file   $io_base_path/Front_End/timing_power_noise/NLDM/tphn16ffcllgv18e_univ_170a/tphn16ffcllgv18e_univffgnp0p88v1p98v125c.db
set io_ffgnp_p88v_m40C_db_file   $io_base_path/Front_End/timing_power_noise/NLDM/tphn16ffcllgv18e_univ_170a/tphn16ffcllgv18e_univffgnp0p88v1p98vm40c.db

set io_ssgnp_p72v_125C_db_file   $io_base_path/Front_End/timing_power_noise/NLDM/tphn16ffcllgv18e_univ_170a/tphn16ffcllgv18e_univssgnp0p72v1p62v125c.db
set io_ssgnp_p72v_m40C_db_file   $io_base_path/Front_End/timing_power_noise/NLDM/tphn16ffcllgv18e_univ_170a/tphn16ffcllgv18e_univssgnp0p72v1p62vm40c.db
set io_tt_p80v_85C_db_file       $io_base_path/Front_End/timing_power_noise/NLDM/tphn16ffcllgv18e_univ_170a/tphn16ffcllgv18e_univtt0p8v1p8v85c.db
set io_tt_p80_25C_db_file        $io_base_path/Front_End/timing_power_noise/NLDM/tphn16ffcllgv18e_univ_170a/tphn16ffcllgv18e_univtt0p8v1p8v25c.db
set io_ffg_p88v_125c_db_file    $io_base_path/Front_End/timing_power_noise/NLDM/tphn16ffcllgv18e_univ_170a/tphn16ffcllgv18e_univffg0p88v1p98v125c.db


# Pad libs
set pad_mw_libs $pad_base_path/Back_End/milkyway/tpbn16ffc_univ_100a/wb/10m/10M_2XA1XD_H_4XE_VHVH_2Z/cell_frame/tpbn16ffc_univ_100a

# Create IO fusion library
create_fusion_lib -dbs [list \
    $io_ffgnp_p88v_125C_db_file \
    $io_ffgnp_p88v_m40C_db_file \
    $io_ssgnp_p72v_125C_db_file \
    $io_ssgnp_p72v_m40C_db_file \
    $io_tt_p80v_85C_db_file \
    $io_tt_p80_25C_db_file \
    $io_ffg_p88v_125c_db_file \
    ] -mw_libs $io_mw_libs io_lib
save_fusion_lib io_lib
redirect -tee -file ./io_lib.report {report_fusion_lib}
close_fusion_lib io_lib

create_fusion_lib -mw_libs $pad_mw_libs pad_lib
save_fusion_lib pad_lib
redirect -tee -file ./pad_lib.report {report_fusion_lib}
close_fusion_lib pad_lib
