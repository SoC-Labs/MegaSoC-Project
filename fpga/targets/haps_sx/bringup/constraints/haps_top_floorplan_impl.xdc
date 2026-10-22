#-----------------------------------------------------------------------------
# HAPS-SX VU19P - floorplan (IMPLEMENTATION ONLY)
#
# DISABLED BY DEFAULT (build_haps_top.tcl: ENABLE_FLOORPLAN 0), and on the
# evidence below it should stay that way unless the goal is run-to-run
# placement repeatability. It is NOT a timing fix. Read the history first.
#
# A joint work commissioned on behalf of SoC Labs, under Arm Academic
# Access license.
#-----------------------------------------------------------------------------
#
# History - two wrong versions of this file, recorded so the reasoning is not
# repeated
# -------
# v1 (2026-09-29) claimed the design "spans all four SLRs" and constrained it
#    to SLR1:SLR2. Both halves were wrong. The SLR boundaries had been inferred
#    from another part's geometry instead of read from this one.
# v2 (server-side review) corrected the target to SLR0:SLR1. Right about the
#    geometry, but a no-op: that is where the design already is.
# Both rested on an unverified premise - that the residual hold violations were
# caused by clock skew across a widely spread placement. They are not.
#
# Measured facts (routed build of 2026-09-29, queried directly)
# --------------
# Device: clock regions X0..X8 by Y0..Y19; five rows per SLR:
#         SLR0 = Y0-Y4, SLR1 = Y5-Y9, SLR2 = Y10-Y14, SLR3 = Y15-Y19.
#         Each SLR has 127,680 slices, 540 RAMB36 tiles, 80 URAM288 sites
#         (URAM only in column X5).
#
# Placement:
#         SLR0  slices 46,989 / 127,680 (37%)   BRAM sites in use 540 (of 540 tiles)
#         SLR1  slices     38 / 127,680         BRAM sites in use  64  (rows Y5-Y6)
#         SLR2, SLR3  empty
#   The design is BLOCK-RAM BOUND. It needs 370 RAMB36 + 234 RAMB18 (about 487
#   tiles), which saturates one SLR's BRAM and spills the remainder just over
#   the SLR boundary, while using barely a third of that SLR's logic. The
#   placement cannot be made more compact by a pblock: its extent is set by
#   where block RAM physically is. (An earlier build placed the same design
#   mostly in SLR1 instead - one SLR plus spill either way.)
#
# Hold:
#   Of the 2000 worst failing hold paths, 0 crossed an SLR boundary, and their
#   mean clock skew was 0.060 ns. The violations were produced by a 0.500 ns
#   user clock uncertainty being applied to hold checks (haps_top.xdc), not by
#   placement. That has been corrected at source.
#
# What would actually change the footprint
# ----------------------------------------
# Not a pblock - a RAM-mapping change. The 16 L2 data banks (16384 x 36 each)
# take 256 RAMB36 tiles, over half the total. Mapped to UltraRAM they would
# need 64 of SLR0's 80 URAM288 sites and BRAM demand would fall to roughly 230
# tiles, at which point the whole design fits inside one SLR with no spill.
# Vivado already considers this and declines ("implemented using BRAM instead
# of URAM due to insufficient pipeline registers"); forcing it means a
# ram_style attribute on _sync_sram_2cycle in rfhds_pg_svt_fpga_models.sv.
# That is an RTL change to the cache RAM model and has NOT been made.
#
# What this pblock is for
# -----------------------
# Repeatability only: it keeps the placer in SLR0 plus the two SLR1 rows it
# already spills into, next to the clock input pin (BM44, region X0Y1) and the
# I/O banks, rather than letting successive builds land in different SLRs.
# It deliberately includes rows Y5-Y6 - excluding them would leave too little
# block RAM and placement would fail.
#-----------------------------------------------------------------------------

create_pblock pblock_soc
resize_pblock [get_pblocks pblock_soc] -add {CLOCKREGION_X0Y0:CLOCKREGION_X8Y6}
add_cells_to_pblock [get_pblocks pblock_soc] [get_cells u_soc]

# Verify after implementation:
#   report_utilization -pblocks [get_pblocks pblock_soc]
#   report_clock_utilization      (g0 "Load Clock Region" count)
