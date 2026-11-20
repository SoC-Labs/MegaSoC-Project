#-----------------------------------------------------------------------------
# HAPS-SX VU19P - SD card I/O timing on PMOD4 (IMPLEMENTATION ONLY), build 62
#
# Same structure and the same reasoning as haps_top_qspi_io_impl.xdc: applied
# during implementation only (needs u_bufg_clk/O and the port), maximum delays
# only, no -min (see the hold discussion in the QSPI file).
#
# A joint work commissioned on behalf of SoC Labs, under Arm Academic
# Access license.
#-----------------------------------------------------------------------------

# SDIO_CLK is i_sdclk[7] of sdfrontend, a register updated every system clock,
# so the fastest SD clock this structure can produce is HCLK/2 = 10 MHz
# (controller setting "50MHz" on a 100 MHz reference). divide_by 2 is exact at
# the fastest setting and conservative at every slower one, including the
# ~76 kHz initialisation rate.
create_generated_clock -name sdio_clk_pad \
    -source [get_pins u_bufg_clk/O] \
    -divide_by 2 \
    [get_ports SDIO_CLK]

# Coarse budgets against a 100 ns period at the fastest rate. The Pmod MicroSD
# sits directly on the header; the card's own tOD/tISU are a few ns.
set_output_delay -clock sdio_clk_pad -max 10.0 [get_ports {SDIO_CMD SDIO_DAT[*]}]
set_input_delay  -clock sdio_clk_pad -max 20.0 [get_ports {SDIO_CMD SDIO_DAT[*]}]
