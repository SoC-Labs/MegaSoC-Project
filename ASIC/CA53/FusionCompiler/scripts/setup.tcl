## Paths Please Edit for your system
set via_map_file    /home/dwn1c21/SoC-Labs/phys_ip/TSMC/28/CMOS/util/PRTF_ICC_28nm_Syn_V19_1a/PR_tech/Synopsys/DFMViaSwapTcl/n28_ICC_DFMSWAP_5X1Y1Z1U_VHV.tcl
set_app_options -list {signoff.check_drc.runset {/home/dwn1c21/SoC-Labs/phys_ip/TSMC/28/CMOS/util/LOGIC_TopMz+Mu_DRC/ICVLN28HP_9M_5X1Y1Z1U_002.22a.encrypt}}
set_app_options -list {signoff.physical.layer_map_file {/home/dwn1c21/SoC-Labs/phys_ip/TSMC/28/CMOS/util/PRTF_ICC_28nm_Syn_V19_1a/PR_tech/Synopsys/GdsOutMap/gdsout_5X1Y1Z1U.map}}
set_app_options -list {signoff.check_drc_live.runset {/home/dwn1c21/SoC-Labs/phys_ip/TSMC/28/CMOS/util/LOGIC_TopMz+Mu_DRC/ICVLN28HP_9M_5X1Y1Z1U_002.22a.encrypt}}
set TLU_dir /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/arm_tech/r3p0/synopsys_tluplus/9m_2xa1xd3xe2z_utrdl


set PG_NETS [list VDD VSS]
set CORE_VOLTAGE 0.8
set tie_hi_cells cln16fcll/TIEHI_X1N_A9PP96CTS_C24
set tie_lo_cells cln16fcll/TIELO_X1N_A9PP96CTS_C24

set fill_cells  {FILL128_A9PP96CTS_C24 \
 FILL64_A9PP96CTS_C24 \
 FILL32_A9PP96CTS_C24 \
 FILL16_A9PP96CTS_C24\
 FILL8_A9PP96CTS_C24 \
 FILL4_A9PP96CTS_C24 \
 FILL3_A9PP96CTS_C24 \
 FILL2_A9PP96CTS_C24 \
 FILL1_A9PP96CTS_C24 \
 }

