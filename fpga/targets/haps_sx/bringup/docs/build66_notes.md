# Build 66 - SD card busy detection after a written block (MBT-72, MBT-73, MBT-75), 25 November 2026

`haps_top_build66_sd_busy_token_20261125.bit`, md5 1a7c0561bf6a1c2c5ebe098deb702a33, 199,112,105 bytes.
**Build 66 = build 65 with the corrected SD controller front end.** The boot ROM is monitor v6.0 as in build 65, now
built from source instead of patched in. The top level, the constraints and the host tools are unchanged.
Capture and log names below are files of the build-66 folder on the SoC Labs build server. The scripts and sources are
in this contribution.

## 1. What was wrong
Three tickets had one cause.

| Ticket | Symptom on the board |
|---|---|
| MBT-72 | A multi-block DMA write aborts with status 0x0501830C at every usable SD clock |
| MBT-73 | The first DMA write after a pause fails even at a slow clock, the next ones pass |
| MBT-75 | A read sent straight after a single-block write is not answered |

`sdfrontend.v` detects the card's busy on DAT0. After the host stops driving it assumed "busy" for 4 SD clocks and then
followed DAT0. A card answers every written block with a CRC status token first: a start bit, three status bits and an
end bit, two clocks after the host's end bit. Only after the token does the card pull DAT0 low. The 4-clock window
ended inside the token, the token's high bits cleared the busy flag, and the card's real busy was never seen.

`sdaxil.v` was then left with its own timer, a fixed number of system clocks. When the timer expired the controller
reported the card ready and, in a multi-block write, sent the next block. The card ignores a block that starts while
it is busy and sends no token, so the frame timed out, the DMA aborted and the controller issued CMD12.

## 2. Proof on the board, build 65
`firmware/sd_tests/sd_gap_probe.c` initialises the card with the driver and then drives the controller register by
register, without the DMA, so the program decides when each block goes out. SanDisk SL16G, 1-bit, 5 MHz. All times are
from the CRC status token of the block just written.

**What the controller reported against what the card did, single block**

| | Microseconds |
|---|---|
| Controller CARDBUSY flag | 203 to 205, every run |
| Card ready by CMD13 | 1010 to 4268 |

The 205 us is the controller's 4095-clock timer at 20 MHz, not the card.

**The card's busy after the first block of a multi-block write**

| Idle time before the write | Card busy |
|---|---|
| none or 1 ms | 0.12 to 0.14 ms, after a first run of 1.7 ms |
| 5 ms | mixed, 0.14 or 1.7 ms |
| 20 ms or more | 1.69 to 1.71 ms, every run |

**Two blocks, block 2 sent a chosen time after the token of block 1, 8 runs per line**

| Gap | Failures, no pause between writes | Failures, 20 ms idle before each write |
|---|---|---|
| 0 to 1500 us | 1 or 2 | 8 |
| 2000 us | 0 | 1 |
| 3000 us | 0 | 0 |

Block 2 failed exactly when it was sent before the card's busy had ended. Through the DMA, as the driver does it, all
16 runs failed the same way: block 1 on the card, block 2 not, block 2 sent 205 us after the token of block 1.

That also explains MBT-73. The first write after a pause meets the 1.7 ms busy. A write that follows at once meets
0.14 ms, which the 205 us timer happened to cover.

## 3. The fix
SoC-Labs/sdio-controller PR #3, merged as 1e02358. The front end holds its busy detection in the "assume busy" state
from the end of the host's transmission until the token has been seen, or until 12 SD clocks have passed without one.
The 4-clock window and the DAT0 tracking then start at the end of the token. One file, `rtl/sdfrontend.v`, 81 lines
added and 3 changed. It is applied to all three front-end variants. Only the variant MegaSoC uses, without SERDES and
DDR, has been exercised.

The original author's current tree has the same idea under the name `pending_ack`. It was added after the SoC Labs
copy was taken.

## 4. Unit simulation
`scripts/tb_sd_busy.v` with `scripts/run_tb_sd_busy.sh`, VCS, the real `sdckgen` and `sdfrontend`, 20 MHz system clock.
The card model sends the token two clocks after the host's block and then holds DAT0 low for the stated time. The
figure is the number of system clocks in which the front end said "not busy" while the card held DAT0 low. Output:
`scripts/tb_sd_busy_20261125.log`.

| Case | Clock divider | Card busy | Before | With the fix |
|---|---|---|---|---|
| Accepted token | 0x03, 5 MHz | 230 us | 4596, all of it | 0 |
| Accepted token | 0x03 | 3 ms | 59996, all of it | 0 |
| Accepted token | 0x10 | 230 us | 4644 | 0 |
| Accepted token | 0x20 | 230 us | 4676 | 0 |
| Accepted token | 0x41 | 230 us | 4784 | 0 |
| CRC error token | 0x03 | none | 0, error seen | 0, error seen |
| No token | 0x03 | none | 0 | 0 |
| R1b command, busy 500 us | 0x03 and 0x20 | 500 us | 0 | 0 |

## 5. Bitstream
`scripts/rebuild_bitstream66.tcl` is the full build script. It is the build-64 script with the SD controller taken
from the repository at the fix, the boot ROM from the monitor v6.0 source, and a guard for each. The guards stop the
build when an SD module would be compiled from an old project copy instead of the repository.

| | Build 66 |
|---|---|
| Run time | 2 h 58 min |
| Setup slack, worst | +0.573 ns |
| Hold slack, worst | +0.010 ns |
| Failing endpoints | 0 |
| DRC errors | 0 |
| New flip-flops | 5, the token wait flag and its 4-bit counter |

The DRC warnings are the same five kinds as build 64. The boot ROM banner still says "build 65", because the text is
in the ROM source and was not changed.

## 6. Board tests, build 66
SanDisk SL16G, images run from the QSPI flash with the CPU caches on.

**Multi-block write stress.** `firmware/sd_tests/sd_mbw_tests.c`: after card initialisation the first data operation
is a 2-block write, then 20 runs each of 2, 4, 8, 16 and 32 blocks. Every write is read back and compared.

| Image | Mode | Failed writes, build 65 | Failed writes, build 66 |
|---|---|---|---|
| Driver before MegaSoC-Tech PR #30 | 1-bit, 5 MHz | not run | 0 of 101 |
| Driver of PR #30, 3 runs | 1-bit, 5 MHz | 101 of 101 | 0 of 303 |
| Driver of PR #30 | 4-bit, 5 MHz | 101 of 101 | 0 of 101 |
| Driver of PR #30 | 4-bit, 10 MHz | not run | 0 of 101 |

606 multi-block writes on build 66, none failed, no read error and no data mismatch. The first write after
initialisation was good in 6 of 6 runs. The older driver passes too, so the controller fix alone cures MBT-72 and
MBT-73.

**`sdio_tests`, 14 tests**

| Image | Errors, build 65 | Errors, build 66 |
|---|---|---|
| Driver before PR #30 | 19 | 0 |
| Driver of PR #30 | 2 | 0 |
| Driver of PR #30, timeouts on the counter | 2 | 0 |
| Driver of PR #30, 4-bit | 2 | 0 |

This is the first time all 14 tests pass on this board. 4-bit mode had never been run on it before.

**Rough transfer times from the stress test.** The counters are in milliseconds, so the figures are indicative.

| Mode | Write per block | Read per block |
|---|---|---|
| 1-bit, 5 MHz | 0.90 ms | 0.81 ms |
| 4-bit, 10 MHz, 32-block transfers | 0.20 ms | 0.09 ms |

The SD card Linux loader reads single blocks by FIFO at 1.35 ms each, so it has room to get faster.

**Regression and Linux.** The 10 regression images pass from the flash, the whole suite in 193 s. Three unattended
boots reached the Linux shell in 28, 28 and 29 s.

## 7. Driver
MegaSoC-Tech PR #30, merged as 37b5ed8. After a write `sdiodrv` polls the card status until the card reports that it
is ready for data. On build 65 that alone removed every read-after-write failure: 19 errors became 2, and the 2 left
were the multi-block DMA writes that need the controller fix. The PR also adds an optional build setting,
`SDIO_TIMEOUT_TICKS_PER_MS`, that bounds the driver's waits by time instead of by poll count.

Both test programs are built with the `sdio_tests` makefile of MegaSoC-Tech with the source file swapped and
`-DSDIO_DEBUG=0`. They write only the scratch sectors 0x1040 to 0x105F, an unallocated gap before the first partition
of the bench card. Check that range on another card before running them.

## 8. Two side results
- **Library start-up, MBT-66.** MegaSoC-Tech PR #32, merged as 49ebaf1, makes every application start with the CPU
  caches on. It was measured on build 65: nine of the ten regression images pass with it unchanged, and eight images
  pass from the DDR4 in RAM mode.
- **`uart_tests` TX overrun check.** The tenth image failed, on builds 65 and 66, because the library change moved the
  test by 16 bytes.
  The check needed three UART writes to arrive within one 160-clock frame. On this board the stores can reach the UART
  about 2000 clocks apart when an instruction fetch from the flash falls between them. The same PR rewrites the check
  so that it no longer depends on that. Which bus element holds the writes back was not traced.

## 9. Not done
- **No VIP simulation.** `sdio_tests` was not run against the card model with the new controller or the new driver.
  CARDBUSY now stays set for as long as the model holds DAT0 low, so waits in the test grow by the model's
  programming time.
- **One detail of MBT-73 is unexplained.** On the old controller the first DMA write passed once any DMA transfer had
  completed. It was not investigated further, because with the fix the first write passes.
- **The faster SD paths are not used yet.** The loader still reads single blocks in 1-bit mode.

## 10. Upstream, 26 November 2026
| Change | Where | Merged as |
|---|---|---|
| Controller fix | SoC-Labs/sdio-controller PR #3 | 1e02358 |
| Driver ready wait | SoC-Labs/MegaSoC-Tech PR #30 | 37b5ed8 |
| Library start-up and `uart_tests` | SoC-Labs/MegaSoC-Tech PR #32 | 49ebaf1 |
| `logical/sdspi` pointer to the fix | SoC-Labs/MegaSoC-Tech PR #33 | 7f4f6f1 |

Jira: MBT-72, MBT-73, MBT-75 and MBT-66 are closed.
