open_project /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.xpr

# Build 54 = build 53 + N25 ROOT-CAUSE FIX: the Arm TSMC example integration of the L2 TAG RAMs (tsmc_cln28hpm_L1_32I_32D_L2_1M/ca53_l2_tagrams.v, written for a 1 MB L2) does not mask the set index by l2_size; this core has a 256 KB L2 (L2_CACHE_SIZE=0001) -> tags written/looked up at different addresses -> hang at SCTLR.I=1. Now: Arm GENERIC ca53_l2_tagrams.v + new/ca53_generic_ram_fpga.v (zero power-up, output holds). rfhds models: zero/ones power-up, Q holds through writes. Match
# downstream: post-route phys_opt with hold fixing.
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property -name {STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.MORE OPTIONS} -value {-hold_fix} -objects [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.TCL.PRE {} [get_runs impl_1]
puts "===BUILD=== qspi_io_impl.xdc used_in_synthesis=[get_property used_in_synthesis [get_files *haps_top_qspi_io_impl.xdc]]"
set f_bram /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.srcs/sources_1/new/axi4_bram_slave.sv
if {[llength [get_files -quiet $f_bram]] == 0} { add_files -norecurse $f_bram; set_property file_type SystemVerilog [get_files $f_bram]; puts "===BUILD=== added axi4_bram_slave.sv" }
set f_emu /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.srcs/sources_1/new/qspi_flash_emu.sv
if {[llength [get_files -quiet $f_emu]] == 0} { add_files -norecurse $f_emu; set_property file_type SystemVerilog [get_files $f_emu]; puts "===BUILD=== added qspi_flash_emu.sv" }

# ---- build 54 (N25): L2 tag RAM integration -> Arm generic (masks the set index by l2_size), FPGA generic RAM model
set f_old1 /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.srcs/sources_1/imports/models/rams/tsmc_cln28hpm_L1_32I_32D_L2_1M/ca53_l2_tagrams.v
set f_old2 /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.srcs/sources_1/imports/models/rams/generic/ca53_generic_ram.v
set f_new1 /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.srcs/sources_1/imports/models/rams/generic/ca53_l2_tagrams.v
set f_new2 /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.srcs/sources_1/new/ca53_generic_ram_fpga.v
foreach f [list $f_old1 $f_old2] { if {[llength [get_files -quiet $f]] > 0} { remove_files $f; puts "===B54=== removed $f" } }
foreach f [list $f_new1 $f_new2] { if {[llength [get_files -quiet $f]] == 0} { add_files -norecurse $f; puts "===B54=== added $f" } }
update_compile_order -fileset sources_1

puts "===BUILD=== GATED_CLOCK_CONVERSION = [get_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION [get_runs synth_1]]"

reset_run synth_1
puts "===BUILD=== launching synth_1"
launch_runs synth_1 -jobs 8
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "===BUILD=== synth_1 FAILED"
    exit 1
}
puts "===BUILD=== synth_1 complete"

# --- constraint guard (replaces must_match, which XDC cannot host) ---
open_run synth_1 -name synth_guard
set ok 1
foreach c {HAPS_CLK} {
    if {[llength [get_clocks -quiet $c]] == 0} {
        puts "===BUILD=== MUSTMATCH FAIL: clock $c does not exist after synthesis"
        set ok 0
    } else {
        puts "===BUILD=== clock $c OK"
    }
}
set fh [open /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.runs/synth_1/runme.log r]
set lg [read $fh]
close $fh
foreach line [split $lg "\n"] {
    if {[regexp {Designutils 20-1307|Vivado 12-4739|Constraints 18-540} $line]} {
        puts "===BUILD=== MUSTMATCH FAIL: $line"
        set ok 0
    }
}
close_design
if {!$ok} {
    puts "===BUILD=== synth_1 FAILED constraint guard"
    exit 1
}

reset_run impl_1
puts "===BUILD=== launching impl_1 through write_bitstream"
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "===BUILD=== impl_1 FAILED"
    exit 1
}
puts "===BUILD=== impl_1 / bitstream complete"

open_run impl_1
set rpt /tmpdir/claude-44910/-home-ad1u25-megasoc-project-FPGA-Tasos-haps-top/da65de02-56b2-483b-9b30-fa33da96a2d8/scratchpad/timing_summary54.rpt
report_timing_summary -delay_type min_max -file $rpt -quiet
set wns [get_property SLACK [get_timing_paths -delay_type max -max_paths 1 -nworst 1]]
set whs [get_property SLACK [get_timing_paths -delay_type min -max_paths 1 -nworst 1]]
puts "===BUILD=== WNS=$wns WHS=$whs"
set fh [open $rpt r]
set content [read $fh]
close $fh
foreach line [split $content "\n"] {
    if {[string match "*WNS(ns)*" $line] || [regexp {^\s+[-0-9]} $line]} {
        puts "===BUILD=== SUMMARY: $line"
    }
}
puts "===BUILD=== impl clocks: [get_clocks]"
puts "===BUILD=== latches: [llength [get_cells -hier -filter {PRIMITIVE_SUBGROUP == LATCH || REF_NAME =~ LD*}]]"
puts "===BUILD=== BUFGCE source check:"
foreach b [lsort [get_cells -hier -filter {REF_NAME =~ "BUFG*"}]] {
    set src [get_pins -leaf -of_objects [get_nets -of_objects [get_pins $b/I]] -filter {DIRECTION == OUT}]
    set src_ref [get_property REF_NAME [get_cells -of_objects $src]]
    puts [format "===BUILD===   %-12s src=%-10s %s" [get_property LOC $b] $src_ref $b]
}
report_drc -file /tmpdir/claude-44910/-home-ad1u25-megasoc-project-FPGA-Tasos-haps-top/da65de02-56b2-483b-9b30-fa33da96a2d8/scratchpad/drc54.rpt -quiet
puts "===BUILD=== DONE==="
