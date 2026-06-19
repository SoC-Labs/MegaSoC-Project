## Paths Please Edit for your system
set_app_options -name lib.setting.milkyway_exec -value /home/dwn1c21/Synopsys/mw/T-2022.03-SP2/bin/AMD.64/Milkyway

set cln16fcll_tech_file         $env(TSMC_16_HOME)/CMOS/FFC_UNIV/util/apr/TN16CLPR001S1_1_7_1A/PRTF_ICC2_16nm_001_Syn_V17_1a/PRTF_ICC2_N16_10M_2Xa1Xd4Xe2Z_UTRDL_9T_PODE.17_1a.tf

set standard_cell_base_path     $env(TSMC_16_HOME)/CMOS/FFC_UNIV/stclib/tcbn16ffcllbwp20p90_100b/TSMCHOME/digital
set lvl_base_path               $env(TSMC_16_HOME)/CMOS/FFC_UNIV/stclib/tcbn16ffcllbwp20p90lvl_110a/TSMCHOME/digital
set mb_base_path                $env(TSMC_16_HOME)/CMOS/FFC_UNIV/stclib/tcbn16ffcllbwp20p90mb_110b/TSMCHOME/digital
set pm_base_path                $env(TSMC_16_HOME)/CMOS/FFC_UNIV/stclib/tcbn16ffcllbwp20p90pm_170b/TSMCHOME/digital

set Synopsys_LPDDR4_V2_PHY_path /home/dwn1c21/SoC-Labs/Synopsys_ip/LPDDR4-m-PHY-V2_TSMC_16FFC/synopsys/dwc_lpddr4_multiphy_v2_tsmc16ffc18/Latest

set io_base_path    $env(TSMC_16_HOME)/CMOS/FFC_UNIV/iolib/tphn16ffcllgv18e_univ_170b/TSMCHOME/digital
set pad_base_path   $env(TSMC_16_HOME)/CMOS/FFC_UNIV/iolib/tpbn16ffc_univ_100a/TSMCHOME/digital

source ../scripts/lib_setup/standard_cells.tcl
source ../scripts/lib_setup/lvl_lib.tcl
source ../scripts/lib_setup/mb_lib.tcl
source ../scripts/lib_setup/pm_lib.tcl
source ../scripts/lib_setup/a53_mems.tcl
source ../scripts/lib_setup/megasoc_mems.tcl
source ../scripts/lib_setup/qspi_mems.tcl
source ../scripts/lib_setup/Synopsys_libs.tcl
source ../scripts/lib_setup/io_libs.tcl

exit