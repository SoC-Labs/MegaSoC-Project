# Build 65, step 1 (read-only): dump the 32 RAMB36E2 cells that hold the boot ROM in the routed build-64 checkpoint.
set DCP /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/bitstreams/build64_reset_policy_mbt74_20261117/haps_top_routed64_final.dcp
set OUT /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/bitstreams/build65_monitor_v6_caches_20261124
open_checkpoint $DCP
set br [lsort -dictionary [get_cells -hier -filter {NAME =~ */u_ROM_wrapper/u_bootrom/RDATA_reg_* && PRIMITIVE_TYPE =~ BLOCKRAM.*}]]
puts "===ROM=== boot ROM block RAMs: [llength $br]"
set fh [open $OUT/rom64_bram_dump.txt w]
foreach c $br {
  puts $fh "CELL $c REF [get_property REF_NAME $c] LOC [get_property LOC $c]"
  foreach p [lsort [list_property $c]] {
    if {[regexp {^(INIT_[0-9A-F][0-9A-F]|INITP_[0-9A-F][0-9A-F])$} $p]} { continue }
    if {[regexp {^(READ_WIDTH|WRITE_WIDTH|DOA_REG|DOB_REG|CASCADE_ORDER|RAM_MODE|CLOCK_DOMAINS|EN_ECC|INIT_A|INIT_B|INIT_FILE|IS_.*INVERTED|RDADDRCHANGE|RSTREG_PRIORITY|SRVAL|WRITE_MODE|SLEEP_ASYNC|ENADDREN)} $p]} { puts $fh "PROP $p [get_property $p $c]" }
  }
  foreach pin [lsort -dictionary [get_pins -of $c -filter {DIRECTION == OUT}]] {
    set n [get_nets -quiet -of $pin]
    if {[llength $n]} { puts $fh "OUT [get_property REF_PIN_NAME $pin] $n" }
  }
  foreach pin [lsort -dictionary [get_pins -of $c -filter {DIRECTION == IN && (REF_PIN_NAME =~ ADDRARDADDR* || REF_PIN_NAME =~ ADDRBWRADDR* || REF_PIN_NAME =~ EN* || REF_PIN_NAME =~ CAS* || REF_PIN_NAME =~ REGCE* || REF_PIN_NAME =~ RST* || REF_PIN_NAME =~ WE*)}]] {
    set n [get_nets -quiet -of $pin]
    puts $fh "IN [get_property REF_PIN_NAME $pin] [expr {[llength $n] ? "$n [get_property TYPE $n]" : "-"}]"
  }
  for {set i 0} {$i < 128} {incr i} { set k [format INIT_%02X $i]; puts $fh "$k [get_property $k $c]" }
  for {set i 0} {$i < 16} {incr i} { set k [format INITP_%02X $i]; puts $fh "$k [get_property $k $c]" }
}
close $fh
puts "===ROM=== DONE"
close_design
