# DDR4 on the HAPS-SX VU19P - step 1: standalone check of the Xilinx DDR4 IP (MGSOC-34), 28 October 2026

Goal: prove the on-board DDR4 SODIMM and the IP placement on this device before touching the SoC. The IP example design
(simple traffic generator) is built as its own bitstream; on the board it calibrates and then writes/reads the DIMM for ever.

## What is here
- `gen_ddr4_ip.tcl` - creates `ddr4_ip/` with IP `ddr4_0` (ddr4 v2.2, Vivado 2024.1) configured as the proven vendor design
  (SoC-Labs/HAPS-ZynqMP-Daughter-Board docs/reference/ddr4-configuration.md): SODIMM MTA16ATF2G64HZ-2G3, 16 GB x64 non-ECC,
  tCK 938 ps (DDR4-2133), 4:1, input clock 3335 ps, CL 15 / CWL 11, DM no DBI, ROW_COLUMN_BANK, AXI 512-bit / 34-bit / ID 1,
  narrow bursts ENABLED (the vendor had them off and stalled on sub-512-bit writes), RD_PRI_REG, MMCM 16/3/6.
  Then opens the IP example project `ddr4_0_ex/` (top `example_top`, traffic generator SIMPLE_TG).
- `haps_sx_ddr4_pins.xdc` - 123 pins generated from SoC-Labs-HAPS-SX-Tools iomap_csv_rev0b/pinfile.csv (DDR4 section):
  banks 29/30/31 = clock regions X0Y10/X0Y11/X0Y12 (SLR2); reference clock AF51/AF52 (GC pair, bank 30). POD12/SSTL12 DCI,
  DCI cascade from bank 30. The board has no PAR/ALERT lines; parity is off (non-ECC SODIMM).
- `haps_sx_ddr4_misc.xdc` - USER_PB2_n (BJ43) as reset, LED_G1 (BE14) = calibration complete, LED_R0 (BE13) = data compare
  error; the IP's TIMING-17 waiver carried over from the generated example_design.xdc, which is otherwise placeholder pins and
  is DISABLED in the project (it would put DDR lines on the SoC's clock and reset pins).
- `haps_ddr4_ex_top.sv` - wrapper: inverts the active-low button into the IP's active-high sys_rst, routes the status LEDs.
- `build_ddr4_ex.tcl` / `build_ddr4_ex.log` - synthesis + implementation + bitstream of `ddr4_0_ex`, reports `ddr4_ex_*.rpt`.
- `device_query*.tcl` (scratchpad copies) - how the bank -> clock region mapping was obtained.

## On the bench
Bitstream: `ddr4_0_ex/ddr4_0_ex.runs/impl_1/haps_ddr4_ex_top.bit`, programmed from srv03335 like the SoC builds (ConfPro
project and GCLK1 as usual; the DDR4 reference clock is the board's own 300 MHz source on AF51/AF52).
Expected: LED_G1 on within a second (calibration complete); LED_R0 stays off (traffic generator sees no compare error).
LED_R0 on = data errors; LED_G1 off = calibration failed (then use the IP's calibration debug through the hardware manager).
USER_PB2 restarts the IP.

## Next steps (step 2, SoC integration)
DRAM_AXI (64-bit, 33-bit address, 20 MHz SYS_CLK, SLR0/1) -> AXI clock + width converter placed in SLR2 -> ddr4_0 AXI
(512-bit, 266.5 MHz). Only the first 8 GB (rank 0) is reachable: AXI address bit 33 tied low. Replace the 512 KB
axi4_bram_slave on the DRAM port (keep it selectable); the monitor's load/go path then runs from real DRAM.

## Result (built 28 October 2026, 11:12-11:53)
- Bitstream `haps_ddr4_ex_top.bit`, md5 7eb74a77169ceb9dfc25ada35233a1dd, archived with reports and sources in
  `bitstreams/ddr4_example_20261028/`.
- Timing: all constraints met, WNS +0.435 ns, WHS +0.010 ns. Clocks: c0_sys_clk 299.85 MHz, MMCM 16/3/6 -> memory 1066 MHz,
  user clock 266.5 MHz; debug hub (calibration XSDB) on the JTAG clock. 0 critical warnings in synthesis and implementation.
- DRC: 4 warnings, none about pins or the memory interface (3x PDCN-1569 LUT equation on the debug hub's BSCAN switch, 1x
  RTSTAT-10 unloaded IP-internal nets). All 123 DDR4 pins applied with POD12/SSTL12 DCI, DCI cascade from bank 30.
- Placement: everything in SLR2 - clock regions X0Y10 (15.3k FF), X0Y11 (15.6k FF, MMCM, 5 BUFGCE), X0Y12 (2.3k FF), a few
  hundred flops in X1Y10/X1Y11; 23.9k LUTs, 33.5k FFs, 25.5 block RAM tiles, 3 DSPs. Nothing in the SoC's regions
  (SLR0, SLR1 rows Y5-Y9) except the debug hub's BSCAN flops near the configuration logic (X8Y6).
- Byte-lane check (pre-build): every DQ byte with its DQS pair and DM in one byte lane; strobes on DBC/QBC pins; all 33
  address/control lines in bank 30. The older haps-sx_vu19p.def lists ACT_N on CA49 (= FLASH_CLK, bank 21): wrong, CSV AE48 used.
- Conclusion for MGSOC-34: the IP fits the board and the device exactly as the vendor design implies; the SoC integration
  needs no floorplanning beyond keeping the AXI converter in SLR2.

## Bench check (to do)
Program from srv03335 as for the SoC builds. Within ~1 s: LED_G1 (BE14) ON = calibrated; LED_R0 (BE13) OFF = no data errors.
Hardware manager: after programming, refresh the device; the `ddr4_0` memory IP appears with its calibration status and
per-byte margins (XSDB through the debug hub). PB2 re-runs reset + calibration. Reprogram build 57 afterwards for the SoC work.

## Bench result, 28 October 12:15-12:20 (board programmed from srv03335, read over JTAG)
The HAPS JTAG is served at 127.0.0.1:3310 (target */xilinx_tcf/Digilent/HAPSSXB87822); `check_ddr4_cal.tcl` connects there.
v1 bitstream: the DDR4 IP CALIBRATED on the real SODIMM - CALIBRATION_FAIL.STATUS = FALSE, "No errors detected during
calibration", every stage PASS or SKIP (DBI and VREF stages skipped by configuration; rank-1 repeats of per-bit steps
skipped as designed), both ranks trained. Full property dump: `bitstreams/ddr4_example_20261028/cal_status_v1_20261028.txt`.
Not readable in v1: the traffic generator's compare-error flag (LED_R0 only) -> v2 bitstream with VIO.
Margins (calibration, rank 0, taps left/right): read window rising 36-45 / 37-45, falling 34-40 / 35-41 per byte; write
DQS-to-DQ window 0x37-0x3d / 0x36-0x3d per byte; rank 1 similar. Symmetric and uniform across the eight bytes: the strobes are
centred and the board routing is clean. (The TG_* margin families in the dump are zero because the IP's margin sweep was not run.)

## v2 result (VIO), 28 October ~12:55 - STEP 1 COMPLETE
`haps_ddr4_ex_top_vio.bit` (md5 fa2ffe3b...) + `haps_ddr4_ex_top_vio.ltx`, timing met (WNS +0.369, WHS +0.010), same 4 benign DRC
warnings. Programmed and read over JTAG with `check_ddr4_cal.tcl <bit> <ltx> reset`: reset through the VIO re-ran calibration
("Calibration is still in-progress" then no errors); VIO probes calib_s = 1, err_s = 0 across three 1 s samples (the traffic
generator's sticky compare-error flag never set), heartbeat toggling. The SODIMM works end to end with the Xilinx IP on this board.
Probe names are the connected nets (calib_s, err_s, hb_cnt, jtag_rst). Capture: `vio_status_v2_20261028.txt`.
