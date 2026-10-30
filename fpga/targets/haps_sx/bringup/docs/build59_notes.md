# Build 59 (launched 2026-10-29 16:31) - L2 DATA RAM integration fix (N25 family), found with the DDR4 tests of build 58
RTL = build 58 (DDR4 SODIMM on the NIC-400 DRAM port). Only the Vivado fileset changes (rebuild_bitstream59.tcl):
  * disabled: imports/models/rams/tsmc_cln28hpm_L1_32I_32D_L2_1M/ca53_l2_datarams.v (Arm TSMC example for a 1 MB L2:
    `.A(l2_dataram_addr_i[13:0])`, unmasked - the file build 58 actually synthesised: instances u_l2_dataram_N_low/high),
    imports/mem_integrations/FPGA/ca53_l2_datarams.v (SoC Labs FPGA version: `.ADDR(l2_dataram_addr_i[11:2])` into
    cmsdk_fpga_sram AW=12 = 1024 words x 16 instances = 64 KB for a 256 KB L2, way bits [1:0] dropped - also wrong, never used),
    imports/mem_integrations/CortexA53/ca53_l2_tagrams.v and .../ca53_l2_datarams.v (duplicates).
  * enabled, the only definitions: imports/models/rams/generic/ca53_l2_datarams.v + ca53_l2_tagrams.v (Arm generic, index
    masked with l2_size) on new/ca53_generic_ram_fpga.v (build 54). Data RAMs: 8 banks x 2^15 x 64 bits = 16 Mbit of BRAM
    (the generic wrapper sizes by CA53_SCU_L2_DATARAM_ADDR_W = 15; only [11:0] vary for 256 KB).
Why: SCU address = {index, way} (ca53scu_ramctl.v:1175). For the 256 KB core the SCU's upper index bits are don't-care;
the unmasked 1 MB example lets a line's data be written to one RAM word and read back from another -> the L2 returns /
writes back ANOTHER LINE OF THE SAME SET (bits 13:6 equal, tag bits differ). Exactly what every failing word of the
29 Oct bench runs showed (build58_notes.md, runs 3-5). The build 54 fix (N25) corrected the TAG RAM integration only.
Expected on the bench: ddr4_fpga_tests v7 (bitstreams/build58_ddr4_20261028/firmware) T3/T6/T8 0 errors in both modes;
T7 (SRAM remapped cacheable) still raises the SError seen on build 58 unless that is also L2-related - to be seen.

## Result (built 29 Oct 16:31-19:17; programmed and checked over JTAG 19:20)
* `haps_top_build59_l2data_20261029.bit`, md5 02de1fff07b03648637dfe4d0e10c0ff. Elaboration: 8 generic data RAM instances
  (u_l2_dataram_0..7), 17 generic tag RAM instances, no SRAMHDE under the L2 (33 TSMC macro models remain = L1/TLB RAMs).
* Synthesis 310 block RAM primitives (build 58: 522): Vivado propagated the constant l2_size mask and trimmed the generic data
  RAMs to 4096 x 64 per bank, so the fix saves BRAM rather than costing it.
* Timing met: WNS +0.448 / WHS +0.010 / WPWS +0.065 ns, 0 failing endpoints (729973 / 729202 / 159709); HAPS_CLK <-> mmcm_clkout0
  asynchronous groups as in build 58; 0 latches. Reports: timing_summary59.rpt, clock_interaction59.rpt, util_slr59.rpt,
  util_hier59.rpt, drc59.rpt; logs rebuild59.log, synth59_runme.log, impl59_runme.log.
* Board programmed 19:20 (check_ddr4_cal.tcl): DDR4 IP calibrates, CALIBRATION_FAIL.STATUS FALSE, no errors
  (cal_status_build59_20261029.txt). THE BOARD HOLDS BUILD 59. Flash content untouched (ddr4_fpga_tests v7 flash image from 12:12).
* Bench next: firmware v7 (firmware/, same images as build58/firmware): `suite firmware/ddr4_fpga_tests_dram.bin` and
  `suite --winbond --timeout 200 firmware/ddr4_fpga_tests_flash.bin` -> expect T1-T6, T8 0 errors, TEST PASSED; T7 (SRAM remap,
  RAM mode) may still SError (separate SIE-300 gating question); then the RAM-mode regression from DDR4 (hello_world_dram etc.).

## Bench 30 October 2026 (firmware v7, haps-dev, console /dev/ttyACM0)
* 06:05 flash mode (`suite --winbond --timeout 200 firmware/ddr4_fpga_tests_flash.bin`, suite_20261030_060554): **PASS 3.1 s,
  "DDR4 total errors: 0 / ** TEST PASSED **"**. On build 58 the same image failed T8 with 7536 errors (and T3/T6.A on v5/v6):
  the dirty-line evictions that wrote another line of the same L2 set back are gone -> the L2 DATA RAM integration (TSMC 1 MB
  example, unmasked index, N25 family) was the fault; the DDR4 bridge is clean with the caches on.
* 06:01 RAM mode (`suite firmware/ddr4_fpga_tests_dram.bin`, suite_20261030_060134): FAIL+EXC 2.5 s - reached T7 and took the
  known SError (ESR_EL3 BF000000) right after the "pgtbl2[4] ... -> ...401" line. T1-T6/T8 lines are in the log (not yet seen).
* T7 SError ROOT CAUSE = test bug, not hardware. The NIC-400 decodes only 64 KB of RAM at 0x800000:
  `nic400_asib_A53_decode_megasoc_main.v:99  decode_int[2] = (44'h800000 <= addr_s) && (addr_s <= 44'h80FFFF)` (Socrates
  memory_map.xml `RAM_0x800000_CPU_MM` range 0x10000). v7 wrote its 32 KB of cells at 0x810000, which is unmapped -> default
  slave -> DECERR on the write-allocate line fill -> reported asynchronously (the store had retired) -> SError. With the region
  Device (uncached) the same access would have been a synchronous data abort. The SIE-300 gating hypothesis is dropped:
  `cfg_gate_resp` is tied 1'b0 in megasoc_tech_wrapper.sv (stall when gated, never SLVERR).
  Side finding (for SoC Labs / Daniel, Low): the FPGA `SRAM_wrapper.sv` holds 128 KB (two cmsdk_fpga_sram banks, memaddr[16:3])
  but only the lower 64 KB is reachable through the interconnect; `sys_memory_map.h` has no RAM size symbol.
* Firmware v8 (`firmware/`, 10:20): T7 cells moved to 0x808000-0x80FFFF (upper 32 KB of the mapped window; stack/heap
  0x800000-0x803FFF, mem_tests cell 0x806000). `ddr4_fpga_tests_dram.bin` md5 0e4e48bed3bc688a3b5662774186188c (69784 B),
  `ddr4_fpga_tests_flash.bin` md5 10df9c7d0d0801a40b7a3064d1b22b32 (69848 B); v7 kept as `*_v7_20261029.*`.
  Expected: RAM mode T1-T8 all 0 errors, TEST PASSED; flash mode unchanged (T7 skipped).
* Still to run on build 59: v8 RAM mode; RAM-mode regression from DDR4 (hello_world_dram ... pl011_uart_tests_dram); build 57's
  flash regression (10 images).

## Bench 30 October 2026, 06:30-06:40 - firmware v8, RAM mode: ALL PASS; RAM regression from DDR4: 7/7 PASS
* `suite firmware/ddr4_fpga_tests_dram.bin` (suite_20261030_063056): **PASS 2.5 s, "DDR4 total errors: 0"**. Per test (20 MHz ticks):
  T1 64 KB x 5 patterns 0 err (771351); T2 33 address cells 0 err (173081); T5a 16 lines/one L2 set 0 resident / 0 from DRAM
  (185445); T5b 18 lines 0/0 (185874); T3 4 MB x 2 passes 0 err (37819267, each write+clean pass ~8.78 M = 0.44 s);
  T6 1 MB cached->uncached 0, uncached->cached 0 (8923269); T8 64 KB dirty DDR4 lines evicted by 512 KB sweep 0 err (546426);
  **T7 32 KB dirty SRAM lines (0x808000) evicted by the sweep 0 err (588812)** - the SError is gone with the mapped address;
  T4 8/16/32-bit Device stores 0 err (129258). Caches: library left SCTLR_EL3 40c52839 (C=0 I=0), test set SMPEN + C/I -> 40c5383d.
* RAM-mode regression executed from the SODIMM (suite_20261030_063316): hello_world, mem_tests, gic_tests, timer_tests, neon_tests,
  peripheral_test, pl011_uart_tests - **7/7 PASS** (these run with the CPU caches off, as the library leaves them).
* Conclusion: MGSOC-34 step 2 (Xilinx DDR4 IP on the NIC-400 DRAM port) is verified on hardware with caches on and off; build 59
  is the board baseline. Remaining optional check: build 57's flash regression (`suite --winbond flash_images/*.bin`) on build 59.

## Bench 30 October 2026, 07:09-08:05 - build 57 flash regression on build 59: 9/9 PASS
* `suite --winbond flash_images/{dap_tests,hello_world,mem_tests,neon_tests,peripheral_test,gic_tests,low_power_tests,
  pl011_uart_tests,timer_tests}_flash.bin` (suite_20261030_070940, images = build 57 folder): **9/9 PASS** from the physical
  W25Q32FW (dap_tests CIDR/PIDR note as on build 57). The L2 data RAM change and the DDR4 integration left the XIP boot path intact.
* `uart_tests_hw` (v5, md5 0ba6c86d) reported HANG at 08:04 - a HOST-SIDE artefact, not the board: I asked for
  `--baud-after uart_tests_hw=2000000`, but v5 keeps the console at 115200 for all its output (build57_notes: "Run WITHOUT
  --baud-after"). haps_qspi.py switches the adapter to 2 Mbaud once "Booting" is seen (after the 3 s first read), so the first
  3 s of output were readable and the tail ("TEST PASSED", end marker) arrived as garbage ("\xef\xbf\xbd0"). Rerun without the flag.
* 10:37 `suite --winbond flash_images/uart_tests_hw_flash.bin` (no --baud-after, suite_20261030_103742): **PASS 3.7 s**,
  "Total integration issues in UART is 0 / ** TEST PASSED **". Build 59 flash regression = **10/10**, same set as build 57.

## Build 59 status (30 October 2026, 10:40): BOARD BASELINE
RAM mode from DDR4: ddr4_fpga_tests v8 PASS (T1-T8, caches on) + 7/7 SoC Labs tests. Flash: ddr4_fpga_tests v7 PASS (caches on)
+ 10/10 SoC Labs/MBT images. DDR4 calibrated, timing met (WNS +0.448). Nothing left to run for MGSOC-34 step 2.
