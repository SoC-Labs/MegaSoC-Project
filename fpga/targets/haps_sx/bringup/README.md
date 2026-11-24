# MegaSoC on the Synopsys HAPS-SX VU19P — bring-up contribution (October 2026, updated 24 November 2026 for build 65)

Everything SoC Labs needs to reproduce the HAPS-SX bring-up of MegaSoC (Arm Cortex-A53) and the state it reached on
30 October 2026 (build 59): the stock boot sequence runs end to end on the board — boot ROM, SRAM, both UARTs, interrupts
through the GIC-400, PPU power sequencing, the on-board W25Q32FW flash programmed over UART and booted in QPI mode through
the XIP window, both CPU caches — and the on-board DDR4 SODIMM is the SoC's DRAM behind the NIC-400 DRAM port (Jira
MGSOC-34). All ten buildable SoC Labs tests pass from the physical flash; seven of them also execute from the DDR4; a
dedicated DDR4/cache test passes from both with the caches on. Full account: `docs/MegaSoC_Work_Record_rev8.pdf`
(Sections 27–32 cover the DDR4 work and the second L2 RAM finding; the bug register is Section 10, rows 1–85); the running
bug log with Jira cross-references is `docs/MegaSoC_bug_log_2026-09-30_to_10-30.md`.

Prepared by Anastasios Dimitriou (SoC Labs, University of Southampton) with Claude Code (Anthropic) as bring-up
assistant. No Arm-licensed source is in this directory: the Vivado project is rebuilt from the Arm IP environment
plus the files and patches here.

## Layout
| Path | Content |
|---|---|
| `rtl/` | FPGA top level `haps_top.sv` (20 MHz differential clock, whole-bus debug UART logger, DDR4 pins and reference clock as top-level ports, LED_G1 = DDR4 calibrated, SD card pads on PMOD4 since build 62), `haps_reset_ctrl.sv` (build 64: the SoC reset policy, formerly inline in the top: 10 s boot-retry reset that stops once a flash boot has begun in a host-silent session, 215 s console hold-off for attended sessions, host reset request = UART_RX low for 4 ms; see "Build 64" below), `haps_ddr4_bridge.sv` (DRAM_AXI 64-bit @ 20 MHz → Xilinx AXI clock converter → 64→512 data-width converter → Xilinx DDR4 IP `ddr4_0`; rank bit tied low; converters held in reset until calibration; a DRAM access before calibration stalls instead of erroring), `debug_uart_probe.sv`, `axi4_bram_slave.sv` (the 512 KB block-RAM slave the DRAM port had before build 58, still selectable with `USE_DDR4 = 0`), `axi4_error_slave.sv`, `qspi_flash_emu.sv` (SST26VF064B-compatible flash model behind the real QSPI controller, instantiated only when `USE_FLASH_EMU = 1`), `PREICG_X4B_A9TS_C31.sv` (clock-gate cell bypass), `rfhds_pg_svt_fpga_models.sv` (behavioural models of the TSMC cache RAM macros). |
| `constraints/` | `haps_top.xdc` (pins: GCLK1, PMOD3 UARTs, bank-21 flash, LEDs, the PMOD4 SD card pins of build 62, `PULLUP` on UART_RX since build 64), clocks, flash I/O, SD card I/O (`haps_top_sdio_io_impl.xdc`, implementation only) and floorplan constraint files, and `haps_top_ddr4_impl.xdc` (implementation only: the 123 DDR4 pins with POD12/SSTL12 DCI and the DCI cascade, LED_G1, `set_clock_groups -asynchronous` between HAPS_CLK and the DDR4 reference clock with its MMCM/PLL children). |
| `ddr4/` | MGSOC-34 step 1 — the Xilinx DDR4 IP alone on the SODIMM: `gen_ddr4_ip.tcl` (IP `ddr4_0`, ddr4 v2.2, configured as the vendor's proven HAPS-SX design with AXI narrow bursts enabled), `haps_sx_ddr4_pins.xdc` (123 pins from SoC-Labs-HAPS-SX-Tools pinfile.csv, banks 29/30/31 = SLR2), `haps_sx_ddr4_misc.xdc`, `haps_ddr4_ex_top*.sv` (example-design wrappers, v2 with a VIO), `build_ddr4_ex*.tcl`, `check_ddr4_cal.tcl` (programs a bitstream over JTAG from the server and prints the IP's calibration status and VIO probes), `probe_parts.tcl`, the IP property dump, `README_ddr4_step1.md` / `README_ddr4_step2.md` (design, results, bench procedure). `sim/`: `tb_bridge.sv` + `ddr4_0_sim_model.sv` + `mk_brsim.tcl`, an xsim testbench of the bridge against a behavioural DDR4 IP model (203 checks, log included). |
| `scripts/` | `rebuild_bitstream.tcl` / `elab.tcl` (the build 54 chain with constraint guards and an elaboration gate), `rebuild_bitstream58.tcl` (adds the three Xilinx IPs to the project when absent, runs their out-of-context synthesis first, then the same chain), `rebuild_bitstream59.tcl` (the L2 RAM fileset correction below, with an assertion that exactly one data and one tag wrapper are in the compile order), `tb_haps.sv` (VCS testbench of the FPGA top), `tb_haps_reset_ctrl.sv` (xsim testbench of the reset policy module, scaled parameters, 18 checks; log `tb_haps_reset_ctrl_20261117.log`) and an example file list. **Build 65:** `dump_rom64.tcl`, `rom_init_gen.py` and `patch_rom65.tcl` change the boot ROM of a routed design without a rebuild (see below); `rom_init_gen_20261124.log` is the layout proof of the build-65 run. |
| `host/` | `haps_qspi.py` (monitor driver: load/program/boot/suite over the console port, termios only; `suite [--flash\|--winbond] [--timeout S]`; since build 64 every verb takes the board back to the monitor with the host reset request when no prompt answers, and the `linux`/`linux2`/`linuxterm` verbs load the EL3 shim, DTB and kernel Image over the console and attach a paced terminal), `haps_capture.sh`, `haps_parse_logger.py` (whole-bus logger decoder). Since build 65: `HAPS_BOOT_CACHES=0` boots the `suite --winbond` images with the CPU caches off (`n D 1 0`), a test that ends inside the first 3 s no longer costs the whole timeout, and a monitor prompt is accepted only when `> ` is the last thing received and the line then stays quiet. |
| `firmware/` | `bootloader_monitor/` (the bring-up boot ROM: UART monitor, flash programming, Winbond start-up, production boot), `dram.scat` (tests linked at 0x8000_0000 for loading into DRAM), `ddr4_fpga_tests/` (the DDR4 and cache test, see below; `makefile` = dram scatter, `makefile.default_scat` = flash XIP variant), `mkflash_pack.py`, the cache probes, and `images/` (flat images of the SoC Labs tests for RAM, emulated flash and physical flash, the seven `*_dram.bin` of the RAM-mode regression executed from DDR4, and `ddr4_fpga_tests_{dram,flash}.bin` v8). The monitor is v6.0 since build 65: a flash image is started with the CPU caches on. |
| `patches/megasoc_tech/` | Changes made to SoC Labs RTL for the FPGA, as unified diffs against megasoc_tech `b4147eb` (the GitLab base this work started from); `megasoc_tech_wrapper.sv.diff` now includes the DDR4 ports and the `USE_DDR4` / `USE_FLASH_EMU` generates. `megasoc_chip.v.build58.diff` and `megasoc_system.sv.build58.diff` are the build-58 DDR4 port additions to the two system-level files of the FPGA tree (relative to their build-57 state). Review before porting: most are FPGA-only (debug taps, clock-gate bypass, RAM slave, emulator mux, DDR4), a few are design fixes already verified on hardware (SRAM wrapper polarity and address range — `SRAM_wrapper.sv.diff`; reset structure and interrupt synchroniser — `megasoc_cpu_ss.sv.diff`, `megasoc_irq_sync.v.diff`; ROM/SRAM power-control gate requests). `megasoc_tech_wrapper.sv.diff` is large because it carries the debug infrastructure; upstream has since changed this file for LPDDR4, so it will not apply cleanly. |
| `patches/ahb_qspi/` | The FPGA variant of the QSPI controller (reclocked on HCLK, zero latches, the two 1-bit write fixes MBT-55/MBT-48) against ahb_qspi `a16f13e`. The current AHB-QSPI master already produces correct 1-bit writes; the FPGA variant is kept for the record. |
| `docs/` | Work record revision 8 (PDF and DOCX; it contains revisions 4–7 in full), the bug log to 30 October, per-build notes for builds 43–59 and 64, and the N25 root-cause note. Added for build 65: `build65_notes.md` and `sdboot_v2_profile_20261123.md` (the measurement that led to it). |

## Files deliberately NOT included (Arm-licensed, or derived from Arm deliverables)
* The configured `CORTEXA53.v`, GIC-400, NIC-400, SIE-300, PCK-600 and the MP030 deliverable: take them from the Arm IP environment as for the ASIC flow.
* Cache RAM integration — **corrected 30 October 2026**: the FPGA build must use Arm's **generic** wrappers for BOTH L2 RAM groups, `models/rams/generic/ca53_l2_tagrams.v` AND `models/rams/generic/ca53_l2_datarams.v` (they mask the set index with `l2_size`), over the FPGA RAM model `ca53_generic_ram_fpga.v` below, together with the TSMC example `ca53_caches_tlb_rams.v` and `ca53scu_l1d_tagrams.v` over `rtl/rfhds_pg_svt_fpga_models.sv`. The TSMC example `ca53_l2_datarams.v` and `ca53_l2_tagrams.v` are written for a 1 MB L2 and address the RAMs with the unmasked 14-bit index: on this core's 256 KB L2 a line's data can be written to one RAM word and read from another, so an eviction writes back another line of the same set. Build 54 corrected the tag RAMs (the cache-enable stop, work record Section 18); builds 54–58 still compiled the example DATA RAM wrapper, which only showed once the caches were exercised with dirty evictions over the DDR4 (Section 29, bug register row 79). Build 59 disables the example and the `mem_integrations/{CortexA53,FPGA}` duplicates in the project (`scripts/rebuild_bitstream59.tcl`); `mem_integrations/FPGA/ca53_l2_datarams.v` is also wrong (64 KB of storage for a 256 KB L2, row 84).
* `ca53_generic_ram_fpga.v`: a copy of Arm's `ca53_generic_ram.v` with three changes, to be made locally: (1) the `initial` block initialises every word to zeros, or ones when `reset_high` is set, unconditionally; (2) `rdata_reg` is assigned only on a read cycle (no `1'bx` in other cycles); (3) `rd_o = rdata_reg` (no `ls_i` gating). It replaces Arm's file in the Vivado project.
* `ApbPC.v`, `pck600_clock_gate.v`: the FPGA copies bypass the clock gate (clock passes straight through) and disable the protocol checker; apply the same locally.
* The Xilinx IP cores (`ddr4_0`, `axi_cc_dram`, `axi_dw_dram`) are generated, not stored: `ddr4/gen_ddr4_ip.tcl` and `scripts/rebuild_bitstream58.tcl` hold every property.

## Rebuilding the Vivado project (2024.1, xcvu19p-fsva3824-2-e)
1. Set up the Arm IP environment and the MegaSoC submodules as for simulation; apply `patches/` to a scratch copy of the SoC Labs sources (they are FPGA-only).
2. Create a project with `rtl/`, `constraints/`, the SoC Labs sources, the Arm IP (CA53 configured with `NUM_CPUS = 1`, `L2_CACHE_SIZE = 4'b0001`) and the RAM models above — generic L2 data AND tag wrappers only; `verilog_define = FPGA_BUILD`; top `haps_top`.
3. Generate `bootrom.v` from the boot ROM of your choice with `bootrom_gen.py -a 14`; the bring-up monitor is in `firmware/bootloader_monitor/`.
4. Build with `scripts/rebuild_bitstream58.tcl` (creates the DDR4 IP and the two AXI converters when absent and synthesises them out of context first, then synth_1 with the constraint guard and impl_1 to the bitstream); `scripts/rebuild_bitstream59.tcl` shows the fileset assertions to keep. Expect WNS ≈ +0.45 ns (the worst path is inside the DDR4 IP's 266.5 MHz domain; HAPS_CLK itself has ≈ 30 ns of slack), WHS +0.01 ns, 0 critical warnings, HAPS_CLK and the DDR4 user clock in asynchronous groups. Without the DDR4 (`USE_DDR4 = 0`, block-RAM slave) the build 54 script applies and WNS is ≈ +14 ns.
5. Board: ConfPro `test_reset_timing.csprj` (GCLK1 = 20 MHz), program with the Vivado hardware manager or `ddr4/check_ddr4_cal.tcl <bit>` (also prints the DDR4 calibration status). Console = UART0 on PMOD3 IO[0]/IO[1] at 115200 8N1; logger = PMOD3 IO[3]. LED_G1 (BE14) lights within a second when the DDR4 has calibrated; PB1 (HAPS_RESET_N) resets the SoC and the DDR4 IP, the 10 s auto-reset and the monitor's `g` leave the DRAM contents alone.

## The DDR4 integration (builds 58–59, MGSOC-34)
* Window: the NIC-400 DRAM port passes 33 address bits; the bridge ties the IP's bit 33 (the rank bit) low, so rank 0 (8 GB of the 16 GB MTA16ATF2G64HZ-2G3 SODIMM) is reachable: CPU 0x8000_0000–0x1_FFFF_FFFF = DRAM 2–8 GB, CPU 0x2_0000_0000–0x2_7FFF_FFFF = DRAM 0–2 GB. `DRAM_BASE` 0x8000_0000 in the firmware is unchanged.
* `firmware/ddr4_fpga_tests/ddr4_fpga_tests.c` (v8): T1 word patterns, T2 one cell per address bit 3..32 plus the alias and the top of the window, T5 L2 set/way aliasing while cache-resident, T3 4 MB block through the caches, T6 cached-write/uncached-read and the reverse, T8 dirty DDR4 lines evicted by a read sweep, T7 the same with the on-chip SRAM remapped cacheable (RAM image only), T4 8/16/32-bit stores above 4 GB. It widens TCR_EL3 (the library's `enable_mmu()` limits EL3 to 4 GB of VA / 32-bit PA), sets CPUECTLR.SMPEN and enables the caches itself (the library leaves them off), and prints each test's duration in 20 MHz generic-counter ticks. Expected: "DDR4 total errors: 0" and "** TEST PASSED **" from DDR4 (`suite firmware/images/ddr4_fpga_tests_dram.bin`) and from the flash (`suite --winbond firmware/images/ddr4_fpga_tests_flash.bin`).
* Firmware facts found on the way (bug register rows 80–85, all reported, none changed upstream): every RAM-mode test of builds 47–58 ran with the CPU caches off (the monitor leaves them off and `boot.s` enables the MMU only); `enable_caches()` never sets SMPEN; the Winbond `n` boot path jumps without the CG092 flash-cache enable (uncached XIP, ~30× slower); the NIC-400 decodes 64 KB of on-chip RAM at 0x80_0000 (`0x800000–0x80FFFF`) while the FPGA SRAM wrapper holds 128 KB — a cached access to 0x81_0000 is a DECERR reported as an SError.

## Running tests
```
haps_qspi.py suite <test>_dram.bin ...                          # load into DDR4 at 0x8000_0000 over UART and run ('g')
haps_qspi.py suite --winbond [--timeout S] <test>_flash.bin ... # program the physical flash and boot through the Winbond start-up
haps_qspi.py suite --flash   <test>_flash.bin ...               # from the in-FPGA emulator (USE_FLASH_EMU = 1)
```
Images built with the MBT-56 scatter-loading fix (single load region) need no SRAM preload; the older per-region
images in `images/` are paired with `<test>_sram.bin`. The corrected uart_tests (v5) keeps the console at 115200: run it
WITHOUT `--baud-after` (that option is for a test that changes the console rate; with it the host misses the tail of the
output and reports a false HANG).

## Status, 30 October 2026 (build 59)
| | From the physical flash | From DDR4 |
|---|---|---|
| ddr4_fpga_tests (caches on) | PASS | PASS |
| hello_world, mem, timer, neon, peripheral, gic, pl011 tests | PASS (7) | PASS (7) |
| low_power_tests, dap_tests (MBT-58), uart_tests v5 (MBT-59) | PASS (3) | no RAM image |
| sdio_tests / coremark / dma350_tests | no card / do not build upstream | |

## Build 64 (17 November 2026): standalone boot, host reset request, SD card byte order
Builds 60–64 came after the October contribution: 60/61 the GIC-400 clock-gate cell as a real BUFGCE (Linux 6.6.161 boots to
a shell on build 61, Jira MGSOC-39), 62/63 the SD card on PMOD4 with the repository sdio-controller RTL (MBT-70 … MBT-74),
64 the files in this update (`docs/build64_notes.md`).
* **Reset policy** (`rtl/haps_reset_ctrl.sv`, instantiated by `haps_top.sv`, parameters at their 20 MHz defaults): the
  periodic 10 s reset is a boot retry only and stops for good once a flash boot has begun in a session in which the host has
  sent nothing (`QSPI_nCS` active more than 2 s after the reset release; the monitor ROM's key window is 5.5 s and it reads the
  JEDEC id only within the first 10 ms). A host-attended session keeps the build-46 behaviour (any byte suspends the reset for
  ~215 s, renewed by every byte), so the flashing harness is unchanged. PB1 resets at any time.
* **Host reset request**: hold UART_RX low for at least 4 ms, then release; the SoC resets on the release and the new session
  counts as unattended. From a PC: one 0x00 character at 1200 baud (7.5 ms low; the longest low of 115200-baud traffic is
  78 µs). `host/haps_qspi.py` does this whenever the monitor does not answer. The request also clears the hold-off. A serial
  BREAK is not used because the bench's DAPLink CDC bridge turns it into a reset of its own MCU.
* **Constraints**: `PULLUP` on UART_RX (a disconnected bridge reads idle-high), the PMOD4 SD card pins and
  `haps_top_sdio_io_impl.xdc`.
* **Results**: one unattended SD-card Linux boot ran 1 day 23 h 20 min (170,403 s) with zero host bytes and zero resets;
  18 of 18 host reset requests reset the board (banner 0.7–1.7 s later); five of five unattended boots reached the shell;
  the 10-image regression passes from the physical flash; `sdio_tests` 12/14 with the driver copying raw little-endian words
  on both PIO paths (the two failures are the multi-block DMA writes MBT-72/73); a monitor-driven probe shows PIO read, PIO
  write, DMA read and DMA write all little-endian natural, i.e. the sdio-controller byte-order fix of its PR #1 verified on
  hardware (MBT-74). Timing: WNS +0.392 / WHS +0.010 ns, DRC 0 errors.

## Build 65 (24 November 2026): the boot ROM starts flash images with the CPU caches on
Build 65 is build 64 with different boot ROM contents and nothing else (`docs/build65_notes.md`).
* **Why.** A profile of the SD-card Linux loader (`docs/sdboot_v2_profile_20261123.md`) showed that the monitor ROM of
  builds 51–64 started every flash image with the CPU caches and the CG092 flash cache off, and that the library start-up
  only enables the MMU (MBT-66): about 100 µs per taken branch, 521 s from the monitor banner to Linux. Neither the SD
  card nor the controller was the bottleneck.
* **Monitor v6.0** (`firmware/bootloader_monitor/bootloader.c`): the production boots (auto-start, `n D 1`, `b`) invalidate
  the data caches by set/way, set CPUECTLR.SMPEN and call `enable_caches()` / `enable_caches_el1()` before the jump, i.e.
  the stock `bootloader.c` hand-over plus the two points of MBT-66. `n D 1 0` and `b 0` keep the caches off. The monitor
  itself and `g` are unchanged, so RAM-loaded programs see the same state as before.
* **ROM patch flow, about 10 minutes instead of a 3 hour rebuild.** The ROM is 32 RAMB36E2 (16K × 2,
  `u_ROM_wrapper/u_bootrom/RDATA_reg_0..31`). `scripts/dump_rom64.tcl` dumps them from the routed checkpoint;
  `scripts/rom_init_gen.py` proves the layout against the ROM known to be in that checkpoint (every bit lane equals one
  data bit at all 16,384 addresses) and writes the INIT strings for the new `bootrom.v`; `scripts/patch_rom65.tcl` applies
  them to the routed checkpoint, reads them back, and writes the bitstream. Nothing is synthesised, placed or routed:
  WNS +0.392 / WHS +0.010 ns as build 64. The paths in the three scripts are those of the SoC Labs build server.
* **Results.** Monitor banner to the Linux banner 27.5 s (521.3 s on build 64 with the first loader; 30.9 s on build 64
  with the loader of MegaSoC-Tech PR #28, which enables the caches itself). Five of five unattended boots. The 10-image
  regression passes from the physical flash with the caches on, the whole suite in 193 s.
* **Found on the way.** `sdio_tests` does worse at full speed: a read issued straight after a write reaches the card while
  it is still programming (MBT-75, now High), and the driver's timeouts are poll counts that shrink with the faster CPU.
  With the caches off it gives the build-64 result (12/14). Reads alone are unaffected.

## Related upstream changes
* MegaSoC-Tech: PRs #4–#10 merged (scatter-loading at start-up MBT-56, abort syndrome MBT-50, CoreSight debug window MBT-58, uart_tests MBT-59, timer INTSTATUS race MBT-61, SPI_WAIT_BUSY bound MBT-57, undriven ports MBT-42, Winbond start-up MBT-47).
* AHB-QSPI: none needed — the write defects MBT-55/MBT-48 found on the GitLab base are already fixed on the current master; megasoc_tech's submodule pointer still needs the bump.
* MegaSoC-Project: `flows/makefile.software` accepts the single-file flash image that the MBT-56 scatter layout produces (PR #7).
* Proposed, not changed here (Arm-licensed library files, or SoC decisions): enable the caches (with SMPEN) in the library start-up or the monitor; widen TCR_EL3 in `enable_mmu()`; `cache_on()` before the Winbond jump; the on-chip RAM size (64 KB decoded vs 128 KB present); the ASIC's own L2 RAM integration should be checked for the same set-index masking (work record Section 32.2, item 50).
* sdio-controller (20 November): PR #1 (byte order on all four data paths, 23 October) is verified on hardware by build 64, the first HAPS build that compiles it; PR #2 adds the trailing `` `default_nettype wire`` every file needs in a single-compilation-unit flow (the Vivado project compiles the repository sources directly since build 63).
* MegaSoC-Tech (20 November): PR #18 merged (no 1.8 V request without a board rail MBT-70; PIO write packing MBT-71, measured on the pre-#1 RTL copy); PR #25 open: PIO write words packed little-endian by default for the controller the tree builds (`SDIO_FIFO_WRITE_LE`), `SDIO_DEBUG` / `SDIO_PROFILE` build options, and `software/src/sdboot/`, the SD-card Linux loader that is the flash boot image of the build-64 results above.
* Linux bring-up (MGSOC-39): the EL3 shim, device tree, kernel configuration fragment, initramfs recipe and console tools are not in this folder yet (they are Arm-IP-free and will come as their own contribution).
* 24 November: sdio-controller PR #2 and MegaSoC-Tech PR #25 are merged. Open: MegaSoC-Tech PR #27 (sdspi pointer to the merged controller commit) and PR #28 (`sdboot` turns the CPU caches on when the boot ROM left them off). Jira: MBT-66 raised to Medium with the measured cost, MBT-75 raised to High with the full-speed result.
