## Paths Please Edit for your system
set cln16fcll_tech_path         /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/arm_tech/r3p0
set tech_file         $env(TSMC_16_HOME)/CMOS/FFC_UNIV/util/apr/TN16CLPR001S1_1_7_1A/PRTF_ICC2_16nm_001_Syn_V17_1a/PRTF_ICC2_N16_10M_2Xa1Xd4Xe2Z_UTRDL_9T_PODE.17_1a.tf


set REPORT_DIR ../reports
set LOG_DIR ../logs
set OUT_DIR ../outputs

# megaSoC Specifics - don't edit
set file_tcl_list $env(SOCLABS_PROJECT_DIR)/imp/ASIC/megasoc/flist/megasoc_fc_flist.tcl
set top_level_verilog $env(SOCLABS_PROJECT_DIR)/megasoc_chip/pads/cln16fcll/logical/megasoc_chip_pads.v
# Variables used in scripts
set lib_name megasoc_chip_pads
set block_name megasoc_chip_pads

set lib_path_list [list \
    ../libs/CA53_L1_btac1 \
    ../libs/CA53_L1_btac2 \
    ../libs/CA53_L1_ddata \
    ../libs/CA53_L1_dirty \
    ../libs/CA53_L1_dtag \
    ../libs/CA53_L1_idata \
    ../libs/CA53_L1_itag \
    ../libs/CA53_L1_tag \
    ../libs/CA53_L1_tlb \
    ../libs/CA53_L2_data \
    ../libs/CA53_L2_tag \
    ../libs/CA53_L2_vict \
    ../libs/cln16fcll \
    ../libs/cln16fcll_lvl \
    ../libs/cln16fcll_mb \
    ../libs/cln16fcll_pm \
    ../libs/ddrphy_acx4 \
    ../libs/ddrphy_dbyte \
    ../libs/ddrphy_master \
    ../libs/ddrphy_utility_cells \
    ../libs/io_lib \
    ../libs/megasoc_bootrom \
    ../libs/megasoc_sram \
    ../libs/pad_lib \
]

set lib_list [list \
    CA53_L1_btac1 \
    CA53_L1_btac2 \
    CA53_L1_ddata \
    CA53_L1_dirty \
    CA53_L1_dtag \
    CA53_L1_idata \
    CA53_L1_itag \
    CA53_L1_tag \
    CA53_L1_tlb \
    CA53_L2_data \
    CA53_L2_tag \
    CA53_L2_vict \
    cln16fcll \
    cln16fcll_lvl \
    cln16fcll_mb \
    cln16fcll_pm \
    ddrphy_acx4 \
    ddrphy_dbyte \
    ddrphy_master \
    ddrphy_utility_cells \
    io_lib \
    megasoc_bootrom \
    megasoc_sram \
    pad_lib \
]


# Libary files for formality

