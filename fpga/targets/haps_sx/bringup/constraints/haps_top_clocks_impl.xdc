#-----------------------------------------------------------------------------
# HAPS-SX VU19P - clock-network constraints (IMPLEMENTATION ONLY)
#
# Marked used_in_synthesis = false by build_haps_top.tcl: every object named
# here (buffer output pins, a post-synthesis register pin) exists only in the
# synthesized netlist.
#
# Note on self-checking: an .xdc file accepts only a small Tcl subset - no
# proc, no loops - so the "did this constraint match anything" checks cannot
# live here. They are in build_haps_top.tcl (GATE 2), which re-evaluates each
# object query below against the synthesized design and stops the build before
# implementation if any comes back empty.
#
# A joint work commissioned on behalf of SoC Labs, under Arm Academic
# Access license.
#-----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Clock input routing (moved here from haps_top.xdc, 2026-09-30)
# -----------------------------------------------------------------------------
# Allows the IBUFDS output to reach global buffers outside its own clock
# region. Added when ~140 clock-gate BUFGCEs were spread across the device;
# that rationale is gone (all gating is bypassed; two buffers remain), so this
# is a candidate for removal - but removing it is an untested change.
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -of_objects [get_pins u_ibufds_clk/O]]

# -----------------------------------------------------------------------------
# RT_CLK - a BUFGCE-gated copy of the main clock (haps_top.sv)
# -----------------------------------------------------------------------------
# u_bufg_clk and u_bufgce_rtclk are parallel global buffers off the same
# IBUFDS. RT_CLK therefore IS HAPS_CLK as far as timing analysis is concerned:
# no generated clock is declared for it, and paths between the RT domain and
# the system domain are ordinary same-clock paths.
#
# That only holds if the two buffers' insertion delays match, so both nets are
# placed in one clock delay group and the tool balances them. Without this,
# buffer-to-buffer skew would land directly on the hold margin of every
# RT<->system path.
set_property CLOCK_DELAY_GROUP haps_clk_grp [get_nets -of_objects [get_pins {u_bufg_clk/O u_bufgce_rtclk/O}]]

# -----------------------------------------------------------------------------
# CLK1HZ - the one genuine derived clock left in the design
# -----------------------------------------------------------------------------
# megasoc_peripheral_subsystem divides RT_CLK by 2^15 and uses bit 14 of that
# counter as the clock of the PL031 RTC's counter
# (RtcCounter.v: always @(posedge CLK1HZ ...)). It is a flop output used as a
# clock, and until now was undeclared: its 32 loads had no clock at all.
#
# -divide_by 2 is deliberately NOT the real ratio. Timing analysis cannot see
# that RT_CLK is gated to one pulse in 610, so the true 1 Hz cannot be
# expressed; 2 is the fastest a toggling flop can run, which makes the
# declared period (100 ns) far shorter than reality and every check against it
# conservative.
create_generated_clock -name CLK1HZ \
    -source [get_pins {u_soc/u_megasoc_system/u_megasoc_tech_wrapper/u_megasoc_peripheral_subsystem/rt_clk_div_reg[14]/C}] \
    -divide_by 2 \
    [get_pins {u_soc/u_megasoc_system/u_megasoc_tech_wrapper/u_megasoc_peripheral_subsystem/rt_clk_div_reg[14]/Q}]

# Crossings between CLK1HZ and the system clock are handled by the RTC's own
# synchronisers (RtcSynctoPCLK.v), so they are bounded rather than timed as
# synchronous paths: the data must arrive within one system-clock period, but
# no setup/hold relationship to a specific edge is claimed.
#
# Both carry an explicit -from AND -to. -datapath_only REQUIRES -from; three
# earlier constraints in this project omitted it and were rejected by Vivado on
# every build ("[Constraints 18-540] ... requires -from to be non-empty")
# without anyone noticing.
set_max_delay -datapath_only -from [get_clocks CLK1HZ]   -to [get_clocks HAPS_CLK] 50.000
set_max_delay -datapath_only -from [get_clocks HAPS_CLK] -to [get_clocks CLK1HZ]   50.000
