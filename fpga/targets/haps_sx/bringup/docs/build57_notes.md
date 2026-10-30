# Build 57 - monitor ROM v5.2 + MBT-58 debug-window fix (26 October 2026, done 17:13)

RTL = build 56 (L2 tag fix, UART loopbacks, QSPI controller 1-bit write fixes, USE_FLASH_EMU = 0, and the
`megasoc_cpu_ss.sv` MBT-58 changes: `.PADDRSYS({16'b0, CPU_DBG_APB.paddr[14:2]})`, `DBGROMADDR` 28'h0001300).
ROM = the UART monitor v5.2 (as builds 51-55), so the usual flow works again:
`haps_qspi.py program <img>`, `haps_qspi.py suite --winbond <imgs>`, `n 6 1`, `load`, `go`.

Timing: WNS 14.240 ns, WHS 0.009 ns, 0 failing endpoints (same worst path as build 56; bitstream differs, md5 in .md5).

## Tests to run (haps-dev, console /dev/ttyACM0 115200)
    python3 haps_qspi.py suite --winbond flash_images/dap_tests_flash.bin flash_images/hello_world_flash.bin
    expected dap_tests: "CIDR = 0xb105100d (class 1)" ... "** TEST PASSED **" (PIDR all zero is expected: DapRomDefs.v unconfigured)
    then the full regression (mem, neon, peripheral, gic, low_power, pl011, timer_tests = fixed image) and
    python3 haps_qspi.py suite --winbond --baud-after uart_tests_hw=2000000 flash_images/uart_tests_hw_flash.bin   (MBT-59 patched test)

Build 56 (stock Winbond bootloader ROM, same RTL) stays archived for the stock-boot check; note its ROM prints at 625 kbaud
(built with the upstream 100 MHz console setting). Corrected stock ROM: $SP/rom57/bootrom_stock_winbond_115200.v (not built).

## Result (haps-dev, 27 Oct 07:38, suite --winbond): dap_tests PASS (CIDR 0xb105100d, PIDR zero as expected), hello_world PASS.
MBT-58 fix confirmed on hardware. Full regression + uart_tests_hw still to run on this build.
## Regression (haps-dev, 27 Oct 08:03, suite --winbond): mem_tests, neon_tests, peripheral_test, gic_tests, low_power_tests, pl011_uart_tests, timer_tests (fixed image) all PASS.
With dap_tests and hello_world: 9/9 PASS from the physical flash on build 57. Remaining: uart_tests_hw (MBT-59).

## 27 Oct, uart_tests_hw (MBT-59) image history on build 57
- v2/v3: HANG in the loopback test (RX IRQ flood while printing; WFI race with code fetched from flash).
- v4 (66080 B, md5 2d3cb5a7...): loopback both directions PASS, SWRESET test skipped, HANG in "UART RX overrun".
  Cause: the RX overrun test checks/clears the flag while UART1 still has two characters in flight (TXBF only
  covers the holding register); with code fetched from flash the re-check comes late, a late character re-sets the
  flag, and the test prints its error message with UART0 TX disabled -> UartPutc() spins on TXBF for ever.
  In VCS (code from ROM) the same image got past that race and reached the TX overrun test, which FAILS by design:
  two back-to-back DATA writes never overrun a CMSDK UART (the first byte moves into the shift register one PCLK
  after the write); a third write is needed.
- v5 (66208 B, md5 0ba6c86d6b1d5ab0f8d6b30bb34a4694): RX overrun waits for the line to go quiet before check/clear and
  restores the console before printing; TX overrun writes three bytes; console_drain() (TXBF + ~2 ms) before every
  UART0 reconfiguration; skip message shortened below 79 chars (c_print_str drops the 80th character).
  Run WITHOUT --baud-after: the patched test never changes the console rate for its output.
  Suite display note: the per-test line is cut at 140 characters, so "...FPGA build)Test" was a truncation, not the
  last byte received. Saved v4 image: uart_tests_hw_flash_v4_66080.bin (this folder).
- 27 Oct 12:45 (haps-dev, suite_20261027_124548): uart_tests_hw v5 from the on-board flash -> TEST PASSED, 0 integration
  issues (both loopbacks, SWRESET skipped, RX overrun, TX overrun). Build 57 now: dap_tests, hello_world, 7 regression
  tests and uart_tests_hw all PASS = 10/10 images. The NUL/garbage tail in the v4 logs is the console adapter being
  switched to 2 Mbaud by --baud-after 3 s after boot (the board was already hung), not board output.
