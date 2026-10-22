# Build 47 (queued behind build 46, 2026-10-14) - tests from RAM over UART, no flash
RTL: megasoc_tech_wrapper.sv u_dram_error_slave now instantiates axi4_bram_slave (sources_1/new/axi4_bram_slave.sv,
  512 KB block RAM, one array per byte lane (Vivado Synth 8-4556 caps a single array at 1 Mbit), INCR/WRAP/FIXED, one outstanding R and W, window aliased) at the NIC-400 "DRAM"
  target 0x8000_0000 (page tables: Normal WB/WA/RA, executable, 1 GB block). Unit TB scratchpad/simbram/tb_bram.sv: 0 errors.
Everything else = build 46 (auto-reset hold-off, logger map 44, monitor ROM v3).
Software: lib/sw_lib/host/scat/dram.scat (new file) - single load region at 0x80000000 (RO+RW, ZI), stack/heap in SRAM
  as boot.s expects. src/hello_world_dram/ (scratch copy, APP_SCAT := dram) -> build/hello_world_dram/host0/hello_world_dram.bin
  (72904 B, entry D2800000). Flow on haps-dev: haps_qspi.py load hello_world_dram.bin 80000000 ; haps_qspi.py go 80000000.
Flash status: W25Q32FW answers ID/status reads (SR1=FF, SR2=00, SR3=60) but ignores array reads, SFDP, erase, program and
  status writes; unchanged after FPGA-board power cycles -> parked; needs a true system power-off or another flash part.
Elaboration attempt 1 (17:23) failed: Synth 8-4556 "size of variable mem is too large" (one 8 Mbit array). Fixed by one array per lane and 512 KB total; unit TB re-run 0 errors.

Result (2026-10-14 21:41): WNS +22.024 ns, WHS +0.010 ns, all constraints met, 0 critical warnings, 16 DRC (unchanged), latches 0. Block RAM tiles 615 (build 46: 487; +128 = 512 KB). Build time 4 h 08 min. Bitstream md5 ccf8b952ef621261ec9425c04e2d4cc2
