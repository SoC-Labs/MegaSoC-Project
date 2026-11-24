# Build 65 - boot ROM = monitor v6.0: flash images start with the CPU caches on (24 November 2026)

`haps_top_build65_monitor_v6_caches_20261124.bit`, md5 e2b8ae1c2173bd21706291953893974c, 199,112,105 bytes.
**Build 65 = build 64 with different boot ROM contents and nothing else.** RTL, constraints, placement and routing are
those of build 64 (`haps_top_build64_reset_policy_mbt74_20261117.bit`, md5 e6e0a488).
Log and capture names below (`patch_rom65.log`, `program65.log`, `board_tests_20261123/`, the `suite_*` folders) are
files of the build-65 folder on the SoC Labs build server; the scripts and sources are in this contribution.

## 1. Why
On builds 51 to 64 the ROM is the UART/flash monitor v5.2, written while enabling the CPU caches still stopped the boot
(N25, fixed in build 54). It starts a flash image with SCTLR_EL3.C = I = 0 and the CG092 flash cache off, and the library
start-up of the image only enables the MMU (MBT-66). The profile run of 23 Nov (`sdboot_v2_profile_20261123.md` in this folder) measured what that
costs: about 100 us per taken branch, 521 s from the monitor banner to
Linux instead of 31 s. sdboot v3 works around it for itself; every other flash image (the ten regression tests, sdio_tests)
still ran uncached. The stock `bootloader.c` enables the caches before it jumps; the ROM now does the same.

## 2. The ROM: `bootloader_monitor` v6.0
Source `firmware/bootloader_monitor/bootloader.c` in this contribution (v5.2 is its previous revision in the git history).
It is the bring-up ROM of this FPGA target and is not part of MegaSoC-Tech.

* New `boot_caches_on()`: data caches invalidated by set/way (they are off, nothing is dirty), CPUECTLR.SMPEN set,
  `enable_caches()`, `enable_caches_el1()`, then one line `[mon] CPU caches on: SCTLR_EL3=40C5383D (C=1 I=1) SMPEN=1`.
  That is the stock `bootloader.c` hand-over plus the two things MBT-66 says it lacks.
* Called last, after the flash start-up, in the production boots only: auto-start, `n D 1`, `b`.
* `n D 1 0` and `b 0` start the image with the caches off, as v5.2 did (prints `CPU caches left off`).
* Unchanged on purpose: the monitor itself runs with the caches off (key window, UART load and flash programming), and
  `g` does not touch the CPU caches, so RAM-loaded programs (ld2, the shim, RAM-mode tests) see the same state as before.
* Built from the current tree (armclang 6.22, `make -B COMPILE_GCC=0 AARCH64=1`, `bootrom_gen.py -a 14`): 54,624 bytes of
  65,536. The ROM in builds 51 to 64 was built on 19 Oct from the pre-GitHub tree. A rebuild of the unchanged v5.2 source
  today differs from it in three places only (168 of 174 functions identical after masking relocations; `main` and
  `winbond_startup` identical): the start-up now enters through `__main`, so RW/ZI data are initialised (v5.2 called
  `main` directly, ticket N35; the stock ROM of build 56 already booted this way), `system_sw_reset()` has a different
  body, and `abort_handler` is five instructions longer.
* Side effect, measured: banner to the jump takes 3.1 s instead of 5.6 s (same key-window loop count in the source;
  why the loop is faster in this build was not looked into). The harness presses a key every 0.3 s and had no trouble with it.

## 3. How the bitstream was made: ROM contents patched into the routed build-64 design
The boot ROM is 32 RAMB36E2 in 16K x 2 mode (`u_ROM_wrapper/u_bootrom/RDATA_reg_0..31`), so new ROM contents are new INIT
strings and nothing else. No synthesis, no placement, no routing: about 10 minutes instead of about 3 hours, and the
timing cannot move.

1. `scripts/dump_rom64.tcl`: opens `haps_top_routed64_final.dcp` and dumps the 32 cells (`rom64_bram_dump.txt`).
2. `scripts/rom_init_gen.py`: proves the layout against the ROM known to be in build 64. Every bit lane of every block RAM
   equals exactly one data bit of the old `bootrom.v` at all 16,384 addresses, the 64 lanes cover the 64 data bits once,
   and the output net names agree: `RDATA_reg_k` holds `RDATA[2k+1:2k]` (`scripts/rom_init_gen_20261124.log`). It then writes the same
   layout for the new ROM: `rom65_init.tcl` (1,077 of 4,096 INIT strings change) and `rom65_expected.txt`.
3. `scripts/patch_rom65.tcl`: opens the routed build-64 checkpoint, applies the INIT strings, reads all 4,096 back against the
   expected file (0 mismatches), checks the design is otherwise untouched (522,817 primitives before and after, 387,721
   nets fully routed, 0 routing errors), reports timing (**WNS +0.392, WHS +0.010 = build 64**), writes
   `haps_top_routed65.dcp` and the bitstream. DRC 0 errors, 20 warnings (the build-64 set). Log `patch_rom65.log`.

A full rebuild with the build-64 recipe was kept ready as the fallback and was not needed.
Reusable for any later ROM-only change: regenerate `bootrom.v`, rerun steps 2 and 3 against the routed checkpoint.

## 4. Pre-test on build 64 before the bitstream existed (bench 19:27 to 19:33 EST, 23 Nov)
The v6.0 source was also linked for DDR4 (the monitor makefile with `APP_SCAT := dram`, `-DMON_RAM_TEST` and without
`BOOT_CODE`), loaded with the old ROM's `m` and started with `g 80000000`. From its prompt `n 6 1` runs
exactly the new hand-over:
* sdboot v3 from the flash: `[mon] CPU caches on`, loader entry state `(M=1 C=1 I=1) SMPEN=1`, Linux banner. PASS.
* The ten regression images, programmed one by one, caches on: **10/10 PASS**.
* `n 6 1 0` (caches off) with hello_world: PASS, prints `CPU caches left off`.

## 5. Programming (24 Nov 00:53 UK)
JTAG tunnel `ssh -f -N -M -S ~/.ssh/jtag3310.sock -L 127.0.0.1:3310:127.0.0.1:3121 haps-dev`, then
`vivado -mode batch -source ddr4/check_ddr4_cal.tcl -tclargs <bit>`: `PROGRAMMED`, DDR4 calibration "No errors detected"
(`program65.log`). The tunnel was closed afterwards (`ssh -S ~/.ssh/jtag3310.sock -O exit haps-dev`). The first attempt
failed because the control socket was put in the scratchpad, whose path is longer than the 108-byte socket limit; the
script's fallback then started an empty local hw_server, which was stopped (`program65_attempt1_no_tunnel.log`).

## 6. Board results (bench 19:53 to 20:28 EST on 23 Nov = 00:53 to 01:28 UK on 24 Nov), `board_tests_20261123/`
* **First boot, unattended, straight after configuration:** `[mon] build 65 QSPI/flash monitor v6.0`, Winbond start-up,
  `[mon] CPU caches on: SCTLR_EL3=40C5383D (C=1 I=1) SMPEN=1`, sdboot v3 `entry state ... (M=1 C=1 I=1) SMPEN=1` (it leaves
  the caches alone), Linux shell.
* **Regression from the flash, caches on: 10/10 PASS, twice** (`suite_20261123_195428`, `suite_20261123_201828`): dap_tests,
  gic_tests, hello_world, low_power_tests, mem_tests, neon_tests, peripheral_test, pl011_uart_tests, timer_tests,
  uart_tests_hw. The second run took **193 s for the ten images** (about 19 s each, nearly all of it flash programming;
  each test itself ends 0.1 to 0.2 s after `n 6 1`). On build 64 the suite needed about 1.6 minutes per image.
* **`n D 1 0` (`HAPS_BOOT_CACHES=0`):** hello_world and mem_tests PASS with `CPU caches left off`; sdio_tests v7 gives
  2 errors, the build-64 result (multi-block write and two-sector write, `SD-WRITE -> ERR 0501830c`, MBT-72/73).
* **RAM path unchanged:** `load monitor_v60_ram.bin 80000000` (75 KB through `m`, sum OK) and `go 80000000` start the RAM
  test copy, which prints its banner.
* **Five unattended boots by reset request, sdboot v3 in the flash: 5/5** reach Linux, all checksums right, read-back
  after the cache clean identical every time; shell check after the fifth: uptime 15.9 s, arch_timer 1,600 (100 Hz).

| Monitor banner to the Linux banner (s)       | build 64, sdboot v1 | build 64, sdboot v3 | build 65, sdboot v3 |
|----------------------------------------------|--------------------:|--------------------:|--------------------:|
| Banner to loader start (key window, start-up)|                 5.8 |                 5.9 |                 3.1 |
| Cache enable inside the loader               |                   - |                 0.6 |      - (in the ROM) |
| Mount, SHIM.BIN, MEGASOC.DTB                 |                 0.9 |                 0.2 |                 0.2 |
| IMAGE read                                   |               336.5 |                17.0 |                17.0 |
| sum32 of the Image                           |               158.9 |                 0.2 |                 0.2 |
| Checks, cache clean, read-back, jump         |                12.5 |                 0.3 |                 0.3 |
| Shim and kernel                              |                 6.7 |                 6.7 |                 6.7 |
| **Total**                                    |           **521.3** |            **30.9** |            **27.5** |

The host sees the first banner line 1.5 to 1.8 s after a reset request, so the Linux banner arrives 28 to 31 s after
the request.

## 7. Finding: at full speed the SD driver's write path fails (MBT-75 made deterministic)
sdio_tests is the one image that does worse with the caches on:

| Image and start                                                    | Errors | What fails |
|--------------------------------------------------------------------|-------:|------------|
| v7, caches off (`n 6 1 0`), as on build 64                         |      2 | Test6, Test9: multi-block DMA writes (MBT-72/73) |
| v7, caches on                                                      |     36 | from Test5 on: `SDIO TIMEOUT: command busy expired`, then a cascade |
| v8 = v7 with `SDIO_BUSY_TIMEOUT_CYCLES` 50,000,000 instead of 50,000, caches on | 9 | every read that follows a write (Test5, 8, 13, 14), plus Test6/Test9 |

* The driver's timeouts are poll counts. One status poll takes on the order of 100 us with the caches off (165 us in the
  profile build) and 1 us with them on, so the test's 50,000-poll limit shrinks from several seconds to 50 ms, less than a card's programming time, and the first expiry leaves
  the controller with a command in flight (`sd_cmd = 00004151, CMDBUSY`).
* With the limit raised 1000 times the cascade is gone but **a single-block read issued straight after a write fails
  every time**: the card is still programming, and nothing in the write path waits for that to end. This is MBT-75
  (Low, "seen in Test14 at a 167 kHz data clock"); slow code had been hiding it.
* Reads alone are unaffected (sdboot: 12,615 reads per boot, no retry, no error).
* Not fixed here. A fix belongs in `sdiodrv.c`: wait for the card to leave the programming state after CMD24/CMD25
  (DAT0 busy or CMD13 until `tran`), and time the timeouts with the generic counter instead of loop counts.
  Until then `HAPS_BOOT_CACHES=0` reproduces the old 12/14.

## 8. Host tool (`host/haps_qspi.py`)
* `HAPS_BOOT_CACHES=0`: `suite --winbond` boots with `n D 1 0`.
* `winbond_boot()`: when the test's end marker arrives inside the first 3 s read it no longer waits out the whole test
  timeout (each caches-on test had cost 60 s in the first run).
* `at_prompt()`: a monitor prompt counts only if `> ` is the last thing received and the line then stays quiet. Incident
  that showed the need: `program` probed while sdio_tests was still printing, took a `> ` in its output for the prompt
  and sent `e 0` to the test; nothing was erased, the step failed with "no prompt after: e 0" and was rerun.

## 9. State now, and rollback
* Bench: build 65 in the FPGA, sdboot v3 (md5 8f875ae6) in the flash, daemon logging, Linux up (28 s after the last
  reset request).
* Project: `haps_top.srcs/sources_1/imports/verilog/bootrom.v` is the v6.0 ROM, so the next full build carries it; the
  v5.2 file is kept next to it as `bootrom.v.monitor_v52_build51_64`.
* Rollback: program `../build64_reset_policy_mbt74_20261117/haps_top_build64_reset_policy_mbt74_20261117.bit`, copy
  `bootrom.v.monitor_v52_build51_64` back, and restore `haps_qspi.py.pre_build65` on haps-dev if wanted (the new tool
  also works with the old ROM).

## 10. Open
* MBT-75 (driver: wait for the end of programming, time-based timeouts). The finding of section 7 is not in Jira yet.
* A pure stock `bootloader.c` ROM (no monitor, no key window) is one more ROM patch away if a production-like boot is
  wanted; it cannot program the flash, so the bench would need this bitstream to update the flash.
