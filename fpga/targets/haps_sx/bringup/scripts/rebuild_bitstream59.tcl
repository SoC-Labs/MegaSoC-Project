# Build 59 = build 58 (DDR4 on the DRAM port) + L2 DATA RAM integration fix (N25 family, found 29 Oct 2026 with the
# DDR4 tests: the fileset still compiled Arm's TSMC 1 MB example ca53_l2_datarams.v, unmasked 14-bit RAM address, for the
# 256 KB L2 -> allocation-driven evictions wrote another line's data). Fix as build 54 did for the tag RAMs: only Arm's
# generic index-masked wrappers (models/rams/generic/ca53_l2_{data,tag}rams.v) stay enabled, on new/ca53_generic_ram_fpga.v.
set P /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top
set SP /tmpdir/claude-44910/-home-ad1u25-megasoc-project-FPGA-Tasos-haps-top/da65de02-56b2-483b-9b30-fa33da96a2d8/scratchpad
open_project $P/haps_top.xpr
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property -name {STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.MORE OPTIONS} -value {-hold_fix} -objects [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.TCL.PRE {} [get_runs impl_1]

# ---- build 59: exactly one definition of each L2 RAM wrapper ----
foreach f [list $P/haps_top.srcs/sources_1/imports/models/rams/tsmc_cln28hpm_L1_32I_32D_L2_1M/ca53_l2_datarams.v \
               $P/haps_top.srcs/sources_1/imports/mem_integrations/FPGA/ca53_l2_datarams.v \
               $P/haps_top.srcs/sources_1/imports/mem_integrations/CortexA53/ca53_l2_tagrams.v \
               $P/haps_top.srcs/sources_1/imports/mem_integrations/CortexA53/ca53_l2_datarams.v] {
    if {[llength [get_files -quiet $f]] > 0} { set_property IS_ENABLED 0 [get_files $f]; puts "===B59=== disabled $f" }
}
foreach f [list $P/haps_top.srcs/sources_1/imports/models/rams/generic/ca53_l2_datarams.v \
               $P/haps_top.srcs/sources_1/imports/models/rams/generic/ca53_l2_tagrams.v \
               $P/haps_top.srcs/sources_1/new/ca53_generic_ram_fpga.v] {
    if {[llength [get_files -quiet $f]] == 0} { add_files -norecurse $f; puts "===B59=== added $f" }
    set_property IS_ENABLED 1 [get_files $f]
    puts "===B59=== enabled $f"
}
update_compile_order -fileset sources_1
set n_data 0; set n_tag 0
foreach f [get_files -compile_order sources -used_in synthesis -of_objects [get_filesets sources_1]] {
    if {[string match *ca53_l2_datarams.v $f]} { incr n_data; puts "===B59=== compile order has DATA wrapper: $f" }
    if {[string match *ca53_l2_tagrams.v $f]}  { incr n_tag;  puts "===B59=== compile order has TAG wrapper: $f" }
}
if {$n_data != 1 || $n_tag != 1 || ![string match *models/rams/generic/* [lindex [get_files -compile_order sources -used_in synthesis -of_objects [get_filesets sources_1] -filter {NAME =~ *ca53_l2_datarams.v}] 0]]} {
    puts "===BUILD=== FAILED: compile order does not hold exactly the generic data+tag wrappers (data=$n_data tag=$n_tag)"; exit 1
}

# ---- IPs (build 58) must be present and synthesised OOC ----
set ooc_runs {}
foreach n {ddr4_0 axi_cc_dram axi_dw_dram} {
    if {[llength [get_ips -quiet $n]] == 0} { puts "===BUILD=== FAILED: IP $n missing"; exit 1 }
    if {[llength [get_runs -quiet ${n}_synth_1]] == 0} { create_ip_run [get_files $P/haps_top.srcs/sources_1/ip/$n/$n.xci] }
    set r [get_runs ${n}_synth_1]
    if {[get_property PROGRESS $r] != "100%" || [get_property NEEDS_REFRESH $r]} { lappend ooc_runs $r }
}
puts "===B59=== OOC synthesis runs to do: $ooc_runs"
if {[llength $ooc_runs]} {
    launch_runs $ooc_runs -jobs 3
    foreach r $ooc_runs { wait_on_run $r; if {[get_property PROGRESS $r] != "100%"} { puts "===BUILD=== OOC run $r FAILED"; exit 1 } }
}
puts "===BUILD=== top = [get_property top [current_fileset]]"

# ---- elaboration check: the generic RAM must now be under the L2 data RAM wrapper ----
set elab_ok 1
if {[catch {synth_design -rtl -name rtl59 -top haps_top -part xcvu19p-fsva3824-2-e} err]} {
    puts "===ELAB=== FAILED (continuing to synth_1): [string range $err 0 600]"; set elab_ok 0
}
if {$elab_ok} {
    puts "===ELAB=== OK"
    puts "===ELAB=== data RAM generic instances: [llength [get_cells -hier -quiet -filter {NAME =~ *u_ca53_l2_datarams/u_l2_dataram_* && (REF_NAME == ca53_generic_ram || ORIG_REF_NAME == ca53_generic_ram)}]] (expect 8)"
    puts "===ELAB=== data RAM cells of any kind: [get_cells -hier -quiet -filter {NAME =~ *u_ca53_l2_datarams/u_l2_dataram_*}]"
    puts "===ELAB=== tag RAM generic instances: [llength [get_cells -hier -quiet -filter {NAME =~ *u_ca53_l2_tagrams/* && (REF_NAME == ca53_generic_ram || ORIG_REF_NAME == ca53_generic_ram)}]]"
    puts "===ELAB=== SRAMHDE/TSMC macro cells left: [llength [get_cells -hier -quiet -filter {REF_NAME =~ SRAMHDE* || REF_NAME =~ RFHSD* || ORIG_REF_NAME =~ SRAMHDE* || ORIG_REF_NAME =~ RFHSD*}]] (expect 0 for the L2 data RAMs; L1 macros may remain)"
    puts "===ELAB=== bridge cells: [llength [get_cells -hier -quiet -filter {NAME =~ *u_dram_ddr4*}]]"
    close_design
}

reset_run synth_1
puts "===BUILD=== launching synth_1"
launch_runs synth_1 -jobs 8
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} { puts "===BUILD=== synth_1 FAILED"; exit 1 }
puts "===BUILD=== synth_1 complete"
open_run synth_1 -name synth_guard
set ok 1
if {[llength [get_clocks -quiet HAPS_CLK]] == 0} { puts "===BUILD=== MUSTMATCH FAIL: clock HAPS_CLK missing"; set ok 0 }
set fh [open $P/haps_top.runs/synth_1/runme.log r]; set lg [read $fh]; close $fh
foreach line [split $lg "\n"] { if {[regexp {Designutils 20-1307|Vivado 12-4739|Constraints 18-540} $line]} { puts "===BUILD=== MUSTMATCH FAIL: $line"; set ok 0 } }
puts "===BUILD=== synth BRAM: [llength [get_cells -hier -quiet -filter {PRIMITIVE_TYPE =~ BLOCKRAM.*}]] block RAM primitives"
close_design
if {!$ok} { puts "===BUILD=== synth_1 FAILED constraint guard"; exit 1 }

reset_run impl_1
puts "===BUILD=== launching impl_1 through write_bitstream"
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} { puts "===BUILD=== impl_1 FAILED"; exit 1 }
puts "===BUILD=== impl_1 / bitstream complete"
open_run impl_1
set rpt $SP/timing_summary59.rpt
report_timing_summary -delay_type min_max -file $rpt -quiet
set wns [get_property SLACK [get_timing_paths -delay_type max -max_paths 1 -nworst 1]]
set whs [get_property SLACK [get_timing_paths -delay_type min -max_paths 1 -nworst 1]]
puts "===BUILD=== WNS=$wns WHS=$whs"
set fh [open $rpt r]; set content [read $fh]; close $fh
foreach line [split $content "\n"] { if {[string match "*WNS(ns)*" $line] || [regexp {^\s+[-0-9]} $line]} { puts "===BUILD=== SUMMARY: $line" } }
report_clock_interaction -file $SP/clock_interaction59.rpt -quiet
report_utilization -slr -file $SP/util_slr59.rpt -quiet
report_utilization -hierarchical -hierarchical_depth 4 -file $SP/util_hier59.rpt -quiet
report_drc -file $SP/drc59.rpt -quiet
puts "===BUILD=== latches: [llength [get_cells -hier -filter {PRIMITIVE_SUBGROUP == LATCH || REF_NAME =~ LD*}]]"
puts "===BUILD=== DONE==="
