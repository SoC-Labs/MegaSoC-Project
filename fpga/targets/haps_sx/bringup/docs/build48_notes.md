# Build 48 (launched 2026-10-15) - axi4_bram_slave first-beat address fix
Build 47 on hardware (15 Oct): RAM at 0x8000_0000 answers (w/r), the UART loader moves 72904 B with a matching
checksum, execution from RAM starts - and faults with an undefined instruction at 0x80000004. Byte-level probes
(8-byte loads at 0x80000000 / 0x80000010 / 0x80001008, a 32-bit write at +4) showed: byte pairs 6-7 of every word
and the 32-bit write at +4 landed in the NEXT word; lanes 0-5 were fine; the hello_world checksum matched only
because the shifted bytes stayed inside the image (zeros at both ends).
Root cause: axi4_bram_slave W_IDLE advanced waddr to the second beat on AW accept even when no W beat was consumed
in that cycle; a first beat arriving after the address was written at address+size. The loader's compiler merges
byte pairs into 16-bit stores (STRH), so bytes 6-7 (+2 -> next word) and 32-bit stores at +4 (+4 -> next word) moved.
Fix: waddr <= WVALID ? next_addr(...) : AWADDR. tb_bram.sv now covers W one/two/three cycles after AW (16-bit,
32-bit, 4-beat burst) - written lanes exact; the ERR lines in that run are the TB expecting 0 in never-written lanes (X).
Everything else = build 47 (monitor ROM v3, hold-off, 512 KB RAM, logger map 44).
Bench note: after a program crashes into the TEST_FAILED spin, the UART hold-off keeps the 10 s auto-reset suspended
for ~215 s from the last keystroke - press PB1 or wait before the next load.
Expected on hardware: `load hello_world_dram.bin 80000000` OK, `x 80000000 4` = D2800000 AA0003E1 AA0003E2 AA0003E3,
`go 80000000` -> "Hello SoCLabs MegaSoC".

Result (2026-10-15 04:25): WNS +19.447 ns, WHS +0.009 ns, all constraints met, 0 critical warnings, 16 DRC (unchanged), latches 0. Bitstream md5 21ecfb54bcc7517c40bbcc374c6033c1

## Hardware result (haps-dev, 2026-10-15)
load b8/hello: lanes exact (x 80000000 2 = D2800000 AA0003E1; w/r 80000104 = AABBCCDD, 80000100 untouched).
load hello_world_dram.bin 80000000 -> OK; x 80000000 4 = D2800000 AA0003E1 AA0003E2 AA0003E3;
go 80000000 -> "***Flash Enabled...Booting*** -> 80000000 / Hello SoCLabs MegaSoC / ** TEST PASSED **".
FIRST SoC Labs TEST TO RUN TO COMPLETION ON THE HAPS-SX VU19P. Path proven: boot ROM (monitor) -> UART0 load into
block RAM at 0x8000_0000 -> execution from RAM with MMU on, caches off -> printf over UART0 -> TEST_PASS.

15 Oct, final flash probes (build 48 monitor): FFh x2, SR1 2-byte read = FFFF, legacy 2-byte SR write -> no change; SR1 still FF; JEDEC OK. Firmware route closed; chip parked. Options: in-FPGA SST26VF064B emulator behind the QSPI controller, or a Micron N25Q part.

## Suite on build 48 (haps-dev, 15 Oct 13:07, haps_qspi.py suite, RAM images zero-padded over ZI)
PASS: hello_world, mem_tests, timer_tests, neon_tests, peripheral_test, gic_tests (timer IRQs through the GIC-400 to
      the A53 at EL3), low_power_tests (core LOGIC_RET_F1 + WFI wake by timer IRQ; ROM PPU OFF -> ON policy sequence)
FAIL: dap_tests - synchronous abort on the first read of 0x0130_0FD0: the system APB into the CoreSight debug block
      (APB-AP/APB-mux in megasoc_cpu_ss) returns PSLVERR; the test expects ID registers or a "skipped" result.
      Likely the debug domain is never powered up (no debugger; JTAG/SWD tied off). Needs a simulation check.
FAIL: sdio_tests - no card fitted; abort during the first multi-block write (after ~7 s of init time-outs).
FAIL: pl011_uart_tests - needs PL011 TX->RX loopback (testbench wires it; the board build does not).
HANG: uart_tests - needs UART0<->UART1 cross-wiring (testbench: tran P1[0]-P1[3], P1[1]-P1[2]); it also sets UART0
      BAUDDIV=10 (2 Mbaud), so its later console output is unreadable at 115200.
Finding (silicon-relevant): boot.s/stack_multi_cpu_init go straight to __rt_lib_init + main; __scatterload never runs,
      so ZI is never zeroed and RW is never copied. Simulation hides it (memory starts at 0, TB preloads RWZI).
      Also the stack is hard-coded at 0x802000 (literal in __stack_multi_cpu_init), inside default.scat's RWZI window.
