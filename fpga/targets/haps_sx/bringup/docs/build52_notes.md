# Build 52 (2026-10-20 14:04) - build 51 + UART loopbacks for the SoC Labs UART tests (N37)
RTL (FPGA only):
  * megasoc_chip.v, live module, under `ifdef FPGA_BUILD: UARTRXD0 = UART0_RXD_DIRECT & UARTTXD1 (console AND
    UART1 TX; both idle high, never active together); UARTRXD1 = UARTTXD0. Same as the testbench's
    tran P1[0]-P1[3], P1[1]-P1[2] (P1 has no pads on the FPGA).
  * haps_top.sv: PL011_UARTRXD = PL011_UARTTXD (was tied high).
ROM: v5.2 unchanged. Host: haps_qspi.py --baud-after NAME=RATE (uart_tests sets UART0 BAUDDIV=10 = 2 Mbaud after
  its banner; the runner switches the console speed once it sees the boot line, back to 115200 afterwards).
Bench: suite --winbond --baud-after uart_tests=2000000 pl011_uart_tests_flash.bin uart_tests_flash.bin
Result: ===BUILD=== WNS=20.349 WHS=0.010, all constraints met, 0 critical warnings.

## Bench 20 Oct (build 52)
pl011_uart_tests from the real flash: PASS (loopback works).
uart_tests unmodified from flash: HANG (console at 2 Mbaud not readable by the bench adapter; also the test bugs below).
Probes (RAM): uart_loop_poll (polled both ways + UART0 RX INTSTATUS): PASS. uart_irq_probe (five ways): showed UART1
  receives the console traffic too (it is wired to UART0 TX) - bytes 0x0A etc. from the previous printf, then framing loss.
uart_tests_115k (scratch copy: BAUDDIV 173, string_in array, UART0 CTRL 0x0B in 2nd half, ~1 ms TX drain before
  enabling UART1 RX): PASS - "Hello UART" via UART1 RX IRQ + WFI, "Goodbye UART" via UART0 RX IRQ + WFI.  => N37 closed.
