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

set megasoc_sram_path           $env(SOCLABS_PROJECT_DIR)/memories/megasoc/sram
set megasoc_sram_lef_file       $megasoc_sram_path/sram_64b_16k.lef
set megasoc_sram_gds_file       $megasoc_sram_path/sram_64b_16k.gds2

foreach corner $sram_corners {
    lappend megasoc_sram_libs   sram_64b_16k_${corner}.lib
    lappend megasoc_sram_dbs    $megasoc_sram_path/sram_64b_16k_${corner}.db
    read_lib $megasoc_sram_path/sram_64b_16k_${corner}.lib
    write_lib -output $megasoc_sram_path/sram_64b_16k_${corner}.db -format db sram_${corner}
    close_lib -all
}

set megasoc_bootrom_path           $env(SOCLABS_PROJECT_DIR)/memories/megasoc/bootrom
set megasoc_bootrom_lef_file       $megasoc_bootrom_path/bootrom.lef
set megasoc_bootrom_gds_file       $megasoc_bootrom_path/bootrom.gds2

foreach corner $sram_corners {
    lappend megasoc_bootrom_libs   bootrom_${corner}.lib_ecsm_t
    lappend megasoc_bootrom_dbs    $megasoc_bootrom_path/bootrom_${corner}.db
    read_lib $megasoc_bootrom_path/bootrom_${corner}.lib_ecsm_t
    write_lib -output $megasoc_bootrom_path/bootrom_${corner}.db -format db rom_via_hdd_${corner}
    close_lib -all
}


# Megasoc SRAM
create_fusion_lib -dbs  $megasoc_sram_dbs -lefs $megasoc_sram_lef_file -technology $cln16fcll_tech_file megasoc_sram
save_fusion_lib megasoc_sram
close_fusion_lib megasoc_sram

# Megasoc Bootrom
create_fusion_lib -dbs  $megasoc_bootrom_dbs -lefs $megasoc_bootrom_lef_file -technology $cln16fcll_tech_file megasoc_bootrom
save_fusion_lib megasoc_bootrom
close_fusion_lib megasoc_bootrom
