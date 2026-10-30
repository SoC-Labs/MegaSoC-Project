# MGSOC-34 step 2 - DDR4 SODIMM integrated into the MegaSoC FPGA build (build 58, 28 October 2026)

Step 1 (README_ddr4_step1.md) proved the Xilinx DDR4 IP configuration on the board. Step 2 puts that IP on the SoC's NIC-400
DRAM port in place of the 512 KB block RAM that builds 47-57 used.

## Design (haps_top.srcs/sources_1/new/haps_ddr4_bridge.sv)
    DRAM_AXI 64-bit / ID 9 / 33-bit addr @ SYS_CLK 20 MHz (SLR0/1)
      -> axi_cc_dram   Xilinx AXI clock converter v2.1, asynchronous FIFOs      20 MHz <-> ui_clk 266.5 MHz
      -> axi_dw_dram   Xilinx AXI data width converter v2.1, 64 -> 512, IDs stored in order (512-bit side has no ID)
      -> ddr4_0        Xilinx DDR4 IP v2.2, step-1 configuration, AXI 512-bit / 34-bit / ID 1 (tied 0)
* Address: NIC-400 passes the low 33 bits; IP bit 33 (rank) tied 0 -> rank 0 = first 8 GB. CPU 0x8000_0000..0x1_FFFF_FFFF =
  DRAM 2..8 GB, CPU 0x2_0000_0000..0x2_7FFF_FFFF = DRAM 0..2 GB. Firmware DRAM_BASE 0x8000_0000 unchanged. The page table maps
  2-4 GB Normal cacheable and >4 GB Device, so the whole 8 GB is reachable (upper part uncached).
* Resets: IP sys_rst = PB1 only (never the SoC auto-reset -> DRAM contents survive 'g' and the 10 s watchdog); converters and
  the IP's AXI shim held in reset while SoC reset | !calib | ui_clk_sync_rst, released through 4-stage synchronisers in each
  domain. An access before calibration stalls (READY low) rather than erroring.
* Status: DDR4_CALIB_COMPLETE -> LED_G1 (BE14); the hw_mig calibration status is readable over JTAG as in step 1.
* The block RAM slave stays selectable: `localparam USE_DDR4 = 0` in megasoc_tech_wrapper.sv.
* Pins: haps_top_ddr4_impl.xdc (the 123 step-1 pins renamed to the top-level ports, DCI cascade, LED, clock groups).

## Simulation (ddr4/sim/, 28 Oct, xsim)
tb_bridge.sv drives the bridge with the real converter IP models and ddr4_0_sim_model.sv (a behavioural stand-in for the DDR4 IP:
ui_clk, reset/calibration timing, 512-bit AXI slave with a sparse memory and stalling handshakes). 203 checks, 0 errors:
write issued before calibration completes only after it; INCR and WRAP (A53 line-fill) bursts; byte/halfword/word writes and
narrow reads; addresses above 4 GB; 0x2_0000_0040 lands at DDR4 line 1 (alias); responses in order with the right IDs; SoC
reset while idle then traffic again. Log: tb_bridge_20261028.log. Re-run: `vivado -mode batch -source ddr4/sim/mk_brsim.tcl`
(creates a scratch project next to the script).

## Build 58
bitstreams/build58_ddr4_20261028/ - build58_notes.md (what changed, bench procedure), firmware/ (ddr4_fpga_tests RAM and flash
images, the RAM-mode regression images), src/ (new sources, xdc, diffs, build script, testbench).

## Result, 28 October 2026
Build 58 bitstream `haps_top_build58_ddr4_20261028.bit` (md5 5af9c318...): timing met (WNS +0.510 / WHS +0.010 ns, HAPS_CLK <-> ui_clk in
asynchronous groups), DRC 0 errors / 20 known warnings, the placer put the whole SoC into SLR2 beside the DDR4 banks. Programmed from
srv03335 over JTAG: the DDR4 IP calibrates inside the SoC design (CALIBRATION_FAIL.STATUS FALSE, all stages PASS/SKIP, as in step 1).
Synthesis lesson: with the backdoor tied off, Vivado fails on the flash emulator's lane RAMs ("Unsupported RAM template", misattributed
to sdax_s2mm.v) - the emulator is now generate-guarded by USE_FLASH_EMU. Firmware checks (ddr4_fpga_tests from DDR4 and from flash,
RAM-mode regression from DDR4) wait for the bench: build58_notes.md, "Bench procedure".

## Bench results 29 October 2026 (build 58, firmware v1-v7 in bitstreams/build58_ddr4_20261028/firmware/)
* The DRAM path works from the CPU: code loaded by the monitor into DDR4 executes from there; with the caches OFF (as all
  earlier RAM-mode runs unknowingly were) T1-T4 pass over 4 MB (v2-v4); with the caches ON (test enables them, SMPEN first)
  single transfers, read bursts (1 MB of line fills), explicit clean+invalidate write-backs, narrow strobes and the >4 GB
  Device window all verify (T1, T2, T4, T5, T6.B 0 errors, both from DDR4 and from flash).
* Failing: allocation-driven dirty evictions (T3 4 MB, T6.A, T8) - the L2 writes back another line of the same set.
  Traced to the L2 DATA RAM integration (Arm TSMC 1 MB example, unmasked address) still in the fileset -> build 59.
* Firmware findings (test adapted): TCR_EL3 4 GB limit (T0SZ 32 / PS 0) -> mmu_extend(); caches off at entry -> SMPEN +
  enable_caches() in the test; T2 cells moved off the RAM image. Monitor: 'n' boot path without CG092 cache_on() ->
  uncached XIP code fetch, ~30x slower. SRAM remapped cacheable -> SError (T7, open).

## Bench results 30 October 2026 (build 59 = build 58 + generic L2 data RAM wrappers)
* Flash mode, firmware v7: PASS, "DDR4 total errors: 0" - T1 words, T2 address bits, T5 L2 ways, T3 4 MB block, T6 paths,
  T8 DDR4 evictions, T4 strobes, all with the CPU caches ON. T8 had 7536 errors on build 58: the L2 data RAM integration was the
  defect, the DDR4 bridge/IP is verified clean.
* RAM mode, firmware v7: ran to T7, SError. Root cause is the test: 0x810000 lies outside the 64 KB RAM window the NIC-400
  decodes at 0x800000 (asib_A53 decode_int[2]); the DECERR on the write-allocate line fill arrives asynchronously. v8 uses
  0x808000-0x80FFFF. Note for the SoC: the FPGA SRAM wrapper is 128 KB but only 64 KB is addressable.
* Next: v8 RAM mode, then the RAM-mode SoC Labs regression executed from the SODIMM, then the flash regression.
* 06:30 RAM mode, firmware v8: PASS, T1-T8 all 0 errors (T7 SRAM evictions included). 06:33 RAM-mode regression from the SODIMM:
  hello_world, mem_tests, gic_tests, timer_tests, neon_tests, peripheral_test, pl011_uart_tests 7/7 PASS. Step 2 verified.
* 07:09-10:40 build 57's flash regression on build 59: 10/10 PASS from the physical flash (dap, hello_world, mem, neon, peripheral,
  gic, low_power, pl011, timer, uart_tests_hw). Build 59 is the board baseline; step 2 complete.
