# Build 54 (launched 2026-10-21 00:56) - N25 root-cause fix: L2 tag RAM integration
See N25_root_cause.md. Changes vs build 53:
  * Vivado fileset: - imports/models/rams/tsmc_cln28hpm_L1_32I_32D_L2_1M/ca53_l2_tagrams.v (Arm TSMC example for a 1 MB L2,
    unmasked set index)  - imports/models/rams/generic/ca53_generic_ram.v (Arm X-style model)
    + imports/models/rams/generic/ca53_l2_tagrams.v (masks the index with l2_size)  + new/ca53_generic_ram_fpga.v
    (same module name ca53_generic_ram: zero/ones power-up, output holds, synthesisable initial).
  * new/rfhds_pg_svt_fpga_models.sv: defined power-up (zeros; I-tag ones), Q holds through write cycles (TSMC-like),
    plain always blocks; SRAMHDE 1-cycle (build 53).
Simulation of exactly this configuration (scratchpad/n25/sim/F1): passes the instruction-cache enable (the hang point
of builds 42-53) - see F1/run.log for the data-cache steps.
Bench: suite --timeout 20 cache_steps_dram.bin cache_probe_dram.bin cache_flashboot_dram.bin
Result (2026-10-21 03:44): ===BUILD=== WNS=14.072 WHS=0.010, all constraints met, 0 critical warnings. Verified in simulation (sim/F5_run_TEST_PASSED.log) before the build.

## Bench 21 Oct 06:18 (build 54) - N25 CLOSED ON HARDWARE
cache_steps_dram: PASS (I-cache on + code, D-cache on + 1 KB SRAM + 64 KB RAM 0 errors, both on + 64 KB 0 errors).
cache_probe_dram:  PASS (enable_caches() as bootloader.c, 8 KB SRAM, 2 x 64 KB RAM, fib loop, disable, retest: 0 errors).
cache_flashboot_dram: booted the image in the flash with both caches on - the flash still held uart_tests from the
  20 Oct loopback session (switches the console to 2 Mbaud -> garbage), so the "HANG" is that test, not the caches.
  Re-run with hello_world programmed pending.
cache_flashboot_dram with hello_world in the flash (06:52): PASS - enable_caches (EL3+EL1) as bootloader.c, Winbond start-up, jump to 0x400000, "Hello SoCLabs MegaSoC / ** TEST PASSED **" with both CPU caches on. The stock boot sequence works end to end on the board.
Flash suite 21 Oct 06:54 (suite --winbond, build 54): 7/7 PASS from the physical flash (hello_world, mem, timer, neon, peripheral, gic, low_power) - the cache fix regressed nothing.

## 21 Oct 16:00 - the three major bugs fixed in the SoC Labs sources (NOT committed; backups *.orig_20261021)
MBT-55 + MBT-48: megasoc_tech/logical/sl_ahb_qspi (own repo soclabs/ahb_qspi.git) qspi_controller.sv - DATA_O 1-bit exit at
  data_counter==6; MSB-first within nibbles (spi_wbit). Unit sim on the original RTL: 31h+1B 17->16 pulses byte 04->02;
  01h+2B 25->24, 00 04 -> 00 02. Diff: ~/Desktop/for_daniel_flash/MBT-55_MBT-48_qspi_controller_1bit_write_fixes.diff
MBT-56: default.scat + bootloader.scat (RW/ZI execution regions inside the ROM load region), stack_multi_cpu_init.s
  main_entry: B __main (armclang). fromelf now emits single-file app_flash.v8-a.hex / bootloader.hex; app_ram hex empty;
  flows/makefile.software accepts both forms. Image for the board: hello_world_flash_scatterfix.bin (72952 B, RW at
  0x10c48, no SRAM preload needed). Bench verification pending: program it, 'n 6 1' -> Hello/TEST PASSED.
MBT-50: system.c abort_handler prints ESR/ELR/FAR (weak handler in the library).
Finding: the SoC Labs VCS flow (simulate/sim/build/simv of 29 Jul) aborts at the flash jump for EVERY image, old or
  new (mem_tests July log, hello_world control run today): the exception is taken by the ROM's handler, i.e. the fetch at
  0x400000 faults (flash model / ROM start-up mismatch, as build 44 on the board). Not caused by these fixes; the flow
  cannot verify flash-booted tests until that is sorted. Not pursued.
Bench 21 Oct (build 54): hello_world_flash_scatterfix.bin programmed (72960 B), booted with n 6 1 and NO SRAM preload -> "Hello SoCLabs MegaSoC / ** TEST PASSED **". MBT-56 fix verified on hardware: the image initialised its own RW/ZI from the flash through __main/__scatterload.
