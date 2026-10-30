###############################################################################
# HAPS-SX VU19P - on-board DDR4 SODIMM for the MegaSoC build (build 58, MGSOC-34 step 2)
#
# Pins: SoC-Labs-HAPS-SX-Tools iomap_csv_rev0b/pinfile.csv, DDR4 section (banks 29/30/31 = clock
# regions X0Y10-X0Y12, SLR2). Same 123 pins and I/O standards as the step-1 example design that
# calibrated and ran error-free on this board on 28 Oct 2026 (ddr4/haps_sx_ddr4_pins.xdc), with the
# top-level port names of haps_top.sv. The older haps-sx_vu19p.def lists ACT_N on CA49 (= FLASH_CLK):
# wrong, the CSV's AE48 is used.
#
# Implementation only (like haps_top_clocks_impl.xdc): the DDR4 IP's own constraints create the
# 299.85 MHz reference clock "c0_sys_clk_p" and its MMCM/PLL children; nothing here is needed in
# synthesis.
#
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
# Contributors: Anastasios Dimitriou (ad1u25@soton.ac.uk)
###############################################################################


set_property -dict {PACKAGE_PIN AF52 IOSTANDARD DIFF_SSTL12} [get_ports {DDR4_SYS_CLK_N}]   ;# C0_SYS_CLK_N bank 30
set_property -dict {PACKAGE_PIN AF51 IOSTANDARD DIFF_SSTL12} [get_ports {DDR4_SYS_CLK_P}]   ;# C0_SYS_CLK_P bank 30
set_property -dict {PACKAGE_PIN AE48 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ACT_n}]   ;# DDR4_ACT_N bank 30
set_property -dict {PACKAGE_PIN AG56 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[0]}]   ;# DDR4_ADDR[0] bank 30
set_property -dict {PACKAGE_PIN AG57 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[1]}]   ;# DDR4_ADDR[1] bank 30
set_property -dict {PACKAGE_PIN AE54 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[2]}]   ;# DDR4_ADDR[2] bank 30
set_property -dict {PACKAGE_PIN AE55 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[3]}]   ;# DDR4_ADDR[3] bank 30
set_property -dict {PACKAGE_PIN AE57 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[4]}]   ;# DDR4_ADDR[4] bank 30
set_property -dict {PACKAGE_PIN AD57 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[5]}]   ;# DDR4_ADDR[5] bank 30
set_property -dict {PACKAGE_PIN AD55 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[6]}]   ;# DDR4_ADDR[6] bank 30
set_property -dict {PACKAGE_PIN AD56 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[7]}]   ;# DDR4_ADDR[7] bank 30
set_property -dict {PACKAGE_PIN AH53 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[8]}]   ;# DDR4_ADDR[8] bank 30
set_property -dict {PACKAGE_PIN AH54 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[9]}]   ;# DDR4_ADDR[9] bank 30
set_property -dict {PACKAGE_PIN AD52 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[10]}]   ;# DDR4_ADDR[10] bank 30
set_property -dict {PACKAGE_PIN AD53 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[11]}]   ;# DDR4_ADDR[11] bank 30
set_property -dict {PACKAGE_PIN AG53 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[12]}]   ;# DDR4_ADDR[12] bank 30
set_property -dict {PACKAGE_PIN AG54 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[13]}]   ;# DDR4_ADDR[13] bank 30
set_property -dict {PACKAGE_PIN AE52 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[14]}]   ;# DDR4_ADDR[14] bank 30
set_property -dict {PACKAGE_PIN AE53 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[15]}]   ;# DDR4_ADDR[15] bank 30
set_property -dict {PACKAGE_PIN AG51 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ADR[16]}]   ;# DDR4_ADDR[16] bank 30
set_property -dict {PACKAGE_PIN AG52 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_BA[0]}]   ;# DDR4_BA[0] bank 30
set_property -dict {PACKAGE_PIN AG46 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_BA[1]}]   ;# DDR4_BA[1] bank 30
set_property -dict {PACKAGE_PIN AG47 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_BG[0]}]   ;# DDR4_BG[0] bank 30
set_property -dict {PACKAGE_PIN AH44 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_BG[1]}]   ;# DDR4_BG[1] bank 30
set_property -dict {PACKAGE_PIN AF47 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_CKE[0]}]   ;# DDR4_CKE[0] bank 30
set_property -dict {PACKAGE_PIN AF45 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_CKE[1]}]   ;# DDR4_CKE[1] bank 30
set_property -dict {PACKAGE_PIN AH56 IOSTANDARD DIFF_SSTL12_DCI} [get_ports {DDR4_CK_C[0]}]   ;# DDR4_CK_C[0] bank 30
set_property -dict {PACKAGE_PIN AF57 IOSTANDARD DIFF_SSTL12_DCI} [get_ports {DDR4_CK_C[1]}]   ;# DDR4_CK_C[1] bank 30
set_property -dict {PACKAGE_PIN AH55 IOSTANDARD DIFF_SSTL12_DCI} [get_ports {DDR4_CK_T[0]}]   ;# DDR4_CK_T[0] bank 30
set_property -dict {PACKAGE_PIN AF56 IOSTANDARD DIFF_SSTL12_DCI} [get_ports {DDR4_CK_T[1]}]   ;# DDR4_CK_T[1] bank 30
set_property -dict {PACKAGE_PIN AG44 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_CS_N[0]}]   ;# DDR4_CS_N[0] bank 30
set_property -dict {PACKAGE_PIN AF46 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_CS_N[1]}]   ;# DDR4_CS_N[1] bank 30
set_property -dict {PACKAGE_PIN AB61 IOSTANDARD POD12_DCI} [get_ports {DDR4_DM_DBI_N[0]}]   ;# DDR4_DM_DBI_N[0] bank 31
set_property -dict {PACKAGE_PIN W60 IOSTANDARD POD12_DCI} [get_ports {DDR4_DM_DBI_N[1]}]   ;# DDR4_DM_DBI_N[1] bank 31
set_property -dict {PACKAGE_PIN AH58 IOSTANDARD POD12_DCI} [get_ports {DDR4_DM_DBI_N[2]}]   ;# DDR4_DM_DBI_N[2] bank 31
set_property -dict {PACKAGE_PIN AE59 IOSTANDARD POD12_DCI} [get_ports {DDR4_DM_DBI_N[3]}]   ;# DDR4_DM_DBI_N[3] bank 31
set_property -dict {PACKAGE_PIN AN55 IOSTANDARD POD12_DCI} [get_ports {DDR4_DM_DBI_N[4]}]   ;# DDR4_DM_DBI_N[4] bank 29
set_property -dict {PACKAGE_PIN AM51 IOSTANDARD POD12_DCI} [get_ports {DDR4_DM_DBI_N[5]}]   ;# DDR4_DM_DBI_N[5] bank 29
set_property -dict {PACKAGE_PIN AL49 IOSTANDARD POD12_DCI} [get_ports {DDR4_DM_DBI_N[6]}]   ;# DDR4_DM_DBI_N[6] bank 29
set_property -dict {PACKAGE_PIN AL47 IOSTANDARD POD12_DCI} [get_ports {DDR4_DM_DBI_N[7]}]   ;# DDR4_DM_DBI_N[7] bank 29
set_property -dict {PACKAGE_PIN AA60 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[0]}]   ;# DDR4_DQ[0] bank 31
set_property -dict {PACKAGE_PIN AB59 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[1]}]   ;# DDR4_DQ[1] bank 31
set_property -dict {PACKAGE_PIN AA62 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[2]}]   ;# DDR4_DQ[2] bank 31
set_property -dict {PACKAGE_PIN AA61 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[3]}]   ;# DDR4_DQ[3] bank 31
set_property -dict {PACKAGE_PIN AB58 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[4]}]   ;# DDR4_DQ[4] bank 31
set_property -dict {PACKAGE_PIN AA59 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[5]}]   ;# DDR4_DQ[5] bank 31
set_property -dict {PACKAGE_PIN Y63 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[6]}]   ;# DDR4_DQ[6] bank 31
set_property -dict {PACKAGE_PIN Y62 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[7]}]   ;# DDR4_DQ[7] bank 31
set_property -dict {PACKAGE_PIN V58 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[8]}]   ;# DDR4_DQ[8] bank 31
set_property -dict {PACKAGE_PIN U61 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[9]}]   ;# DDR4_DQ[9] bank 31
set_property -dict {PACKAGE_PIN W62 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[10]}]   ;# DDR4_DQ[10] bank 31
set_property -dict {PACKAGE_PIN U63 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[11]}]   ;# DDR4_DQ[11] bank 31
set_property -dict {PACKAGE_PIN V59 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[12]}]   ;# DDR4_DQ[12] bank 31
set_property -dict {PACKAGE_PIN U62 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[13]}]   ;# DDR4_DQ[13] bank 31
set_property -dict {PACKAGE_PIN V63 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[14]}]   ;# DDR4_DQ[14] bank 31
set_property -dict {PACKAGE_PIN W63 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[15]}]   ;# DDR4_DQ[15] bank 31
set_property -dict {PACKAGE_PIN AF59 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[16]}]   ;# DDR4_DQ[16] bank 31
set_property -dict {PACKAGE_PIN AF60 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[17]}]   ;# DDR4_DQ[17] bank 31
set_property -dict {PACKAGE_PIN AG58 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[18]}]   ;# DDR4_DQ[18] bank 31
set_property -dict {PACKAGE_PIN AF61 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[19]}]   ;# DDR4_DQ[19] bank 31
set_property -dict {PACKAGE_PIN AF62 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[20]}]   ;# DDR4_DQ[20] bank 31
set_property -dict {PACKAGE_PIN AE62 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[21]}]   ;# DDR4_DQ[21] bank 31
set_property -dict {PACKAGE_PIN AG59 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[22]}]   ;# DDR4_DQ[22] bank 31
set_property -dict {PACKAGE_PIN AG61 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[23]}]   ;# DDR4_DQ[23] bank 31
set_property -dict {PACKAGE_PIN AC61 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[24]}]   ;# DDR4_DQ[24] bank 31
set_property -dict {PACKAGE_PIN AC60 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[25]}]   ;# DDR4_DQ[25] bank 31
set_property -dict {PACKAGE_PIN AD60 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[26]}]   ;# DDR4_DQ[26] bank 31
set_property -dict {PACKAGE_PIN AD61 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[27]}]   ;# DDR4_DQ[27] bank 31
set_property -dict {PACKAGE_PIN AC58 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[28]}]   ;# DDR4_DQ[28] bank 31
set_property -dict {PACKAGE_PIN AC59 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[29]}]   ;# DDR4_DQ[29] bank 31
set_property -dict {PACKAGE_PIN AD63 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[30]}]   ;# DDR4_DQ[30] bank 31
set_property -dict {PACKAGE_PIN AD62 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[31]}]   ;# DDR4_DQ[31] bank 31
set_property -dict {PACKAGE_PIN AJ55 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[32]}]   ;# DDR4_DQ[32] bank 29
set_property -dict {PACKAGE_PIN AL54 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[33]}]   ;# DDR4_DQ[33] bank 29
set_property -dict {PACKAGE_PIN AL55 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[34]}]   ;# DDR4_DQ[34] bank 29
set_property -dict {PACKAGE_PIN AL56 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[35]}]   ;# DDR4_DQ[35] bank 29
set_property -dict {PACKAGE_PIN AJ56 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[36]}]   ;# DDR4_DQ[36] bank 29
set_property -dict {PACKAGE_PIN AM54 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[37]}]   ;# DDR4_DQ[37] bank 29
set_property -dict {PACKAGE_PIN AN54 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[38]}]   ;# DDR4_DQ[38] bank 29
set_property -dict {PACKAGE_PIN AM56 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[39]}]   ;# DDR4_DQ[39] bank 29
set_property -dict {PACKAGE_PIN AK53 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[40]}]   ;# DDR4_DQ[40] bank 29
set_property -dict {PACKAGE_PIN AJ52 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[41]}]   ;# DDR4_DQ[41] bank 29
set_property -dict {PACKAGE_PIN AN53 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[42]}]   ;# DDR4_DQ[42] bank 29
set_property -dict {PACKAGE_PIN AM53 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[43]}]   ;# DDR4_DQ[43] bank 29
set_property -dict {PACKAGE_PIN AK52 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[44]}]   ;# DDR4_DQ[44] bank 29
set_property -dict {PACKAGE_PIN AJ53 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[45]}]   ;# DDR4_DQ[45] bank 29
set_property -dict {PACKAGE_PIN AL51 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[46]}]   ;# DDR4_DQ[46] bank 29
set_property -dict {PACKAGE_PIN AL52 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[47]}]   ;# DDR4_DQ[47] bank 29
set_property -dict {PACKAGE_PIN AK50 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[48]}]   ;# DDR4_DQ[48] bank 29
set_property -dict {PACKAGE_PIN AK49 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[49]}]   ;# DDR4_DQ[49] bank 29
set_property -dict {PACKAGE_PIN AJ47 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[50]}]   ;# DDR4_DQ[50] bank 29
set_property -dict {PACKAGE_PIN AN48 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[51]}]   ;# DDR4_DQ[51] bank 29
set_property -dict {PACKAGE_PIN AM49 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[52]}]   ;# DDR4_DQ[52] bank 29
set_property -dict {PACKAGE_PIN AN49 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[53]}]   ;# DDR4_DQ[53] bank 29
set_property -dict {PACKAGE_PIN AK47 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[54]}]   ;# DDR4_DQ[54] bank 29
set_property -dict {PACKAGE_PIN AM48 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[55]}]   ;# DDR4_DQ[55] bank 29
set_property -dict {PACKAGE_PIN AL44 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[56]}]   ;# DDR4_DQ[56] bank 29
set_property -dict {PACKAGE_PIN AM46 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[57]}]   ;# DDR4_DQ[57] bank 29
set_property -dict {PACKAGE_PIN AN46 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[58]}]   ;# DDR4_DQ[58] bank 29
set_property -dict {PACKAGE_PIN AN44 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[59]}]   ;# DDR4_DQ[59] bank 29
set_property -dict {PACKAGE_PIN AJ45 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[60]}]   ;# DDR4_DQ[60] bank 29
set_property -dict {PACKAGE_PIN AJ46 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[61]}]   ;# DDR4_DQ[61] bank 29
set_property -dict {PACKAGE_PIN AN45 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[62]}]   ;# DDR4_DQ[62] bank 29
set_property -dict {PACKAGE_PIN AM44 IOSTANDARD POD12_DCI} [get_ports {DDR4_DQ[63]}]   ;# DDR4_DQ[63] bank 29
set_property -dict {PACKAGE_PIN Y60 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_C[0]}]   ;# DDR4_DQS_C[0] bank 31
set_property -dict {PACKAGE_PIN V61 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_C[1]}]   ;# DDR4_DQS_C[1] bank 31
set_property -dict {PACKAGE_PIN AG63 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_C[2]}]   ;# DDR4_DQS_C[2] bank 31
set_property -dict {PACKAGE_PIN AB63 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_C[3]}]   ;# DDR4_DQS_C[3] bank 31
set_property -dict {PACKAGE_PIN AK55 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_C[4]}]   ;# DDR4_DQS_C[4] bank 29
set_property -dict {PACKAGE_PIN AJ51 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_C[5]}]   ;# DDR4_DQS_C[5] bank 29
set_property -dict {PACKAGE_PIN AK48 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_C[6]}]   ;# DDR4_DQS_C[6] bank 29
set_property -dict {PACKAGE_PIN AK45 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_C[7]}]   ;# DDR4_DQS_C[7] bank 29
set_property -dict {PACKAGE_PIN Y59 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_T[0]}]   ;# DDR4_DQS_T[0] bank 31
set_property -dict {PACKAGE_PIN V60 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_T[1]}]   ;# DDR4_DQS_T[1] bank 31
set_property -dict {PACKAGE_PIN AG62 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_T[2]}]   ;# DDR4_DQS_T[2] bank 31
set_property -dict {PACKAGE_PIN AC63 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_T[3]}]   ;# DDR4_DQS_T[3] bank 31
set_property -dict {PACKAGE_PIN AK54 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_T[4]}]   ;# DDR4_DQS_T[4] bank 29
set_property -dict {PACKAGE_PIN AJ50 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_T[5]}]   ;# DDR4_DQS_T[5] bank 29
set_property -dict {PACKAGE_PIN AJ48 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_T[6]}]   ;# DDR4_DQS_T[6] bank 29
set_property -dict {PACKAGE_PIN AK44 IOSTANDARD DIFF_POD12_DCI} [get_ports {DDR4_DQS_T[7]}]   ;# DDR4_DQS_T[7] bank 29
set_property -dict {PACKAGE_PIN AE45 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ODT[0]}]   ;# DDR4_ODT[0] bank 30
set_property -dict {PACKAGE_PIN AE47 IOSTANDARD SSTL12_DCI} [get_ports {DDR4_ODT[1]}]   ;# DDR4_ODT[1] bank 30
set_property -dict {PACKAGE_PIN AD46 IOSTANDARD LVCMOS12} [get_ports {DDR4_RESET_N}]   ;# DDR4_RESET_N bank 30

# DCI reference: cascade from the address/control bank 30 to the data banks
set_property DCI_CASCADE {29 31} [get_iobanks 30]

# LED_G1 (bank 83, 1.8 V): DDR4 calibration complete
set_property -dict {PACKAGE_PIN BE14 IOSTANDARD LVCMOS18} [get_ports {LED_DDR4_CALIB}]

# The SoC clock (HAPS_CLK 20 MHz and its CLK1HZ child) and the DDR4 domains (c0_sys_clk_p 299.85 MHz,
# MMCM/PLL children: ui_clk 266.5 MHz, memory clocks) are unrelated. Every crossing is inside
# haps_ddr4_bridge: the AXI clock converter's asynchronous FIFOs (constrained by the IP) and the
# reset synchronisers (ASYNC_REG).
# Two spellings of the same relationship (-quiet: whichever lookup is empty is skipped): the IP creates its reference clock
# on its c0_sys_clk_p pin, which Vivado may report under the top-level port (as in the step-1 build) or under the pin name.
set_clock_groups -quiet -asynchronous -group [get_clocks -include_generated_clocks HAPS_CLK] -group [get_clocks -quiet -include_generated_clocks -of_objects [get_ports DDR4_SYS_CLK_P]]
set_clock_groups -quiet -asynchronous -group [get_clocks -include_generated_clocks HAPS_CLK] -group [get_clocks -quiet -include_generated_clocks {c0_sys_clk_p DDR4_SYS_CLK_P}]
