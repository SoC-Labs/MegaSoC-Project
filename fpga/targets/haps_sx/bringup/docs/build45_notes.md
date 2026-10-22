# Build 45 (2026-10-13) - QSPI/flash monitor ROM (Winbond W25Q32FW)
RTL = build 44 (logger map 44, stuck indicators). Only the boot ROM changes:
  software/src/bootloader_monitor/bootloader.c (scratch, not committed), armclang, 45 KB image, caches off.
Boot: banner -> flash identify (66/99 reset, JEDEC; if the chip was left in QPI: QIO=1, FFh, back to SPI, retry)
      -> "press any key within ~3 s" (tests UART0 RX, pin BE19) -> no key: auto start:
         SPI XIP (0Bh, 8 dummy) 4 words | Winbond QPI: 50h+31h QE (fallback 06h+31h), 38h, C0h P=3 (8 dummy),
         QPI XIP 0Bh 4 words, QPI XIP EBh continuous (mode A0, No_CMD) 4 words, FFh exit QPI, back to SPI XIP
         -> jump to 0x400000 if word0 is not FF/00/CC, else monitor.
Monitor commands (hex args): r/w/x memory, c raw SPI_CMD, j JEDEC, q QIO, i info, s 0|1|2|9 start-up variants,
  e erase 4 KB, p program (N bytes + LE sum32), m memory load, k sum32 verify, g jump, a auto, h help.
Host: ~/script/haps_qspi.py [-p /dev/ttyACM0] cmd|program|load|go|term  (termios only).
Controller quirk found by code reading: in SPI mode (QIO=0) qspi_controller.sv DATA_O shifts write data LSB-first per
  nibble -> byte X reaches the flash as {rev4(X[7:4]),rev4(X[3:0])}. The ROM pre-swaps (fix_wr) in SPI mode; the QE
  readback (SR2 via 35h) on hardware will confirm. QPI writes are unaffected. Candidate bug register entry.
CG092 flash cache: CCR resets to 0 = bypass (p_flash_cache_f0.v line 1171); monitor reads the window with CCR=0 and
  enables the cache (CCR=1, wait SR&3==2) only before a jump.
Expected first run: JEDEC EF6016, SPI XIP words FFFFFFFF (erased), QPI words FFFFFFFF if the Winbond sequence is right,
  then the monitor prompt. Then: haps_qspi.py program build/hello_world/host0/app_flash.v8-a.hex/EXEC_ROM 0 ; load RWZI
  (0xAC bytes) to 800000 ; go.

Result (2026-10-14 02:33): WNS +20.009 ns, WHS +0.007 ns, all constraints met, 0 critical warnings, 16 DRC (unchanged), latches 0. Build time 3 h 42 min. Bitstream md5 8dcb1270b935fd10a3fa750a3f71f0ba
