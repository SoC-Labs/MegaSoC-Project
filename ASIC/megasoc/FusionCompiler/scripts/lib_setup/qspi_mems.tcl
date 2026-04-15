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

set flash_cache_tag_PATH           $env(SOCLABS_PROJECT_DIR)/memories/qspi/flash_cache_tag
set flash_cache_tag_lef_file       $flash_cache_tag_PATH/flash_cache_tag.lef
set flash_cache_tag_gds_file       $flash_cache_tag_PATH/flash_cache_tag.gds2

foreach corner $sram_corners {
    lappend flash_cache_tag_libs   flash_cache_tag_${corner}.lib
    lappend flash_cache_tag_dbs    $flash_cache_tag_PATH/flash_cache_tag_${corner}.db
    read_lib $flash_cache_tag_PATH/flash_cache_tag_${corner}.lib
    write_lib -output $flash_cache_tag_PATH/flash_cache_tag_${corner}.db -format db flash_cache_tag_${corner}
    close_lib -all
}

set flash_cache_data_PATH           $env(SOCLABS_PROJECT_DIR)/memories/qspi/flash_cache_data
set flash_cache_data_lef_file       $flash_cache_data_PATH/flash_cache_data.lef
set flash_cache_data_gds_file       $flash_cache_data_PATH/flash_cache_data.gds2

foreach corner $sram_corners {
    lappend flash_cache_data_libs   flash_cache_data_${corner}.lib
    lappend flash_cache_data_dbs    $flash_cache_data_PATH/flash_cache_data_${corner}.db
    read_lib $flash_cache_data_PATH/flash_cache_data_${corner}.lib
    write_lib -output $flash_cache_data_PATH/flash_cache_data_${corner}.db -format db flash_cache_data_${corner}
    close_lib -all
}


# Flash Cache Tag ram
create_fusion_lib -dbs $flash_cache_tag_dbs -lefs $flash_cache_tag_lef_file -technology $cln16fcll_tech_file flash_cache_tag
save_fusion_lib flash_cache_tag
close_fusion_lib flash_cache_tag

# Flash Cache Data ram
create_fusion_lib -dbs $flash_cache_data_dbs -lefs $flash_cache_data_lef_file -technology $cln16fcll_tech_file flash_cache_data
save_fusion_lib flash_cache_data
close_fusion_lib flash_cache_data

