# MegaSoC HAPS bring-up: Jira updates and new tickets

Prepared 30 September 2026 from: the MBT board (MBT-23 to MBT-36), the HAPS bug register of 29 September, the work record rev4 (17 September) and its predecessors, and the merged tree (build 37, in progress on the Linux machine).

"Build 37" is the merged tree: downstream Build E sources plus the RT clock fix. It has not been run on hardware. No bitstream from any build after build 25 has been run on hardware.

---

## Part A. Updates to existing tickets

### MBT-23 Clock Gating (Done)
- Add **Component:** `pck600_clock_gate.v`, `gic400_inter_clkgate.v`, and `PREICG_X4B_A9TS_C31.sv` (the CA53 cell, bypassed first, build 28, revision 0.04). All three families are now bypassed; the ticket names only the first two.
- Add: "FPGA only. All three bypasses must be reverted for the ASIC flow. The original models are kept in the files."
- Add **Build:** downstream Build A; Linux build 36 and build 37.
- Add **Related:** register B2, B3; work record rev4 section 5.4.

### MBT-24 Reset (In Review)
- Add: "ROM and SRAM reset equations differ (SRAM includes `devretresetn_o`); not reconciled."
- Add **Verification:** static only. Not run on hardware.
- Add **Build:** Build A; build 37.
- Add **Related:** register C1, C2.

### MBT-25 CORTEX A53 Reset Ordering (In Review)
- Add: "`cpu_resetn_common` ANDs the power-on, warm and L2 resets. A warm reset therefore also asserts `nCPUPORESET` and `nPRESETDBG`, so debug state is lost on every warm reset. Acceptable for bring-up; record for the ASIC."
- Add: "A second implementation (`megasoc_cpu_rst_seq`, Linux build 36) existed and was dropped in the 30 September merge. Build 37 uses `cpu_resetn_common`."
- Add **Related:** register C3, C4.

### MBT-26 L2 Data RAM Model (Done)
- Add **Verification:** "Checked in simulation with an isolated read (Linux, 28 September). Not run on hardware."
- Add **Related:** register D1.

### MBT-27 ROM (Done)
- Add: "Not run on hardware. A comment dated August in `megasoc_tech_wrapper.sv` records a hardware observation that a constant `ext_gt_qreqn` stranded the controller in `ST_OPEN` after the first read. Reading the FSM, that should not happen with `cfg_gate_resp = 0`, but confirm on the first boot test of build 37."
- Consider status In Review until then.
- Add **Related:** register E10; MBT-35.

### MBT-28 QSPI (In Review)
- Add: "Behaviour change: divider value 0 now gives HCLK/2, not HCLK. Firmware that relied on div 0 will see half the SCLK rate."
- Add: "Merged into the Linux tree on 30 September (build 37). Before that the Linux tree still had the muxed clock and 186 latches."
- Add: "The three `set_max_delay -datapath_only` lines that this replaced had never been in force (rejected for lack of `-from`, Constraints 18-540)."
- Add **Related:** register B7, E12, G2, G6, G7.

### MBT-29 Peripheral Subsystem (Done)
- Add: "The default-slave fix landed in the same build: `PORT4_ENABLE(1)` and `defslv_hsel` qualified by `hsel`. Unmapped addresses in 0x4000_0000 to 0x5FFF_FFFF now return a bus error instead of OKAY with data 0. Firmware that touched an unmapped address will now fault."
- Add **Related:** register E5, E1, E2.

### MBT-30 DRAM_AXI HRDW (Done)
- Add: "This slave terminates the DRAM port because DRAM is not integrated on the HAPS board. The upstream simulation responder (MBT-17) is a different file."
- Add **Related:** register E4.

### MBT-31 EXP_M HRDW (Done)
- **Change status to In Progress.**
- Fix the reference: the write-side `BVALID` fix upstream is MBT-16, not MBT-21. MBT-21 is the read side.
- Add: "Checked the fork against upstream. The fixes from MBT-16 (outstanding-write counter), MBT-20 (`BID` echo) and MBT-21 (`RVALID`, `RID`) are all missing. With `AWREADY`, `WREADY`, `ARREADY` tied 1 and `BVALID`, `RVALID` tied 0, any access to the expansion window is accepted and never answered. Tying `BVALID` to 0 removed the protocol violation but left a hang. Resolution: port the three upstream fixes into `megasoc_system.sv`."
- Add **Related:** register E3; MBT-16, MBT-20, MBT-21.

### MBT-32 Debug Infrastructure (Done)
- Add: "Log format in build 37 is the per-signal format described here (ARVALID on ID 0x00, overflow on ID 0x01). A whole-bus format existed in Linux build 36 and was dropped in the merge."
- Add: "Still open: the clock-activity flag is always true now that gating is bypassed, so it measures nothing (register F4). `ncorereset_dbg` is a separate AND gate, not a tap on the reset net reaching the CPU (F5). Timestamps are captured at FIFO push, not at detection (F6)."
- Add: "The 100% ARVALID figure from builds 23 to 28 was measured with the earlier logger after the capture-process fix. The ID 0x00 move addresses a starvation risk that would have hidden a positive result, not a negative one, so the 100% figure stands, but it has not been re-measured on any build since 25."
- Add **Related:** register F1 to F7.

### MBT-33 Clock Topology (Done)
- Retitle to "Dead USE_BUFGCE defparams". The current title suggests a wider fix than was made.
- Add **Related:** register B1.

### MBT-34 ROM / SRAM Ports (In Progress)
- Add **Component:** `ROM_wrapper.v:138`; `SRAM/fpga/SRAM_wrapper.sv`; controller `sie300_axi5_sram_ctrl_1`.
- Add **How found:** synthesis warnings Synth 8-689.
- Add **Detail:** in the ROM wrapper only `memwen` is short (8 into 9); `memd` and `memq` are 65 bits with bit 64 tied 0. In the SRAM wrapper `memd`, `memq` and `memwen` are all one bit short, so the controller's bit-64 read input is undriven.
- Add **Resolution:** none yet. Widen the wrapper signals; tie or store bit 64.
- Add **Criticality:** Medium, pending a check of whether the controller uses bit 64 in this configuration.
- Add **Related:** register D2.

### MBT-35 SMC Q-channel (To Do)
- Add **Component:** `sie300_axi5_sram_ctrl_1_lpi_ctrl.sv:67,126` (Arm-licensed).
- Add **How found:** static review.
- Add **Resolution:** none. Licensed IP, so the proposal is a bound assertion that the state never equals `2'b10`, not an RTL edit.
- Add **Criticality:** Low on FPGA; reachable only through an upset.
- Add **Related:** register E11; the two Q-channel fixes in new tickets N6 and N7.

### MBT-36 CPU Subsystem (To Do)
- Retitle to "IRQ synchroniser is a single flop".
- Add **Component:** `megasoc_irq_sync.v`.
- Add **Root cause:** one flop stage on 240 interrupt lines; the GIC-400 requires inputs synchronous to its clock.
- Add **Resolution:** upstream made this two-stage under MBT-15. The fork did not pick it up. Port that change and add `ASYNC_REG`.
- Add **Criticality:** Medium. Not on the boot path.
- Add **Related:** register E8; MBT-15.

### All 14
- Add a **Build** line naming the build the fix is in.
- The nine Done tickets have no hardware confirmation. Either move to In Review or state "verified by tool reports only".

---

## Part B. New tickets

Same field order as the existing MBT tickets. "Fixed" means in build 37 unless stated.

### CPU boot

**N1. CPU never issued its first fetch: unconstrained Removal hazard on the execution clock enable**
* **Component:** `ca53governor_cpu_clk_reset.v` (`stop_clk_reg`, async PRE fed by `u_ca53_cell_sync0/r1_reg`); `haps_top.xdc`.
* **Problem:** `CPU_AXI.ARVALID` never asserted at the CPU port. Build 6 worked and build 13, nominally identical, did not.
* **How found:** Hardware captures with the debug UART logger over several builds; timing analysis of the path once the hold waiver was understood.
* **Root cause:** The Removal check on that path was waived by the blanket `set_false_path -hold` (N2), so no build had ever verified it. Placement landed on either side of the real margin from build to build.
* **Resolution:** A 60 x 60 SLICE pblock keeping the two cells together (`pblock_governor_clkgate_proximity`), builds 23 to 28. Since the clock-gate bypass (MBT-23) `stop_clk_reg` no longer exists, so the pblock now holds one cell and does nothing. Remove it (register G4).
* **Reproducibility:** Placement-dependent before the fix.
* **Criticality:** High. This was the boot blocker from December to September.
* **Status:** Resolved. 164/164 boots on builds 23 to 28. Not re-measured since build 25.
* **Related:** MGSOC-33; work record rev4 section 3; register G4.

**N2. Blanket hold waiver hid every hold and removal check**
* **Component:** `haps_top.xdc`.
* **Problem:** `set_false_path -hold -from/-to [get_clocks HAPS_CLK]` on the only clock waived all hold and removal analysis. 168,745 failing endpoints appeared when it was removed (build 26).
* **How found:** Independent constraints review, 8 September; confirmed by rebuild.
* **Root cause:** Waiver added in early bring-up as "standard for single-clock prototypes". In Vivado a hold-class exception also covers Removal.
* **Resolution:** Removed (build 26). Every "hold clean" result before 8 September measured nothing.
* **Reproducibility:** 100%.
* **Criticality:** High.
* **Status:** Resolved.
* **Related:** register G1; N1, N3.

**N3. CA53 synchroniser cells lacked ASYNC_REG**
* **Component:** `ca53_cell_sync.v` (36 instances); `haps_top.xdc`.
* **Problem:** Two-flop synchronisers with no `ASYNC_REG`; the worst path in the 168,745-endpoint picture was one of them.
* **How found:** Hold audit after N2.
* **Root cause:** Attribute absent from the licensed RTL.
* **Resolution:** `set_property ASYNC_REG TRUE` on `r0_reg` and `r1_reg` in the XDC (build 27). Together with MBT-23: 168,745 to 33,509 failing endpoints (build 28).
* **Reproducibility:** 100%.
* **Criticality:** Medium.
* **Status:** Resolved. Open point: the XDC filter matched 37 cells where about 72 are expected (register G5). Check post-synthesis names.
* **Related:** register G5; MBT-23.

**N4. ARVALID reliability under-measured by a broken capture process**
* **Component:** Host-side capture (`/dev/ttyUSB0`).
* **Problem:** Boot success read as 28/36 (78%). Two follow-up hypotheses (a second `ca53_cpu_reset.v` hazard; the SCU tag-invalidate handshake) were investigated against this figure.
* **How found:** Process list on the capture host.
* **Root cause:** Orphaned `cat /dev/ttyUSB0` readers from earlier sessions split the byte stream between them.
* **Resolution:** Kill stale readers before capture. Clean captures then measured 51/51 and 113/113.
* **Reproducibility:** Whenever a stale reader existed.
* **Criticality:** Medium. Misdirected several weeks of investigation.
* **Status:** Resolved (process). Add a check to the capture script.
* **Related:** rev4 section 3.3; MBT-32.

**N5. Real boot console (PMOD2) never observed**
* **Component:** UART0 path to PMOD3 IO[0]; bootloader.
* **Problem:** No firmware output has ever been captured on the console UART, on any build.
* **How found:** Every capture since July.
* **Root cause:** Unknown. Register item 3 shows the boot ROM touches no peripheral before UART init and the banner is due within about 350 us of reset, so a silent console means the CPU stopped early.
* **Resolution:** Register next steps 1 and 2: program the Build B or build 37 bitstream, capture both UARTs across several auto-reset cycles, and probe the SRAM bus (first write 0x0080_1ff0) to separate "never fetched" from "peripheral path dead".
* **Reproducibility:** 100%.
* **Criticality:** High. This is the current boot question.
* **Status:** Open.
* **Related:** rev4 section 4.3; MBT-32.

### Power and Q-channel

**N6. ROM Q-channel ports tied off, deadlocking the ROM power controller**
* **Component:** `megasoc_tech_wrapper.sv`, `ROM_wrapper.v`.
* **Problem:** `clk_qreqn` and `pwr_qreqn` tied to 1 with responses unconnected. The ROM PPU never completed its handshake; the CPU stalled on the first fetch.
* **How found:** Hardware capture (ILA), early bring-up.
* **Root cause:** Tie-offs in place of the PPU connection.
* **Resolution:** Q-channels connected to the ROM PPU, as for the SRAM.
* **Reproducibility:** 100%.
* **Criticality:** High.
* **Status:** Resolved (pre-review). Later shown not to be the ARVALID cause (N1).
* **Related:** MBT-27, MBT-35.

**N7. SRAM external gate override wired to the live power request**
* **Component:** `SRAM_wrapper.sv`.
* **Problem:** The low-power sequencer could park in `ST_START_GATE`, blocking all SRAM AXI traffic.
* **How found:** Hardware capture, early bring-up.
* **Root cause:** `ext_gt_qreqn` driven from the power request instead of held at 1.
* **Resolution:** Tied to 1.
* **Reproducibility:** 100% when the request toggled.
* **Criticality:** High.
* **Status:** Resolved (pre-review).
* **Related:** MBT-27, MBT-35.

### Bus and peripherals

**N8. Expansion window hangs: fork missing three upstream EXP_M fixes**
* **Component:** `megasoc_system.sv`, non-`INC_EXP` branch.
* **Problem:** Ready signals tied 1, valid signals tied 0. Any read or write to the window is accepted and never answered.
* **How found:** Comparing the fork with MBT-16, MBT-20, MBT-21.
* **Root cause:** Upstream fixes not ported to the HAPS fork.
* **Resolution:** Port the outstanding-request counters and ID echo.
* **Reproducibility:** 100% for any access to the window.
* **Criticality:** High if firmware touches the window; otherwise latent.
* **Status:** Open.
* **Related:** MBT-31 (reopened), MBT-16, MBT-20, MBT-21.

**N9. Unmapped peripheral addresses answered OKAY with data 0**
* **Component:** `megasoc_peripheral_subsystem.sv:316`, `megasoc_peripheral_addr_decode.v:28`.
* **Problem:** The AHB default slave was on a disabled mux port, and `defslv_hsel` was not qualified by `hsel`.
* **How found:** Static review.
* **Root cause:** `PORT4_ENABLE(0)`; missing `hsel` term.
* **Resolution:** `PORT4_ENABLE(1)`; `defslv_hsel = hsel & ~(...)`.
* **Reproducibility:** 100%.
* **Criticality:** Medium. Bad firmware pointers now fault instead of passing silently.
* **Status:** Resolved (Build A, build 37). Not run on hardware.
* **Related:** register E1, E2; MBT-29.

**N10. Undriven and unconnected ports in the peripheral and CPU subsystems**
* **Component:** `megasoc_peripheral_subsystem.sv:835` (`PRDATA_SPI[31:16]`); USRT instances (`INVBAUDDIV8_o` unconnected); `megasoc_cpu_ss.sv:42-43` (`RDMEMATTR`, `WRMEMATTR`); `rfhds_pg_svt_fpga_models.sv` (`CENY`, `WENY`, `AY`, `GWENY` tied 0, active-low).
* **Problem:** Four groups of ports left undriven or tied to the asserted level.
* **How found:** Synthesis warnings; static review.
* **Root cause:** Incomplete wrapper wiring.
* **Resolution:** Tie `PRDATA_SPI[31:16]` to 0; connect or tie the USRT output; drive or remove the memory attribute outputs; check whether any wrapper consumes the RAM shim outputs.
* **Reproducibility:** 100%.
* **Criticality:** Low to Medium.
* **Status:** Open.
* **Related:** register E6, E7, E9, D3.

### Clocking and constraints

**N11. RT clock 107 times too slow and unconstrained**
* **Component:** `haps_top.sv:130-135`; `megasoc_peripheral_subsystem.sv:639-805`; `haps_top.xdc`.
* **Problem:** `rt_clk = rtc_div[15]` gave 305 Hz where 32.768 kHz is intended; `CLK1HZ` ticked once per 107 s. Neither clock was declared, leaving 47 register pins outside analysis; the 32-bit RTC counter had no timing clock at all (TIMING-17).
* **How found:** Review; `report_methodology` on build 36.
* **Root cause:** Placeholder divider; counter bits used as clocks.
* **Resolution:** Divide-by-610 toggle register declared as `RT_CLK` (build 36, build 37). Still open: `rt_clk_div[14]` inside the peripheral subsystem is undeclared.
* **Reproducibility:** 100%.
* **Criticality:** Low. Not on the boot path.
* **Status:** Partly resolved.
* **Related:** register B4, B5, B6.

**N12. Broad hold failures from clock skew; floorplan not yet tried**
* **Component:** Implementation; `haps_top_floorplan_impl.xdc`.
* **Problem:** About 20,000 hold pins the router cannot fix, spread across NIC-400, the PPUs, SDIO and axi2axil. Build 37 predecessors: 22,000 to 27,000 failing endpoints, worst -3.9 ns (Linux) and -0.66 ns after the QSPI rewrite (downstream Build B).
* **How found:** Timing reports; `report_clock_utilization` (clock drives about 89,000 loads over 57 to 59 clock regions); TIMING-15 (265 large-skew paths).
* **Root cause:** A design using 6% of LUTs placed across SLR0 and SLR1; worst paths cross the SLR boundary.
* **Resolution:** Proposed pblock. The downstream file said `SLR1:SLR2` and "all four SLRs"; measured on this part the design sits in SLR0 and SLR1, so the range was corrected to `SLR0:SLR1`. Not enabled. `route.enableGlobalHoldIter` was tested and had no effect (register G8).
* **Reproducibility:** 100%.
* **Criticality:** High for a stable prototype.
* **Status:** Open.
* **Related:** register B9, G4, G8.

**N13. Constraints that silently did nothing**
* **Component:** `haps_top.xdc`; project flow.
* **Problem:** Three cases: (a) `set_max_delay -datapath_only` without `-from`, rejected on every build (Constraints 18-540), so the build 30/30b experiment compared `set_false_path` against no constraint; (b) a Tcl `proc` in the XDC, rejected (Designutils 20-1307), dropping every constraint that used it (Linux build 36 first attempt); (c) `CLOCK_DEDICATED_ROUTE FALSE` on `u_ibufds_clk/O` finds no object during synthesis.
* **How found:** Synthesis logs read after the fact.
* **Root cause:** Critical warnings not checked between synthesis and implementation.
* **Resolution:** (a) removed with the QSPI rewrite; (b) guard moved to the build script, which stops if an expected clock is missing or the log shows 18-540, 20-1307 or 12-4739; (c) open, retest without it. Also open: six `get_pins -hier -filter` queries flagged XDCB-5 (slow, not wrong).
* **Reproducibility:** 100%.
* **Criticality:** Medium.
* **Status:** Partly resolved.
* **Related:** register G2, G3; MBT-28.

**N14. Simulation and FPGA use different clock topologies**
* **Component:** `megasoc_clock_ctrl.v` (behavioural flist) against the FPGA top.
* **Problem:** Simulation drives three unrelated clocks (1 GHz, 500 MHz, 250 MHz); the FPGA ties CPU, SYS and FLASH clocks to one 20 MHz net.
* **How found:** Diff of the simulation path against the FPGA path, July.
* **Root cause:** `top_BEHAV.flist` selects the free-running multi-clock model.
* **Resolution:** None in RTL. Record which flist a simulation used before treating it as representative.
* **Reproducibility:** 100%.
* **Criticality:** Medium.
* **Status:** Documented.
* **Related:** work record rev3 section 6.

**N15. XDC clock period did not match the board clock**
* **Component:** `haps_top.xdc`; ConfPro configuration.
* **Problem:** The design was analysed at a different frequency from the one ConfPro programmed.
* **How found:** Board bring-up, before July.
* **Root cause:** Constraint written before the board clock was settled.
* **Resolution:** Period set to match (now 50 ns, 20 MHz).
* **Reproducibility:** 100%.
* **Criticality:** Medium.
* **Status:** Resolved (pre-review).
* **Related:** rev3 section 6.4.

### Reset

**N16. Top-level reset structure**
* **Component:** `haps_top.sv:88-125`.
* **Problem:** `auto_reset_n`, a 28-bit comparator output, is mixed into an async-reset branch without being in the sensitivity list (simulation/synthesis mismatch). `HAPS_RESET_N` is used directly as an async reset with no debounce and asynchronous release.
* **How found:** Static review.
* **Root cause:** Bring-up convenience logic.
* **Resolution:** Register `auto_reset_n` and apply it synchronously; synchronise the board reset release.
* **Reproducibility:** Latent.
* **Criticality:** Low.
* **Status:** Open.
* **Related:** register C5, C6.

### Firmware and boot image

**N17. Boot ROM image stale, then regenerated**
* **Component:** `bootrom.v`; `bootrom_gen.py`.
* **Problem:** The embedded ROM lagged a firmware fix by one instruction word; earlier, a UART fix had never been compiled into what the FPGA ran.
* **How found:** Regenerating from the current `bootloader.hex` and comparing.
* **Root cause:** ROM image not regenerated after firmware changes.
* **Resolution:** Regenerated (build 24). Make regeneration part of the build.
* **Reproducibility:** 100%.
* **Criticality:** Medium.
* **Status:** Resolved.
* **Related:** rev4 section 4.

**N18. Console output routed to a debug-only peripheral**
* **Component:** `uart_stdout.c`.
* **Problem:** Firmware printed to USRT0, not UART0. No output could reach the board pins.
* **How found:** Bring-up review.
* **Root cause:** Wrong peripheral selected in the retarget.
* **Resolution:** Retargeted to UART0.
* **Reproducibility:** 100%.
* **Criticality:** High for observability.
* **Status:** Resolved (pre-review).
* **Related:** N5.

**N19. Bootrom writes UART before configuring the GPIO pin mux**
* **Component:** Boot ROM firmware.
* **Problem:** Early output is lost on the real chip, where the pin mux must be set first.
* **How found:** Firmware review during rev4.
* **Root cause:** Initialisation order.
* **Resolution:** Not confirmed fixed.
* **Reproducibility:** 100% on silicon; hidden on FPGA, where the pins are direct.
* **Criticality:** Medium. Latent silicon bug; relevant to tape-out.
* **Status:** Open (unverified).
* **Related:** rev4 section 2.4, item 7.

### Debug and tooling

**N20. ILA readback unreliable at 20 MHz; ILA removed**
* **Component:** Debug hub; `ROM_wrapper.v` (`ila_1`, removed).
* **Problem:** JTAG readback gave frozen probes and simultaneous glitches on unrelated signals (Xicom 50-38, 50-41). A leftover `ila_1` instance later remained as a black box.
* **How found:** Captures compared against UART loopback.
* **Root cause:** Debug hub behaviour at this clock; instance left after the ILA was removed.
* **Resolution:** UART logger is the only debug channel; instance removed (Build A, build 36).
* **Reproducibility:** 100%.
* **Criticality:** Low.
* **Status:** Resolved.
* **Related:** register B8; MBT-32.

**N21. Testbench cannot fail**
* **Component:** `tb_haps_top.sv`; `haps_top.xpr` (sim_1).
* **Problem:** No `$fatal` or `$error`; a dead CPU and a clean boot both exit 0. The peripheral-write monitor watches an SRAM address. `DEBUG_UART_TX` is unconnected. `sim_1` lacks the `FPGA_BUILD` define, so simulation elaborates different UART wiring from synthesis. No flash model.
* **How found:** Static review.
* **Root cause:** Bench written for waveform inspection, not regression.
* **Resolution:** Accumulate errors and `$fatal`; correct the monitor address; connect the debug UART; add the define; add a flash model or stub.
* **Reproducibility:** 100%.
* **Criticality:** Medium. MBT-28 notes the QSPI rewrite is unsimulated for this reason.
* **Status:** Open.
* **Related:** register H1 to H6.

**N22. Project file not portable**
* **Component:** `haps_top.xpr`.
* **Problem:** Five files had duplicate entries, one portable and one pointing at a machine-specific path, with the portable copy disabled. Opening on a second machine failed with "could not find file" and "cannot open include file Axi.v".
* **How found:** Moving the project to a second PC.
* **Root cause:** Import duplication (136 files carry an `AutoDisabled` duplicate; 5 had no enabled copy).
* **Resolution:** Duplicates removed; surviving entries enabled.
* **Reproducibility:** 100% on another machine.
* **Criticality:** Low.
* **Status:** Resolved.
* **Related:** rev4 section 8; register A1.

**N23. Vivado 2026.1 port**
* **Component:** `haps_top.xpr`; `imports/sdspi/rtl/*.v`; `build_haps_top.tcl`.
* **Problem:** Include paths pointed at a file; 17 SD-card files set `` `default_nettype none `` and never reset it, breaking the SIE-300 files compiled after them; a 2024.1 incremental checkpoint was reused; a run property with a space and a value starting with "-" aborted the script.
* **How found:** Porting to Windows, 17 to 21 September.
* **Root cause:** Environment differences.
* **Resolution:** All fixed in the downstream tree; the `default_nettype` fix is in build 37.
* **Reproducibility:** 100% under 2026.1.
* **Criticality:** Low.
* **Status:** Resolved.
* **Related:** register A1, A2, A3, A5. A4 (licence lost on VPN drop) is a process note.

**N24. Two build trees diverged and were merged**
* **Component:** Linux project (Vivado 2024.1) and Windows project (Vivado 2026.1).
* **Problem:** From 17 to 29 September the two trees fixed the same bugs differently (CPU reset, logger) and each had fixes the other lacked (QSPI rewrite downstream; RT clock on Linux).
* **How found:** File-by-file diff, 30 September.
* **Root cause:** Parallel work without a shared repository.
* **Resolution:** Downstream taken as base; RT clock and build-script guard carried over; floorplan range corrected. Build 37. Build 36 sources archived.
* **Reproducibility:** n/a.
* **Criticality:** Process.
* **Status:** Resolved. Decide which machine builds from here.
* **Related:** all of the above.


---

## Added 9 October 2026 (from the build 39–41 hardware captures)

**N24. FPGA SRAM wrapper drives active-low controller enables into an active-high RAM: every SRAM write dropped, every read returns zero**
* **Component:** `SRAM/fpga/SRAM_wrapper.sv` (dated 10 Jul 2026); `cmsdk_fpga_sram.v`; `sie300_axi5_sram_ctrl_sys`.
* **Problem:** The CPU boots, fetches from ROM, runs `enable_mmu`, sets up the stack and enters `__rt_lib_init`, whose first stack-based `RET` pops a zero link register and jumps to the reset vector. The boot restarts every ~300 µs, forever, with no exception and no reset. The console is never reached.
* **How found:** Whole-bus debug logger with sticky milestone flags and a sampled fetch-address field (builds 39–41): first SRAM write at 0x801BF0 confirmed; no vector-table fetch ever; no warm reset; fetch samples covering the reset path repeatedly. Then static read of the wrapper.
* **Root cause:** `sie300` drives `memcen` and `memwen` active low (`memcen_arb = ~access`, `memwen_arb = ~wstrb`); `cmsdk_fpga_sram` has active-high `CS` and `WREN`; the wrapper connects them without inversion. During every access `CS = 0`, so writes are dropped and `RDATA` is forced to 0. `ROM_wrapper.v` inverts (`.EN(~memcen)`), which is why ROM reads work; the behavioural `SRAM.v` is active low, which is why simulation passes. The wrapper also indexed the RAM by `memaddr[15:2]`, aliasing every 64 KB.
* **Resolution:** `.CS(~memcen)`, `.WREN(~memwen[3:0])`, `.WREN(~memwen[7:4])`, `.ADDR(memaddr[16:3])`. Checked in simulation with SMC-style control polarity (write, byte-strobed write, read-back, no aliasing). Build 42.
* **Reproducibility:** 100%, every boot.
* **Criticality:** High. This is the boot blocker that remained after the first-fetch fix (N1).
* **Status:** Fix built; hardware confirmation pending.
* **Related:** N1, N5, MBT-34 (same wrapper, width mismatch), MBT-26 (same class: FPGA memory model vs controller contract).

---

## Added 14 October 2026 (builds 42–47, hardware 10–14 October)

### Status changes to the 14 existing tickets

| Ticket | Was | Proposed | Why |
|---|---|---|---|
| MBT-23 Clock Gating | Done | Done, add "verified on hardware" | Boots 42–45 run through ROM, SRAM, UART and QSPI with all three gate families bypassed. |
| MBT-24 Reset | In Review | Done | Logger shows an identical reset release every boot (POR, L2, ROM released at 2–3 µs, first fetch at 107 µs) across >60 boots of builds 42–46. Note: build 46 gates the 10 s auto-reset with UART activity (FPGA-only test feature, N31). |
| MBT-25 CA53 Reset Ordering | In Review | Done | Same evidence as MBT-24. Keep the ASIC note that a warm reset also asserts the power-on and debug resets. |
| MBT-26 L2 Data RAM Model | Done | **Reopen → In Progress** | `enable_caches()` stops the boot on hardware (N25). The FPGA cache RAM models, including the two-cycle L2 data model this ticket changed, are the prime suspect. |
| MBT-27 ROM | Done | Done, add "verified on hardware" | ROM returns data on every boot; no `ST_OPEN` strand seen. |
| MBT-28 QSPI | In Review | In Review, add three sub-findings | Controller proven end to end (JEDEC EF 60 16, 90h/ABh/4Bh IDs, SPI-mode XIP reads). Found by simulation: N27 (SPI-mode write data nibble-reversed), N28 (SCLK glitch), N29 (window error while XIP off). |
| MBT-29 Peripheral Subsystem | Done | Done, add "verified on hardware" | UART0 TX and RX both work on the board (console and monitor). |
| MBT-30 DRAM_AXI HRDW | Done | Done, add note | Replaced in build 47 by a 512 KB block-RAM slave so tests can run from 0x8000_0000 (N34). Error slave kept as fallback. |
| MBT-31 EXP_M HRDW | In Progress | Done (tool-verified) | The MBT-16/20/21 fixes were ported in the 9 October merge. Not exercised on hardware (boot does not touch the window). |
| MBT-32 Debug Infrastructure | Done | Done, update description | Logger is now whole-bus with sticky milestones, a 50 ms sampled last-address field and >1.6 ms stuck indicators. It found N24 and N25. |
| MBT-33 Clock Topology | Done | Done, retitle as before | No change. |
| MBT-34 ROM / SRAM Ports | In Progress | Done | Widths fixed in the merge, polarity fixed (N24); SRAM proven on hardware since build 42 (stack push and pop, banner). |
| MBT-35 SMC Q-channel | To Do | To Do, Low | No SRAM Q-channel misbehaviour in any boot; assertion proposal stands. |
| MBT-36 CPU Subsystem (IRQ sync) | To Do | Done (tool-verified) | Two-stage synchroniser with ASYNC_REG ported in the merge. Interrupts not exercised yet. |

N24 (SRAM wrapper polarity): status **Verified on hardware** — build 42 printed the banner on 10 October; every boot since. This also closes N5 (console never observed).

### New tickets

**N25. `enable_caches()` stops the boot on the FPGA**
* **Component:** `cpu_asm_codes.c enable_caches()` (IC IALLU + SCTLR_EL3.C/I); FPGA cache RAM models `sources_1/new/rfhds_pg_svt_fpga_models.sv`; `ca53_scu_rams` built with L2_OUTPUT_LATENCY = 0.
* **Problem:** After the banner no AXI transaction, no exception, no WFI for the rest of the 10 s window (build 42). With the two cache-enable calls removed (build 43) the same ROM runs on to the QSPI set-up and the flash jump.
* **How found:** Whole-bus logger (no reads after 50 ms, VECTOR 0, WFI 0) plus A/B ROM swap.
* **Root cause:** Open. First use of L1/L2 cache RAMs on hardware. Synthesis uses the TSMC-named wrappers over the hand-written FPGA macro models; the L2 data model's two-cycle pipeline was already patched once (21 September).
* **Resolution:** None yet. FPGA-configuration RTL simulation of the boot with caches on, first with the FPGA models, then with Arm's generic RAM wrappers.
* **Criticality:** High for FPGA. Not an ASIC issue if it is the models.
* **Related:** MBT-26, N24.

**N26. `SPI_STARTUP()` has no branch for the on-board Winbond part and jumps regardless of its own result**
* **Component:** `qspi_flash.c SPI_STARTUP`, `bootloader.c main`.
* **Problem:** The HAPS-SX flash is a Winbond W25Q32FW (JEDEC EF 60 16). The driver handles SST (0xBF) or assumes Micron (0x35 enter QPI, 0x81 volatile configuration). On the Winbond part the controller ends up in QPI while the chip stays in SPI, every XIP read returns 0xCCCCCCCC, and `main` prints "Flash Enabled" and jumps anyway. The jump fetches 0xCCCCCCCC and takes an undefined-instruction exception (ESR EC 0x00, ELR 0x400000, build 44). `SPI_STARTUP` also returns 1 (no flash) without disabling the jump.
* **How found:** Build 44 diagnostic ROM printing the ID, controller registers, four window words and the EL3 syndrome.
* **Resolution:** Branch on manufacturer byte 0xEF: QE via 50h/31h, 38h enter QPI, C0h dummy clocks matching the controller, EBh with mode 0xA0 for continuous read; check the return value before jumping. Not yet validated because of N30.
* **Criticality:** Medium (blocks flash boot on this board; ASIC boards use a different part).
* **Related:** MBT-28, N17, N30.

**N27. QSPI controller sends SPI-mode write data with the nibbles bit-reversed**
* **Component:** `qspi_controller.sv`, DATA_O state, QIO = 0 branch; `apb_qspi_regs.v` WRITE_DATA nibble swap.
* **Problem:** In 1-bit mode the controller shifts write data out LSB-first within each nibble, so a byte X reaches the flash as {rev4(X[7:4]), rev4(X[3:0])}. Opcode, address and all reads are correct; QPI writes are correct.
* **How found:** Unit simulation of regs + mux + controller + divider (xsim): pattern 01 02 04 08 10 20 40 80 55 AA 0F F0 12 34 56 78 arrives as 08 04 02 01 80 40 20 10 AA 55 0F F0 84 C2 A6 E1.
* **Root cause:** `QSPI_IO_o_reg[0] <= QSPI_WDATA_reg[0]` with a right shift, after the APB block has already swapped nibbles for the QPI path.
* **Resolution:** Shift MSB-first in SPI mode (or feed the SPI path from the un-swapped register). Until then firmware must pre-swap (the monitor ROM does).
* **Criticality:** Medium. Latent in production firmware (SST and Micron paths only write in QPI), but any status-register or page-program write in SPI mode is corrupted. Shared with the ASIC RTL.
* **Related:** MBT-28.

**N28. QSPI SCLK output can glitch at the start of every transaction**
* **Component:** `qspi_controller.sv`: `assign QSPI_SCLK = QSPI_SCLK_e ? QSPI_SCLK_i : CPOL`.
* **Problem:** `QSPI_SCLK_e` and `QSPI_SCLK_i` are flops that switch on the same HCLK edge; the mux output shows a zero-width pulse in simulation on every transaction (7 of 7). On silicon this is a runt pulse whose width is the skew between the two paths.
* **How found:** Same unit simulation.
* **Resolution:** Gate SCLK with an enable registered on the opposite SCLK phase, or generate SCLK from a single flop.
* **Criticality:** Low on FPGA (commands decode correctly on the board); review for the ASIC.
* **Related:** MBT-28.

**N29. Any access to the flash window while XIP is off is a bus error, and the boot ROM reports every synchronous exception the same way**
* **Component:** `ahb_qspi_interface.sv` (ERR state when `~XIP_ACTIVE`); `system.c abort_handler`.
* **Problem:** The AHB slave returns HRESP ERROR when XIP is inactive, which becomes a synchronous external abort. The default handler prints "Unexpected abort exception." for every synchronous exception, so an undefined instruction, a data abort and an instruction abort are indistinguishable on the console.
* **Resolution:** Keep the error response (correct) but document it; make the handler print ESR_EL3, ELR_EL3 and FAR_EL3 (done in the diagnostic ROMs, propose for the bootloader).
* **Criticality:** Low.
* **Related:** MBT-28, N26.

**N30. On-board W25Q32FW flash answers identification and status reads but refuses everything else**
* **Component:** HAPS-SX VU19P on-board SPI flash (bank 21).
* **Problem:** JEDEC, 90h, ABh and unique-ID reads are correct; SR3 reads the factory default (0x60); SR2 reads 0x00; SR1 reads 0xFF on every read. Array reads (03h, 0Bh XIP), SFDP (5Ah), sector erase, page program, status-register writes, suspend (75h) and software reset (66h/99h) have no visible effect. Unchanged after several FPGA-board power cycles through ConfPro.
* **How found:** Build 45 monitor ROM, raw command sessions from haps-dev on 14 October.
* **Root cause:** Chip-side: a status register locked at 0xFF (all block-protect bits set) or a faulty die. The controller is cleared by N27's unit simulation and by the ID reads.
* **Resolution:** None from software. Try a full system power-off on site; otherwise fit a different flash (a Micron-based Pmod would match the unmodified driver). Work continues without the flash (N34).
* **Criticality:** Blocker for flash boot on this board only.
* **Update 15 October:** FFh exit-continuous-read (twice), a two-byte SR1 read (FFFF, a constant register image) and the legacy two-byte status write (01h, SR1+SR2 = 00 00) also had no effect; JEDEC still EF 60 16 afterwards. Every command class in the datasheet has now been tried from the board; the firmware route is closed for this die. Decision: tests run from UART-loaded RAM (N34); for the XIP path either an in-FPGA SST26VF064B-compatible flash emulator behind the real controller, or a physical Micron N25Q part (supported by the ROM as it is).
* **Related:** N26.

**N31. Periodic 10 s auto-reset makes interactive sessions impossible**
* **Component:** `haps_top.sv` reset shaping (AUTO_RST_PERIOD).
* **Problem:** The unconditional 10 s reset (added for unattended logging) cut every monitor session: a 68 KB flash programming run was reset after 12 of 17 blocks.
* **Resolution:** Build 46: any falling edge on UART_RX suspends the auto-reset for 2^32 cycles (~215 s), renewed per byte; PB1 unchanged. FPGA-only.
* **Criticality:** Low.

**N32. Control-register writes are not ordered against the first flash-window load**
* **Component:** `bootloader_monitor` v2 (build 45); same pattern exists in `bootloader.c` (`SPI_STARTUP` then jump).
* **Problem:** A load from the flash window issued right after the CTRL/XIP and cache-control writes reached the AHB slave before XIP was active (different Device regions, no barrier) and took a synchronous external abort (ESR 0x96000210, ELR in `auto_start`). The production bootloader only avoids this because the UART print between set-up and jump takes milliseconds.
* **Resolution:** `dsb sy` after every QSPI/CG092 control write (build 46 ROM v3); add the same to `bootloader.c` before the jump.
* **Criticality:** Medium (firmware).
* **Related:** N26, N29.

**N33. First flash-window reads of build 45 did not set the FLASH_AHB access flag**
* **Component:** `megasoc_tech_wrapper.sv flash_ahb_access_ever_dbg`; CG092 flash cache path.
* **Problem:** The first boot of build 45 read "BOOT", 1, 2, 0 from 0x400000 without the sticky FLASH_AHB flag rising; the flag rose only on the later (aborting) access. After the erase session the window read all ones. Unexplained: either the first reads were served without an AHB transfer (cache state?) or the tap point is not where it is believed to be.
* **Resolution:** Investigate with the monitor (`x 400000` while watching the logger) once the flash is usable, or in simulation.
* **Criticality:** Low; affects debug instrumentation only.

**N34 (task). UART-loaded test execution from RAM**
* **Component:** `axi4_bram_slave.sv` (new, 512 KB at the DRAM target 0x8000_0000, unit-tested), monitor ROM `m`/`g` commands, host tool `haps_qspi.py`, scatter `dram.scat`, `src/hello_world_dram`.
* **Purpose:** Run SoC Labs tests on the board without the flash and without a bitstream per test: `load <bin> 80000000`, `go 80000000`. Build 47.
* **Status:** Done, verified on hardware 15 October (build 48): hello_world loaded over UART0 and ran to "** TEST PASSED **". Build 47 exposed a first-write-beat address bug in the new slave (data arriving after the address was stored at address+size), fixed in build 48.
* **Related:** N30, MBT-30, Daniel's note on loading via the debug port.

## Added 15 October 2026 (builds 48-49, first test suite on hardware)

Suite on build 48 (tests loaded over UART into RAM at 0x8000_0000): PASS hello_world, mem_tests, timer_tests, neon_tests,
peripheral_test, gic_tests, low_power_tests. These close the "no hardware evidence" notes on MBT-29 (peripherals),
MBT-36 (interrupts reach the core through the GIC; synchroniser exercised) and the Q-channel/PPU items (N6, N7):
core retention with wake-up by timer interrupt, and the ROM power domain cycled OFF and ON through its PPU.

**N35. Start-up code never runs scatter-loading: uninitialised globals are not zeroed and initialised data is not copied on silicon**
* **Component:** `lib/sw_lib/apps/src/boot.s` (B __stack_multi_cpu_init), `stack_multi_cpu_init.s` (main_entry: BL __rt_lib_init; BL main); `scat/default.scat`.
* **Problem:** `__main`/`__scatterload` is never called. ZI (e.g. `int idx = 0;`) keeps whatever is in RAM; RW in its own SRAM load region is never copied. Simulation hides both (memory starts at 0, the testbench preloads RWZI from app_ram.hex). The stack is hard-coded at 0x802000 inside default.scat's RWZI window.
* **How found:** reading the disassembly while preparing tests to run from RAM on the FPGA; consecutive tests in the same RAM would inherit each other's bytes.
* **Resolution:** call `__main` (or zero ZI and copy RW in boot.s), and give RW a load address in the flash region. FPGA workaround: images padded with zeros over ZI; SRAM preload of RWZI over UART.
* **Concrete case:** `qspi_flash.c` `uint8_t SET_QIO_MODE_CMD = 0x38;` links to 0x00804004 (bootloader RWZI in SRAM). The ROM image never contains the 0x38, so on silicon the SST branch of `SPI_STARTUP()` sends whatever byte SRAM powers up with as its enter-QPI opcode. The Micron branch assigns 0x35 first and is unaffected.
* **Criticality:** High for silicon bring-up (silent wrong initial values; breaks the SST flash boot), none in simulation.

**N36. System access to the CoreSight debug block at 0x0130_0000 returns a bus error on the FPGA**
* **Component:** debug APB in `megasoc_cpu_ss.sv` (APB-AP / APB-mux in front of the A53 debug port); `dap_tests`.
* **Problem:** the first read of 0x0130_0FD0 takes a synchronous external abort; the test expects ID registers or a "skipped" result.
* **Root cause:** open; likely the debug power domain is never powered up (no debugger, JTAG/SWD tied off on the HAPS build).
* **Resolution:** check in simulation whether the APB-mux requires CDBGPWRUPACK/CSYSPWRUPACK; make the test tolerate the error.
* **Criticality:** Low.

**N37 (task). Loopback wiring for the UART tests on the FPGA**
* `pl011_uart_tests` fails and `uart_tests` hangs on the board because the testbench supplies the loopbacks (PL011 TX->RX; UART0<->UART1 through P1[0]-P1[3], P1[1]-P1[2]). Add the same wiring in haps_top for test builds. `uart_tests` also switches UART0 to 2 Mbaud, so its later console output is unreadable at 115200.

`sdio_tests` fails with no card fitted (abort during the first write after the initialisation time-outs); not a ticket until a card or model is present.

**N34 update:** build 49 adds an in-FPGA SST26VF064B-compatible flash emulator behind the real QSPI controller, so the XIP path and the unmodified `SPI_STARTUP` can be tested without the dead on-board chip (N30). Simulated with the real controller stack: 0 errors. Built 15 October (WNS +29.3 ns).

**Flash path result, build 49 (15 October):** hello_world, timer_tests, peripheral_test, gic_tests and low_power_tests run to "TEST PASSED" from the XIP window, booted by the unmodified `SPI_STARTUP` (SST branch) against the in-FPGA emulator. mem_tests and neon_tests hung because their flash images were stale builds with another UART clock (rebuilt; re-run pending).

**N38. `SPI_WAIT_BUSY()` can hang after a short QSPI command**
* **Component:** `qspi_flash.c` `SPI_WAIT_BUSY` (`while(busy != 1); while(busy != 0);`).
* **Problem:** the first loop waits for BUSY to rise. A 2-clock QPI command (e.g. FFh Reset-QIO) can complete before the first STATUS read, and the loop never exits. Seen on the board in a RAM-resident probe on 15 October.
* **Resolution:** wait only for not-busy after a fixed short delay, or latch a "done" flag in the controller (`qspi_finished` already exists in `apb_qspi_regs`).
* **Criticality:** Low today (production commands are 8-clock SPI or long reads); latent for any short command.

**Flash path result, re-run 15 October 18:40:** with the rebuilt images, mem_tests and neon_tests also pass from flash. All seven tests that pass from RAM (hello_world, mem_tests, timer_tests, neon_tests, peripheral_test, gic_tests, low_power_tests) pass from the XIP window through the unmodified `SPI_STARTUP`. A RAM-resident probe read the whole image back through the window with 8-, 32-, 64- and 128-bit loads (including line-crossing ones) with 0 errors. N34 and the emulator part of the flash work are Done; N30 (dead on-board chip) and N26 (Winbond branch) remain open for a real part.

## Added 19 October 2026 (corrections and a new controller bug)

**N30 revised: the on-board W25Q32FW is probably healthy.** The "SR1 reads FF" evidence came from opcode 09h, a typo in the test commands (05h is Read Status Register-1); SR1 has not been read correctly yet. Sector erase worked (a header at offset 0 was erased). Page program and the QE status write had no effect because of N39 and N27 below. Status: re-test on build 50. Criticality lowered from Highest to Medium.

**N39. QSPI controller sends one extra clock at the end of every 1-bit (SPI-mode) write**
* **Component:** `qspi_controller.sv` DATA_O next-state logic, SPI branch: `if(data_counter == 3'h7) next_state = IDLE;` (DATA_I uses `3'h6`). Present in the upstream SoC Labs RTL (`megasoc_tech/logical/sl_ahb_qspi`), so shared with the ASIC.
* **Problem:** every 1-bit write sends 8*(N+1)+1 clocks; nCS rises off a byte boundary and SPI NOR flashes discard page programs and status-register writes. Erase and all reads are unaffected; 4-bit writes are exact.
* **How found:** the QE write and page programs had no effect on the board while erase worked; unit simulation counting real SCLK pulses per transaction (31h + 1 byte: 17 instead of 16; 01h + 2 bytes: 25 instead of 24; page program of 16 bytes: 161 instead of 160), reproduced on the original SCLK-clocked RTL.
* **Resolution:** end at `3'h6` in 1-bit mode (project copy, build 50); unit simulation exact. To be reported upstream together with N27.
* **Why it never showed:** `SPI_STARTUP` writes only in 4-bit mode (SST and Micron branches). A Winbond part needs a 1-bit status write (QE) before it can enter QPI.
* **Criticality:** High for any flash that needs 1-bit writes (Winbond QE, programming in 1-bit mode); none for the current SST/Micron boot path.

**N27 update:** confirmed on the original RTL as well (QE byte 0x02 arrives as 0x04). Fixed in the project copy for build 50 (MSB first within each nibble); upstream report pending.

**N28 update:** the SCLK start glitch was introduced by the FPGA reclocking (Build B); the original SCLK-clocked controller does not glitch. Not an ASIC issue.

**Build 50 (19 October, building):** real on-board flash again (USE_FLASH_EMU = 0), controller fixes N39 + N27, monitor ROM v5 with the Winbond start-up drafted for Daniel (`n` command; auto-boot from the real flash when an image is present), ROM globals initialised explicitly (N35), no automatic flash writes at boot.

**19 October, afternoon - the on-board W25Q32FW works with the fixed controller (build 50, register-level sessions).** First page program accepted (16-byte pattern read back exactly). QPI: 38h accepted, JEDEC in 4-bit = EF 60 16 (all four data lines work), C0h, 0Bh and EBh reads exact, XIP window in continuous/No_CMD mode returns flash data. N30 can be closed (chip healthy; root cause was N39/N27). N26 (Winbond branch) validated step by step on hardware with two corrections for the draft: controller N_Dummy for EBh is 6 with C0h P=11 (the mode byte counts), and leaving QPI continuous-read mode needs a 10-clock all-ones transaction before FFh. Build 51 (ROM v5.2) automates it.

**19 October 17:00 - MILESTONE: hello_world executed from the physical on-board flash** (build 50, driven by hand through the monitor): programmed over UART with the fixed controller, booted in QPI continuous-read mode through the XIP window with the CG092 flash cache enabled. N30 closed (chip healthy), N26 validated on hardware (two corrections for the draft), N27/N39 fixes validated on hardware.

**20 October - all seven passing tests run from the physical on-board flash (build 51, unattended):** hello_world, mem_tests, timer_tests, neon_tests, peripheral_test, gic_tests, low_power_tests, each programmed over UART and booted by the ROM's Winbond start-up (N26 sequence, dummy count 6) in QPI continuous-read mode. The flash boot path is complete on hardware. Remaining FPGA items: N25 (cache enable hang), N37 (UART loopbacks), N36 (debug APB); firmware items for upstream: N26, N27, N32, N35, N38, N39.

**20 October - N37 closed (build 52, UART loopbacks):** pl011_uart_tests passes from the real flash; the UART0/UART1 cross-wiring, both receive interrupts and the WFI wake-ups work on hardware (scratch copy of uart_tests passes both directions).

**N40. `uart_tests` cannot pass on hardware as written (test bugs, not SoC bugs)**
* **Component:** `software/src/uart_tests/uart_tests.c`.
* **Problems:** (1) `char* string_in;` is a NULL pointer: the RX handlers write through address 0 into ROM space, and the compare can never match on silicon (the simulation ROM is a preloaded memory that accepts writes). (2) The second half writes `CMSDK_UART0->CTRL = 10`, clearing TX enable on the console UART: every later printf, including the result, is lost (first byte fills the buffer, the second waits forever). (3) UART1 RX is enabled while the banner is still shifting out of UART0 TX, which is also UART1 RX in the loopback: UART1 loses framing (passes in simulation only because at 10 Mbaud the last character finishes in time). (4) BAUDDIV 10 leaves the console at 2 Mbaud (at 20 MHz), unreadable by most bench adapters.
* **Fix:** `char string_in[32]`; `CMSDK_UART0->CTRL = 0x0B`; drain UART0 TX (or wait for a TX-idle status) before enabling UART1 RX; keep the console baud, or restore it before printing.
* **Criticality:** Low (test only).

**N25 root cause found (20 October, build 53 building):** the FPGA model of the TSMC macro SRAMHDE_PG_SVT_16384x36M16WM0, used for the 16 Cortex-A53 L2 data RAM slices, had a 2-cycle read pipeline, after misreading Arm's TSMC integration comment "two-cycle latency between the enable input and the data outputs". Arm's generic model (`ca53_generic_ram`) is a 1-cycle registered read: enable at edge N, data valid after edge N+1 (sampled at N+2, Arm's "two cycles"). Every L2 data read therefore returned the previous access's data, which only matters once the caches are enabled: the post-banner stop in `enable_caches()` on every build since 42. Unit simulation against `ca53_generic_ram` over 4000 random cycles: corrected model 0 mismatches in 1387 reads, old model 1370. FPGA-only issue (the ASIC uses the real macro); no SoC Labs RTL involved. Fix in `rfhds_pg_svt_fpga_models.sv`; build 53 carries it, test = cache probe from RAM, then the stock boot with caches on.

**N25 root cause, revised (21 October 00:45, RTL simulation of the FPGA design):** not the L2 data RAM latency alone. The FPGA build used Arm's TSMC *example* integration of the L2 tag RAMs (`tsmc_cln28hpm_L1_32I_32D_L2_1M/ca53_l2_tagrams.v`), written for a 1 MB L2, which feeds the tag RAMs the unmasked set index. The configured core has a 256 KB L2 (`L2_CACHE_SIZE = 4'b0001`); Arm's generic integration masks the index with `l2_size`. Tags were therefore written and looked up at different RAM words, and the first instruction-cache line fill through the L2 after `enable_caches()` corrupted execution. Proven by bisection: swapping only that file between TSMC and generic decides pass/hang; all FPGA RAM models match Arm's generic RAM in unit tests; power-up contents are irrelevant. FPGA-only (silicon uses SoC Labs' own 256 KB integration). Fix in build 54: Arm generic `ca53_l2_tagrams.v` + an FPGA variant of `ca53_generic_ram` (defined power-up, output holds), verified in simulation first.

**N25, 21 October 01:45:** the build 54 configuration passes the complete cache test in RTL simulation of the FPGA design: instruction cache on, data cache on, both on, 64 KB memory tests with zero errors, TEST PASSED. Hardware confirmation pending on build 54.

**N25 CLOSED (21 October 06:18, build 54 on hardware):** the Cortex-A53 runs with both caches enabled on the HAPS board. Stepwise probe: instruction cache on with code execution, data cache on with 1 KB SRAM and 64 KB RAM tests (0 errors), both caches on with a 64 KB test (0 errors), TEST PASSED. Second probe repeating the stock `enable_caches()` sequence of `bootloader.c`: PASS. Root cause and fix as described above (FPGA-only L2 tag RAM integration). The flash-boot-with-caches run executed the image present in the flash (uart_tests) correctly; hello_world re-run pending.

**21 October 06:52 - MILESTONE: stock boot sequence complete on the board.** hello_world booted from the physical on-board flash with both CPU caches enabled (the `bootloader.c` sequence: enable_caches at EL3 and EL1, flash start-up, jump to 0x400000) and passed. Every FPGA bring-up blocker is now closed; N36 (debug APB read) remains as a low-priority item.

**21 October 06:54 - regression on build 54:** the seven passing SoC Labs tests run from the physical flash again, 7/7 PASS. Final FPGA status: all bring-up items closed except N36 (debug APB read, low priority).

## 21 October 2026 - the three major bugs fixed in the SoC Labs sources (uncommitted; diffs in ~/Desktop/for_daniel_flash/)

**MBT-55 and MBT-48 -> In Review (fix available):** `qspi_controller.sv` in the ahb_qspi repository (nested under megasoc_tech/logical/sl_ahb_qspi): the 1-bit DATA_O state exits on `data_counter == 3'h6` like DATA_I, and the 1-bit data path sends each nibble MSB first (`spi_wbit`). Unit simulation on the original RTL: 31h + 0x02 = 16 clocks carrying 0x02 (was 17 carrying 0x04); 01h + 00 02 = 24 clocks, 00 02 (was 25, 00 04). The identical logic has run on the FPGA since build 50 (QE set, page programs, 7/7 tests from the chip).

**MBT-56 -> In Review (fix available, verified on hardware):** `default.scat` and `bootloader.scat` make RW/ZI execution regions of the ROM load region; `stack_multi_cpu_init.s` enters the C library with `B __main` (scatter-load, `__rt_entry`, `__rt_lib_init`, `main`) under armclang. Side effect: fromelf writes `app_flash.v8-a.hex` and `bootloader.hex` as single files (one load region) and `app_ram.v8-a.hex` is empty; `flows/makefile.software` accepts both forms. Verified: hello_world built with the fix, programmed into the on-board flash and booted on build 54 with no SRAM preload, printed its banner and TEST PASSED. The bootloader's `SET_QIO_MODE_CMD` now has its initial value in the ROM image.

**MBT-50 -> In Review (fix available):** `system.c` weak `abort_handler` prints ESR_EL3 (EC, ISS), ELR_EL3 and FAR_EL3.

**New finding (sim flow):** the SoC Labs VCS flow (`simulate/sim/build/simv`, 29 July) aborts at the flash jump for every image, old or new (mem_tests July log; hello_world control run 21 October); the exception is taken by the ROM's handler, so the fetch at 0x400000 itself faults - a flash-model / ROM start-up mismatch in the simulation set-up, same symptom as build 44 on the board. Flash-booted tests cannot currently be verified in that flow.
