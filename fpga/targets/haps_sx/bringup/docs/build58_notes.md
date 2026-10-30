# Build 58 - on-board DDR4 SODIMM on the NIC-400 DRAM port (MGSOC-34 step 2), 28 October 2026

RTL = build 57 (monitor ROM v5.2, MBT-58 DAP fix, UART loopbacks, L2 tag fix, USE_FLASH_EMU = 0) plus:

* `new/haps_ddr4_bridge.sv` - DRAM_AXI (64-bit, ID 9, 33-bit address, SYS_CLK 20 MHz) -> `axi_cc_dram` (Xilinx AXI clock
  converter v2.1, asynchronous) -> `axi_dw_dram` (AXI data width converter v2.1, 64 -> 512, single thread, no ID on the
  512-bit side) -> `ddr4_0` (Xilinx DDR4 IP v2.2, exactly the step-1 configuration that calibrated on this board:
  MTA16ATF2G64HZ-2G3 SODIMM, 2 ranks, DDR4-2133 / tCK 938 ps, 299.85 MHz reference on AF51/AF52, 4:1, CL15/CWL11,
  DM_NO_DBI, ROW_COLUMN_BANK, AXI 512-bit / 34-bit / ID 1, narrow bursts on, RD_PRI_REG).
* `megasoc_tech_wrapper.sv`: `localparam USE_DDR4 = 1` selects the bridge instead of the 512 KB `axi4_bram_slave`
  (generate if/else, the block RAM stays selectable with 0). New ports DDR4_SYS_CLK_P/N, DDR4_SYS_RST, DDR4_CALIB_COMPLETE;
  DDR4_CK_T/C widened to [1:0] (two clock pairs on the SODIMM). Same in `megasoc_system.sv`, `megasoc_chip.v` (active module).
* `haps_top.sv`: the DDR4 pins and the reference clock are top-level ports; `DDR4_SYS_RST = ~HAPS_RESET_N` (PB1 only - the
  10 s auto-reset and the monitor's 'g' do not touch the IP, DRAM contents survive); `LED_DDR4_CALIB` on BE14 (LED_G1).
* `megasoc_tech_wrapper.sv`: `qspi_flash_emu` is now instantiated only when `USE_FLASH_EMU = 1` (generate guard, outputs
  tied otherwise). Needed: with the bridge on the DRAM port the emulator's backdoor is tied to constants and Vivado 2024.1 then
  fails on its lane RAMs - `ERROR: [Synth 8-2914] Unsupported RAM template` x7 + `[Synth 8-5743]`, misattributed to
  `sdspi/rtl/sdax_s2mm.v:63` (the message points at the last parsed file; build 57's RAM messages pointed at qspi_flash_emu.sv the
  same way). Reproduced standalone (`ddr4/sim/../emu_repro`, scratch): lane 0 maps, lanes 1-7 error. Side effect: builds 50-57
  kept the dead emulator's 512 KB of block RAM alive through that backdoor read path; build 58 frees it.
* `constrs_1/new/haps_top_ddr4_impl.xdc` (implementation only): the 123 DDR4 pins (POD12/SSTL12 DCI, DCI cascade 30 -> 29/31),
  LED_G1, `set_clock_groups -asynchronous` HAPS_CLK (+CLK1HZ) vs c0_sys_clk_p (+MMCM/PLL children).
* Address map: the NIC-400 passes the low 33 address bits (window 0x8000_0000-0x2_7FFF_FFFF); the bridge ties IP address bit 33
  (the rank bit) low -> rank 0 only, 8 GB: CPU 0x8000_0000..0x1_FFFF_FFFF = DRAM 2..8 GB, CPU 0x2_0000_0000.. = DRAM 0..2 GB.
* Resets: converters and the IP's AXI shim are held in reset while SoC reset | !calib_complete | ui_clk_sync_rst (one source,
  4-stage synchroniser per domain). A DRAM access before calibration completes stalls the CPU (AWREADY/ARREADY low) instead
  of returning an error.

Pre-change copies: `*.pre_build58` next to each edited file. Build script: `rebuild_bitstream58.tcl` (this folder) - creates the
three IPs in the project when absent, runs their OOC synthesis, an elaboration check, synth_1, the constraint guard, impl_1.

## Firmware (this folder, `firmware/`)
* `ddr4_fpga_tests_dram.bin` (66280 B, dram scatter, runs FROM the DDR4 at 0x8000_0000) and `ddr4_fpga_tests_flash.bin`
  (66344 B, default scatter, code in flash, data in DDR4). Source `ddr4_fpga_tests.c` (also in
  megasoc_tech/software/src/ddr4_fpga_tests{,_flash}/, built with `make -B COMPILE_GCC=0 AARCH64=1`):
  T1 64 KB patterns, T2 one cell per address bit 3..32 + the 0x2_0000_0000 alias + top of window (written all, then verified),
  T3 4 MB hashed block through the caches (clean+invalidate before reading), T4 8/16/32-bit stores on Device memory above 4 GB
  (narrow AXI writes -> WSTRB/DM lanes). Expected output ends in "** TEST PASSED **".
* `*_dram.bin` of the SoC Labs tests (from build 48) - the RAM-mode regression, now from real DDR4.

## Bench procedure (haps-dev, console /dev/ttyACM0 115200), board programmed from srv03335
1. Program `haps_top_build58_ddr4_20261028.bit`. Within ~1 s LED_G1 (BE14) must light = DDR4 calibrated (also readable from
   srv03335 over JTAG: `vivado -mode batch -source ddr4/check_ddr4_cal.tcl` prints the hw_mig CAL_STATUS). LED5 heartbeat as before.
2. Monitor banner on the console as on build 57 (nothing in the ROM changed).
3. `python3 haps_qspi.py suite firmware/ddr4_fpga_tests_dram.bin`  (RAM mode: loads 66 KB into DDR4 at 0x8000_0000 over the UART,
   'g 80000000', code executes from DDR4) -> PASS expected, "running from DDR4".
4. `python3 haps_qspi.py suite --winbond firmware/ddr4_fpga_tests_flash.bin` (from the physical flash) -> PASS, "running from flash/ROM".
5. RAM-mode regression from DDR4: `python3 haps_qspi.py suite firmware/hello_world_dram.bin firmware/mem_tests_dram.bin ...`
   (build 48 ran 7/11 of these from the block RAM; same expectations: dap/sdio/uart variants have their own issues, see build 48 notes).
6. Build 57's flash regression (`suite --winbond flash_images/*_flash.bin`) must still pass - the DRAM port is not used by it.
If LED_G1 stays off: PB1 re-runs calibration; `check_ddr4_cal.tcl` shows which stage failed. If the monitor hangs on 'load' into
0x8000_0000: the bridge is waiting for calibration (AWREADY low) - the same LED tells.

## Result (built 28 October 2026 15:16-17:58, programmed and checked over JTAG 17:53-17:57)
* Bitstream `haps_top_build58_ddr4_20261028.bit`, md5 5af9c3184fb18c5b2815ec8c8a7d8b39. Attempt 1 stopped at the elaboration check
  (OOC IP netlists did not exist yet - the script now runs the IP OOC synthesis first); attempt 2 failed in synthesis on the flash
  emulator's RAMs (see above); attempt 3 = this bitstream.
* Timing met: WNS +0.510 ns / WHS +0.010 ns / WPWS +0.065 ns, 0 failing of 336969 endpoints. Per clock: HAPS_CLK WNS 29.77 ns,
  DDR4_SYS_CLK_P (299.85 MHz reference) 2.06 ns, the 0.51 ns worst path is inside the IP's MMCM/PLL domains as in step 1.
  Clock interaction HAPS_CLK <-> mmcm_clkout0 (ui_clk): "Asynchronous Groups" (232 + 126 endpoints ignored) - the clock-group
  constraint applied under the clock's actual name DDR4_SYS_CLK_P (the reference clock is created on the top-level port, NOT as
  c0_sys_clk_p; the xdc names both).
* DRC: 0 errors, 20 warnings = build 57's 17 (8 DPOP-4 / 7 DPOP-3 DSP pipelining in the A53, 1 PDRC-153 gated clock in the
  peripheral subsystem, 1 RTSTAT-10) + the 3 PDCN-1569 LUT-equation warnings of the debug hub seen in step 1; RTSTAT-10 now lists
  168 IP-internal nets (calibration RIU) instead of 1. 0 latches.
* Placement: the placer put the WHOLE SoC into SLR2 next to the DDR4 banks (SLR2: 40.6 % CLBs, 270.5k LUTs = 26.5 %, 114.5k FFs;
  SLR0/1/3 < 300 LUTs each; SLLs: 180 SLR2<->SLR3, 24 SLR2<->SLR1, 0 to SLR0 beyond I/O) instead of SLR0/1 as in build 57. No
  floorplan constraint is active; timing is met, so left as is. Bridge: 19953 LUTs, 18204 FFs, 25 block RAM tiles (IP 23.5 + converters).
* Board (JTAG from srv03335, `check_ddr4_cal.tcl <bit>`): programmed 17:53; the DDR4 IP inside the SoC design CALIBRATED:
  CALIBRATION_FAIL.STATUS = FALSE, "No errors detected during calibration", RANK0 stages 01-27 PASS or SKIP exactly as in step 1,
  DDR_CAL_ERROR_CODE 000. Full dump: `cal_status_build58_20261028.txt`. LED_G1 should be on. The board now holds BUILD 58.
* Still to do on the bench (needs the console): steps 3-6 of the procedure above - ddr4_fpga_tests from DDR4 and from flash, the
  RAM-mode regression from DDR4, build 57's flash regression on build 58.
* 29 October: board re-programmed by Tasos; calibration re-read over JTAG (`cal_status_build58_20261029.txt`): CALIBRATION_FAIL.STATUS FALSE,
  no errors, RANK0 stages PASS/SKIP as before. Bench steps 3-6 next.

## 29 October bench run 1 (firmware v1 = 28 Oct images): RAM HANG / flash FAIL+EXC -> two firmware faults, the bridge is fine
* RAM mode (`suite ddr4_fpga_tests_dram.bin`): the monitor loaded 66 KB into DDR4 and the A53 executed it from there
  ("running from DDR4 (pc 08000b6a8)"), then HANG after 60 s without a TEST line. Cause: T2's cells at DRAM_BASE + 2^k,
  k = 3..16, lie INSIDE the running image (0x8000_0008 .. 0x8001_0000: boot code, monitor_vectors at +0x800, library code,
  RW data) and overwrite it; the bit-31 fault below then had no intact handler to run.
* Flash mode (`suite --winbond ddr4_fpga_tests_flash.bin`): programmed and verified, T1 passed, T2 cell k = 31 -> data abort
  ESR_EL3 96000044 (write, translation fault level 0), FAR 0x1_0000_0000. The library's enable_mmu() programs
  TCR_EL3 = 0x00102F20 = T0SZ 32 (4 GB of VA) and PS 0 (32-bit PA), so the DRAM window above 4 GB
  (0x1_0000_0000-0x2_7FFF_FFFF) cannot be reached although pgtbl1 describes 512 GB (1 GB Device blocks above 4 GB).
* Firmware v2 (29 Oct 10:16): mmu_extend() widens TCR_EL3 to T0SZ 25 / PS 0b010 (39-bit VA, 40-bit PA = A53 PARange) with
  ISB + TLBI ALLE3 + DSB before T1; T2 cells moved to DRAM_BASE + 2 MB + 2^k (reference cell at +2 MB). Images:
  ddr4_fpga_tests_dram.bin 66432 B md5 49e28c743fcd8c922c02727debefe8e7, ddr4_fpga_tests_flash.bin 66480 B md5
  08a03123015318a9e9f59c676cb7b99f; the v1 images/source are kept as *_v1_20261028.*. Library finding (ticket to propose,
  not posted): EL3 address range limited to 4 GB, so no stock test can reach DRAM above 4 GB (lpddr4 tests included).
* 29 Oct 08:16 (bench, firmware v2): RAM mode `suite ddr4_fpga_tests_dram.bin` -> PASS 7.7 s, T1-T4 0 errors, TEST PASSED, running from DDR4 ->
  the DRAM port with the Xilinx DDR4 IP is functionally proven from the CPU. Flash mode (v2): TCR widened, T1 0 errors, T2 done,
  no end marker within the 60 s suite timeout during T3 (4 MB x 2) -> firmware v3 adds CNTPCT per-test times + T3 progress lines;
  re-run with --timeout 200 to tell slow (XIP code fetch) from hung.
* 29 Oct run 2 (firmware v3, 10:32, flash, --timeout 200): T1 0 errors but 330.8 M ticks, T2 0 errors, T3 pass-0 write+clean
  1.67 G ticks -> the suite's "HANG" was slowness: the monitor's Winbond 'n' boot jumps WITHOUT cache_on() (CG092 flash cache
  off, unlike the 'g' path) and the application's boot.s never enables the CPU caches (only enable_mmu), so flash-mode code
  fetches were uncached QSPI reads (~30x slower). Counter = 20 MHz (CNTFRQ_EL0 unset).
* 29 Oct run 3 (firmware v5 = v4 + enable_caches() in the test, 11:26 RAM / 11:37 flash): SCTLR_EL3 40c52839 (M=1 C=0 I=0)
  in BOTH modes before the test, CPUECTLR 0 (SMPEN=0) -> every earlier RAM-mode run (builds 47-58) ran with the CPU caches OFF,
  i.e. the DRAM port had only ever seen single 64-bit transfers. With C=I=1: flash mode as fast as DDR4 (T1 786 K vs 771 K
  ticks), T1/T2/T4 0 errors, T3 (4 MB, exceeds the 256 KB L2) FAILS in both modes: 291801 (RAM) / 708736 (flash) of 1048576
  checks. Wrong data = another line of the SAME L2 set (address bits 13:6 equal, tags differ): RAM @80400000 got T1's line
  0x80108000 (bits 15,20,22), flash @804000c0 got T3's line 0x807980c0 (bits 15,16,19,20,21). T3 timing ~7 us per line = L1
  bypassed. Suspects: CPUECTLR.SMPEN = 0 (A53 requires it before enabling the caches; the library never sets it) and/or the
  L2 tag RAM integration (N25 area). Firmware v6 (15:52): sets SMPEN before enable_caches(), adds T5 (cache-resident L2-set
  aliasing, 16 and 18 lines) and T6 (1 MB cached writes read with C=0; uncached writes read cached). The DRAM bridge is not
  implicated by the data so far (caches-off T3 passed, cell/burst tests pass).
* 29 Oct run 4 (firmware v6: SMPEN set before enable_caches, + T5 cache-resident L2-set aliasing, + T6 cached-write/uncached-read
  cross-check; 11:53 RAM / 11:53 flash): T5 0 errors (16 and 18 lines in one set, resident and from DRAM) -> L2 tag/way
  handling is fine, the "same set" pattern of run 3 was not SMPEN. T3 still fails (34864 RAM / 32360 flash of 1048576).
  T6: 1 MB written cached and read with C=0 -> 73136 / 83680 of 131072 words WRONG; 1 MB written uncached and read cached
  (line fills) -> 0 errors. So read bursts and single writes are right; the data written back by the L2 is wrong.
* 29 Oct run 5 (firmware v7, + T8 dirty DDR4 lines evicted by a read sweep, + T7 same with SRAM remapped cacheable; 12:12):
  T8 7536 of 8192 words wrong (92 %) with reads only on the DRAM port otherwise; T7 (RAM mode) -> SError ESR_EL3 BF000000
  right after pgtbl2[4] -> Normal WB (the SRAM path does not take cache-line bursts - separate finding, log pending).
  Every wrong word of runs 3-5 traced (scratchpad analysis) to the pattern value of ANOTHER LINE OF THE SAME L2 SET:
  xor of the two addresses always has bits 13:6 = 0 (0x338000, 0x27bc000, 0x24d4000, 0x828000, 0x24f4000, 0x2404000,
  0x508000); in T8 the stale data came from a line that had only ever been written uncached (T6.B), i.e. data the bridge
  never carried as a write -> the L2 wrote back another way's data. DDR4 BRIDGE CLEARED. Root cause in the Vivado fileset:
  the L2 DATA RAM wrapper synthesised is Arm's TSMC 1 MB example (unmasked `[13:0]`), the same N25 defect the build 54 fix
  removed from the TAG RAMs only (synth log: haps_top/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_0_low/u/mem_reg).
  -> build 59 (bitstreams/build59_l2data_fix_20261029/): generic masked data+tag wrappers only. Launched 16:31.
* Also learnt today: the monitor ROM leaves the CPU caches OFF and boot.s only enables the MMU -> every RAM-mode run of
  builds 47-58 ran with C=I=0 (single 64-bit transfers everywhere); the Winbond 'n' boot path skips the CG092 cache_on();
  the library's enable_caches() never sets CPUECTLR.SMPEN; TCR_EL3 limits EL3 to 4 GB VA / 32-bit PA.
* T7 SError lead (29 Oct, RTL read only): the on-chip SRAM is behind Arm's SIE-300 AXI5 SRAM controller (full INCR/WRAP burst
  support, addr_dec.sv), and its ONLY SLVERR source is the gate-response FSM in resp_gen.sv (`resp_fsm_en & gate_resp` -> the
  controller answers 2'b10 while clock/power gated via cfg_gate_resp / the Q-channels). So cacheable bursts to the SRAM most
  likely hit the LPI gating path, not a burst limitation. Needs the RAM-mode log of suite_20261029_121231 and a look at
  cfg_gate_resp / SRAM_qchan_q handling in SRAM_wrapper.sv before anything is changed. Low priority (library maps SRAM Device).
