# Build 64 (launched 2026-11-17 14:45, bitstream 17:35) - standalone boot: reset policy module and UART_RX pull-up; sdio-controller byte order (MBT-74)
RTL = build 63 (SD card on PMOD4 from build 62, repository sdio-controller RTL compiled directly since build 63) plus:
  * `rtl/haps_reset_ctrl.sv` (new) replaces the inline reset shaping of `haps_top.sv` (history in the module header:
    2026-08-11 free-running ~10 s auto-reset for unattended logging; 2026-10-14 build 46 UART_RX hold-off of ~215 s so a
    host can use the monitor ROM). The SD-card Linux boot of build 63 showed the two gaps: with no host connected the 10 s
    reset killed every boot ~4 s into the kernel load, and a host had to send a byte at least every 215 s to keep Linux alive.
    New policy, parameters at their defaults (20 MHz):
      1. the periodic reset is a BOOT RETRY only: it stops for good (until PB1, a host reset request or power) once a flash
         boot has begun, i.e. `QSPI_nCS` goes active more than `BOOT_DETECT_MIN` = 2 s after the SoC reset release in a
         session in which the host has sent nothing (the monitor ROM reads the JEDEC id within ~10 ms of reset and does not
         touch the flash again until its key window, measured 5.5 s, has expired: the next chip-select edge IS the boot);
      2. host-attended sessions are unchanged (build-46 behaviour): any UART_RX byte before that point marks the session
         attended, no latch is set, the board resets ~215 s after the host's last byte, which the flashing harness relies on;
      3. host reset request: UART_RX held low for >= `RESET_REQ_MIN_LOW` = 4 ms and then released resets the SoC on the
         release (the new boot starts on an idle line and counts as unattended). The host sends one 0x00 at 1200 baud
         (7.5 ms low); the longest low of 115200-baud traffic is a 0x00 = 78 us. A stuck-low line never fires; the one
         release of a line that was stuck low gives a single reset. The request also clears the hold-off, so a boot that
         fails before the flash stage is retried after 10 s. PB1 unchanged. Why a slow character and not a serial BREAK: the
         bench's DAPLink CDC bridge (0d28:0204) turns a BREAK into a reset of its own target MCU and never pulls the line low.
    Status outputs `boot_latched / attended / rx_holdoff / host_reset_req` are brought out for the debug probe (not wired).
    Verified before the build in xsim: `scripts/tb_haps_reset_ctrl.sv`, 18/18 (`scripts/tb_haps_reset_ctrl_20261117.log`).
  * `constraints/haps_top.xdc`: `PULLUP` on UART_RX, so a disconnected or unpowered bridge reads idle-high and the long-low
    detector cannot fire on a floating pin.
  * sdio-controller `sdaxil.v` (MBT-74): byte swap at the single FIFO -> `sdtxframe` read-out under `OPT_LITTLE_ENDIAN`,
    no swap on the RX FIFO -> DMA path (`sdrxframe` already stores the word little-endian natural). Builds 62c and 63 had
    compiled the RTL at SoC-Labs/sdio-controller 4106f5a, which transmits bits 31:24 first and double-swaps the DMA read;
    the repository's main carries the same correction since ce36dd6 (PR #1, 23 Oct 2026), so build 64 is the first HAPS
    build whose controller matches the repository. Also `` `default_nettype wire`` at the end of every sdspi file, needed
    when Vivado compiles the repository sources in front of the SoC Labs sources.
  * Firmware for the test: `sdio_tests` v7 = v6 recipe (1-bit) built with `-DSDIO_FIFO_WRITE_LE=1` (the driver packs PIO
    write words LSB-first, the mirror of `sdio_store_word()`).
Build chain: `rebuild_bitstream64.tcl` = the build-62c recipe (project synthesis with source-text guards, implementation to
opt_design, then the non-project steps with the GIC clock gates at BUFGCE_X0Y34/35 and USER_CLOCK_ROOT X4Y8, hold re-route
rounds, bitstream only with WHS >= 0). Tcl note: `string match` reads `[get_ports UART_RX]` inside a pattern as a character
class, so the guards use `string first`.

## Result (2 h 50 min)
* `haps_top_build64_reset_policy_mbt74_20261117.bit`, md5 e6e0a488144a2ecef3523a8779b1b696. Routed WNS +0.392 / WHS +0.010 /
  WPWS +0.065 ns, 0 failing endpoints (731809 / 731028 / 160367), 0 negative-hold endpoints on the first route; 133 flops
  under `u_rst_ctrl`; UART_RX PULLTYPE = PULLUP; 310 block RAM primitives; 0 latches; DRC 0 errors / 20 warnings.
* Programmed over JTAG 17 Nov 17:38 (`check_ddr4_cal.tcl`): DDR4 calibration PASS.

## Bench results, 17-19 November 2026 (SanDisk SL16G in the Digilent Pmod MicroSD, sdboot v1 as the flash boot image)
| Check | Result |
|---|---|
| Acceptance 1: unattended SD-card Linux boot must survive total host silence | PASS: one boot 17 Nov 17:40, `uptime` 1 day 23:20 on 19 Nov 17:08 = 170,403 s (arch_timer count 17,040,306 at 100 Hz) with zero host bytes and zero resets; build 63 reset every 10 s without host bytes |
| Host reset request (0x00 at 1200 baud through the DAPLink bridge) | 18 requests, 18 resets; monitor banner 0.7-1.7 s after the request |
| Unattended Linux boots on 19 Nov (reset request, no further host byte) | 5 of 5 reached the shell (Linux 6.6.161, 6 min 20 s after reset, 336 s of it the 6.46 MB Image at 26.7 ms/sector) |
| Regression from the physical flash (dap, gic, hello_world, low_power, mem, neon, peripheral, pl011_uart, timer, uart_tests_hw) | 10/10 PASS, ~1.6 min per image with the reset request between images |
| `sdio_tests` v7 (SDIO_FIFO_WRITE_LE=1, 1-bit) from the flash | 12/14, twice; only Test6 and Test9 fail = the 2-block DMA writes of MBT-72/MBT-73 (`SD-WRITE -> ERR 0501830c`), as on build 63; every single-block write/readback and the 16-sector sweep pass with the driver copying raw little-endian words on both PIO paths |
| Probe 5 (byte order on the four data paths, monitor-driven) | PIO read word 127 of sector 0 = AA550000; the 1-block DMA read into SRAM and into DDR4 gives the same words as the PIO read and decodes as a correct MBR in natural order (type 0C, LBA 8192, size 31,108,096 sectors, 55 AA at 510..511); a 1-block DMA write of that image reads back identical through PIO: all four paths little-endian natural, MBT-74 hardware fix verified. 2-block DMA write still ends 0x0401030C with dma_len 0 (MBT-72/73) |

Bench-tool notes: the DAPLink CDC bridge delivers the monitor banner unreliably right after the host's 1200 -> 115200 baud
switch (intact after ~1.7 s, as a fragment, or not until the auto-start line "[mon] JEDEC=1660EF (Winbond)" 5.5 s later);
the reset itself was never missed. `host/haps_qspi.py` therefore presses a key from the moment it sends the request until
the monitor prompt answers, treats any early monitor line as the banner, and every verb falls back to a reset request when
no prompt comes (a running Linux is taken back to the monitor in ~20 s). Stopping a run while the monitor is mid-transfer
leaves it in binary receive; the next erase fails once ("dap_tests ERROR erase 0" on 19 Nov, pass on rerun).

Open after build 64: MBT-72/73 (multi-block DMA writes; the full-LGCARDBUSY busy-window change tried on build 63 did not fix
them and is not upstreamed); the 26.7 ms/sector read rate (sdboot v2 with SDIO_PROFILE=1 is built for it); 4-bit mode; the
sdspi submodule pointer and reset-controller port in megasoc_tech; a stock-ROM rebuild.
