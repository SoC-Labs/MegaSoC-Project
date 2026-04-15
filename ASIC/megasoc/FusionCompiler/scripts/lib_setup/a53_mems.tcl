# SRAM files (using Arm compiler)
set sram_corners [list \
    ffgnp_0p88v_0p88v_125c \
    ffgnp_0p88v_0p88v_m40c \
    ssgnp_0p72v_0p72v_125c \
    ssgnp_0p72v_0p72v_m40c \
    tt_0p80v_0p80v_85c \
    tt_0p72v_0p72v_0c \
    tt_0p80v_0p80v_25c \
    ]

set CA53_L2_DATA_PATH           $env(SOCLABS_PROJECT_DIR)/memories/A53/L2_DATA
set CA53_L2_Data_lef_file       $CA53_L2_DATA_PATH/L2_data.lef
set CA53_L2_Data_gds_file       $CA53_L2_DATA_PATH/L2_data.gds2

foreach corner $sram_corners {
    lappend CA53_L2_Data_libs   L2_data_${corner}.lib
    lappend CA53_L2_Data_dbs    $CA53_L2_DATA_PATH/L2_data_${corner}.db
    read_lib $CA53_L2_DATA_PATH/L2_data_${corner}.lib
    write_lib -output $CA53_L2_DATA_PATH/L2_data_${corner}.db -format db L2_data_sram_${corner}
    close_lib -all
}


set CA53_L2_TAG_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L2_TAG
set CA53_L2_TAG_lef_file        $CA53_L2_TAG_PATH/L2_tag.lef
set CA53_L2_TAG_gds_file        $CA53_L2_TAG_PATH/L2_tag.gds2

foreach corner $sram_corners {
    lappend CA53_L2_TAG_libs   L2_tag_${corner}.lib
    lappend CA53_L2_TAG_dbs    $CA53_L2_TAG_PATH/L2_tag_${corner}.db
    read_lib $CA53_L2_TAG_PATH/L2_tag_${corner}.lib
    write_lib -output $CA53_L2_TAG_PATH/L2_tag_${corner}.db -format db L2_tag_rf_${corner}
    close_lib -all
}

set CA53_L2_VICT_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L2_VICTIM
set CA53_L2_VICT_lef_file        $CA53_L2_VICT_PATH/L2_vict.lef
set CA53_L2_VICT_gds_file        $CA53_L2_VICT_PATH/L2_vict.gds2

foreach corner $sram_corners {
    lappend CA53_L2_VICT_libs   L2_vict_${corner}.lib
    lappend CA53_L2_VICT_dbs    $CA53_L2_VICT_PATH/L2_vict_${corner}.db
    read_lib $CA53_L2_VICT_PATH/L2_vict_${corner}.lib
    write_lib -output $CA53_L2_VICT_PATH/L2_vict_${corner}.db -format db L2_vict_rf_${corner}
    close_lib -all
}

set CA53_L1_TAG_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_TAG
set CA53_L1_TAG_lef_file        $CA53_L1_TAG_PATH/L1_tag.lef
set CA53_L1_TAG_gds_file        $CA53_L1_TAG_PATH/L1_tag.gds2

foreach corner $sram_corners {
    lappend CA53_L1_TAG_libs   L1_tag_${corner}.lib
    lappend CA53_L1_TAG_dbs    $CA53_L1_TAG_PATH/L1_tag_${corner}.db
    read_lib $CA53_L1_TAG_PATH/L1_tag_${corner}.lib
    write_lib -output $CA53_L1_TAG_PATH/L1_tag_${corner}.db -format db L1_tag_rf_${corner}
    close_lib -all
}

set CA53_L1_iDATA_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_iDATA
set CA53_L1_iDATA_lef_file        $CA53_L1_iDATA_PATH/L1_idata.lef
set CA53_L1_iDATA_gds_file        $CA53_L1_iDATA_PATH/L1_idata.gds2

foreach corner $sram_corners {
    lappend CA53_L1_iDATA_libs   L1_idata_${corner}.lib
    lappend CA53_L1_iDATA_dbs    $CA53_L1_iDATA_PATH/L1_idata_${corner}.db
    read_lib $CA53_L1_iDATA_PATH/L1_idata_${corner}.lib
    write_lib -output $CA53_L1_iDATA_PATH/L1_idata_${corner}.db -format db L1_idata_rf_${corner}
    close_lib -all
}

set CA53_L1_iTAG_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_iTAG
set CA53_L1_iTAG_lef_file        $CA53_L1_iTAG_PATH/L1_itag.lef
set CA53_L1_iTAG_gds_file        $CA53_L1_iTAG_PATH/L1_itag.gds2

foreach corner $sram_corners {
    lappend CA53_L1_iTAG_libs   L1_itag_${corner}.lib
    lappend CA53_L1_iTAG_dbs    $CA53_L1_iTAG_PATH/L1_itag_${corner}.db
    read_lib $CA53_L1_iTAG_PATH/L1_itag_${corner}.lib
    write_lib -output $CA53_L1_iTAG_PATH/L1_itag_${corner}.db -format db L1_itag_rf_${corner}
    close_lib -all
}

set CA53_L1_dDATA_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_dDATA
set CA53_L1_dDATA_lef_file        $CA53_L1_dDATA_PATH/L1_ddata.lef
set CA53_L1_dDATA_gds_file        $CA53_L1_dDATA_PATH/L1_ddata.gds2

foreach corner $sram_corners {
    lappend CA53_L1_dDATA_libs   L1_ddata_${corner}.lib
    lappend CA53_L1_dDATA_dbs    $CA53_L1_dDATA_PATH/L1_ddata_${corner}.db
    read_lib $CA53_L1_dDATA_PATH/L1_ddata_${corner}.lib
    write_lib -output $CA53_L1_dDATA_PATH/L1_ddata_${corner}.db -format db L1_ddata_rf_${corner}
    close_lib -all
}


set CA53_L1_dTAG_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_dTAG
set CA53_L1_dTAG_lef_file        $CA53_L1_dTAG_PATH/L1_dtag.lef
set CA53_L1_dTAG_gds_file        $CA53_L1_dTAG_PATH/L1_dtag.gds2

foreach corner $sram_corners {
    lappend CA53_L1_dTAG_libs   L1_dtag_${corner}.lib
    lappend CA53_L1_dTAG_dbs    $CA53_L1_dTAG_PATH/L1_dtag_${corner}.db
    read_lib $CA53_L1_dTAG_PATH/L1_dtag_${corner}.lib
    write_lib -output $CA53_L1_dTAG_PATH/L1_dtag_${corner}.db -format db L1_dtag_rf_${corner}
    close_lib -all
}

set CA53_L1_dDIRTY_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_dDIRTY
set CA53_L1_dDIRTY_lef_file        $CA53_L1_dDIRTY_PATH/L1_ddirty.lef
set CA53_L1_dDIRTY_gds_file        $CA53_L1_dDIRTY_PATH/L1_ddirty.gds2

foreach corner $sram_corners {
    lappend CA53_L1_dDIRTY_libs   L1_ddirty_${corner}.lib
    lappend CA53_L1_dDIRTY_dbs    $CA53_L1_dDIRTY_PATH/L1_ddirty_${corner}.db
    read_lib $CA53_L1_dDIRTY_PATH/L1_ddirty_${corner}.lib
    write_lib -output $CA53_L1_dDIRTY_PATH/L1_ddirty_${corner}.db -format db L1_ddirty_rf_${corner}
    close_lib -all
}

set CA53_L1_TLB_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_TLB
set CA53_L1_TLB_lef_file        $CA53_L1_TLB_PATH/L1_tlb.lef
set CA53_L1_TLB_gds_file        $CA53_L1_TLB_PATH/L1_tlb.gds2

foreach corner $sram_corners {
    lappend CA53_L1_TLB_libs   L1_tlb_${corner}.lib
    lappend CA53_L1_TLB_dbs    $CA53_L1_TLB_PATH/L1_tlb_${corner}.db
    read_lib $CA53_L1_TLB_PATH/L1_tlb_${corner}.lib
    write_lib -output $CA53_L1_TLB_PATH/L1_tlb_${corner}.db -format db L1_tlb_rf_${corner}
    close_lib -all
}

set CA53_L1_BTAC1_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_BTAC1
set CA53_L1_BTAC1_lef_file        $CA53_L1_BTAC1_PATH/L1_btac1.lef
set CA53_L1_BTAC1_gds_file        $CA53_L1_BTAC1_PATH/L1_btac1.gds2

foreach corner $sram_corners {
    lappend CA53_L1_BTAC1_libs   L1_btac1_${corner}.lib
    lappend CA53_L1_BTAC1_dbs    $CA53_L1_BTAC1_PATH/L1_btac1_${corner}.db
    read_lib $CA53_L1_BTAC1_PATH/L1_btac1_${corner}.lib
    write_lib -output $CA53_L1_BTAC1_PATH/L1_btac1_${corner}.db -format db L1_btac1_rf_${corner}
    close_lib -all
}


set CA53_L1_BTAC2_PATH            $env(SOCLABS_PROJECT_DIR)/memories/A53/L1_BTAC2
set CA53_L1_BTAC2_lef_file        $CA53_L1_BTAC2_PATH/L1_btac2.lef
set CA53_L1_BTAC2_gds_file        $CA53_L1_BTAC2_PATH/L1_btac2.gds2

foreach corner $sram_corners {
    lappend CA53_L1_BTAC2_libs   L1_btac2_${corner}.lib
    lappend CA53_L1_BTAC2_dbs    $CA53_L1_BTAC2_PATH/L1_btac2_${corner}.db
    read_lib $CA53_L1_BTAC2_PATH/L1_btac2_${corner}.lib
    write_lib -output $CA53_L1_BTAC2_PATH/L1_btac2_${corner}.db -format db L1_btac2_rf_${corner}
    close_lib -all
}


# L1 BTAC 2 RF SRAM
create_fusion_lib -dbs $CA53_L1_BTAC2_dbs -lefs $CA53_L1_BTAC2_lef_file -technology $cln16fcll_tech_file CA53_L1_btac2
save_fusion_lib CA53_L1_btac2
close_fusion_lib CA53_L1_btac2

# L1 BTAC 1 RF SRAM
create_fusion_lib -dbs  $CA53_L1_BTAC1_dbs -lefs $CA53_L1_BTAC1_lef_file -technology $cln16fcll_tech_file CA53_L1_btac1
save_fusion_lib CA53_L1_btac1
close_fusion_lib CA53_L1_btac1

# L1 TLB RF SRAM
create_fusion_lib -dbs  $CA53_L1_TLB_dbs -lefs $CA53_L1_TLB_lef_file -technology $cln16fcll_tech_file CA53_L1_tlb
save_fusion_lib CA53_L1_tlb
close_fusion_lib CA53_L1_tlb

# L1 Data DIRTY RF SRAM
create_fusion_lib -dbs  $CA53_L1_dDIRTY_dbs -lefs $CA53_L1_dDIRTY_lef_file -technology $cln16fcll_tech_file CA53_L1_dirty
save_fusion_lib CA53_L1_dirty
close_fusion_lib CA53_L1_dirty

# L1 Data TAG RF SRAM
create_fusion_lib -dbs  $CA53_L1_dTAG_dbs -lefs $CA53_L1_dTAG_lef_file -technology $cln16fcll_tech_file CA53_L1_dtag
save_fusion_lib CA53_L1_dtag
close_fusion_lib CA53_L1_dtag

# L1 Data DATA RF SRAM
create_fusion_lib -dbs  $CA53_L1_dDATA_dbs -lefs $CA53_L1_dDATA_lef_file -technology $cln16fcll_tech_file CA53_L1_ddata
save_fusion_lib CA53_L1_ddata
close_fusion_lib CA53_L1_ddata

# L1 Instruction TAG RF SRAM
create_fusion_lib -dbs  $CA53_L1_iTAG_dbs -lefs $CA53_L1_iTAG_lef_file -technology $cln16fcll_tech_file CA53_L1_itag
save_fusion_lib CA53_L1_itag
close_fusion_lib CA53_L1_itag

# L1 Instruction Data RF SRAM
create_fusion_lib -dbs  $CA53_L1_iDATA_dbs -lefs $CA53_L1_iDATA_lef_file -technology $cln16fcll_tech_file CA53_L1_idata
save_fusion_lib CA53_L1_idata
close_fusion_lib CA53_L1_idata

# L1 TAG RF SRAM
create_fusion_lib -dbs  $CA53_L1_TAG_dbs -lefs $CA53_L1_TAG_lef_file -technology $cln16fcll_tech_file CA53_L1_tag
save_fusion_lib CA53_L1_tag
close_fusion_lib CA53_L1_tag

# L2 Victim SRAM
create_fusion_lib -dbs  $CA53_L2_VICT_dbs -lefs $CA53_L2_VICT_lef_file -technology $cln16fcll_tech_file CA53_L2_vict
save_fusion_lib CA53_L2_vict
close_fusion_lib CA53_L2_vict


# L2 Tag SRAM
create_fusion_lib -dbs  $CA53_L2_TAG_dbs -lefs $CA53_L2_TAG_lef_file -technology $cln16fcll_tech_file CA53_L2_tag
save_fusion_lib CA53_L2_tag
close_fusion_lib CA53_L2_tag

# L2 Data SRAM
create_fusion_lib -dbs  $CA53_L2_Data_dbs -lefs $CA53_L2_Data_lef_file -technology $cln16fcll_tech_file CA53_L2_data
save_fusion_lib CA53_L2_data
close_fusion_lib CA53_L2_data

