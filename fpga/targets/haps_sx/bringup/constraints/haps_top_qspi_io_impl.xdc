#-----------------------------------------------------------------------------
# HAPS-SX VU19P - QSPI flash I/O timing (IMPLEMENTATION ONLY)
#
# Applied during implementation only: create_generated_clock below needs both
# the buffered clock net (u_bufg_clk/O) and the QSPI_SCLK port, and neither
# resolves during synthesis. This file is marked used_in_synthesis = false by
# build_haps_top.tcl.
#
# Structure adapted from D. Mapstone's Pynq-Z2 AHB-QSPI constraints for the
# same SoC Labs QSPI IP, with two deliberate differences - see below.
#
# A joint work commissioned on behalf of SoC Labs, under Arm Academic
# Access license.
#-----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# SCLK as seen at the flash
# -----------------------------------------------------------------------------
# Difference 1 from the Pynq design: it also declares a generated clock on the
# divider output QSPI_SCLK_i, because there the controller is clocked FROM
# SCLK. This design no longer is - Build B (2026-09-23) reduced SCLK to a
# registered level plus two HCLK edge enables - so QSPI_SCLK_i clocks nothing
# internally and an internal generated clock there would describe a domain that
# does not exist. Only the pad-level clock is declared, because that is a real
# waveform at a real pin.
#
# qspi_clock_div toggles QSPI_SCLK_reg on the terminal count of QSPI_CLK_DIV,
# and since Build B both div==0 and div==1 mean "toggle every HCLK cycle", so
# the fastest SCLK this structure can produce is HCLK/2 = 10 MHz. divide_by 2
# is therefore exact at the fastest setting and conservative (it assumes a
# shorter period than reality) at every larger divisor.
create_generated_clock -name qspi_sclk_pad \
    -source [get_pins u_bufg_clk/O] \
    -divide_by 2 \
    [get_ports QSPI_SCLK]

# -----------------------------------------------------------------------------
# Setup: kept, and meaningful
# -----------------------------------------------------------------------------
# Conservative budget, not vendor-derived: the W25Q32FW's tSU/tV are
# single-digit ns against a 100 ns SCLK period. These exist to catch gross
# errors - a runaway divider, an absurd data path - not to close a tight
# interface.
set_output_delay -clock qspi_sclk_pad -max 10.0 [get_ports {QSPI_IO[*]}]
set_input_delay  -clock qspi_sclk_pad -max 20.0 [get_ports {QSPI_IO[*]}]

# -----------------------------------------------------------------------------
# Hold: explicitly excluded, and here is why
# -----------------------------------------------------------------------------
# Difference 2 from the Pynq design, and a correction to this file's own first
# version (2026-09-28), which specified -min 0.0 on both directions.
#
# What went wrong: with -min in place, the routed build reported
#
#   WARNING: [Route 35-455] Router was unable to fix hold violation on 319 pins
#   because of high hold requirement. Such pins are:
#     QSPI_IO_IOBUF[3]_inst/OBUFT/I
#     QSPI_IO_IOBUF[2]_inst/OBUFT/I ...
#
# - i.e. the pads these constraints had just started covering. WHS went from
# -0.664 ns (Build B, no I/O constraints) to -0.856 ns (Build C, with them).
# The constraints were demanding hold margin the hardware does not need.
#
# Why the tool cannot work it out for itself: the controller changes data on
# the SCLK FALLING edge and the flash samples it on the following RISING edge,
# so there is half an SCLK period - 50 ns at 10 MHz - of intrinsic margin. That
# used to be visible to Vivado, because the launching flops were genuinely
# clocked by SCLK. Since Build B they are clocked by HCLK and merely ENABLED on
# the falling-edge pulse, and an enable is not something static timing analysis
# can use to establish a phase relationship. Vivado therefore treats every
# HCLK edge as a potential launch and checks hold against the capture edge with
# no offset at all, which is both wrong and unachievable.
#
# The half-period separation is guaranteed structurally by qspi_clock_div's
# rise/fall enables, not by placement or routing, so excluding the hold check
# here excludes a check that has no physical meaning - it does not waive a real
# risk. Setup is left in force above.
#
# If the enable structure in qspi_clock_div.v is ever changed so that data no
# longer changes a half period before the capture edge, THIS EXCLUSION MUST BE
# REVISITED.
set_false_path -hold -to   [get_ports {QSPI_IO[*]}]
set_false_path -hold -from [get_ports {QSPI_IO[*]}]

# -----------------------------------------------------------------------------
# Chip select
# -----------------------------------------------------------------------------
# A slow control line: asserted many SCLK cycles before the first clock edge
# and released well after the last one, so there is no meaningful
# source-synchronous relationship to constrain. Previously (before 2026-09-28)
# it was over-constrained as a source-synchronous output alongside the data.
set_false_path -to [get_ports QSPI_nCS]
