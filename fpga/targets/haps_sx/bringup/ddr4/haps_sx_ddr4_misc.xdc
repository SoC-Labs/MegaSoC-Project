# HAPS-SX VU19P - standalone DDR4 example design: reset button and status LEDs
# Bank 20 (push buttons, 1.8 V) and bank 83 (LEDs, 1.8 V fixed) as in haps_top.xdc of the SoC build.
set_property -dict {PACKAGE_PIN BJ43 IOSTANDARD LVCMOS18} [get_ports {USER_PB2_n}]      ;# USER_PB2_n, active low -> sys_rst (active high) in the wrapper
set_property -dict {PACKAGE_PIN BE14 IOSTANDARD LVCMOS18} [get_ports {LED_CALIB}]       ;# LED_G1: c0_init_calib_complete
set_property -dict {PACKAGE_PIN BE13 IOSTANDARD LVCMOS18} [get_ports {LED_ERR}]         ;# LED_R0: c0_data_compare_error (traffic generator)
# The 300 MHz reference enters an HP bank at 1.2 V; the IP's own XDC creates its clock from c0_sys_clk_p.
set_false_path -from [get_ports USER_PB2_n]
# Carried over from the IP's example_design.xdc (the rest of that file is placeholder pins and is disabled): waiver for the
# TIMING-17 methodology warning on the calibration XSDB slave port, with the wrapper instance in the path.
create_waiver -internal -user ddr4_v2_2_23 -scope -type METHODOLOGY -id {TIMING-17} -description "Ignore the TIMING-17 Critical Warning for sl_iport_i" -objects [get_pins -quiet -leaf -of [get_nets -quiet u_example_top/u_ddr4_*/inst/u_ddr4_mem_intfc/u_ddr_cal_top/u_ddr_cal/U_XSDB_SLAVE/sl_iport_i*] -filter {DIRECTION==IN}]
# v2: GCLK1 (20 MHz, LVDS, bank 20) clocks the VIO only - same pins and standard as haps_top.xdc of the SoC build
set_property -dict {PACKAGE_PIN BM44 IOSTANDARD LVDS} [get_ports {HAPS_CLK_IN_P}]
set_property -dict {PACKAGE_PIN BN44 IOSTANDARD LVDS} [get_ports {HAPS_CLK_IN_N}]
create_clock -name haps_clk20 -period 50.000 [get_ports HAPS_CLK_IN_P]
set_clock_groups -asynchronous -group [get_clocks haps_clk20] -group [get_clocks -include_generated_clocks -of_objects [get_ports c0_sys_clk_p]]
