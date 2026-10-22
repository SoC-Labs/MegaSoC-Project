# MegaSoC on the Synopsys HAPS-SX VU19P — bring-up contribution (October 2026)

Everything SoC Labs needs to reproduce the HAPS-SX bring-up of MegaSoC (Arm Cortex-A53) and the state it reached on
21 October 2026: the stock boot sequence runs end to end on the board — boot ROM, SRAM, both UARTs, interrupts through
the GIC-400, PPU power sequencing, the on-board W25Q32FW flash programmed over UART and booted in QPI mode through the
XIP window, and both CPU caches enabled. Seven of the eleven SoC Labs tests pass from RAM, from an in-FPGA flash
emulator and from the physical flash. Full account: `docs/MegaSoC_Work_Record_rev6.pdf`; bug register rows 1–68 are
in its Section 10; the running bug log with Jira cross-references is `docs/MegaSoC_bug_log_2026-09-30_to_10-21.md`.

Prepared by Anastasios Dimitriou (SoC Labs, University of Southampton) with Claude Code (Anthropic) as bring-up
assistant. No Arm-licensed source is in this directory: the Vivado project is rebuilt from the Arm IP environment
plus the files and patches here.

## Layout
| Path | Content |
|---|---|
| `rtl/` | FPGA top level `haps_top.sv` (20 MHz differential clock, resets, 10 s auto-reset with console hold-off, whole-bus debug UART logger), `debug_uart_probe.sv`, `axi4_bram_slave.sv` (512 KB block-RAM slave on the DRAM port, UART-loadable), `axi4_error_slave.sv`, `qspi_flash_emu.sv` (SST26VF064B-compatible flash model behind the real QSPI controller, selected by `USE_FLASH_EMU`), `PREICG_X4B_A9TS_C31.sv` (clock-gate cell bypass), `rfhds_pg_svt_fpga_models.sv` (behavioural models of the TSMC cache RAM macros: 1-cycle registered read, defined power-up, output held through writes). |
| `constraints/` | `haps_top.xdc` (pins: GCLK1, PMOD3 UARTs, bank-21 flash, LEDs; one clock domain), clocks, flash I/O and floorplan constraint files. |
| `scripts/` | `rebuild_bitstream.tcl` / `elab.tcl` (build chain with constraint guards and an elaboration gate), `tb_haps.sv` (VCS testbench of the FPGA top: console tap on UART0's data register, bus and cache-RAM monitors) and an example file list. |
| `host/` | `haps_qspi.py` (monitor driver: load/program/boot/suite over the console port, termios only), `haps_capture.sh`, `haps_parse_logger.py` (whole-bus logger decoder). |
| `firmware/` | `bootloader_monitor/` (the bring-up boot ROM: UART monitor, flash programming, Winbond start-up with the validated dummy count and exit sequence, production boot), `dram.scat` (tests linked at 0x8000_0000 for RAM loading), `mkflash_pack.py`, the cache probes, and `images/` (flat images of the SoC Labs tests for RAM, emulated flash and physical flash). |
| `patches/megasoc_tech/` | Changes made to SoC Labs RTL for the FPGA, as unified diffs against megasoc_tech `b4147eb` (the GitLab base this work started from). Review before porting: most are FPGA-only (debug taps, clock-gate bypass, RAM slave, emulator mux), a few are design fixes already verified on hardware (SRAM wrapper polarity and address range — `SRAM_wrapper.sv.diff`; reset structure and interrupt synchroniser — `megasoc_cpu_ss.sv.diff`, `megasoc_irq_sync.v.diff`; ROM/SRAM power-control gate requests). `megasoc_tech_wrapper.sv.diff` is large because it carries the debug infrastructure; upstream has since changed this file for LPDDR4, so it will not apply cleanly. |
| `patches/ahb_qspi/` | The FPGA variant of the QSPI controller: reclocked on HCLK with rise/fall enables (no generated clock), zero latches, plus the two 1-bit write fixes (MBT-55, MBT-48). Diffs against ahb_qspi `a16f13e`, the GitLab base this work started from. The current AHB-QSPI master (146 commits later) already produces correct 1-bit writes — verified by simulation on 21 October: 31h+1 byte = 16 clocks carrying 0x02, 02h+16 bytes = 160 clocks, data exact — so no change is proposed there; the FPGA variant is kept only for the record. |
| `docs/` | Work record revision 6 (PDF and DOCX), the bug log, per-build notes for builds 43–54 and the N25 root-cause note. |

## Files deliberately NOT included (Arm-licensed, or derived from Arm deliverables)
* The configured `CORTEXA53.v`, GIC-400, NIC-400, SIE-300, PCK-600 and the MP030 deliverable: take them from the Arm IP environment as for the ASIC flow.
* Cache RAM integration: the FPGA build uses Arm's **generic** `models/rams/generic/ca53_l2_tagrams.v` (not the TSMC example, which is for a 1 MB L2 and mis-indexes this core's 256 KB L2 — the cause of the cache-enable stop, work record Section 18) together with the TSMC example `ca53_caches_tlb_rams.v`, `ca53_l2_datarams.v` and `ca53scu_l1d_tagrams.v` over the models in `rtl/rfhds_pg_svt_fpga_models.sv`.
* `ca53_generic_ram_fpga.v`: a copy of Arm's `ca53_generic_ram.v` with three changes, to be made locally: (1) the `initial` block initialises every word to zeros, or ones when `reset_high` is set, unconditionally; (2) `rdata_reg` is assigned only on a read cycle (no `1'bx` in other cycles); (3) `rd_o = rdata_reg` (no `ls_i` gating). It replaces Arm's file in the Vivado project.
* `ApbPC.v`, `pck600_clock_gate.v`: the FPGA copies bypass the clock gate (clock passes straight through) and disable the protocol checker; apply the same locally.

## Rebuilding the Vivado project (2024.1, xcvu19p-fsva3824-2-e)
1. Set up the Arm IP environment and the MegaSoC submodules as for simulation; apply `patches/` to a scratch copy of the SoC Labs sources (they are FPGA-only).
2. Create a project with `rtl/`, `constraints/`, the SoC Labs sources, the Arm IP (CA53 configured with `NUM_CPUS = 1`, `L2_CACHE_SIZE = 4'b0001`) and the RAM models above; `verilog_define = FPGA_BUILD`; top `haps_top`.
3. Generate `bootrom.v` from the boot ROM of your choice with `bootrom_gen.py -a 14`; the bring-up monitor is in `firmware/bootloader_monitor/`.
4. Build with `scripts/rebuild_bitstream.tcl` (it refuses to run if the clock constraints are not in force). Expect WNS ≈ +14 ns, WHS +0.01 ns, 0 critical warnings, one clock domain.
5. Board: ConfPro `test_reset_timing.csprj` (GCLK1 = 20 MHz), program with the Vivado hardware manager. Console = UART0 on PMOD3 IO[0]/IO[1] at 115200 8N1; logger = PMOD3 IO[3].

## Running tests
```
haps_qspi.py load  <test>_dram.bin 80000000 ; haps_qspi.py go 80000000        # from RAM
haps_qspi.py suite --winbond <test>_flash.bin ...                             # program the physical flash and boot
haps_qspi.py suite --flash   <test>_flash.bin ...                             # from the in-FPGA emulator (USE_FLASH_EMU = 1)
```
Images built with the MBT-56 scatter-loading fix (single load region) need no SRAM preload; the older per-region
images in `images/` are paired with `<test>_sram.bin`.

## Related upstream changes (separate pull requests)
* AHB-QSPI: none needed — the write defects MBT-55/MBT-48 found on the GitLab base are already fixed on the current master.
* MegaSoC-Tech: scatter-loading at start-up (MBT-56) and the abort handler syndrome print (MBT-50).
* MegaSoC-Project: `flows/makefile.software` accepts the single-file flash image that the MBT-56 scatter layout produces.
