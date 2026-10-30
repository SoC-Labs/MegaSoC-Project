# Build 55 (2026-10-22) - regression rebuild of build 54 after the work folder was switched to GitHub
Identical sources (ROM v5.2, L2 tag fix, loopbacks, real flash). Purpose: confirm the FPGA project builds independently of the git update. Result: ===BUILD=== WNS=15.130 WHS=0.009, all constraints met, 0 critical warnings, DRC Violations found: 17.

## Tests on build 55, 23 Oct (firmware built from the updated GitHub tree, single-load-region images, no SRAM preload)
RAM: cache_steps PASS, cache_probe PASS.
Flash (suite --winbond): hello_world, mem_tests, neon_tests, peripheral_test, gic_tests, low_power_tests, pl011_uart_tests PASS;
  timer_tests FAIL ("INTSTATUS did not clear"); dap_tests FAIL (ESR 96000210 = sync external data abort at 0x01300FD0, N36);
  uart_tests HANG (MBT-59 test defects unchanged).
timer_tests: the new upstream test (not in our fork before) leaves the timer running with RELOAD = 50 (2.5 us at 20 MHz),
  clears the interrupt and reads INTSTATUS; code fetched from the flash window with caches off (~20 us per 16-byte line)
  cannot read before the timer re-fires (set wins over clear in cmsdk_apb_timer.v). Unmodified test from RAM: PASS.
  Flash image with CTRL = 0 before INTCLEAR: PASS. -> test defect, fix proposed (branch fix/timer-intstatus-race).
