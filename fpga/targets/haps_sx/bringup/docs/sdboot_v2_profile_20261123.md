# sdboot v2 read-path profile on build 64, and the cache fix in sdboot v3 (23 November 2026)

**Outcome: with the CPU caches turned on by the loader (sdboot v3, section 7) the board goes from the monitor banner
to the Linux banner in 30.9 s instead of 521.3 s.** Sections 1 to 5 are the profile run that found the cause.

One run of `sdboot_v2_prof_flash.bin` (md5 8a8c638b, built 17 Nov with `-DSDIO_PROFILE=1 -DSDIO_DEBUG=0`) from the physical
flash on HAPS-SX build 64, unattended boot after a host reset request. Bench capture on haps-dev:
`~/haps_captures/sdboot_v2_prof_20261123_182658/` (run log) and `~/haps_captures/sdboot_20261123_182746/` (console, events);
copies in `sdboot_v2_prof_20261123/` next to this file. Times are host wall-clock stamps from `events.log`
(`~/sdcon/prof_timeline.py`), cross-checked against the loader's own generic-timer figures.

Before the run the board had been in Linux for 4 days 5 h 12 min (364,325 s, arch_timer count 36,432,510 at 100 Hz) on
build 64 with only the daemon's keep-alive bytes: no reset of any kind since 19 Nov 13:06 bench time.

## 1. Result in one line

The SD card and the controller are not the bottleneck. The loader spends about 100 us in every loop iteration it executes,
whatever the loop does, because it runs in place from the QSPI flash with the CPU caches off and the flash cache off.

## 2. Boot timeline, reset banner to the Linux banner

| Phase                                         | sdboot v1 (s) | sdboot v2 profile (s) |
|-----------------------------------------------|--------------:|----------------------:|
| Monitor banner to loader start (key window)   |           5.8 |                   5.8 |
| Mount, SHIM.BIN, MEGASOC.DTB                  |           0.9 |                   1.3 |
| IMAGE read (6,457,352 bytes)                  |         336.5 |                 261.6 |
| sum32 of the loaded image (inside the printf) |         158.9 |                 158.9 |
| Magic checks, cache clean, jump               |          12.5 |                  10.2 |
| Shim and kernel up to the Linux banner        |           6.7 |                   6.7 |
| **Total**                                     |     **521.3** |             **444.5** |

v1 column: capture `sdboot_20261119_130604`; the two other v1 boots on record (`sdboot_20261117_123643` on build 64 and
`sdboot_20261117_051106` on build 63) give the same phase lengths to 0.1 s. **Correction to the 17 Nov notes:** they gave
"6 min 20 s after the banner" for the whole boot. The logs say 8 min 41 s; the 336 s figure is the IMAGE read alone, and
the checksum that follows it costs another 159 s that nobody had noticed because nothing is printed while it runs.

v2 reads faster than v1 (20.7 ms against 26.7 ms per sector). The likely reason is that it was built with `SDIO_DEBUG=0`
(fewer branches per block); that was not isolated in a separate run.

## 3. Per-block breakdown (IMAGE, 12,615 single-block reads, no start retries)

| Part of one 512-byte read                          | Time (ms) | Share |
|----------------------------------------------------|----------:|------:|
| CMD17 issue and wait for the transfer to start     |      0.60 |   3 % |
| Wait for the block (status polls, 18 per block)    |      3.51 |  17 % |
| Copy 128 words from the FIFO to DDR4               |     12.74 |  61 % |
| Outside the driver: FatFs, disk layer, caller loop |      3.89 |  19 % |
| **Total per block**                                |  **20.73** |       |

Loader output: `prof 12615 blocks, start-retries 0: avg start 596 us, busy 3511 us (phase1 97 us/0 polls, phase2 2969
us/18 polls), fifo 12735 us, block 16840 us`. The "busy" figures printed for SHIM.BIN and MEGASOC.DTB (10,009 and 7,512 us)
are inflated: `sdio_prof_reset()` in this image does not clear `t_busy`, so they include the mount reads. `block - start -
fifo` gives 3.58 and 3.51 ms for them. The fix is already in the upstream copy (MegaSoC-Tech PR #25). The "max block" value
is lost: the console prints only the first 160 characters of the line.

## 4. Why: every loop iteration costs about 100 us

| Loop                                   | Measured                         | Per iteration |
|----------------------------------------|----------------------------------|--------------:|
| sum32 over the image                   | 158.9 s for 1,614,338 words      |         98 us |
| FIFO copy                              | 12.735 ms for 128 words          |         99 us |
| `dc civac` cache clean                 | about 10 s for 100,900 lines     |        ~99 us |
| Status poll (phase 2)                  | 2.969 ms for 18 polls            |        165 us |
| Phase 1 with zero polls (straight code)| 97 us between two counter reads  |             - |

100 us is 2,000 CPU clocks at 20 MHz. Three loops with very different bodies cost the same per pass, so the cost is per
taken branch, not per instruction: a fresh instruction fetch from the flash.

Source side:
* `boot.s` (`mmu_cache_setup`) calls only `enable_mmu`. `enable_caches()` is called by the stock `bootloader.c` and by a
  few tests (`ddr4_fpga_tests`, `cache_*`), not by the application start-up. This is MBT-66.
* The ROM in build 64 is still the build-51 monitor (`bootloader_monitor`, "Caches stay OFF", written while N25 was open;
  N25 was fixed in build 54). Its Winbond auto-start jumps to 0x400000 without `enable_caches()` and without turning on
  the CG092 flash cache (the boot log prints `CG092 CCR=00000040`, enable bit clear).
* So sdboot executes in place over QPI (EBh continuous read) with no cache anywhere on the fetch path. The
  comment in `sdboot.c` "the app runs with the MMU and caches on" is wrong.

At the time of the profile run the cause was inferred from these measurements and from the source. Section 7 confirms
it: v3 prints `C=0 I=0 SMPEN=0` on entry and, once it has enabled the caches, reads the Image 15 times faster than v2
(20 times faster than v1).

## 5. What it means

* MBT-72/73/75 and the SD clock are unrelated to the load time.
* Card plus controller need at most 4.1 ms per block (start + wait), and part of that is the 165 us polling step.
* Next experiment (firmware only, no bitstream; done the same evening, section 7): sdboot v3 that sets CPUECTLR.SMPEN and calls `enable_caches()` first
  thing in `main()`, as `ddr4_fpga_tests` does. The loader already cleans and invalidates the three load regions before
  the jump. Expected, not measured: the read approaches the card's own time (12,615 blocks at 3.5 ms or less, about 45 s), the
  checksum and the cache clean drop to about a second, total boot around one minute.
* Structural fixes: the stock boot ROM (caches on before the jump, open item "stock-ROM rebuild"), and MBT-66 in the
  library start-up. After that, multi-block reads through the DMA (byte order is natural since build 64) and 4-bit mode.

## 6. Bench state after the profile run

sdboot v1 (md5 7af38e56) reprogrammed and verified, daemon restarted, board booted Linux unattended (`restore.log`,
banner 526 s after the reset request). Superseded an hour later by section 7.

## 7. sdboot v3: the loader turns the CPU caches on (23 November 2026, bench 18:57 to 19:02 EST)

Source: `megasoc_tech/software/src/sdboot/sdboot.c` (local FPGA tree; copy in `sdboot_v3_cache_20261123/sdboot_v3.c`, the
v2 source is kept as `sdboot.c.v2_20261117`). First thing in `main()`: print the state, invalidate the data caches by
set/way (they are off, nothing is dirty), set CPUECTLR.SMPEN, call the library's `enable_caches()`. The rest of the loader
is unchanged except that the Image is summed a second time after the cache clean, so the check covers the DDR4 contents
and not the cached copy, and the profile line is split in two (160-character console limit). The local driver's
`sdio_prof_reset()` now clears `t_busy` (as upstream).

Images (armclang 6.22, `make -B COMPILE_GCC=0 AARCH64=1`, `fromelf --bin`; logs `sdboot_v3*_build.log`):
* `flash_images/sdboot_v3_cache_flash.bin`, md5 8f875ae6, 76,064 bytes: caches on at the start. **This is the one in the flash.**
* `flash_images/sdboot_v3b_cache_after_mount_flash.bin`, md5 c4d58b25 (`-DSDBOOT_CACHE_STAGE=2`): caches on after the card
  is mounted. Built as a fallback in case the card initialisation did not like fast code. Not needed, never flashed.

Run: `sdboot_v3_cache_20261123/v3_run.sh` on haps-dev, five unattended boots by reset request, capture
`sdboot_20261123_185755`. **5 of 5 reached Linux**; every boot printed sum32 E163559E / AC6FB671 / 3ECCA48F (the source
files) and "read back after the cache clean 3ECCA48F ... same"; no start retries, no `TEST FAILED`.

Cache state as found and as left (identical in the five boots):
```
sdboot: entry state SCTLR_EL3 40C52839 (M=1 C=0 I=0) SMPEN=0
sdboot: caches invalidated and enabled in 460 ms
sdboot: now SCTLR_EL3 40C5383D (M=1 C=1 I=1) SMPEN=1
```

| Phase, monitor banner to the Linux banner       | sdboot v1 (s) | sdboot v3 (s) |
|-------------------------------------------------|--------------:|--------------:|
| Monitor banner to loader start (key window)     |           5.8 |           5.9 |
| Cache invalidate and enable, state prints       |             - |           0.6 |
| Mount, SHIM.BIN, MEGASOC.DTB                    |           0.9 |           0.2 |
| IMAGE read (6,457,352 bytes)                    |         336.5 |          17.0 |
| sum32 of the loaded image                       |         158.9 |           0.2 |
| Magic checks, cache clean, read-back sum, jump  |          12.5 |           0.3 |
| Shim and kernel up to the Linux banner          |           6.7 |           6.7 |
| **Total**                                       |     **521.3** |      **30.9** |

The loader part (loader start to the jump) repeats to 0.01 s over the five boots. The host sees 25.3 s instead of 30.9 s
in two of them only because the DAPLink bridge dropped the first banner line (`boot_timeline.py` then times from the
second `[mon] JEDEC=` line, after the key window).

| Part of one 512-byte read (IMAGE, 12,615 reads) | v2, caches off (ms) | v3, caches on (ms) |
|-------------------------------------------------|--------------------:|-------------------:|
| CMD17 issue and wait for the transfer to start  |                0.60 |               0.01 |
| Wait for the block                              |                3.51 |               1.02 |
| Copy 128 words from the FIFO to DDR4            |               12.74 |               0.25 |
| Outside the driver: FatFs, disk layer, loop     |                3.89 |               0.06 |
| **Total per block**                             |           **20.73** |           **1.35** |

A status poll now takes 1.0 us (994 polls in 997 us; was 165 us), a FIFO word 2.0 us (was 99 us), a sum32 word 0.15 us
(was 98 us).

What limits the boot now: the card's data phase (1.0 ms per block at the 5 MHz, 1-bit setting: 4,096 data bits are
0.82 ms on the wire), the 5.6 s monitor key window and the 6.7 s kernel start. Next gains, in order: 4-bit mode and a
faster SD clock, then multi-block reads through the DMA (byte order natural since build 64) once the FIFO copy becomes
the larger part.

Linux after the fifth boot: shell answers, uptime 70 s with arch_timer 7,012 (100 Hz), `dmesg` has no error, failure,
panic or oops line, MemTotal 1,990,828 kB.

## 8. Bench state now, and rollback

sdboot v3 (md5 8f875ae6) is in the flash, the daemon is logging, the board boots Linux by itself in about 31 s.
Rollback on haps-dev: stop the daemon (`touch ~/sdcon/stop`), `cd ~/build56 && python3 ~/script/haps_qspi.py program
sdboot_v1_flash.bin`, restart the daemon, `touch ~/sdcon/reset`.

## 9. Open after this

* Upstream: `software/src/sdboot/sdboot.c` in MegaSoC-Tech (PR #25) still has the wrong "caches on" comment and no cache
  enable. The v3 change is harmless where a boot ROM has already enabled the caches (it only acts when C or I is 0).
  A PR needs a go.
* MBT-66 (Low): this is what the missing cache enable in the application start-up costs on hardware. A comment and a
  priority change need a go.
* The monitor ROM (build 51 vintage) still starts flash images with every cache off: all ten regression images run the
  same way. Fix with the stock-ROM rebuild.
