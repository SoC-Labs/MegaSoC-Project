set D /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/ddr4
open_project $D/ddr4_0_ex/ddr4_0_ex.xpr
if {[get_ips -quiet vio_0] eq ""} {
  create_ip -name vio -vendor xilinx.com -library ip -version 3.0 -module_name vio_0
  set_property -dict {CONFIG.C_NUM_PROBE_IN {3} CONFIG.C_PROBE_IN0_WIDTH {1} CONFIG.C_PROBE_IN1_WIDTH {1} CONFIG.C_PROBE_IN2_WIDTH {1} CONFIG.C_NUM_PROBE_OUT {1} CONFIG.C_PROBE_OUT0_WIDTH {1} CONFIG.C_PROBE_OUT0_INIT_VAL {0x0}} [get_ips vio_0]
  generate_target {instantiation_template synthesis implementation} [get_ips vio_0]
}
update_compile_order -fileset sources_1
puts "===TOP=== [get_property top [current_fileset]]"
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} { puts "===SYNTH=== FAILED"; exit 1 }
puts "===SYNTH=== OK"
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
open_run impl_1
report_timing_summary -file $D/ddr4_ex_vio_timing.rpt
report_drc -file $D/ddr4_ex_vio_drc.rpt
report_utilization -slr -file $D/ddr4_ex_vio_util.rpt
report_io -file $D/ddr4_ex_vio_io.rpt
write_debug_probes -force $D/haps_ddr4_ex_top_vio.ltx
set wns [get_property STATS.WNS [get_runs impl_1]]; set whs [get_property STATS.WHS [get_runs impl_1]]
puts "===BUILD=== WNS=$wns WHS=$whs status=[get_property STATUS [get_runs impl_1]] DONE==="
