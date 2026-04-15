
set synopsys_corners [list \
    ff0p88v125c_cbest_CCbest_pg \
    ff0p88v125c_cworst_CCworst_pg \
    ff0p88v125c_rcbest_CCbest_pg \
    ff0p88v125c_rcworst_CCworst_pg \
    ff0p88vn40c_cbest_CCbest_pg \
    ff0p88vn40c_cworst_CCworst_pg \
    ff0p88vn40c_rcbest_CCbest_pg \
    ff0p88vn40c_rcworst_CCworst_pg \
    ss0p72v125c_cbest_CCbest_pg \
    ss0p72v125c_cworst_CCworst_pg \
    ss0p72v125c_rcbest_CCbest_pg \
    ss0p72v125c_rcworst_CCworst_pg \
    ss0p72vn40c_cbest_CCbest_pg \
    ss0p72vn40c_cworst_CCworst_pg \
    ss0p72vn40c_rcbest_CCbest_pg \
    ss0p72vn40c_rcworst_CCworst_pg \
    tt0p8v25c_typical_pg \
    ]

set synopsys_utility_corners [list \
    ff0p88v125c_pg \
    ff0p88vn40c_pg \
    ss0p72v125c_pg \
    ss0p72vn40c_pg \
    tt0p8v25c_pg \
    ]



set acx4_ew_lef_file $Synopsys_LPDDR4_V2_PHY_path/acx4_ew/Latest/lef/7M_2Xa1Xd_h_3Xe_vhv/dwc_ddrphyacx4_top_ew_merged.lef
foreach corner $synopsys_corners {
    lappend acx4_libs_list    $Synopsys_LPDDR4_V2_PHY_path/acx4_ew/Latest/timing/7M_2Xa1Xd_h_3Xe_vhv/lib_pg/dwc_ddrphyacx4_top_ew_${corner}.db
}

set dbyte_ew_lef_file $Synopsys_LPDDR4_V2_PHY_path/dbyte_ew/Latest/lef/7M_2Xa1Xd_h_3Xe_vhv/dwc_ddrphydbyte_top_ew_merged.lef
foreach corner $synopsys_corners {
    lappend dbyte_libs_list    $Synopsys_LPDDR4_V2_PHY_path/dbyte_ew/Latest/timing/7M_2Xa1Xd_h_3Xe_vhv/lib_pg/dwc_ddrphydbyte_top_ew_${corner}.db
}

set master_lef_file $Synopsys_LPDDR4_V2_PHY_path/master/Latest/lef/7M_2Xa1Xd_h_3Xe_vhv/dwc_ddrphymaster_top_merged.lef
foreach corner $synopsys_corners {
    lappend master_libs_list    $Synopsys_LPDDR4_V2_PHY_path/master/Latest/timing/7M_2Xa1Xd_h_3Xe_vhv/lib_pg/dwc_ddrphymaster_top_${corner}.db
}

set utility_cells_lef_file $Synopsys_LPDDR4_V2_PHY_path/utility_cells/Latest/lef/7M_2Xa1Xd_h_3Xe_vhv/dwc_ddrphy_utility_cells_merged.lef
foreach corner $synopsys_utility_corners {
    lappend utility_cells_libs_list    $Synopsys_LPDDR4_V2_PHY_path/utility_cells/Latest/timing/7M_2Xa1Xd_h_3Xe_vhv/lib_pg/dwc_ddrphy_utility_cells_${corner}.db
}

# Synopsys LPDDR4 v2 PHY ACX4
create_fusion_lib -dbs  $acx4_libs_list -lefs $acx4_ew_lef_file -technology $cln16fcll_tech_file ddrphy_acx4
save_fusion_lib ddrphy_acx4
close_fusion_lib ddrphy_acx4

# Synopsys LPDDR4 v2 PHY DBYTE
create_fusion_lib -dbs  $dbyte_libs_list -lefs $dbyte_ew_lef_file -technology $cln16fcll_tech_file ddrphy_dbyte
save_fusion_lib ddrphy_dbyte
close_fusion_lib ddrphy_dbyte

# Synopsys LPDDR4 v2 PHY Master
create_fusion_lib -dbs  $master_libs_list -lefs $master_lef_file -technology $cln16fcll_tech_file ddrphy_master
save_fusion_lib ddrphy_master
close_fusion_lib ddrphy_master

# Synopsys LPDDR4 v2 PHY Utility cells
create_fusion_lib -dbs  $utility_cells_libs_list -lefs $utility_cells_lef_file -technology $cln16fcll_tech_file ddrphy_utility_cells
save_fusion_lib ddrphy_utility_cells
close_fusion_lib ddrphy_utility_cells
