# HAPS-SX DDR4 check over JTAG from srv03335 (no bench access needed).
#   vivado -mode batch -source check_ddr4_cal.tcl -tclargs <bitstream> [<probes.ltx>] [reset]
# Programs the VU19P with <bitstream>, refreshes it, prints the DDR4 IP calibration status and, if the bitstream has the
# VIO (v2), the status probes. With "reset" as the last argument the IP is reset through the VIO and re-calibrated first.
set bit ""; set ltx ""; set do_reset 0
foreach a $argv { if {[string match *.bit $a]} { set bit $a } elseif {[string match *.ltx $a]} { set ltx $a } elseif {$a eq "reset"} { set do_reset 1 } }
open_hw_manager
# The HAPS-SX JTAG is served at 127.0.0.1:3310 (hardware manager journal of the SoC builds); target */xilinx_tcf/Digilent/HAPSSX*
if {[catch {connect_hw_server -url 127.0.0.1:3310 -allow_non_jtag} err]} { puts "connect 127.0.0.1:3310 failed: $err"; connect_hw_server -allow_non_jtag }
set tgt [lindex [get_hw_targets -quiet */xilinx_tcf/Digilent/HAPSSX*] 0]
if {$tgt eq ""} { set tgt [lindex [get_hw_targets] 0] }
puts "TARGET: $tgt"
current_hw_target $tgt
open_hw_target
set dev [lindex [get_hw_devices -filter {PART =~ xcvu19p*}] 0]
if {$dev eq ""} { puts "NO VU19P FOUND: [get_hw_devices]"; exit 1 }
current_hw_device $dev
if {$ltx ne ""} { set_property PROBES.FILE $ltx $dev; set_property FULL_PROBES.FILE $ltx $dev }
if {$bit ne ""} {
  set_property PROGRAM.FILE $bit $dev
  program_hw_devices $dev
  puts "PROGRAMMED $bit"
}
after 2000
refresh_hw_device $dev
# --- DDR4 IP calibration (through the debug hub, present in both v1 and v2) ---
set migs [get_hw_migs -quiet -of_objects $dev]
if {$migs eq ""} { puts "NO hw_mig core visible (debug hub not found?)" } else {
  foreach m $migs {
    refresh_hw_mig $m
    puts "=== $m ==="
    foreach p [lsort [list_property $m]] {
      if {[regexp -nocase {CAL|STATUS|ERROR|MARGIN|STAGE|FREQ|DQS|BYTE|RANK} $p]} { puts "  $p = [get_property $p $m]" }
    }
  }
}
# --- v2: VIO probes (named after the connected nets, so match by wildcard) ---
set vios [get_hw_vios -quiet -of_objects $dev]
if {$vios ne ""} {
  set vio [lindex $vios 0]
  puts "VIO probes: [get_hw_probes -of_objects $vio]"
  set prst [lindex [get_hw_probes -quiet -of_objects $vio -filter {NAME =~ *jtag_rst*}] 0]
  if {$do_reset && $prst ne ""} {
    set_property OUTPUT_VALUE 1 $prst; commit_hw_vio $vio; after 200
    set_property OUTPUT_VALUE 0 $prst; commit_hw_vio $vio
    puts "VIO: IP reset pulsed through $prst, waiting 2 s for calibration"; after 2000
    foreach m $migs { refresh_hw_mig $m; puts "after reset: CALIBRATION_FAIL.STATUS = [get_property CALIBRATION_FAIL.STATUS $m], [get_property CAL_ERROR_MSG $m]" }
  }
  foreach i {1 2 3} {
    refresh_hw_vio $vio
    set line ""
    foreach pr [get_hw_probes -of_objects $vio] {
      set v ""; catch {set v [get_property INPUT_VALUE $pr]}; if {$v eq ""} { catch {set v "out:[get_property OUTPUT_VALUE $pr]"} }
      append line " [get_property NAME $pr]=$v"
    }
    puts "VIO sample $i:$line"
    after 1000
  }
  puts "Expect: calib (calib_s) = 1, err (err_s) = 0, heartbeat (hb_cnt) changing between samples."
} else { puts "No VIO in this bitstream (v1): calibration status above is the result; the compare-error flag is only on LED_R0." }
close_hw_manager
puts "CHECK DONE"
