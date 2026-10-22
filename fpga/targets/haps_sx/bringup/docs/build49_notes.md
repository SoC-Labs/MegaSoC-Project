# Build 49 (launched 2026-10-15 ~18:00) - in-FPGA QSPI flash emulator, production flash boot
Why: the on-board W25Q32FW answers only ID/status reads (N30); firmware cannot recover it.
RTL (all FPGA-only, in sources_1/new or the tech wrapper):
  * qspi_flash_emu.sv (new): SST26VF064B-compatible SPI/QPI slave on the controller's pad-side signals
    (JEDEC BF 26 43; 9F/05/35/06/04/38/FF/66/99/03/0B/EB/02/20/D8/C7/60; QPI 0Bh/EBh = addr + mode + 4 dummy;
    mode Ax -> continuous read (No_CMD); FFh / Reset-QIO exits; clock-less CS pulses ignored). Store = 512 KB BRAM,
    one true-dual-port array per byte lane; port A = backdoor, port B = flash side. Reset with the SoC; store is not.
  * megasoc_tech_wrapper.sv: USE_FLASH_EMU = 1 -> controller QSPI_IO_i comes from the emulator (pads still driven,
    inputs ignored); emulator store = second 512 KB window of the DRAM slave: 0x8008_0000..0x800F_FFFF = flash 0..7FFFF.
  * axi4_bram_slave.sv: BD_BIT = 19 backdoor ports; reads and writes now serialised (one port on the backdoor).
ROM v4 (software/src/bootloader_monitor, 48 KB): on JEDEC BF runs the UNMODIFIED library SPI_STARTUP() and jumps to
  0x400000 like bootloader.c (CG092 untouched, caches off) - automatically at reset if word 0 = D2800000, or with 'b'.
Simulation (scratchpad/simemu/tb_emu.sv, xsim, real apb_qspi_regs + mux + controller + clock_div + ahb_qspi_interface):
  SST SPI_STARTUP sequence, CTRL 03A00101, AHB line reads @10/@40/@40(NO_FETCH)/@1FF0/@0, Reset-QIO, SPI 03h,
  erase + status, program + readback, SPI-mode XIP, erased-line read, backdoor read: 0 errors.
  tb_bram.sv with serialised handshakes: 0 errors. Found and fixed in simulation: output-byte function sensitivity
  (sim artefact), continuous-mode exit, clock-less CS pulse from the controller's NO_FETCH path.
Images: flash_images/<test>_flash.bin (EXEC_ROM, flash offset 0) + <test>_sram.bin (RW + zeroed ZI for 0x800000) for
  hello_world, mem_tests, timer_tests, uart_tests, pl011_uart_tests, gic_tests, neon_tests, peripheral_test,
  low_power_tests, sdio_tests, dap_tests (stock default.scat builds; mkflash_pack.py).
Bench:  haps_qspi.py load hello_world_flash.bin 80080000 ; haps_qspi.py load hello_world_sram.bin 800000 ;
        haps_qspi.py boot   -> SPI_STARTUP rc=0 CTRL=03A00101 flash[0..3]=D2800000 AA0003E1 ... -> Hello / TEST PASSED
        After that every reset auto-boots the image from the emulated flash (once the UART hold-off expires).

Result (2026-10-15 20:57): WNS +29.320 ns, WHS +0.010 ns, all constraints met, 0 critical warnings, latches 0. Block RAM tiles 743 (+128 = emulator store). DRC 20 = the usual 16 + 4 x RPBF-3 warnings "IO port buffering is incomplete" on QSPI_IO[0..3]: expected, the pad inputs are no longer used (the controller listens to the emulator). Bitstream md5 bd23bd48611aea76c3b54268969b2d3d

Bench note: the ROM RW global SET_QIO_MODE_CMD (0x00804004, initial 0x38) is never initialised (N35); haps_qspi.py writes 0x38 there before every production boot (suite --flash and boot). Without it SPI_STARTUP SST branch sends a random enter-QPI opcode.

## First flash suite on build 49 (haps-dev, 15 Oct 17:15, suite --flash, production boot through the unmodified SPI_STARTUP)
PASS from the XIP window: hello_world, timer_tests, peripheral_test, gic_tests, low_power_tests.
HANG: mem_tests, neon_tests - NOT the XIP path: their flash images were stale builds (mem_tests 2026-07-29,
  BAUDDIV 0x364 = 100 MHz assumption -> console bytes 0xF0/0x00; neon_tests 2026-01-29, old UART init, BAUDDIV 0x20).
  mkflash only rebuilt tests with no existing flash build. Rebuilt with make -B 15 Oct 23:32 (mem, neon, dap); every
  packaged test now has BAUDDIV 0xAD.
XIP probe (xip_probe_dram.bin, RAM): first version hung after its banner in the library SPI_WAIT_BUSY after a 2-clock
  QPI command (FFh): SPI_WAIT_BUSY waits for BUSY to rise first and can miss a transaction that short. Probe now waits
  for not-busy only. Same latent race exists in the monitor's qpi_exit_any (worked 7/7 so far) and in any library user
  that issues a short command.
Runner: 'suite' no longer runs the generic up-front prompt check (it refused to start while a test was spinning).

## Re-run with rebuilt images (haps-dev, 15 Oct 18:40)
XIP probe (RAM-resident, compares the window with the emulator store over 0x12000 bytes): 32-bit, 64-bit, 128-bit
16-aligned, 128-bit 4-aligned line-crossing, 8-bit and a second 32-bit pass: 0 errors.
Flash suite: mem_tests PASS, neon_tests PASS, hello_world PASS.
=> All 7 tests that pass from RAM also pass from the XIP window: hello_world, mem_tests, timer_tests, neon_tests,
   peripheral_test, gic_tests, low_power_tests - booted by the unmodified SPI_STARTUP (SST branch), caches off.
