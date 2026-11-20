`timescale 1ns/1ps
// Testbench for haps_reset_ctrl.sv (build 64). Scaled parameters: period 20000 cycles, hold-off 6000, boot detect 4000,
// reset request >= 80 cycles low, reset length 2^6 cycles. "Normal" UART bytes use 4 cycles per bit (a 0x00 = 36 cycles
// low, below the 80-cycle request threshold, same 1:2 ratio direction as 78 us vs 4 ms on the board).
module tb_haps_reset_ctrl;
    localparam int PERIOD = 20000, HOLDOFF = 6000, BOOTMIN = 4000, REQLOW = 80, RSTLOG2 = 6;
    logic clk = 0, pb_reset_n = 0, uart_rx = 1, qspi_ncs = 1;
    logic nreset_soc, boot_latched, attended, rx_holdoff, host_reset_req;
    always #25 clk = ~clk;   // 20 MHz
    haps_reset_ctrl #(
        .AUTO_RST_PERIOD(PERIOD), .RX_HOLDOFF_LOAD(HOLDOFF), .BOOT_DETECT_MIN(BOOTMIN),
        .RESET_REQ_MIN_LOW(REQLOW), .RST_LEN_LOG2(RSTLOG2)
    ) dut (.*);

    int n_resets = 0, n_fail = 0, n_pass = 0;
    always @(negedge nreset_soc) n_resets++;
    task automatic wait_cycles(input int n); repeat (n) @(posedge clk); endtask
    task automatic uart_byte(input byte b, input int bit_cycles = 4);
        uart_rx = 0; wait_cycles(bit_cycles);                         // start bit
        for (int i = 0; i < 8; i++) begin uart_rx = b[i]; wait_cycles(bit_cycles); end
        uart_rx = 1; wait_cycles(bit_cycles);                         // stop bit
    endtask
    task automatic qspi_access(); qspi_ncs = 0; wait_cycles(20); qspi_ncs = 1; wait_cycles(5); endtask
    task automatic wait_release(); @(posedge nreset_soc); wait_cycles(2); endtask
    task automatic check(input string what, input bit ok);
        if (ok) begin n_pass++; $display("PASS %s", what); end
        else    begin n_fail++; $display("FAIL %s  (t=%0t resets=%0d latched=%b attended=%b holdoff=%b nreset=%b)",
                                         what, $time, n_resets, boot_latched, attended, rx_holdoff, nreset_soc); end
    endtask

    int r0;
    initial begin
        wait_cycles(5); pb_reset_n = 1;
        // ---- T1: nothing connected, no flash access: periodic retry resets every PERIOD ----
        wait_release(); r0 = n_resets;            // first release after PB1
        wait_cycles(3 * PERIOD + 100);
        check("T1 periodic retry: 3 resets in 3 periods with no boot", n_resets == r0 + 3);

        // ---- T2: unattended boot: early JEDEC read must not latch, access after BOOTMIN must ----
        wait_release(); r0 = n_resets;
        wait_cycles(100); qspi_access();
        check("T2a early flash access (monitor JEDEC) does not latch", boot_latched == 0);
        wait_cycles(BOOTMIN + 100); qspi_access();
        check("T2b flash access after BOOT_DETECT_MIN latches", boot_latched == 1);
        wait_cycles(3 * PERIOD);
        check("T2c no periodic reset once latched (3 periods)", n_resets == r0);
        // typing into the running system, then a silence longer than the hold-off
        uart_byte(8'h6c); uart_byte(8'h73); uart_byte(8'h0a);
        check("T2d bytes after the latch mark the session attended", attended == 1);
        wait_cycles(HOLDOFF + 2 * PERIOD);
        check("T2e still no reset after the hold-off expires (latched)", n_resets == r0 && boot_latched == 1);
        // a normal 0x00 character (36 cycles low) is not a reset request
        uart_byte(8'h00);
        wait_cycles(PERIOD);
        check("T2f a 0x00 character at the normal rate is not a reset request", n_resets == r0);

        // ---- T3: host reset request: long low, reset on release ----
        uart_rx = 0; wait_cycles(REQLOW + 120); uart_rx = 1;
        wait_cycles(10);
        check("T3a reset within a few cycles of the release", n_resets == r0 + 1 && nreset_soc == 0);
        wait_release();
        check("T3b new session: latch and attended cleared, hold-off cleared", boot_latched == 0 && attended == 0 && rx_holdoff == 0);
        r0 = n_resets;
        // boot fails before any flash access -> periodic retry resumes within one period
        wait_cycles(PERIOD + 200);
        check("T3c periodic retry resumes after a requested reset with no boot", n_resets == r0 + 1);

        // ---- T4: attended session: a byte in the key window, flash activity later, no latch; silence -> reset ----
        wait_release(); r0 = n_resets;
        wait_cycles(200); uart_byte(8'h0a);
        check("T4a attended flag set by the key", attended == 1);
        wait_cycles(BOOTMIN + 100); qspi_access(); qspi_access();
        check("T4b flash activity in an attended session does not latch", boot_latched == 0);
        wait_cycles(HOLDOFF + PERIOD + 200);
        check("T4c host silence -> hold-off expiry -> periodic reset (build-46 behaviour kept)", n_resets == r0 + 1);

        // ---- T5: stuck-low line while latched: no reset until it is released ----
        wait_release(); r0 = n_resets;
        wait_cycles(BOOTMIN + 100); qspi_access();
        check("T5a latched again", boot_latched == 1);
        uart_rx = 0; wait_cycles(3 * PERIOD);
        check("T5b stuck-low UART_RX causes no reset", n_resets == r0);
        uart_rx = 1; wait_cycles(10);
        check("T5c the release of a stuck-low line gives exactly one reset", n_resets == r0 + 1);
        wait_release();

        // ---- T6: PB1 still works at any time, also when latched ----
        r0 = n_resets;
        wait_cycles(BOOTMIN + 100); qspi_access();
        pb_reset_n = 0; wait_cycles(3); pb_reset_n = 1;
        check("T6a PB1 asserts the SoC reset", nreset_soc == 0 && boot_latched == 0);
        wait_release();
        check("T6b release after PB1", nreset_soc == 1);

        $display("SUMMARY: %0d passed, %0d failed", n_pass, n_fail);
        $finish;
    end
endmodule
