# Build 66 = build 65 + the sdio-controller front-end fix for the card busy detection (25 Nov 2026, MBT-72 / MBT-75):
#   1. megasoc_tech/logical/sdspi on branch fix/busy-after-crc-token-mbt72-75 = SoC-Labs/sdio-controller main (2f8d794)
#      + 268bb21 "sdfrontend: start the card busy detection after the CRC status token". This also drops the local
#      sdaxil busy-window change of builds 63-65 (a6680fe), which had no effect on the fault.
#   2. boot ROM = monitor v6.0 from source (bootrom.v, md5 cabc4305), as patched into build 65.
#   Everything else (source swap, guards, 62c implementation recipe, reset controller) is the build-64 script.
set P /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top
set OUT $P/bitstreams/build66_sd_busy_token_20261125
set REPO_RTL $P/../../megasoc_tech/logical/sdspi/rtl
set IMP_RTL $P/haps_top.srcs/sources_1/imports/sdspi/rtl
set SWAP {afifo sdaxil sdax_mm2s sdax_s2mm sdckgen sdcmd sddma_mm2s sddma_rxgears sddma_s2mm sddma_txgears sddma sdfifo sdfrontend sdio sdrxframe sdskid sdtxframe sdwb}
set GATE_FILTER {NAME =~ *u_GIC400/u_gic_clk/u_inter_clkgate* && (REF_NAME == BUFGCE || ORIG_REF_NAME == BUFGCE)}
set GP {u_soc/u_megasoc_system/u_megasoc_tech_wrapper/u_megasoc_cpu_ss/u_GIC400/u_gic_clk/u_inter_clkgate_p/g_bufgce.u_bufgce}
set GPRI {u_soc/u_megasoc_system/u_megasoc_tech_wrapper/u_megasoc_cpu_ss/u_GIC400/u_gic_clk/u_inter_clkgate_pri/g_bufgce.u_bufgce}
set BITNAME haps_top_build66_sd_busy_token_[clock format [clock seconds] -format %Y%m%d].bit
proc gate_report {tag} {
  global GATE_FILTER
  set g [get_cells -hier -quiet -filter $GATE_FILTER]
  puts "===GATE=== $tag: [llength $g] GIC clock-gate BUFGCE(s)"
  foreach c $g {
    set o [get_nets -quiet -of [get_pins -quiet $c/O]]
    puts "===GATE=== $tag:   $c LOC=[get_property -quiet LOC $c] CLOCK_ROOT=[get_property -quiet CLOCK_ROOT $o] USER_CLOCK_ROOT=[get_property -quiet USER_CLOCK_ROOT $o] loads=[llength [get_pins -quiet -leaf -of $o -filter {DIRECTION==IN}]]"
  }
  return [llength $g]
}
proc sd_ports_report {tag} {
  set ps [get_ports -quiet {SDIO_CLK SDIO_CMD SDIO_DAT[*]}]
  puts "===SD=== $tag: [llength $ps] SD ports"
  foreach p $ps { puts "===SD=== $tag:   $p dir=[get_property DIRECTION $p] LOC=[get_property -quiet PACKAGE_PIN $p] IOSTD=[get_property -quiet IOSTANDARD $p] PULL=[get_property -quiet PULLTYPE $p]" }
  return [llength $ps]
}
proc rst_report {tag} {
  # the new reset controller must survive every stage: its state flops carry the policy
  set c [get_cells -hier -quiet -filter {NAME =~ u_rst_ctrl/* && (PRIMITIVE_TYPE =~ REGISTER.* || REF_NAME =~ FD*)}]
  puts "===RST=== $tag: [llength $c] flops under u_rst_ctrl; UART_RX PULLTYPE=[get_property -quiet PULLTYPE [get_ports UART_RX]]"
  return [llength $c]
}
proc tsum {tag} {
  set wns [get_property SLACK [get_timing_paths -delay_type max -max_paths 1 -nworst 1]]
  set whs [get_property SLACK [get_timing_paths -delay_type min -max_paths 1 -nworst 1]]
  set nh [llength [get_timing_paths -delay_type min -max_paths 2000 -nworst 1 -slack_lesser_than 0]]
  puts "===B66=== $tag: WNS=$wns WHS=$whs neg-hold-endpoints(first 2000)=$nh"
  return $whs
}

# ================= Part A: project mode, source swap, full synthesis, opt_design =================
open_project $P/haps_top.xpr
set_property top haps_top [current_fileset]
set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs synth_1]
set_property INCREMENTAL_CHECKPOINT {} [get_runs synth_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED false [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.TCL.PRE {} [get_runs impl_1]
set_property verilog_define {FPGA_BUILD SDFRONTEND_SPLIT_TRISTATE SDIO_AXI} [current_fileset]
puts "===B66=== verilog_define: [get_property verilog_define [current_fileset]]"
# ---- build 64 sources: the reset controller must be in sources_1; the top and the XDC must carry the build-64 text ----
set rc $P/haps_top.srcs/sources_1/new/haps_reset_ctrl.sv
if {![file exists $rc]} { puts "===BUILD=== FAILED: $rc missing (apply_build64.sh not run)"; exit 1 }
set rcf [get_files -quiet -of_objects [get_filesets sources_1] $rc]
if {[llength $rcf] == 0} { add_files -norecurse -fileset sources_1 $rc; set rcf [get_files -of_objects [get_filesets sources_1] $rc]; puts "===B66=== added $rc" }
set_property file_type SystemVerilog $rcf
set_property used_in {synthesis implementation simulation} $rcf
set fh [open $P/haps_top.srcs/sources_1/new/haps_top.sv r]; set tsrc [read $fh]; close $fh
if {![string match "*haps_reset_ctrl u_rst_ctrl*" $tsrc] || [string match "*auto_rst_period_cnt*" $tsrc]} { puts "===BUILD=== FAILED: haps_top.sv is not the build-64 version (reset controller instance)"; exit 1 }
set fh [open $P/haps_top.srcs/constrs_1/new/haps_top.xdc r]; set xsrc [read $fh]; close $fh
# (string match would read the [..] as a character class: use string first)
set pat_pullup "set_property PULLUP true \[get_ports UART_RX\]"
if {[string first $pat_pullup $xsrc] < 0} { puts "===BUILD=== FAILED: haps_top.xdc has no PULLUP on UART_RX"; exit 1 }
set fh [open $REPO_RTL/sdaxil.v r]; set asrc [read $fh]; close $fh
set pat_txswap "next_tx_mem\[7:0\], next_tx_mem\[15:8\]"
set pat_sd2s "r_sd2s_data <= (OPT_LITTLE_ENDIAN)"
if {[string first $pat_txswap $asrc] < 0 || [string first $pat_sd2s $asrc] >= 0} { puts "===BUILD=== FAILED: $REPO_RTL/sdaxil.v is not the MBT-74 version (TX swap present, sd2s swap removed)"; exit 1 }
set fh [open $REPO_RTL/sdfrontend.v r]; set fsrc [read $fh]; close $fh
if {[string first "tx_token_wait" $fsrc] < 0 || [string first "GEN_TOKEN_WAIT" $fsrc] < 0} { puts "===BUILD=== FAILED: $REPO_RTL/sdfrontend.v is not the build-66 version (no tx_token_wait)"; exit 1 }
if {[string first "r_busy_counter <= 16;" $asrc] < 0} { puts "===BUILD=== FAILED: $REPO_RTL/sdaxil.v is not the SoC-Labs main version (busy window table expected)"; exit 1 }
set romv $P/haps_top.srcs/sources_1/imports/verilog/bootrom.v
set rommd5 [lindex [exec md5sum $romv] 0]
if {$rommd5 ne "cabc4305269c44bf24de65e9be49600b"} { puts "===BUILD=== FAILED: $romv is not the monitor v6.0 ROM (md5 $rommd5)"; exit 1 }
puts "===B66=== sdfrontend has tx_token_wait, sdaxil is the main version, boot ROM is monitor v6.0"
puts "===B66=== build-66 source texts OK"
# ---- swap the sdio-controller sources (idempotent, as in build 63) ----
foreach m $SWAP {
  set imp [get_files -quiet -of_objects [get_filesets sources_1] $IMP_RTL/$m.v]
  if {[llength $imp]} { set_property IS_ENABLED 0 $imp } else { puts "===B66=== note: $IMP_RTL/$m.v not in sources_1" }
  set rp [file normalize $REPO_RTL/$m.v]
  if {![file exists $rp]} { puts "===BUILD=== FAILED: $rp missing"; exit 1 }
  set rf [get_files -quiet -of_objects [get_filesets sources_1] $rp]
  if {[llength $rf] == 0} { add_files -norecurse -fileset sources_1 $rp; set rf [get_files -of_objects [get_filesets sources_1] $rp]; puts "===B66=== added $rp" }
  set_property IS_ENABLED 1 $rf
  set_property used_in {synthesis implementation simulation} $rf
  set_property file_type SystemVerilog $rf
}
update_compile_order -fileset sources_1
# ---- guards on the compile order (build 63) ----
set n_data 0; set n_tag 0; set n_gate 0; set n_repo 0; set n_imp 0; set n_rst 0
foreach f [get_files -compile_order sources -used_in synthesis -of_objects [get_filesets sources_1]] {
  if {[string match *ca53_l2_datarams.v $f]} { incr n_data }
  if {[string match *ca53_l2_tagrams.v $f]}  { incr n_tag }
  if {[string match *gic400_inter_clkgate.v $f]} { incr n_gate }
  if {[string match *haps_reset_ctrl.sv $f]} { incr n_rst }
  if {[string match */megasoc_tech/logical/sdspi/rtl/*.v $f]} { incr n_repo }
  if {[string match */imports/sdspi/rtl/*.v $f]} { incr n_imp; puts "===B66=== still in compile order: $f" }
}
puts "===B66=== compile order: data=$n_data tag=$n_tag gate=$n_gate rst=$n_rst repo-sdspi=$n_repo imports-sdspi=$n_imp"
if {$n_data != 1 || $n_tag != 1 || $n_gate != 1 || $n_rst != 1} { puts "===BUILD=== FAILED: compile order (data=$n_data tag=$n_tag gate=$n_gate rst=$n_rst), expected 1/1/1/1"; exit 1 }
foreach m $SWAP { if {[llength [get_files -quiet -compile_order sources -used_in synthesis -of_objects [get_filesets sources_1] -filter "NAME =~ *imports/sdspi/rtl/$m.v"]]} { puts "===BUILD=== FAILED: imports copy of $m.v still compiled"; exit 1 } }
foreach m {sdax_mm2s sdax_s2mm sdaxil sddma sdio sdfrontend sdcmd sdckgen sdrxframe sdtxframe} { if {[llength [get_files -quiet -compile_order sources -used_in synthesis -of_objects [get_filesets sources_1] -filter "NAME =~ */megasoc_tech/logical/sdspi/rtl/$m.v"]] == 0} { puts "===BUILD=== FAILED: repository $m.v not in the synthesis compile order"; exit 1 } }
set gf [lindex [get_files -compile_order sources -used_in synthesis -of_objects [get_filesets sources_1] -filter {NAME =~ *gic400_inter_clkgate.v}] 0]
set fh [open $gf r]; set gsrc [read $fh]; close $fh
if {![string match *BUFGCE* $gsrc] || ![string match *DONT_TOUCH* $gsrc]} { puts "===BUILD=== FAILED: $gf is not the DONT_TOUCH BUFGCE version"; exit 1 }
set wf $P/haps_top.srcs/sources_1/imports/top_megasoc_tech/megasoc_tech_wrapper.sv
set fh [open $wf r]; set wsrc [read $fh]; close $fh
if {![regexp {OPT_EMMC\(1'b0\), \.OPT_1P8V\(1'b0\)} $wsrc]} { puts "===BUILD=== FAILED: wrapper live sdio instance does not have OPT_1P8V(1'b0)"; exit 1 }
puts "===B66=== source guards OK"
# ---- IPs ----
set ooc_runs {}
foreach n {ddr4_0 axi_cc_dram axi_dw_dram} {
  if {[llength [get_ips -quiet $n]] == 0} { puts "===BUILD=== FAILED: IP $n missing"; exit 1 }
  if {[llength [get_runs -quiet ${n}_synth_1]] == 0} { create_ip_run [get_files $P/haps_top.srcs/sources_1/ip/$n/$n.xci] }
  set r [get_runs ${n}_synth_1]
  if {[get_property PROGRESS $r] != "100%" || [get_property NEEDS_REFRESH $r]} { lappend ooc_runs $r }
}
puts "===B66=== OOC synthesis runs to do: $ooc_runs"
if {[llength $ooc_runs]} { launch_runs $ooc_runs -jobs 3; foreach r $ooc_runs { wait_on_run $r; if {[get_property PROGRESS $r] != "100%"} { puts "===BUILD=== OOC run $r FAILED"; exit 1 } } }
# ---- elaboration: 2 gates, 6 SD ports, reset controller present ----
if {[catch {synth_design -rtl -name rtl66 -top haps_top -part xcvu19p-fsva3824-2-e} err]} { puts "===ELAB=== FAILED: [string range $err 0 800]"; exit 1 }
puts "===ELAB=== OK"
set ok 1
if {[gate_report ELAB] != 2} { puts "===BUILD=== FAILED: elaboration does not show 2 GIC BUFGCEs"; set ok 0 }
if {[sd_ports_report ELAB] != 6} { puts "===BUILD=== FAILED: expected 6 SD ports"; set ok 0 }
if {[llength [get_cells -quiet u_rst_ctrl]] != 1} { puts "===BUILD=== FAILED: u_rst_ctrl not in the elaborated design"; set ok 0 }
close_design
if {!$ok} { exit 1 }
# ---- synthesis ----
reset_run synth_1
puts "===BUILD=== launching synth_1"
launch_runs synth_1 -jobs 8
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} { puts "===BUILD=== synth_1 FAILED"; exit 1 }
puts "===BUILD=== synth_1 complete"
set fh [open $P/haps_top.runs/synth_1/runme.log r]; set lg [read $fh]; close $fh
foreach line [split $lg "\n"] { if {[regexp {Designutils 20-1307|Vivado 12-4739|Constraints 18-540} $line]} { puts "===BUILD=== MUSTMATCH FAIL: $line"; set ok 0 } }
if {[regexp {Incremental synthesis run: yes|read_checkpoint -auto_incremental} $lg]} { puts "===BUILD=== FAILED: synth_1 ran incrementally"; set ok 0 }
set n1p8 [regexp -all {Parameter OPT_1P8V bound to: 1'b1} $lg]; set n0p8 [regexp -all {Parameter OPT_1P8V bound to: 1'b0} $lg]
puts "===B66=== synth log: OPT_1P8V bound 1'b1 x$n1p8, 1'b0 x$n0p8"
if {$n1p8 != 0} { puts "===BUILD=== FAILED: OPT_1P8V still bound to 1 somewhere"; set ok 0 }
set srcs [regexp -all -inline {synthesizing module 'sd[a-z_0-9]*' \[[^\]]*\]} $lg]
foreach s0 [lsort -unique $srcs] { puts "===B66=== $s0" }
if {[regexp {synthesizing module 'sd[a-z_0-9]*' \[[^\]]*imports/sdspi} $lg]} { puts "===BUILD=== FAILED: an sd* module was synthesised from the imports copy"; set ok 0 }
if {![regexp {synthesizing module 'haps_reset_ctrl'} $lg]} { puts "===BUILD=== FAILED: haps_reset_ctrl was not synthesised"; set ok 0 }
foreach line [split $lg "\n"] { if {[regexp {Parameter (AUTO_RST_PERIOD|BOOT_DETECT_MIN|RESET_REQ_MIN_LOW|RX_HOLDOFF_LOAD|RST_LEN_LOG2) bound to} $line]} { puts "===RST=== $line" } }
open_run synth_1 -name synth_guard
if {[llength [get_clocks -quiet HAPS_CLK]] == 0} { puts "===BUILD=== MUSTMATCH FAIL: clock HAPS_CLK missing"; set ok 0 }
if {[gate_report SYNTH] != 2} { puts "===BUILD=== FAILED: synthesis did not keep the 2 GIC BUFGCEs"; set ok 0 }
if {[sd_ports_report SYNTH] != 6} { puts "===BUILD=== FAILED: SD ports missing after synthesis"; set ok 0 }
if {[rst_report SYNTH] < 100} { puts "===BUILD=== FAILED: reset controller flops missing after synthesis (expected ~150: 28+2+1+20+1+32+28+1+2+16)"; set ok 0 }
set tw [get_cells -hier -quiet -filter {NAME =~ *GEN_TOKEN_WAIT*r_token_wait_reg* || NAME =~ *GEN_TOKEN_WAIT*r_token_count_reg*}]
puts "===SD=== SYNTH: [llength $tw] token-wait flops: $tw"
if {[llength $tw] < 2} { puts "===BUILD=== WARNING: token-wait flops of sdfrontend not found by name after synthesis (check the netlist)" }
if {[get_property -quiet PULLTYPE [get_ports UART_RX]] != "PULLUP"} { puts "===BUILD=== FAILED: UART_RX has no PULLUP after synthesis"; set ok 0 }
puts "===SD=== SYNTH: [llength [get_cells -hier -quiet -filter {NAME =~ *SDIO_* && (REF_NAME =~ IOBUF* || REF_NAME =~ OBUF* || REF_NAME =~ IBUF*)}]] SD pad buffers"
puts "===BUILD=== synth BRAM: [llength [get_cells -hier -quiet -filter {PRIMITIVE_TYPE =~ BLOCKRAM.*}]] block RAM primitives"
close_design
if {!$ok} { puts "===BUILD=== synth_1 FAILED guard"; exit 1 }
# ---- impl_1 to opt_design ----
reset_run impl_1
puts "===BUILD=== launching impl_1 to opt_design"
launch_runs impl_1 -to_step opt_design -jobs 8
wait_on_run impl_1
set optdcp $P/haps_top.runs/impl_1/haps_top_opt.dcp
if {![file exists $optdcp] || [string match -nocase *error* [get_property STATUS [get_runs impl_1]]]} { puts "===BUILD=== impl_1 opt_design FAILED: [get_property STATUS [get_runs impl_1]]"; exit 1 }
close_project
puts "===BUILD=== opt_design complete, switching to the non-project recipe"

# ================= Part B: non-project, the 62c recipe from the opt checkpoint (unchanged from build 63) =================
set_param general.maxThreads 8
set_param route.enableHoldExpnBailout 0
open_checkpoint $optdcp
if {[gate_report OPT] != 2} { puts "===BUILD=== FAILED: opt_design removed the GIC BUFGCEs"; exit 1 }
if {[llength [get_cells -quiet $GP]] != 1 || [llength [get_cells -quiet $GPRI]] != 1} { puts "===BUILD=== FAILED: gate BUFGCE names changed"; exit 1 }
rst_report OPT
set_property LOC BUFGCE_X0Y34 [get_cells $GP]
set_property LOC BUFGCE_X0Y35 [get_cells $GPRI]
set_property USER_CLOCK_ROOT X4Y8 [get_nets -of [get_pins $GP/O]]
set_property USER_CLOCK_ROOT X4Y8 [get_nets -of [get_pins $GPRI/O]]
gate_report CONSTRAINED
place_design
puts "===B66=== place_design done; main clk CLOCK_ROOT=[get_property -quiet CLOCK_ROOT [get_nets clk]]"
gate_report PLACED
tsum PLACED
phys_opt_design
tsum PHYSOPT
write_checkpoint -force $OUT/haps_top_physopt66.dcp
route_design
puts "===B66=== route_design done"
set whs [tsum ROUTED]
gate_report ROUTED
write_checkpoint -force $OUT/haps_top_routed66.dcp
set attempt 0
while {$whs < 0 && $attempt < 3} {
  incr attempt
  set paths [get_timing_paths -delay_type min -max_paths 200 -nworst 1 -slack_lesser_than 0]
  set nets {}
  foreach p $paths { set n [get_nets -quiet -of [get_pins [get_property ENDPOINT_PIN $p]]]; if {[llength $n] && [lsearch $nets $n] < 0} { lappend nets $n } }
  puts "===B66=== hold attempt $attempt: [llength $paths] failing endpoints, [llength $nets] nets"
  if {[llength $paths] > 200} { puts "===B66=== too many hold violators for the net re-route recipe; trying phys_opt_design -hold_fix once"; phys_opt_design -hold_fix; set whs [tsum PHYSOPT_HOLD]; break }
  set margin [expr {0.150 * $attempt}]
  set_clock_uncertainty -hold $margin [get_clocks HAPS_CLK]
  route_design -unroute -nets $nets
  route_design -preserve
  set_clock_uncertainty -hold 0.0 [get_clocks HAPS_CLK]
  set whs [tsum "HOLDFIX_$attempt"]
}
puts "===SD=== ROUTED: [sd_ports_report ROUTED] SD ports; sdio_clk_pad clocks: [llength [get_clocks -quiet sdio_clk_pad]]"
rst_report ROUTED
report_timing_summary -delay_type min_max -file $OUT/timing_summary66.rpt -quiet
report_timing -to [get_ports {SDIO_CMD SDIO_DAT[*] SDIO_CLK}] -max_paths 6 -file $OUT/sd_out_timing66.rpt -quiet
report_timing -from [get_ports {SDIO_CMD SDIO_DAT[*]}] -max_paths 6 -file $OUT/sd_in_timing66.rpt -quiet
report_drc -file $OUT/drc66.rpt -quiet
report_clock_utilization -file $OUT/clock_utilization66_routed.rpt -quiet
report_utilization -slr -file $OUT/util_slr66.rpt -quiet
puts "===B66=== latches: [llength [get_cells -hier -filter {PRIMITIVE_SUBGROUP == LATCH || REF_NAME =~ LD*}]]"
write_checkpoint -force $OUT/haps_top_routed66_final.dcp
if {$whs < 0} { puts "===BUILD=== FAILED: hold not closed (WHS=$whs); no bitstream written"; exit 1 }
write_bitstream -force $OUT/$BITNAME
puts "===B66=== bitstream written: $OUT/$BITNAME"
puts "===BUILD=== DONE==="
