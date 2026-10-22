# Build 44 (prepared 2026-10-13, not yet launched) - "what did the flash jump hit?"
Build 43 result (capture 20261013_074023 on haps-dev, 10 boots, identical):
  console: banner, "[diag: caches left off]", "***Flash Enabled...Booting***", "Unexpected abort exception.", "** TEST FAILED **"
  logger : QSPIapb=1 (~3.6 ms), FLASH=1 and VECTOR=1 (~5.5 ms), then CPU spins at UartEndSimulation (ROM+0x78B0/0x78C0 fetches).
  => enable_caches() was what stopped build 42 after the banner (separate issue, still open).
  => the jump to 0x400000 takes a synchronous exception. ahb_qspi_interface.sv returns HRESP=ERROR for ANY
     AHB transfer while XIP_ACTIVE=0, and SPI_STARTUP() leaves XIP off (returns 1, ignored by main) when the
     JEDEC ID reads 0 or FFFFFFFF. So either the flash did not answer (-> external abort on the fetch) or it
     answered but holds no valid code (-> undefined instruction). The console cannot tell these apart.
Build 44 changes vs 43:
  1. ROM v2 = software/src/bootloader_diag2/bootloader.c (scratch, not committed), armclang, caches still off:
     prints QSPI CTRL/STATUS, JEDEC ID (SPI_RESET + SPI_READ_JEDIC, CTRL untouched so SPI_STARTUP still cold-paths),
     SPI_STARTUP rc + CTRL/STATUS, 4 data words from 0x400000 (a data abort here = AHB ERROR = XIP off),
     then the jump. abort_handler() overridden: prints ESR_EL3 / EC / ISS / ELR_EL3 / FAR_EL3.
     EC 0x20/0x21 instruction abort, 0x24/0x25 data abort (ISS DFSC 0x10 = synchronous external abort), 0x00 undefined.
  2. Logger bits 10/12 = dbg_wr_stuck / dbg_rd_stuck (outstanding >= 2^15 cycles = 1.6 ms) instead of raw levels,
     which saturated the logger in build 43 (49455 lines, all '!'). Parser map 44 (default), capture script default MAP=44.
Decision pending: is the QSPI flash on the HAPS board populated/programmed? If it is known to be empty, the abort is
expected and the next milestone is programming it (build/<test>/host0/app_flash.v8-a.hex images), not another build.

Result (2026-10-13 18:28): WNS +20.009 ns, WHS +0.007 ns, all constraints met, 0 critical warnings, 16 DRC (same rules as 42/43), latches 0, clocks HAPS_CLK qspi_sclk_pad CLK1HZ. Build time 5 h 18 min. Bitstream md5 d52d80da5128e6ed78f9c070bcda9e05
Netlist check (synth dcp, 2026-10-13 18:35): 76 stuck-counter cells and 54 dbg_last_addr/dbg_val flops present; L2 data RAM slices resolve to SRAMHDE_PG_SVT_16384x36M16WM0 -> _sync_sram_2cycle (sources_1/new/rfhds_pg_svt_fpga_models.sv) -> RAMB36E2, i.e. the hand-written FPGA cache RAM models are what is on the board.

## Hardware result (haps-dev capture 20261013_172355, 10 boots, identical)
console per boot:
  QSPI CTRL=00000000 STATUS=00000000 before startup
  JEDEC ID=001660EF            -> bytes EF 60 16 = Winbond W25Q32FW (1.8 V, 32 Mbit). Flash answers; controller, divider, pads OK.
  SPI_STARTUP rc=0 CTRL=03A00101 STATUS=00000001  -> non-SST ("Micron") path: QIO=1, XiP=1, Mode_Code=0xA0, Cont_Rd=1, No_CMD=1
  flash[0x400000..0x40000C] = CCCCCCCC x4         -> XIP window returns a constant pattern, not FFFFFFFF: controller reads in QPI
                                                     (4 bits/clk) while the Winbond part is still in SPI mode (0x35 is not its
                                                     Enter-QPI command and QE was never set). Nibble 1100 = IO3,IO2 high (pull-ups), IO1,IO0 low.
  ***Flash Enabled...Booting***
  sync exception ESR_EL3=02000000 EC=0x00 ELR_EL3=00400000 FAR=0 -> fetch from 0x400000 SUCCEEDED (no external abort); 0xCCCCCCCC is an
                                                     UNDEFINED A64 encoding -> "unknown reason" exception. CG092 flash-cache + AHB->QSPI read path works.
logger (map 44): 639 lines, 0 dropped (stuck indicators fixed the saturation); QSPIapb @4.3 ms, FLASH @27.8 ms, VECTOR @37.7 ms,
  RDstuck=WRstuck=0, then spin at UartEndSimulation (ROM+0x78B0/0x78C0).
Conclusion: everything from CPU to flash die works on hardware. Blocker = SPI_STARTUP has only SST (0xBF) and Micron paths.
Next: Winbond path (QE via 0x31/0x01, Enter QPI 0x38, Set Read Parameters 0xC0 to match N_Dummy, AHB read opcode 0xEB with mode 0xA0
for continuous read) - ideally inside a UART-driven monitor ROM so the sequence can be tuned without 5 h rebuilds.
