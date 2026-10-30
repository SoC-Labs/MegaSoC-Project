# Build 56 - stock Winbond bootloader ROM + debug-window fix (26 October 2026)

Sources = build 55 (L2 tag fix, UART loopbacks, QSPI controller write fixes, USE_FLASH_EMU = 0) plus:

1. `imports/verilog/bootrom.v` = the STOCK SoC Labs bootloader (`bootloader.c` + `qspi_flash.c` with the new
   `WINBOND_QPI_STARTUP()` branch, upstream branch `fix/spi-startup-winbond`), built for the 20 MHz / 115200 console.
   The monitor ROM (v5.2) is NOT in this build: `n`, `b`, `program`, `load`, `go` do not exist. The ROM starts the
   flash in QPI/continuous-read mode and jumps to the flash image. Monitor ROM saved as
   `$SP/rom50/bootrom_monitor_v52_build55.v`; build 55 bitstream still has it.
2. `megasoc_cpu_ss.sv` (MBT-58): `.PADDRSYS({16'b0, CPU_DBG_APB.paddr[14:2]})` - offset within the 32 KB DEBUG window
   instead of the full system address; `DBGROMADDR` 28'h0001300 (ROM table at 0x0130_0000). Upstream branch
   `fix/dap-system-apb-offset`. Verified in RTL simulation of this configuration (`$SP/n25/sim/dap/run4.log`:
   dap_tests TEST PASSED with the CIDR-based check).

Timing: WNS 14.240 ns, WHS 0.009 ns, 0 failing endpoints (`timing_summary56.rpt`). 10 critical warnings, same
classes as build 55 (`rebuild56.log`).

## How to test (two-bitstream procedure, because the stock ROM cannot program the flash)
1. Load the build 55 bitstream, `haps_qspi.py program flash_images/<test>_flash.bin` (monitor ROM programs the chip).
2. Load this bitstream, press reset: the stock ROM boots the image from the physical flash, console 115200.
3. Expected: `dap_tests_flash.bin` prints `CIDR = 0xb105100d (class 1)` and `** TEST PASSED **`;
   `hello_world_flash.bin` proves the stock Winbond start-up; `uart_tests_hw_flash.bin` is the MBT-59 patched test
   (console goes to 2 Mbaud after the first lines - use `--baud-after`), `timer_tests_flash.bin` has the N41 fix.
