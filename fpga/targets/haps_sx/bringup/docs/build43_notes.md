# Build 43 (launched 2026-10-12) - post-banner hang diagnostic
Sources = build 42 (Build G merge + SRAM polarity fix) plus:
1. DIAGNOSTIC boot ROM: megasoc_tech/software/src/bootloader_nocache/bootloader.c (scratch copy, NOT committed):
   enable_caches()/enable_caches_el1() removed, printf("[diag: caches left off]\n") added after the banner.
   Built with armclang (COMPILE_GCC=0 AARCH64=1), image build/bootloader_nocache/host0/app_flash.v8-a.hex/SEC_ROM_BOOT_IMG,
   bootrom_gen.py -a 14 -> haps_top.srcs/sources_1/imports/verilog/bootrom.v. Original kept as bootrom.v.orig_20260812fw
   (regenerating the original hex reproduced the installed file byte-for-byte except the Date line).
   Same code layout as the original (main 0x8C00, vectors 0x800/0xA00, first stack push 0x801BF0) -> sticky flags still valid.
   enable_mmu only sets SCTLR_EL3.M (bit 0), so with this ROM the CPU runs MMU-on, I/D caches OFF.
   Expected main flow: UartStdOutInit -> banner -> diag print -> SL_QSPI->CLK_DIV=4 -> SPI_STARTUP -> "***Flash Enabled...Booting***" -> BLR 0x400000.
2. Logger taps (megasoc_tech_wrapper.sv / haps_top.sv), bus map:
   0 ARVALID_ever 1 RVALID_ever 2 ROM_rvalid_ever 3 SRAM_write_ever 4 SRAM_boot_write(0x..1BF0) 5 FLASH_ahb_access_ever
   6 UART0_apb_write_ever 7 uart0_tx_ever_low 8 POR_n 9 cpu_standbywfe 10 dbg_wr_outstanding 11 WFI 12 dbg_rd_outstanding
   13 dbg_vector_fetch_ever 14 dbg_qspi_apb_ever 15 nreset_soc 31:16 dbg_val
   dbg_val = every 50 ms (1e6 cycles @20 MHz) the LAST accepted CPU AXI address (AR or AW), {region[2:0], addr[14:2]}:
   0 ROM<0x8000, 1 ROM>=0x8000, 2 SRAM, 3 QSPI flash window, 4 QSPI regs, 5 peripherals, 7 >=0x8000_0000.
3. Parser ~/script/haps_parse_logger.py updated to this map (REGION dict); capture script console default /dev/ttyACM0.
   Both must be scp'd to haps-dev before the capture.
Reading the result:
 - "[diag: caches left off]" + "Flash Enabled" printed  -> enable_caches() was the hang; FLASH flag / dbg_val=FLASH+... show the jump to 0x400000.
 - banner only again, RDpend=1 -> CPU waiting on the bus; dbg_val says where. RDpend=WRpend=0, no traffic -> internal stall.
 - exception: VECTOR flag + dbg_val around ROM+0x0A00 / abort handler.
Revert for any non-diagnostic build: cp bootrom.v.orig_20260812fw bootrom.v
