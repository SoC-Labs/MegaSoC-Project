# Build 46 (launched 2026-10-14 ~11:25) - monitor v3 + auto-reset hold-off
RTL: haps_top.sv - falling edge on UART_RX suspends the 10 s auto-reset for 2^32 cycles (~215 s), renewed per byte
     (build 45 monitor sessions were cut at 10 s: 12 of 17 hello_world blocks programmed, then reset). Elab: 36 hold-off flops.
ROM v3 (software/src/bootloader_monitor, armclang, 47 KB): dsb sy after every control write (build 45 data-aborted on a window
     read overtaking the CTRL write, ELR 0x8660 EC 0x25 DFSC 0x10); wait_wip bounded + prints SR1 on timeout; write-order probe
     on sector 0x3FF000 (only if erased) -> g_wrmode; QE via 50h+31h only (no non-volatile SR writes); auto-jump only if
     word0 == D2800000; prints CG092 CCR/SR and 16 bytes via 03h at start; commands t (probe), o M (set mapping).
Unit simulation (scratchpad/simqspi/tb_qspi.sv, xsim; apb_qspi_regs + mux + controller + clock_div, CLK_DIV=4):
  * SPI-mode (QIO=0) write data reaches the flash nibble-reversed: pattern 01 02 04 08 10 20 40 80 55 AA 0F F0 12 34 56 78
    is seen as 08 04 02 01 80 40 20 10 AA 55 0F F0 84 C2 A6 E1. Mapping = map_wr mode 1. Opcode/address correct. QPI correct.
  * Reads: 16-byte READ_DATA little-endian per word; 1-byte read lands in bits 31:24; JEDEC 4-byte -> 001660EF as on hardware.
  * Enable bit is auto-cleared by the APB block on ACK (no transaction restart).
  * HAZARD: QSPI_SCLK = SCLK_e ? SCLK_i : CPOL with both flops switching on the same HCLK edge -> zero-width glitch at the start
    of every transaction in simulation (7 of 7). A runt pulse on the pad is possible in hardware; commands are decoded correctly
    on the board today. Bug-register candidate: register the SCLK gate on the opposite phase.
Hardware state (build 45 monitor, 14 Oct morning): JEDEC EF6016 OK; SR3 = 60 (Winbond default) so status reads are real;
  SR2 = 00; SR1 = FF (BUSY+WEL+all protection bits) persistently; array reads (03h), SFDP (5Ah) return FF; WREN+PP, sector erase
  and Write-SR1(00) have no effect. Consistent with the chip stuck BUSY (accepts only status reads). Window read of "BOOT 1 2 0"
  at first boot of build 45 did not set the FLASH_AHB flag - unexplained. Next: ID commands (90h/ABh/4Bh) then power-cycle the board.
