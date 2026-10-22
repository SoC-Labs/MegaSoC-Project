
## RTL simulation of the FPGA design (20 Oct 23:40, VCS, scratchpad/n25/sim)
files.f = Vivado compile order (769 files) + unisims IBUFDS/BUFG/BUFGCE + glbl; ROM = cache_steps program (bootloader scat, SIM_FAST_UART);
tb_haps.sv taps UART0 DATA writes. Runs 400 ms of SoC time in 45 s CPU. REPRODUCES THE HANG: console stops after
"step 2: SCTLR.I = 1 ..." - enabling the INSTRUCTION cache alone stops the core (ic iallu ok, MMU on). Monitored run
(run2.log, hang.vpd) traces CPU AXI and L1 I / L2 data RAM enables after the hang.

## 21 Oct 00:05 - simulation findings (N25)
* A/B: with Arm generic RAM models the sim passes I-cache enable, D-cache enable, SRAM/RAM tests (run_generic.log). With my models it hangs at SCTLR.I=1.
* Arm generic model initialises the I-TAG RAMs (u_itag_ram0/1) to ALL ONES (reset_high); all other RAMs start X. IFU: tag bits [30:29] == 11 means invalid (ca53ifu_cp15.v compare_ns). The core does not rewrite the tag RAM at reset / IC IALLU (ic iallu completes but the hang follows). FPGA BRAM powers up as ZEROS -> every I-cache line "valid, tag 0, NS=0" -> false hits for the ROM at address 0 as soon as the I-cache is enabled.
* Fix (models file): INIT_ONES parameter, RFHSD_PG_SVT_256x32M4WM0 (I-tag) initialised to ones via a synthesisable initial block; all other arrays explicitly zero (matches BRAM). Runs: z2 = zeros everywhere (expect hang like the FPGA), o2 = ones in I-tag (expect pass).
* z2 (all RAM arrays preset to ZERO = FPGA BRAM): HANGS at SCTLR.I=1 exactly like the board (run z2/run.log) -> the simulation now reproduces the hardware faithfully.
* d2 trace: after SCTLR.I=1 the IFU does linefills (AXI len=3 bursts from the ROM answered correctly), writes tag/data RAMs, keeps fetching - but the program never prints again: consistent with false hits on stale "valid, tag 0" lines.
* Differential unit tests (simram2/tb_l1.sv, tb_l2.sv): all 10 RFHSD models match ca53_generic_ram read data on random traffic (0 mismatches). o2 (I-tag preset ones, rest zeros): still HANGS. So the init of the I-tag alone is not it.
* Model change (build 54 candidate): Q now holds through write cycles (TSMC RF behaviour; Arm generic drives X there). Runs: h1 = my models + hold; g0 = generic with I-tag zeros; g1b = generic with an X-free RAM model (zeros/ones init, hold) - if g1b hangs, the generic "pass" was X-luck and the cause is elsewhere (clock-gate bypass model PREICG FPGA_BYPASS_GATING=1 is the next suspect).
* F2 trace (final config, data-cache test): NOT a hang - the 64 KB RAM test runs with the I-cache OFF, so every loop iteration refetches its code line from ROM (~1.25 us); D-cache line fills from the RAM slave (WRAP bursts) proceed normally, no stuck handshake. The earlier "stall" was the TB silence threshold. F3 runs the whole program to completion.
* SECOND ISSUE (01:15): with the D-cache on, the 64 KB RAM test freezes: after ~32 line fills from 0x80020000 the core goes completely silent on the bus (no AR/AW, all READY=1) - identical counters (ar=8934 r=23513 aw=1432) in the all-generic run and in the final config -> not the RAM models. Candidates: an unanswered read (NIC/DRAM slave) or an internal core stall. F4 tracks outstanding reads per ID at the CPU port and at the DRAM slave.

## 21 Oct 01:45 - FINAL CONFIGURATION PASSES THE WHOLE CACHE TEST IN SIMULATION (F5)
cache_steps: ic iallu, I-cache on + code, I off, D-cache on + SRAM 1 KB + RAM 64 KB (0 errors), D off, both on + RAM 64 KB, TEST PASSED at 73.5 ms SoC time.
The "second issue" was a simulation artefact: never-written words of the simulated RAM slave were X and poisoned the data cache; with the slave zero-initialised (like FPGA BRAM) everything completes. Build 54 = this configuration.
