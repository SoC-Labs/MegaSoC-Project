###############################################################################
# HAPS-SX VU19P 1F - MegaSoC Bring-Up Constraints
#
# Pin assignments verified against HAPS-SX VU19P 1F System Reference Manual.
#
# Clock:   GCLK1 (LVDS, bank 20) - BM44/BN44
# Reset:   PB1 push button (bank 20) - BK44
# LEDs:    LED5 green (bank 83) - BF14
# UART:    PMOD2 connector (bank 88, SLR1) - BB16/BB17
# QSPI:    On-board SPI flash (bank 21) - CA49/CB49/CC49/CC50/CA51/CB51
#
# Bank voltages:
#   Bank 20 = 1.8V (fixed - push buttons, clock input)
#   Bank 21 = 1.8V (fixed - SPI flash, Mictor)
#   Bank 83 = 1.8V (fixed - LEDs, PMOD3)
#   Bank 88 = UNVERIFIED for this board - see PMOD2 UART note below
#
# A joint work commissioned on behalf of SoC Labs, under Arm Academic
# Access license.
#
# Contributors
#   Anastasios Dimitriou (ad1u25@soton.ac.uk)
#
# Copyright 2021-4, SoC Labs (www.soclabs.org)
###############################################################################

############################
# Clock - GCLK1 (LVDS differential)
#
# GCLK1 = 20 MHz in ConfPro (deliberate - see below).
#
# NOTE: normal operation is 100 MHz - the HAPS JTAG debug infrastructure
# on this target is fixed at 10 MHz and the ILA/debug-hub clock-domain-
# crossing logic needs several times that on the design clock to read
# trace data back reliably.
#
# 20 MHz timing-margin experiment (2026-07-30): ran with zero timing
# violations (WNS/TNS/WHS/THS all clean, all endpoints passing) and the
# CPU still never issued its first AXI fetch, ruling out the un-promoted
# PREICG_X4B_A9TS_C31 clock-gate timing as the root cause. Staying at
# 20 MHz deliberately from here on - ILA readback is confirmed corrupted
# at this frequency (Xicom 50-38/50-41, frozen clock-toggle probe,
# simultaneous glitches on unrelated signals), so debug visibility now
# comes from a dedicated RTL UART event-logger (see debug_uart_probe.sv)
# instead of the ILA/JTAG path. UART loopback confirmed the UART path
# itself (dongle/cable/terminal) is fine.
############################
set_property PACKAGE_PIN BM44 [get_ports HAPS_CLK_IN_P]
set_property PACKAGE_PIN BN44 [get_ports HAPS_CLK_IN_N]
set_property IOSTANDARD LVDS [get_ports HAPS_CLK_IN_P]
set_property IOSTANDARD LVDS [get_ports HAPS_CLK_IN_N]

# 20 MHz clock (50 ns period)
create_clock -period 50.000 -name HAPS_CLK [get_ports HAPS_CLK_IN_P]

# 2026-09-30: clock uncertainty split into -setup and -hold.
#
# This used to be `set_clock_uncertainty 0.500 [get_clocks HAPS_CLK]`. Without
# -setup, that value applies to HOLD checks as well, and it turned out to be
# the entire remaining hold problem in this design.
#
# Measured on the routed build of 2026-09-29 (WHS -0.615 ns):
#   - worst hold path: data 0.239 ns, clock skew 0.292 ns, Clock Uncertainty
#     0.500 ns of which User Uncertainty 0.500 ns and every jitter term 0.000;
#   - all 2000 worst failing hold paths were inside one SLR, with a mean clock
#     skew of 0.060 ns - so not skew, and not SLR crossings;
#   - THS -11,592 ns across the 19,696 pins the router reported it could not
#     fix is an average violation of 0.59 ns, i.e. this margin plus a little.
# So the design was being asked for half a nanosecond of extra delay on every
# direct flop-to-flop path, the router gave up ("[Route 35-514] Design has a
# large number of hold violators. This is likely a design or constraint issue.
# Router is turning off hold fixing"), and post-route phys_opt cleaned up what
# it could alone. It WAS a constraint issue.
#
# For paths launched and captured by the same edge of the same clock, source
# jitter is common to both flops and cancels; Vivado's own computed hold
# uncertainty here is 0.000 ns. The 0.500 ns margin is meaningful for setup
# (it guards against period jitter on the board clock) and is kept there. Hold
# gets a small explicit guardband instead of a blanket half-nanosecond.
set_clock_uncertainty -setup 0.500 [get_clocks HAPS_CLK]
set_clock_uncertainty -hold  0.050 [get_clocks HAPS_CLK]

# 2026-09-30: `set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets
# u_ibufds_clk/O]` MOVED to haps_top_clocks_impl.xdc (implementation only).
# It is an implementation constraint on a net that does not resolve during
# synthesis, so every synthesis log carried "set_property CLOCK_DEDICATED_ROUTE
# could not find object" - a warning that had to be mentally filtered out, in a
# project where silently-unmatched constraints have caused real damage. With
# it gone, the build script's post-synthesis gate can treat ANY unmatched
# constraint in the synthesis log as a failure.
#
# Its original rationale (~100-140 clock-gate BUFGCEs spread across the device,
# each wanting the clock source) no longer applies: every clock gate is now
# bypassed and only two global buffers hang off the IBUFDS. It is retained in
# the implementation file because removing it is an untested change, not
# because it is known to still be needed.

# 2026-09-08: REMOVED. This blanket "hold waiver - standard for large SoC
# prototypes on single clock" (set_false_path -hold -from/-to [get_clocks
# HAPS_CLK]) was the actual root cause hidden underneath all the pblock
# work below. In Vivado, -hold-class exceptions cover BOTH ordinary Hold
# AND Removal (an independent SoC-Labs constraints review of this file
# reached the same conclusion independently, from SDC semantics rather
# than the empirical route we took). HAPS_CLK is the only clock, so
# -from + -to spanned every sequential path in the design: this didn't
# just hide stop_clk_reg's Removal check, it hid EVERY hold/removal check
# in the whole design. Every "WHS clean" result recorded in this file's
# history measured nothing real for hold/removal - the pblock below
# empirically helped (0/46 -> 100% on real hardware) but was never
# verified against an actual, unblinded timing analysis until now.
#
# The set_max_delay -datapath_only override that used to sit here is
# removed too - it only ever constrained Recovery (~50ns slack, never
# failing) and was outranked by the false_path above anyway (SDC
# precedence: set_false_path always wins over set_max_delay/set_min_delay
# on the same path, confirmed empirically earlier this session). It did
# nothing.
#
# Deliberately NOT touching the pblock below in this same change - it's
# the one thing with real hardware proof behind it (164/164 boot success
# across two independent clean captures, builds 23-25). This removal is
# an isolated experiment: same physical placement, real hold/removal
# analysis turned back on, see what a genuinely unblinded build reports.
# Expect new violations to surface elsewhere in the design (predicted by
# the same review - ~20 of 24 BUFGCEs are driven by combinational LUT2
# logic rather than a clean source, which creates real, previously-hidden
# hold exposure independent of stop_clk_reg specifically). If so, the
# next step is likely the RTL-level fix (bypass clock gating to one net)
# rather than XDC exceptions - re-litigating exception scoping already
# failed once (see git history 2026-08-27 through 2026-09-01) and isn't
# worth repeating.
#
# 2026-09-09: build 26 (waiver removed, everything else unchanged) came
# back with 157k-168k failing hold endpoints, worst slack -3.719ns.
# phys_opt_design -hold_fix (Vivado's standard automatic hold-buffer
# insertion, never once run on this design since hold was always waived)
# barely moved it: 168745 -> 168706 failing endpoints. Confirms this isn't
# ordinary local-routing hold slop that place/route can absorb on its own.
#
# Root-caused the dominant failure: the single worst path in the whole
# design is a Removal check (same failure class as stop_clk_reg, path
# group **async_default**), from ca53_cpu_reset.v's u_ca53_cell_sync1/
# r1_reg - the "second hazard" flagged and deprioritized earlier this
# investigation - into a CLR pin inside u_ca53ifu_pf_bpd's branch-
# predictor table (6488 flops in that one module). A 3000-path sample of
# the worst failing endpoints showed 94% landing in that same module -
# not because it has its own defect, but because one bad net's fanout
# hits thousands of individual CLR pins across a huge register array.
# ca53_cell_sync.v (the generic synchroniser cell backing both this and
# stop_clk_reg's u_ca53_cell_sync0) is a plain 2-FF r0/r1 chain with no
# ASYNC_REG anywhere in the RTL or this XDC, despite genuinely being an
# async-to-sync boundary (inp_i and resetn_i tied to the same net at each
# instantiation, so r0's D changes at the instant its own async clear
# releases - textbook metastability-capture flop). 36 instantiation sites
# project-wide.
#
# Fix: tag every instance's r0/r1 pair ASYNC_REG. This tells Vivado's
# placer to keep each synchroniser's two stages close together and tells
# the STA engine these are genuine synchronisers, not ordinary same-clock
# logic - the standard, textbook way to declare this in Xilinx tools
# (matches ARM's own generic ca53_cell_sync intent, just never actually
# marked as such for FPGA synthesis). Doing this via XDC rather than
# editing the read-only AAA-licensed RTL.
set_property ASYNC_REG TRUE [get_cells -hier -filter {NAME =~ "*ca53_cell_sync*/r0_reg" || NAME =~ "*ca53_cell_sync*/r1_reg"}]

# 2026-09-02: build 13 (identical XDC to the known-working build 6, same
# hold waiver, same set_max_delay above) still came back 0/46 for
# ARVALID/RVALID on real hardware - proof build 6's success was never
# actually guaranteed by these constraints, just a lucky placement outcome
# on that particular run. The real Removal-timing hazard on stop_clk_reg's
# async PRE (see the long comment above) is still genuinely unconstrained
# in every build using this XDC; different builds' placement just happens
# to land on different sides of the real margin. Multiple attempts to fix
# this by reconstructing the timing-exception scope all failed or broke
# something else (see above and git history).
#
# This is a placement constraint instead, not a timing exception - it
# can't affect any other path's hold-waiver coverage the way the exception
# rewrites did, since it only tells the placer where these two specific
# cells may go, independent of any -hold/-to/-from exception scoping.
# Region chosen from where these two cells have actually landed across
# several real builds this session (e.g. SLICE_X218Y452/453,
# SLICE_X184-193Y485).
#
# 2026-09-02: the first version of this pblock (60x60 slices,
# SLICE_X170Y440:SLICE_X230Y500) measurably helped on real hardware
# (sticky ARVALID-ever latch went from 0/46 to 12/16 boot attempts) but
# left the two cells 54 columns / 23 rows apart within that region -
# achieved Removal margin only +0.085ns when checked directly (interactive
# report_timing, not part of the actual build's own analysis, which still
# treats this path as a false path per the reverted exception scoping
# above). CLOCK_REGION query confirmed both cells land in the same clock
# region row (Y7) but adjacent columns (X3 vs X4) - the "SLR Crossing"
# noted in that report is in the clock TREE's shared path from its fixed
# physical root, largely (not perfectly) cancelled by clock pessimism
# removal for a shared net, not something a 2-cell pblock can address
# directly.
#
# Tried shrinking to 20x20 slices (SLICE_X190Y440:SLICE_X210Y460) next,
# expecting tighter proximity to help further. It didn't: pblocks are soft
# constraints by default, and the placer partially ignored the tighter
# box anyway (stop_clk_reg landed at X124, 76 columns from r1_reg at
# X200 - further apart than the 60x60 version's 54, even though PBLOCK
# membership still showed assigned). Directly-checked achieved Removal
# margin came back WORSE: -0.034ns (violated) vs the 60x60 version's
# +0.085ns (met). Both results sit within ~0.1ns of the real threshold
# regardless of region size, suggesting this path's true physical margin
# is inherently thin and not reliably improvable by naive pblock-size
# tuning alone. Reverted to the 60x60 version below, since it's the one
# actually confirmed on real hardware to substantially help (0/46 boot
# attempts -> 12/16 for the sticky ARVALID-ever latch). If better
# reliability is needed beyond this, likely candidates are an RLOC-based
# true-adjacency constraint (stronger than a pblock) or addressing the
# separate ca53_cpu_reset.v hazard found during this investigation
# (affects many other clock-gate-enable registers, could account for some
# of the remaining ~25% failure rate independently of this specific path).
#
# Also tried a LARGER region (200x200, SLICE_X100Y350:SLICE_X300Y550,
# same center) than the 60x60 version, expecting more placer freedom to
# find a naturally better solution than either the cramped 20x20 or an
# arbitrarily-bounded box. It found the CLOSEST proximity of any attempt
# (1 column, 30 rows apart - versus 54 for 60x60 and 76 for 20x20), but
# the achieved Removal margin was the WORST of the three: -0.131ns.
#
# This reframes the whole approach: Removal is a MINIMUM-delay check, not
# a maximum-delay one - unlike an ordinary setup/recovery concern, it
# needs the data path delay to be large enough, not small, so shrinking
# physical distance pushes the wrong direction. But the three results
# (+0.085ns at 54 cols, -0.034ns at 76 cols, -0.131ns at 1 col) don't
# form a clean, monotonic relationship with distance either - clock skew
# and the specific routing path taken clearly matter as much as raw
# proximity. Concluded blind pblock-size tuning isn't converging
# reliably (three iterations, three different outcomes, no clear trend
# to keep pushing). Reverted to the 60x60 version, the only one with
# actual confirmed hardware data (0/46 -> 12/16 for the sticky
# ARVALID-ever latch, a real, substantial improvement over no pblock at
# all). Further improvement, if needed, likely requires something more
# deliberate than size-tuning - e.g. explicitly targeting a specific
# minimum (not just any) delay via RLOC or a routing-aware constraint -
# or addressing the separate ca53_cpu_reset.v hazard found during this
# investigation instead.
# 2026-09-30: pblock_governor_clkgate_proximity REMOVED (kept below, commented).
#
# Everything the long history above says about it was true of the design it was
# written for. None of it is true of the design being built now:
#
#   - It was aimed at a Removal path from u_ca53_cell_sync0/r1_reg into
#     stop_clk_reg's async preset, feeding a clock gate. Every clock gate is
#     now bypassed, stop_clk_reg has no load and is optimised away, and the
#     pblock was found (2026-09-22 netlist) to contain ONE cell, not two.
#   - Its region, SLICE_X170Y440:SLICE_X230Y500, is clock-region rows Y7-Y8,
#     i.e. SLR1. The design now places almost entirely in SLR0 (2026-09-29
#     build: 46,989 slices in SLR0, 38 in SLR1). So it was pinning one leftover
#     synchroniser flop several clock regions - and an SLR boundary - away
#     from the logic it belongs to.
#   - The hardware evidence for it (0/46 -> 28/36 boots) was read through a
#     debug logger since shown unable to report ARVALID reliably, so that
#     figure does not establish what it was taken to establish.
#
# If a placement constraint on the governor's reset synchroniser is ever wanted
# again, it should be re-derived against the current netlist, not restored.
#
# create_pblock pblock_governor_clkgate_proximity
# resize_pblock pblock_governor_clkgate_proximity -add {SLICE_X170Y440:SLICE_X230Y500}
# add_cells_to_pblock pblock_governor_clkgate_proximity [get_cells -hier -filter { \
#   NAME =~ "*u_governor_cpu_clk_reset/u_ca53_cell_sync0/r1_reg" \
#   || NAME =~ "*u_governor_cpu_clk_reset/stop_clk_reg" \
# }]

# 2026-09-03: also tried explicit LOC-pinning both cells to a specific,
# hand-picked, verified-empty site pair (SLICE_X170Y456 / SLICE_X224Y456 -
# same 54-column X separation as this pblock's best measured result,
# +0.085ns, but on the identical Y row to eliminate row-level clock skew).
# It came back WORSE: -0.123ns (violated), with clock skew still 0.139ns
# despite the matched row (confirming skew isn't simply a function of row
# alignment - finer routing/BEL-level factors we can't predict by hand
# are at play) and a smaller data path delay than the pblock version
# despite the "same" column distance. That's four real data points now
# (this pblock's own natural result: +0.085ns MET; 20x20: -0.034ns;
# 200x200: -0.131ns; this LOC pin: -0.123ns) and none of three deliberate,
# reasoned attempts beat Vivado's own free placement within this
# moderate-sized region. Concluded hand-engineering a better placement
# for this specific path isn't working reliably with the tools/visibility
# we have, and reverted to this plain pblock - the one config with actual
# confirmed hardware data (0/46 -> 28/36, ~78%).


############################
# Reset - PB1 push button (active low)
# Bank 20, 1.8V fixed
############################
set_property PACKAGE_PIN BK44 [get_ports HAPS_RESET_N]
set_property IOSTANDARD LVCMOS18 [get_ports HAPS_RESET_N]
set_false_path -from [get_ports HAPS_RESET_N]

############################
# Heartbeat - LED5 (green, active high)
# Bank 83, 1.8V fixed
############################
set_property PACKAGE_PIN BF14 [get_ports HB]
set_property IOSTANDARD LVCMOS18 [get_ports HB]

############################
# UART0 - PMOD2 connector (bank 88, SLR1)
#
# Moved from PMOD3 to PMOD2 (2026-07-30). Pin locations and the LVCMOS33
# voltage below are carried over from a DIFFERENT project's constraints for
# this same physical HAPS-SX kit (not independently verified against this
# specific board/unit) - that source flags that the HAPS-SX manual's own
# "Bank Voltage" column is wrong for the PMOD headers (says 1.8V, bench-
# measured as 3.3V on their unit). VERIFY WITH A MULTIMETER on PMOD2 pin 6
# or 12 before connecting a USB-UART dongle - do not trust this over a
# direct bench measurement. Getting this wrong risks overdriving the
# dongle or the FPGA input.
#
# PMOD2 pinout (2x6 header):
#   Pin 3 (IO[2]) = BB16 = uart_txd (FPGA output, SoC transmits)
#   Pin 4 (IO[3]) = BB17 = uart_rxd (FPGA input,  SoC receives)
#   Pin 5  = GND    Pin 11 = GND
#   Pin 6  = supply Pin 12 = supply (verify voltage - see above)
#
# Cross TX/RX at the dongle: dongle RX <- BB16 (uart_txd),
# dongle TX -> BB17 (uart_rxd). Ground the dongle to PMOD2 pin 5 or 11.
# Note: pins 1,2,7,8 on PMOD2 may be in use elsewhere (MDIO/MDIO_DIR/
# PHY_NRST/PPS in the source project) - not used by this design, but
# worth checking against your own PMOD2 wiring before assuming they're free.
############################
set_property PACKAGE_PIN BB16 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]

set_property PACKAGE_PIN BB17 [get_ports UART_RX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RX]

############################
# PL011 secondary UART - PMOD3 IO[2]
############################
set_property PACKAGE_PIN BG19 [get_ports PL011_TX]
set_property IOSTANDARD LVCMOS18 [get_ports PL011_TX]

############################
# Debug UART event logger - PMOD3 IO[3] (bank 83, 1.8V, documented/
# trusted pinout - unlike PMOD2's LVCMOS33, this one is verified against
# the HAPS-SX manual, not a secondhand reference). See debug_uart_probe.sv.
############################
set_property PACKAGE_PIN BF19 [get_ports DEBUG_UART_TX]
set_property IOSTANDARD LVCMOS18 [get_ports DEBUG_UART_TX]

############################
# QSPI - On-board SPI Flash (W25Q32FW)
# Bank 21, 1.8V fixed
############################
set_property PACKAGE_PIN CA49 [get_ports QSPI_SCLK]
set_property IOSTANDARD LVCMOS18 [get_ports QSPI_SCLK]

set_property PACKAGE_PIN CB49 [get_ports QSPI_nCS]
set_property IOSTANDARD LVCMOS18 [get_ports QSPI_nCS]

set_property PACKAGE_PIN CC49 [get_ports {QSPI_IO[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {QSPI_IO[0]}]

set_property PACKAGE_PIN CC50 [get_ports {QSPI_IO[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {QSPI_IO[1]}]

set_property PACKAGE_PIN CA51 [get_ports {QSPI_IO[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {QSPI_IO[2]}]

set_property PACKAGE_PIN CB51 [get_ports {QSPI_IO[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {QSPI_IO[3]}]

# 2026-09-14: QSPI_SCLK_i (qspi_clock_div.v, inside u_sl_ahb_qspi) is a
# genuine second clock - HCLK divided by QSPI_CLK_DIV, a runtime-writable
# register, not a fixed ratio. It had no clock declaration at all in this
# file, so Vivado was auto-propagating HAPS_CLK's own waveform through the
# divider's passthrough mux and analyzing QSPI_SCLK_i-domain flops (e.g.
# u_qspi_controller/data_in_reg) as if same-edge with HAPS_CLK - confirmed
# as the mechanism behind the QSPI cluster of hold violations found while
# investigating the post-waiver-removal timing picture (worst path traced
# to exactly this: a HAPS_CLK-domain source into a QSPI_SCLK_i-domain
# destination, both reported "clocked by HAPS_CLK").
#
# Declared as its own clock here, sourced from the buffered root clock and
# using divide_by 2 as a representative ratio (the fastest non-passthrough
# case, i.e. QSPI_CLK_DIV=1 toggling every HCLK edge) purely so same-domain
# analysis inside qspi_controller/qspi_controller_mux has *some* period to
# check against - real hardware always runs the SPI clock equal to or
# slower than this, so it's a conservative choice, not an exact one (the
# actual ratio is software-configurable at runtime and cannot be captured
# by a single static divide value). Declared at this specific synchroniser
# flop's clock pin (added in qspi_controller.sv, predictable post-synth
# name) rather than at the divider's own output, to sidestep needing to
# trace generated-clock propagation through the passthrough mux by hand.
#
# 2026-09-15: attempted a create_generated_clock + set_clock_groups
# -asynchronous declaration here first (build 29). Checked directly
# afterward: it only applied to the one leaf pin it was declared on (1 of
# 1434 sequential cells in u_sl_ahb_qspi actually resolved to QSPI_SCLK_i;
# everything else stayed on HAPS_CLK) - declaring a generated clock at a
# downstream consumer's pin doesn't propagate it network-wide the way
# declaring it at the true source does, and this source is additionally a
# runtime-selected 2:1 mux between HCLK and the divided clock (see
# qspi_clock_div.v), a genuinely tricky case for clock propagation to
# trace through unambiguously. Result: no real improvement (build 29's
# endpoint count was flat-to-slightly-worse vs build 28).
#
# 2026-09-16: set_false_path on these three (build 30/30b) built badly
# twice in a row - once stalled indefinitely in routing (12h+, congestion
# spiking to 100k+ overlapping nodes in CA53-internal logic unrelated to
# QSPI), once finished routing (~14.5h) but left 8 nets with unresolved
# RTSTAT-6 partial route conflicts, also in unrelated CA53-internal logic
# (TLB, BIU linefill mgmt, store buffer, DCU load-store pipe), blocking
# write_bitstream. Build 29, with the RTL synchronisers in place but no
# XDC exception at all (still using the non-functional generated-clock
# attempt), built fine - so the false_path itself, not the RTL change, is
# the likely trigger: removing all timing pressure from these 3 paths
# appears to let the placer land on a much harder-to-route solution
# elsewhere, even though the paths themselves are physically unrelated to
# the congestion.
#
# Narrower fix: set_max_delay -datapath_only instead of a full
# false_path. This still excuses the bogus same-edge check (there is no
# statically provable phase relationship to verify, since QSPI_CLK_DIV is
# runtime-writable) but gives the placer/router a concrete, boundeded
# target to route toward rather than "don't care at all" freedom - the
# same distinction this file already documents for Recovery-side
# constraints elsewhere. 40ns (comfortably under the 50ns HAPS_CLK period,
# generous for a single-LUT-level synchroniser data path) is a
# conservative, arbitrary-but-safe bound, not a precisely-derived one -
# appropriate for a boundary with no fixed timing relationship to pin down
# exactly anyway. The metastability risk itself is handled separately, in
# RTL: QSPI_ENABLE (forward) and AHB_QSPI_ENABLE_ACK / AHB_QSPI_BUSY
# (return) are real 2-stage ASYNC_REG synchronisers in qspi_controller.sv
# / ahb_qspi_interface.sv - this constraint only excuses the (otherwise
# meaningless) static timing check on their first stage, it doesn't
# substitute for the synchroniser itself.
# 2026-09-23 (Build B): REMOVED, and the problem underneath them removed too.
#
# Two things were wrong with these three lines. First, they never did anything:
# Vivado requires -datapath_only to be accompanied by -from, and rejected all
# three outright on every build with "CRITICAL WARNING: [Constraints 18-540]
# set_max_delay -datapath_only requires -from to be non-empty". So the "narrower
# fix" recorded above was never actually in force - which also reframes the
# build 30/30b routing failures: that experiment compared set_false_path against
# *no constraint at all*, not against set_max_delay.
#
# Second, they are now unnecessary. QSPI_SCLK_i is no longer a clock: the whole
# of u_sl_ahb_qspi runs on HCLK with SCLK reduced to a registered level plus two
# single-cycle edge enables (see qspi_clock_div.v). Source and destination of
# these paths are the same clock, so there is no crossing left to except, and
# the 901 no-clock register/latch pins measured on the 2026-09-22 netlist -
# essentially all of them in this block - should now be properly analyzed.
#
# The QSPI_enable_meta/_sync pair is kept in RTL as a plain two-stage pipeline.

# I/O timing for the boot flash: see haps_top_qspi_io_impl.xdc.
#
# 2026-09-28: the first version of these constraints (in this file) referenced
# the flash I/O delays to HAPS_CLK. That was the wrong reference - the flash
# samples MOSI and launches MISO relative to SCLK at the pin, not relative to
# our internal 20 MHz clock - so they have been replaced by a pad-level
# generated clock plus SCLK-referenced delays.
#
# They live in a separate, implementation-only constraint file because
# create_generated_clock needs the buffered clock net and the port, neither of
# which resolves during synthesis (the same reason CLOCK_DEDICATED_ROUTE on
# line 66 reports "could not find object" in the synthesis log). Structure
# borrowed from D. Mapstone's Pynq-Z2 AHB-QSPI constraints for the same IP,
# adapted: that design clocks the controller FROM SCLK, which this one no
# longer does (see qspi_clock_div.v), so only the pad-level clock carries over
# and the internal generated clock is deliberately omitted.

# Asynchronous / don't-care outputs - these are LED and UART pins with no
# receiver timing requirement, and were previously unconstrained by omission
# rather than by intent.
set_false_path -to   [get_ports {UART_TX PL011_TX DEBUG_UART_TX HB}]
set_false_path -from [get_ports UART_RX]



# 2026-10-08: REMOVED - `set_false_path -to [get_pins -hier -filter {NAME =~
# "*ca53_core0_clk_toggle_sync1_reg*/D"}]`.
#
# It was added when ca53_core0_clk_toggle_src was clocked by the CA53's own
# gated clock, making its capture into the SYS_CLK domain a genuine
# asynchronous crossing that a 2-flop synchroniser resolves and static timing
# should not judge. That premise is gone: every clock gate is bypassed, so the
# source flop is on HAPS_CLK, the same clock as the capture flop, and this was
# excluding an ordinary same-clock path. The routed design of 2026-10-05 has
# exactly one clock network and no unconstrained endpoints; this was the last
# exception in the project without a current justification. It is now timed
# like everything else. The ASYNC_REG pair in megasoc_tech_wrapper.sv is left
# in place - harmless, and correct again should gating ever be re-enabled.
