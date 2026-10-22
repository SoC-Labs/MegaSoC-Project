# Build 51 (2026-10-19 19:04) - build 50 hardware + monitor ROM v5.2
No RTL change versus build 50 (real W25Q32FW, controller write fixes N39/N27).
ROM v5.2 (bootloader_monitor_v52.c): winbond_startup rewritten from the 19 Oct bench measurements -
  robust exit from QPI continuous read (10 clocks of ones, FFh, 66h/99h), QE re-set before 38h, QPI JEDEC check,
  C0h P=0x30, EBh + mode A0 by direct SPI_CMD transaction with N_Dummy 6 (then 8 as fallback), AHB_CMD = EBh/6,
  XIP No_CMD window compared with a 1-bit reference read, boot if word 0 = D2800000.
  Auto-start at reset (JEDEC EF): same routine -> boots the image in the flash without host involvement.
  'n [D] [1]' runs it by hand. 'b' = SST/library path (emulator builds only).
Host: haps_qspi.py suite --winbond <test>_flash.bin ... (program, SRAM preload, 'n 6 1' / 'n 8 1').
Bench expectation: hello_world (already in the flash) boots at the first reset after programming the bitstream.

## Result (haps-dev, 20 Oct 05:29, suite --winbond): 7/7 PASS from the PHYSICAL on-board W25Q32FW
hello_world, mem_tests, timer_tests, neon_tests, peripheral_test, gic_tests, low_power_tests - each programmed over
UART (erase 1.3 s, program 7 s, verified through the 1-bit window), booted by ROM v5.2's Winbond start-up at N_Dummy 6
on the first attempt, executed in QPI continuous-read mode through the XIP window (flash cache bypassed).
Same 7 tests now pass from RAM (build 48), from the emulated flash (build 49) and from the real flash (build 51).
(The 60 s shown per test is the runner's fixed wait for the end marker, not the test time.)
