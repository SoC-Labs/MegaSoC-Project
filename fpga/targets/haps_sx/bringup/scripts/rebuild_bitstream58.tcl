# Build 58 = build 57 RTL + MGSOC-34 step 2: on-board DDR4 SODIMM on the NIC-400 DRAM port.
#   new/haps_ddr4_bridge.sv (Xilinx DDR4 IP ddr4_0 + axi_cc_dram clock converter + axi_dw_dram width converter),
#   megasoc_tech_wrapper.sv USE_DDR4 = 1 (replaces the 512 KB axi4_bram_slave), DDR4 pins and reference clock threaded
#   through megasoc_chip / megasoc_system / haps_top, constrs haps_top_ddr4_impl.xdc (123 DDR4 pins, LED_G1, clock groups).
set P /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top
set SP /tmpdir/claude-44910/-home-ad1u25-megasoc-project-FPGA-Tasos-haps-top/da65de02-56b2-483b-9b30-fa33da96a2d8/scratchpad
open_project $P/haps_top.xpr

set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property -name {STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.MORE OPTIONS} -value {-hold_fix} -objects [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.TCL.PRE {} [get_runs impl_1]

# ---- sources (builds 47-57) ----
foreach f [list $P/haps_top.srcs/sources_1/new/axi4_bram_slave.sv $P/haps_top.srcs/sources_1/new/qspi_flash_emu.sv \
               $P/haps_top.srcs/sources_1/imports/models/rams/generic/ca53_l2_tagrams.v $P/haps_top.srcs/sources_1/new/ca53_generic_ram_fpga.v] {
    if {[llength [get_files -quiet $f]] == 0} { add_files -norecurse $f; puts "===BUILD=== added $f" }
}
foreach f [list $P/haps_top.srcs/sources_1/imports/models/rams/tsmc_cln28hpm_L1_32I_32D_L2_1M/ca53_l2_tagrams.v $P/haps_top.srcs/sources_1/imports/models/rams/generic/ca53_generic_ram.v] {
    if {[llength [get_files -quiet $f]] > 0} { remove_files $f; puts "===BUILD=== removed $f" }
}
# ---- build 58 sources ----
set f_br $P/haps_top.srcs/sources_1/new/haps_ddr4_bridge.sv
if {[llength [get_files -quiet $f_br]] == 0} { add_files -norecurse $f_br; puts "===B58=== added haps_ddr4_bridge.sv" }
set_property file_type SystemVerilog [get_files $f_br]
set f_xdc $P/haps_top.srcs/constrs_1/new/haps_top_ddr4_impl.xdc
if {[llength [get_files -quiet $f_xdc]] == 0} { add_files -fileset constrs_1 -norecurse $f_xdc; puts "===B58=== added haps_top_ddr4_impl.xdc" }
set_property used_in_synthesis false [get_files $f_xdc]
puts "===B58=== ddr4 xdc used_in_synthesis=[get_property used_in_synthesis [get_files $f_xdc]] used_in_implementation=[get_property used_in_implementation [get_files $f_xdc]]"

# ---- build 58 IPs ----
proc setp {ip d} { if {[catch {set_property -dict $d $ip} err]} { puts "===B58=== SETPROP FAILED: $d -> [string range $err 0 300]"; exit 1 } }
if {[llength [get_ips -quiet ddr4_0]] == 0 && [file exists $P/haps_top.srcs/sources_1/ip/ddr4_0/ddr4_0.xci]} {
    add_files -norecurse $P/haps_top.srcs/sources_1/ip/ddr4_0/ddr4_0.xci; puts "===B58=== re-added existing ddr4_0.xci"
}
if {[llength [get_ips -quiet ddr4_0]] == 0} {
    create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 -module_name ddr4_0
    set ip [get_ips ddr4_0]
    # as ddr4/gen_ddr4_ip.tcl (step 1, calibrated on the board 28 Oct): speed first, the IP validates part/type against tCK
    setp $ip {CONFIG.C0.DDR4_TimePeriod {938}}
    setp $ip {CONFIG.C0.DDR4_MemoryType {SODIMMs}}
    setp $ip {CONFIG.C0.DDR4_MemoryPart {MTA16ATF2G64HZ-2G3}}
    setp $ip {CONFIG.C0.DDR4_InputClockPeriod {3335}}
    setp $ip {CONFIG.C0.DDR4_DataWidth {64}}
    setp $ip {CONFIG.C0.DDR4_Ecc {false}}
    setp $ip {CONFIG.C0.DDR4_CasLatency {15}}
    setp $ip {CONFIG.C0.DDR4_CasWriteLatency {11}}
    setp $ip {CONFIG.C0.DDR4_DataMask {DM_NO_DBI}}
    setp $ip {CONFIG.C0.DDR4_PhyClockRatio {4:1}}
    setp $ip {CONFIG.C0.DDR4_Mem_Add_Map {ROW_COLUMN_BANK}}
    setp $ip {CONFIG.C0.DDR4_AxiSelection {true}}
    setp $ip {CONFIG.C0.DDR4_AxiDataWidth {512}}
    setp $ip {CONFIG.C0.DDR4_AxiAddressWidth {34}}
    setp $ip {CONFIG.C0.DDR4_AxiIDWidth {1}}
    setp $ip {CONFIG.C0.DDR4_AxiNarrowBurst {true}}
    setp $ip {CONFIG.C0.DDR4_AxiArbitrationScheme {RD_PRI_REG}}
    setp $ip {CONFIG.C0.DDR4_Ordering {Normal}}
    setp $ip {CONFIG.System_Clock {Differential}}
    setp $ip {CONFIG.Debug_Signal {Disable}}
    puts "===B58=== created ddr4_0"
}
if {[llength [get_ips -quiet axi_cc_dram]] == 0 && [file exists $P/haps_top.srcs/sources_1/ip/axi_cc_dram/axi_cc_dram.xci]} {
    add_files -norecurse $P/haps_top.srcs/sources_1/ip/axi_cc_dram/axi_cc_dram.xci; puts "===B58=== re-added existing axi_cc_dram.xci"
}
if {[llength [get_ips -quiet axi_cc_dram]] == 0} {
    create_ip -name axi_clock_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_cc_dram
    setp [get_ips axi_cc_dram] {CONFIG.PROTOCOL {AXI4} CONFIG.ID_WIDTH {9} CONFIG.ADDR_WIDTH {34} CONFIG.DATA_WIDTH {64} CONFIG.ACLK_ASYNC {1} CONFIG.SYNCHRONIZATION_STAGES {3}}
    setp [get_ips axi_cc_dram] {CONFIG.SI_CLK.FREQ_HZ {20000000}}
    setp [get_ips axi_cc_dram] {CONFIG.MI_CLK.FREQ_HZ {266500000}}
    puts "===B58=== created axi_cc_dram"
}
if {[llength [get_ips -quiet axi_dw_dram]] == 0 && [file exists $P/haps_top.srcs/sources_1/ip/axi_dw_dram/axi_dw_dram.xci]} {
    add_files -norecurse $P/haps_top.srcs/sources_1/ip/axi_dw_dram/axi_dw_dram.xci; puts "===B58=== re-added existing axi_dw_dram.xci"
}
if {[llength [get_ips -quiet axi_dw_dram]] == 0} {
    create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_dw_dram
    setp [get_ips axi_dw_dram] {CONFIG.PROTOCOL {AXI4} CONFIG.SI_DATA_WIDTH {64} CONFIG.MI_DATA_WIDTH {512} CONFIG.SI_ID_WIDTH {9} CONFIG.ADDR_WIDTH {34} CONFIG.FIFO_MODE {0}}
    setp [get_ips axi_dw_dram] {CONFIG.SI_CLK.FREQ_HZ {266500000}}
    puts "===B58=== created axi_dw_dram"
}
foreach n {ddr4_0 axi_cc_dram axi_dw_dram} {
    set ip [get_ips $n]
    set fh [open $SP/${n}_props58.txt w]; puts $fh [report_property -return_string $ip CONFIG.*]; close $fh
    generate_target all $ip
    puts "===B58=== generated $n"
}
set ooc_runs {}
foreach n {ddr4_0 axi_cc_dram axi_dw_dram} {
    if {[llength [get_runs -quiet ${n}_synth_1]] == 0} { create_ip_run [get_files $P/haps_top.srcs/sources_1/ip/$n/$n.xci]; puts "===B58=== created run ${n}_synth_1" }
    set r [get_runs ${n}_synth_1]
    if {[get_property PROGRESS $r] != "100%" || [get_property NEEDS_REFRESH $r]} { lappend ooc_runs $r }
}
puts "===B58=== OOC synthesis runs to do: $ooc_runs"
if {[llength $ooc_runs]} {
    launch_runs $ooc_runs -jobs 3
    foreach r $ooc_runs { wait_on_run $r; puts "===B58=== $r progress [get_property PROGRESS $r] status: [get_property STATUS $r]" }
    foreach r $ooc_runs { if {[get_property PROGRESS $r] != "100%"} { puts "===BUILD=== OOC run $r FAILED"; exit 1 } }
}
update_compile_order -fileset sources_1
puts "===BUILD=== GATED_CLOCK_CONVERSION = [get_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION [get_runs synth_1]]"
puts "===BUILD=== top = [get_property top [current_fileset]]"

# ---- elaboration check first (4 min) so port/width mistakes do not cost a 2.5 h synthesis ----
# Non-fatal: a 'module not found' here can be the OOC IP link step rather than an RTL error; the real synthesis
# below elaborates again and is the one that decides.
set elab_ok 1
if {[catch {synth_design -rtl -name rtl58 -top haps_top -part xcvu19p-fsva3824-2-e} err]} {
    puts "===ELAB=== FAILED (continuing to synth_1): [string range $err 0 600]"
    set elab_ok 0
}
if {$elab_ok} {
puts "===ELAB=== OK"
puts "===ELAB=== bridge cells: [llength [get_cells -hier -quiet -filter {NAME =~ *u_dram_ddr4*}]]"
puts "===ELAB=== bram slave cells: [llength [get_cells -hier -quiet -filter {NAME =~ *u_dram_error_slave*}]]"
puts "===ELAB=== ddr4 ip: [get_cells -hier -quiet -filter {REF_NAME == ddr4_0 || ORIG_REF_NAME == ddr4_0}]"
puts "===ELAB=== DDR4 ports: [llength [get_ports -quiet DDR4_*]] LED: [get_ports -quiet LED_DDR4_CALIB]"
close_design
}

reset_run synth_1
puts "===BUILD=== launching synth_1"
launch_runs synth_1 -jobs 8
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} { puts "===BUILD=== synth_1 FAILED"; exit 1 }
puts "===BUILD=== synth_1 complete"

# --- constraint guard ---
open_run synth_1 -name synth_guard
set ok 1
foreach c {HAPS_CLK} {
    if {[llength [get_clocks -quiet $c]] == 0} { puts "===BUILD=== MUSTMATCH FAIL: clock $c does not exist after synthesis"; set ok 0 } else { puts "===BUILD=== clock $c OK" }
}
puts "===BUILD=== synth clocks: [get_clocks]"
set fh [open $P/haps_top.runs/synth_1/runme.log r]; set lg [read $fh]; close $fh
foreach line [split $lg "\n"] {
    if {[regexp {Designutils 20-1307|Vivado 12-4739|Constraints 18-540} $line]} { puts "===BUILD=== MUSTMATCH FAIL: $line"; set ok 0 }
}
close_design
if {!$ok} { puts "===BUILD=== synth_1 FAILED constraint guard"; exit 1 }

reset_run impl_1
puts "===BUILD=== launching impl_1 through write_bitstream"
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} { puts "===BUILD=== impl_1 FAILED"; exit 1 }
puts "===BUILD=== impl_1 / bitstream complete"

open_run impl_1
set rpt $SP/timing_summary58.rpt
report_timing_summary -delay_type min_max -file $rpt -quiet
set wns [get_property SLACK [get_timing_paths -delay_type max -max_paths 1 -nworst 1]]
set whs [get_property SLACK [get_timing_paths -delay_type min -max_paths 1 -nworst 1]]
puts "===BUILD=== WNS=$wns WHS=$whs"
set fh [open $rpt r]; set content [read $fh]; close $fh
foreach line [split $content "\n"] {
    if {[string match "*WNS(ns)*" $line] || [regexp {^\s+[-0-9]} $line]} { puts "===BUILD=== SUMMARY: $line" }
}
puts "===BUILD=== impl clocks: [get_clocks]"
report_clock_interaction -file $SP/clock_interaction58.rpt -quiet
report_utilization -slr -file $SP/util_slr58.rpt -quiet
report_utilization -hierarchical -hierarchical_depth 4 -file $SP/util_hier58.rpt -quiet
report_drc -file $SP/drc58.rpt -quiet
puts "===BUILD=== latches: [llength [get_cells -hier -filter {PRIMITIVE_SUBGROUP == LATCH || REF_NAME =~ LD*}]]"
puts "===BUILD=== DONE==="
