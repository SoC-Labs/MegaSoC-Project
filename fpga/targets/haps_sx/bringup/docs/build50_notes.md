# Build 50 (launched 2026-10-19 ~11:55) - real on-board W25Q32FW with fixed QSPI SPI writes
Why: the 14-15 Oct "dead chip" diagnosis was wrong. (1) SR1 was read with opcode 09h (typo; 05h is RDSR1), so
"SR1 = FF" meant nothing. (2) Page program and the QE write were discarded by the chip because the QSPI controller
sends one extra SCLK at the end of every 1-bit write (N39) and sends the bits of each nibble in reverse (N27).
Both are in the upstream SoC Labs RTL (verified by simulating megasoc_tech/logical/.../qspi_controller.sv).
Changes:
  * qspi_controller.sv (project copy; original kept as qspi_controller.sv.pre_build50): SPI DATA_O ends at
    data_counter == 3'h6; data out MSB first within each nibble (spi_wbit). Unit TB scratchpad/simqspi/tb_qspi.sv:
    real-pulse counts exact for all transactions, data bytes exact without pre-swap. tb_emu.sv still 0 errors.
  * megasoc_tech_wrapper.sv: USE_FLASH_EMU = 0 (controller listens to the pads again; emulator store still present).
  * ROM v5.1 (bootloader_monitor): globals set in main (N35: g_id, g_rx_seen, g_wrmode = 0 raw, SET_QIO_MODE_CMD);
    no automatic flash writes at boot (old probe wore sector 0x3FF000 on every reset); robust qpi_exit_any (FFh x2,
    66/99 in 4-bit and 1-bit, short-command wait - N38); 'n [D] [1]' = Winbond start-up as drafted for Daniel with
    controller N_Dummy D (6 or 8) and a 1-bit 03h reference read for comparison; auto-start on JEDEC EF tries D=6 then 8
    and boots if the window matches and word 0 = D2800000; 'i' also prints SR3.
Host: haps_qspi.py suite --winbond <test>_flash.bin ... = program real flash (e/p, verify through the 1-bit window),
  preload <test>_sram.bin at 0x800000, boot with 'n 6 1' (falls back to 'n 8 1'). Tested against a fake monitor.

Result (2026-10-19 14:34): WNS +15.067 ns, WHS +0.010 ns, all constraints met, 0 critical warnings, latches 0. DRC 17: the usual 16 minus the 4 RPBF-3 of build 49 (pads are inputs again) plus 1 RTSTAT-10 (see below). Bitstream md5 8886534422178b054eca8ef9125f256e

## Bench, 19 Oct ~16:00 (build 50, raw register sessions) - the real W25Q32FW works
1-bit: 66h/99h reset, QE volatile write (50h, 31h 02) -> SR2=02; WREN -> SR1=02; page program 16 bytes at 0 ->
  read back 03020100 07060504 0B0A0908 0F0E0D0C = FIRST DATA EVER PROGRAMMED INTO THIS CHIP FROM THE SOC.
QPI: 38h accepted (1-bit JEDEC afterwards reads FFFFFFFF); JEDEC in 4-bit = 001660EF (all four lines work);
  0Bh with 2 dummy (power-up P) and with 8 dummy after C0h P=0x30: exact. EBh + mode A0 + N_Dummy 8: data one byte
  late (04030201 ...) -> for EBh the chip counts the 2 mode-byte clocks within its 8 -> controller N_Dummy = 6.
  XIP window in No_CMD continuous mode works (x 400000 shows the data, 400010 all FF).
Exit: three 2-clock FFh did NOT leave QPI continuous mode (1-bit JEDEC then read 000000FC): in continuous mode the
  chip takes them as address nibbles. Robust exit = 4-bit 10 clocks of ones (FFh + FF FF FF FF: address + mode FF
  ends continuous mode), then FFh (exit QPI), then 1-bit 66h/99h.  -> ROM v5.2 (build 51) uses this; N_Dummy 6 first.
Build 51 chain restarted 16:17 (first launch killed: ROM had the weak exit).

## MILESTONE 19 Oct ~17:00 - hello_world executed from the PHYSICAL on-board flash (build 50, by hand)
program hello_world_flash.bin (17 sectors erased 1.3 s, 68640 B programmed 7.1 s, verified via the 1-bit window),
load hello_world_sram.bin 800000, then raw commands: QE (50h, 31h 02), 38h, QPI JEDEC OK, C0h 30, CTRL=1A00001,
EBh N_Dummy 6 -> D2800000 AA0003E1 AA0003E2 AA0003E3, AHB_CMD=60EB, CTRL=3A00101, x 400000 = same,
go 400000 (flash cache ON) -> "Hello SoCLabs MegaSoC / ** TEST PASSED **".
Gotcha: the exit sequence's 66h/99h reset clears volatile QE -> QE must be re-set before every 38h (ROM v5.2 does).
