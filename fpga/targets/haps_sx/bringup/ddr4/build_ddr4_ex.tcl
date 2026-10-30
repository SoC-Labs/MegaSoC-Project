set D /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/ddr4
open_project $D/ddr4_0_ex/ddr4_0_ex.xpr
add_files -norecurse $D/haps_ddr4_ex_top.sv
set_property is_enabled false [get_files -of_objects [get_filesets constrs_1] example_design.xdc]   ;# placeholder pins of the generated example: collide with the board
add_files -fileset constrs_1 -norecurse [list $D/haps_sx_ddr4_pins.xdc $D/haps_sx_ddr4_misc.xdc]
set_property top haps_ddr4_ex_top [current_fileset]
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
report_timing_summary -file $D/ddr4_ex_timing.rpt
report_drc -file $D/ddr4_ex_drc.rpt
report_utilization -slr -file $D/ddr4_ex_util.rpt
report_clock_utilization -file $D/ddr4_ex_clock_util.rpt
report_io -file $D/ddr4_ex_io.rpt
set wns [get_property STATS.WNS [get_runs impl_1]]; set whs [get_property STATS.WHS [get_runs impl_1]]
puts "===BUILD=== WNS=$wns WHS=$whs status=[get_property STATUS [get_runs impl_1]] DONE==="
