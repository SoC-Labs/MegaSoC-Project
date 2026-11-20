`timescale 1ns/1ps
//-----------------------------------------------------------------------------
// haps_reset_ctrl.sv - SoC reset policy of the HAPS-SX top (build 64, 17 Nov 2026)
//
// Contributors
//   Anastasios Dimitriou (ad1u25@soton.ac.uk)
//
// History of the reset shaping (formerly inline in haps_top.sv, section 2):
//  * 2026-08-11: free-running ~10 s auto-reset so that unattended boots repeat and the debug UART probe can log many
//    boot attempts into one capture. PB1 (HAPS_RESET_N) resets at any time.
//  * 2026-10-14 (build 46): any UART_RX start bit suspends the auto-reset for 2^32 cycles (~215 s at 20 MHz), renewed
//    by every byte, so a host can talk to the monitor ROM. Edge detection, so a floating or stuck-low pin cannot
//    disable the auto-reset.
//  * 2026-11-17 (build 64): the SD-card Linux boot showed the two remaining gaps: with no host connected the 10 s reset
//    killed every boot ~4 s into the kernel load, and a host had to send a byte at least every 215 s to keep Linux
//    alive. New policy:
//      1. The periodic reset is a BOOT-RETRY ONLY. It stops for good (until PB1, a host reset request or power) once
//         a flash boot has begun: the SoC asserts QSPI_nCS more than BOOT_DETECT_MIN after its reset release in a
//         session in which the host has sent nothing. The monitor ROM reads the JEDEC id within ~10 ms of reset and
//         does not touch the flash again until its key window (~5.5 s measured, "press any key within ~3 s") has
//         expired, so the next chip-select edge IS the flash boot (XIP fetches or image copy). A host-attended
//         session (any UART_RX byte before that point) never sets the latch and keeps the build-46 behaviour, which the
//         bench harness relies on: host goes silent -> hold-off expires -> periodic reset -> monitor key window.
//      2. A host can request a reset at any time by holding UART_RX low for at least RESET_REQ_MIN_LOW (4 ms). A 0x00
//         character sent at 1200 baud is 7.5 ms low; the longest low of normal 115200-baud traffic (a 0x00) is 78 us.
//         The reset fires when the line is RELEASED, so the new boot starts on an idle line and the new session counts
//         as unattended unless the host then types. A stuck-low line never fires (no release); the one release of a
//         line that was stuck low gives a single reset. The bench's DAPLink CDC bridge turns a serial BREAK into a reset
//         of its own target MCU and never pulls the line low, hence the low-baud character rather than tcsendbreak().
//      3. The hold-off is cleared by a host reset request so that a boot that fails before the flash stage is retried
//         after 10 s, not 215 s.
//    Typing into a running Linux (bytes after the latch) never re-arms the periodic reset.
//-----------------------------------------------------------------------------
module haps_reset_ctrl #(
    parameter logic [27:0] AUTO_RST_PERIOD   = 28'd200_000_000, // ~10 s at 20 MHz: boot-retry period
    parameter logic [31:0] RX_HOLDOFF_LOAD   = 32'hFFFF_FFFF,   // ~215 s: host-attended hold-off (build 46)
    parameter logic [27:0] BOOT_DETECT_MIN   = 28'd40_000_000,  // 2 s after reset release: flash activity after this = boot
    parameter logic [19:0] RESET_REQ_MIN_LOW = 20'd80_000,      // 4 ms of UART_RX low = host reset request
    parameter int          RST_LEN_LOG2      = 15               // nreset_soc released 2^15 cycles (~1.6 ms) after the last cause
) (
    input  logic clk,             // 20 MHz system clock
    input  logic pb_reset_n,      // HAPS_RESET_N (PB1), asynchronous, active low
    input  logic uart_rx,         // UART_RX pad, idle high
    input  logic qspi_ncs,        // QSPI_nCS as driven by the SoC (same clock domain, idle high)
    output logic nreset_soc,      // SoC reset, active low
    output logic boot_latched,    // 1 = a flash boot has begun in an unattended session; periodic reset disabled
    output logic attended,        // 1 = the host has sent at least one byte since the last SoC reset
    output logic rx_holdoff,      // 1 = within RX_HOLDOFF_LOAD cycles of the last UART_RX start bit
    output logic host_reset_req   // 1-cycle pulse: UART_RX released after >= RESET_REQ_MIN_LOW low
);

    // ---- free-running boot-retry period (2026-08-11) ----
    logic [27:0] period_cnt;
    always_ff @(posedge clk or negedge pb_reset_n)
        if (!pb_reset_n)                               period_cnt <= '0;
        else if (period_cnt == AUTO_RST_PERIOD - 1'b1) period_cnt <= '0;
        else                                           period_cnt <= period_cnt + 1'b1;

    // ---- UART_RX synchroniser and edges ----
    (* ASYNC_REG = "true" *) logic [1:0] rx_sync;
    logic rx_q;
    always_ff @(posedge clk or negedge pb_reset_n)
        if (!pb_reset_n) begin
            rx_sync <= 2'b11;
            rx_q    <= 1'b1;
        end else begin
            rx_sync <= {rx_sync[0], uart_rx};
            rx_q    <= rx_sync[1];
        end
    wire rx_fall = rx_q & ~rx_sync[1];   // start bit of a character (or the start of a long low)
    wire rx_rise = ~rx_q & rx_sync[1];   // line released

    // ---- host reset request: line released after a long low (build 64) ----
    logic [19:0] rx_low_cnt;             // consecutive low samples, saturating
    always_ff @(posedge clk or negedge pb_reset_n)
        if (!pb_reset_n)                           rx_low_cnt <= '0;
        else if (rx_sync[1])                       rx_low_cnt <= '0;
        else if (rx_low_cnt != RESET_REQ_MIN_LOW)  rx_low_cnt <= rx_low_cnt + 1'b1;
    // In the cycle rx_sync[1] first reads high, rx_low_cnt still holds the saturated count (it clears a cycle later).
    always_ff @(posedge clk or negedge pb_reset_n)
        if (!pb_reset_n) host_reset_req <= 1'b0;
        else             host_reset_req <= rx_rise & (rx_low_cnt == RESET_REQ_MIN_LOW);

    // ---- host-attended hold-off (build 46) ----
    logic [31:0] holdoff_cnt;
    always_ff @(posedge clk or negedge pb_reset_n)
        if (!pb_reset_n)              holdoff_cnt <= '0;
        else if (host_reset_req)      holdoff_cnt <= '0;
        else if (rx_fall)             holdoff_cnt <= RX_HOLDOFF_LOAD;
        else if (holdoff_cnt != '0)   holdoff_cnt <= holdoff_cnt - 1'b1;
    assign rx_holdoff = (holdoff_cnt != '0);

    // ---- boot detection (build 64): QSPI chip select after BOOT_DETECT_MIN in an unattended session ----
    logic [27:0] uptime_cnt;             // cycles since nreset_soc release, saturating at BOOT_DETECT_MIN
    wire         uptime_ok = (uptime_cnt == BOOT_DETECT_MIN);
    logic        qspi_ncs_q;
    always_ff @(posedge clk or negedge pb_reset_n)
        if (!pb_reset_n) begin
            uptime_cnt   <= '0;
            qspi_ncs_q   <= 1'b1;
            attended     <= 1'b0;
            boot_latched <= 1'b0;
        end else begin
            qspi_ncs_q <= qspi_ncs;
            if (!nreset_soc) begin           // every SoC reset starts a new session
                uptime_cnt   <= '0;
                attended     <= 1'b0;
                boot_latched <= 1'b0;
            end else begin
                if (!uptime_ok) uptime_cnt <= uptime_cnt + 1'b1;
                if (rx_fall)    attended   <= 1'b1;
                if (qspi_ncs_q & ~qspi_ncs & uptime_ok & ~attended) boot_latched <= 1'b1;
            end
        end

    // ---- reset generation ----
    wire auto_reset = (period_cnt < 28'd64) & ~rx_holdoff & ~boot_latched;
    logic [RST_LEN_LOG2:0] rst_cnt;
    always_ff @(posedge clk or negedge pb_reset_n)
        if (!pb_reset_n) begin
            rst_cnt    <= '0;
            nreset_soc <= 1'b0;
        end else if (auto_reset | host_reset_req) begin
            rst_cnt    <= '0;
            nreset_soc <= 1'b0;
        end else begin
            if (!rst_cnt[RST_LEN_LOG2]) rst_cnt <= rst_cnt + 1'b1;
            nreset_soc <= rst_cnt[RST_LEN_LOG2];
        end

endmodule
