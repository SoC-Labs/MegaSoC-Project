# Build 65 = build 64 with new boot ROM contents (UART/flash monitor v6.0), 24 Nov 2026. See build65_notes.md.
# The boot ROM is 32 RAMB36E2 (u_bootrom/RDATA_reg_0..31, 16K x 2 each). This script opens the ROUTED build-64 checkpoint,
# replaces their INIT strings (rom65_init.tcl, generated and layout-proven by rom_init_gen.py), reads every INIT back
# against rom65_expected.txt, and writes the checkpoint and the bitstream. Nothing is synthesised, placed or routed, so
# every net, every delay and the timing are those of build 64.
set P /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top
set B64 $P/bitstreams/build64_reset_policy_mbt74_20261117/haps_top_routed64_final.dcp
set OUT $P/bitstreams/build65_monitor_v6_caches_20261124
set BITNAME haps_top_build65_monitor_v6_caches_[clock format [clock seconds] -format %Y%m%d].bit
set_param general.maxThreads 8
open_checkpoint $B64
set br [lsort -dictionary [get_cells -hier -filter {NAME =~ */u_ROM_wrapper/u_bootrom/RDATA_reg_* && PRIMITIVE_TYPE =~ BLOCKRAM.*}]]
puts "===B65=== boot ROM block RAMs: [llength $br]"
if {[llength $br] != 32} { puts "===BUILD=== FAILED: expected 32 boot ROM block RAMs"; exit 1 }
set nbram [llength [get_cells -hier -filter {PRIMITIVE_TYPE =~ BLOCKRAM.*}]]
set ncells [llength [get_cells -hier -filter {IS_PRIMITIVE == 1}]]
puts "===B65=== design before the patch: $ncells primitives, $nbram block RAMs"
source $OUT/rom65_init.tcl
puts "===B65=== rom65_init.tcl applied"
set fh [open $OUT/rom65_expected.txt r]; set bad 0; set n 0
while {[gets $fh line] >= 0} {
  if {$line eq ""} { continue }
  lassign [split $line " "] cell key val
  incr n
  set got [get_property $key [get_cells $cell]]
  if {![string equal -nocase $got $val]} { incr bad; if {$bad <= 5} { puts "===B65=== READBACK MISMATCH $cell $key: $got" } }
}
close $fh
puts "===B65=== read-back: $n INIT strings checked, $bad mismatches"
if {$bad != 0 || $n != 4096} { puts "===BUILD=== FAILED: ROM read-back"; exit 1 }
# the design itself must be untouched
set ncells2 [llength [get_cells -hier -filter {IS_PRIMITIVE == 1}]]
puts "===B65=== design after the patch: $ncells2 primitives"
if {$ncells2 != $ncells} { puts "===BUILD=== FAILED: cell count changed"; exit 1 }
set rs [report_route_status -return_string]
foreach l [split $rs "\n"] { if {[regexp {routable nets|fully routed nets|nets with routing errors|unrouted nets} $l]} { puts "===B65=== route status: [string trim $l]" } }
if {![regexp {# of nets with routing errors[ .:]*0 } $rs]} { puts "===B65=== note: check the route status lines above" }
set wns [get_property SLACK [get_timing_paths -delay_type max -max_paths 1 -nworst 1]]
set whs [get_property SLACK [get_timing_paths -delay_type min -max_paths 1 -nworst 1]]
puts "===B65=== timing (must equal build 64: WNS +0.392, WHS +0.010): WNS=$wns WHS=$whs"
if {$whs < 0 || $wns < 0} { puts "===BUILD=== FAILED: timing"; exit 1 }
puts "===B65=== GIC clock gates: [llength [get_cells -hier -quiet -filter {NAME =~ *u_GIC400/u_gic_clk/u_inter_clkgate* && (REF_NAME == BUFGCE || ORIG_REF_NAME == BUFGCE)}]]; reset controller flops: [llength [get_cells -hier -quiet -filter {NAME =~ u_rst_ctrl/* && (PRIMITIVE_TYPE =~ REGISTER.* || REF_NAME =~ FD*)}]]; UART_RX pull: [get_property -quiet PULLTYPE [get_ports UART_RX]]"
write_checkpoint -force $OUT/haps_top_routed65.dcp
write_bitstream -force $OUT/$BITNAME
puts "===B65=== bitstream written: $OUT/$BITNAME"
puts "===BUILD=== DONE==="
