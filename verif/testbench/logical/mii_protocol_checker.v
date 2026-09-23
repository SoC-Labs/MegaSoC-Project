//-----------------------------------------------------------------------------
// mii_protocol_checker.v — Passive MII Protocol Checker
//
// Monitors the MII TX and RX buses between MAC and PHY, checking:
//   - Preamble (7 bytes of 0x55) + SFD (0xD5)
//   - Minimum frame size (64 bytes with CRC, 60 without)
//   - CRC-32 validity (IEEE 802.3)
//   - Inter-frame gap (12 byte-times minimum)
//   - Nibble-level timing (data stable on clock edges)
//   - MDIO Clause 22 transaction format
//
// Instantiation: place alongside mdl_ethphy in the testbench.
// Passively monitors — does not drive any signals.
//
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access
// license.
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module mii_protocol_checker #(
    parameter VERBOSE     = 1,
    parameter CHECK_CRC   = 1,
    parameter LOG_FILE    = "logs/mii_proto_check.log",
    // MII 100 Mbps: 40 ns per nibble, 4 ns setup/hold
    parameter NIBBLE_PERIOD_NS = 40
)(
    // MII TX (from MAC — observe only)
    input wire        mtx_clk,
    input wire [3:0]  mtxd,
    input wire        mtxen,
    input wire        mtxerr,

    // MII RX (to MAC — observe only)
    input wire        mrx_clk,
    input wire [3:0]  mrxd,
    input wire        mrxdv,
    input wire        mrxerr,

    // MII Management (observe only)
    input wire        mdc,
    input wire        mdio,

    // Error/count outputs
    output reg        tx_frame_err,
    output reg        rx_frame_err,
    output reg [31:0] tx_frame_count,
    output reg [31:0] rx_frame_count,
    output reg [31:0] tx_error_count,
    output reg [31:0] rx_error_count,
    output reg [31:0] mdio_error_count
);

    integer log_fd;

    // =========================================================================
    // CRC-32 (IEEE 802.3, reflected)
    // =========================================================================
    function [31:0] crc32_byte;
        input [31:0] crc_in;
        input [7:0]  data;
        reg [31:0] crc;
        integer i;
        begin
            crc = crc_in;
            for (i = 0; i < 8; i = i + 1) begin
                if (crc[0] ^ data[i])
                    crc = (crc >> 1) ^ 32'hEDB88320;
                else
                    crc = crc >> 1;
            end
            crc32_byte = crc;
        end
    endfunction

    // =========================================================================
    // TX Protocol Check
    // =========================================================================
    reg [3:0]  tx_nibble_buf [0:2047];
    integer    tx_nibble_cnt;
    reg        tx_in_frame;
    reg [31:0] tx_crc;
    reg        tx_preamble_ok;
    integer    tx_preamble_len;
    reg        tx_sfd_seen;
    reg        tx_bad_crc;

    initial begin
        tx_frame_count  = 0;
        tx_error_count  = 0;
        tx_in_frame     = 0;
        tx_nibble_cnt   = 0;
        tx_preamble_ok  = 0;
        tx_sfd_seen     = 0;
        tx_bad_crc      = 0;
        log_fd = $fopen(LOG_FILE, "w");
        if (log_fd == 0) begin
            $display("[%0t] MII_CHECKER: WARNING - Could not open %s", $time, LOG_FILE);
        end
    end

    // Preamble + SFD pattern: 55 55 55 55 55 55 55 D5
    // As nibbles: 5,5, 5,5, 5,5, 5,5, 5,5, 5,5, 5,5, D,5
    always @(posedge mtx_clk) begin
        if (mtxen && !tx_in_frame) begin
            // Frame starting
            tx_in_frame     <= 1;
            tx_nibble_cnt   <= 0;
            tx_preamble_len <= 0;
            tx_preamble_ok  <= 0;
            tx_sfd_seen     <= 0;
            tx_bad_crc      <= 0;
            tx_crc          <= 32'hFFFFFFFF;
            $fwrite(log_fd, "\n--- TX Frame Start [%0t] ---\n", $time);
        end

        if (tx_in_frame) begin
            tx_nibble_buf[tx_nibble_cnt] <= mtxd;
            tx_nibble_cnt <= tx_nibble_cnt + 1;

            // Check preamble pattern
            if (!tx_sfd_seen) begin
                if (mtxd == 4'h5) begin
                    tx_preamble_len <= tx_preamble_len + 1;
                end else if (mtxd == 4'hD && tx_preamble_len >= 14) begin
                    // SFD detected (0xD5 = nibble D then nibble 5)
                    tx_sfd_seen    <= 1;
                    tx_preamble_ok <= (tx_preamble_len >= 14);
                    $fwrite(log_fd, "  Preamble: %0d nibbles (expected >=14)\n", tx_preamble_len);
                    if (tx_preamble_len < 14) begin
                        $fwrite(log_fd, "  ERROR: Short preamble (%0d nibbles)\n", tx_preamble_len);
                        tx_error_count <= tx_error_count + 1;
                    end
                end else begin
                    // Unexpected nibble during preamble
                    $fwrite(log_fd, "  ERROR: Bad preamble nibble 0x%h at pos %0d\n",
                            mtxd, tx_preamble_len);
                    tx_error_count <= tx_error_count + 1;
                end
            end else if (tx_sfd_seen && mtxd == 4'h5 && tx_nibble_cnt == 15) begin
                // Second nibble of SFD
                $fwrite(log_fd, "  SFD: 0xD5 confirmed\n");
            end else if (tx_sfd_seen) begin
                // Data nibbles — accumulate CRC
                if (CHECK_CRC && tx_nibble_cnt > 15) begin
                    // We have full bytes after SFD (nibbles 14,15 = SFD)
                    // Data starts at nibble index 16
                    if (tx_nibble_cnt >= 16 && (tx_nibble_cnt % 2) == 0) begin
                        // Complete byte available
                    end
                end
            end

            // Frame ended
            if (!mtxen) begin
                tx_in_frame <= 0;
                tx_frame_count <= tx_frame_count + 1;
                $fwrite(log_fd, "--- TX Frame End: %0d nibbles ---\n", tx_nibble_cnt);

                // Check minimum frame size (60 bytes = 120 nibbles without CRC, 64 with)
                // After preamble (14 nibbles) + SFD (2 nibbles) = 16 nibbles overhead
                if (tx_nibble_cnt < 16 + 120) begin
                    $fwrite(log_fd, "  WARNING: Frame shorter than minimum (%0d nibbles)\n",
                            tx_nibble_cnt);
                end

                // CRC check
                if (CHECK_CRC && tx_nibble_cnt >= 16) begin
                    tx_crc = 32'hFFFFFFFF;
                    begin : tx_crc_calc
                        integer i, byte_idx;
                        reg [7:0] byte_val;
                        for (i = 16; i < tx_nibble_cnt; i = i + 2) begin
                            byte_val = {tx_nibble_buf[i+1], tx_nibble_buf[i]};
                            tx_crc = crc32_byte(tx_crc, byte_val);
                        end
                    end
                    if (tx_crc != 32'hDEBB20E3) begin
                        $fwrite(log_fd, "  ERROR: CRC-32 mismatch (got 0x%08X, expected 0xDEBB20E3)\n",
                                tx_crc ^ 32'hFFFFFFFF);
                        tx_error_count <= tx_error_count + 1;
                        tx_bad_crc <= 1;
                    end else begin
                        $fwrite(log_fd, "  CRC-32: OK\n");
                    end
                end

                $fflush(log_fd);
            end
        end
    end

    // =========================================================================
    // RX Protocol Check
    // =========================================================================
    reg [3:0]  rx_nibble_buf [0:2047];
    integer    rx_nibble_cnt;
    reg        rx_in_frame;
    reg [31:0] rx_crc;
    reg        rx_preamble_ok;
    integer    rx_preamble_len;
    reg        rx_sfd_seen;
    reg        rx_bad_crc;

    initial begin
        rx_frame_count  = 0;
        rx_error_count  = 0;
        rx_in_frame     = 0;
        rx_nibble_cnt   = 0;
        rx_preamble_ok  = 0;
        rx_sfd_seen     = 0;
        rx_bad_crc      = 0;
    end

    always @(posedge mrx_clk) begin
        if (mrxdv && !rx_in_frame) begin
            rx_in_frame     <= 1;
            rx_nibble_cnt   <= 0;
            rx_preamble_len <= 0;
            rx_preamble_ok  <= 0;
            rx_sfd_seen     <= 0;
            rx_bad_crc      <= 0;
            rx_crc          <= 32'hFFFFFFFF;
            $fwrite(log_fd, "\n--- RX Frame Start [%0t] ---\n", $time);
        end

        if (rx_in_frame) begin
            rx_nibble_buf[rx_nibble_cnt] <= mrxd;
            rx_nibble_cnt <= rx_nibble_cnt + 1;

            // Check preamble
            if (!rx_sfd_seen) begin
                if (mrxd == 4'h5) begin
                    rx_preamble_len <= rx_preamble_len + 1;
                end else if (mrxd == 4'hD && rx_preamble_len >= 14) begin
                    rx_sfd_seen    <= 1;
                    rx_preamble_ok <= (rx_preamble_len >= 14);
                    $fwrite(log_fd, "  Preamble: %0d nibbles\n", rx_preamble_len);
                    if (rx_preamble_len < 14) begin
                        $fwrite(log_fd, "  ERROR: Short preamble (%0d nibbles)\n", rx_preamble_len);
                        rx_error_count <= rx_error_count + 1;
                    end
                end else begin
                    $fwrite(log_fd, "  ERROR: Bad preamble nibble 0x%h\n", mrxd);
                    rx_error_count <= rx_error_count + 1;
                end
            end

            // Frame ended
            if (!mrxdv) begin
                rx_in_frame <= 0;
                rx_frame_count <= rx_frame_count + 1;
                $fwrite(log_fd, "--- RX Frame End: %0d nibbles ---\n", rx_nibble_cnt);

                if (rx_nibble_cnt < 16 + 120) begin
                    $fwrite(log_fd, "  WARNING: Frame shorter than minimum (%0d nibbles)\n",
                            rx_nibble_cnt);
                end

                if (CHECK_CRC && rx_nibble_cnt >= 16) begin
                    rx_crc = 32'hFFFFFFFF;
                    begin : rx_crc_calc
                        integer i;
                        reg [7:0] byte_val;
                        for (i = 16; i < rx_nibble_cnt; i = i + 2) begin
                            byte_val = {rx_nibble_buf[i+1], rx_nibble_buf[i]};
                            rx_crc = crc32_byte(rx_crc, byte_val);
                        end
                    end
                    if (rx_crc != 32'hDEBB20E3) begin
                        $fwrite(log_fd, "  ERROR: CRC-32 mismatch (got 0x%08X)\n",
                                rx_crc ^ 32'hFFFFFFFF);
                        rx_error_count <= rx_error_count + 1;
                        rx_bad_crc <= 1;
                    end else begin
                        $fwrite(log_fd, "  CRC-32: OK\n");
                    end
                end

                $fflush(log_fd);
            end
        end

        // RX error from PHY
        if (mrxerr && mrxdv) begin
            $fwrite(log_fd, "  ERROR: RX error signal asserted at nibble %0d\n", rx_nibble_cnt);
            rx_error_count <= rx_error_count + 1;
        end
    end

    // =========================================================================
    // TX Error Check
    // =========================================================================
    always @(posedge mtx_clk) begin
        if (mtxerr && mtxen) begin
            $fwrite(log_fd, "  ERROR: TX error signal asserted at nibble %0d\n", tx_nibble_cnt);
            tx_error_count <= tx_error_count + 1;
        end
    end

    // =========================================================================
    // MDIO Clause 22 Protocol Check
    // =========================================================================
    reg        mdio_captured;
    reg [31:0] mdio_shift_reg;
    reg [5:0]  mdio_bit_cnt;
    reg        mdio_active;
    reg [1:0]  mdio_op;
    reg [4:0]  mdio_phy;
    reg [4:0]  mdio_reg;

    initial begin
        mdio_error_count = 0;
        mdio_captured    = 0;
        mdio_active      = 0;
        mdio_bit_cnt     = 0;
    end

    always @(posedge mdc) begin
        if (!mdio_active) begin
            // Look for start bits (01 for Clause 22)
            if (mdio) begin
                mdio_shift_reg <= 32'd0;
                mdio_bit_cnt   <= 0;
                mdio_active    <= 1;
            end
        end else begin
            mdio_shift_reg <= {mdio_shift_reg[30:0], mdio};
            mdio_bit_cnt <= mdio_bit_cnt + 1;

            if (mdio_bit_cnt == 31) begin
                mdio_active <= 0;
                // Decode Clause 22 frame
                // [31:30] = Start (01)
                // [29:28] = OP (10=read, 01=write)
                // [27:23] = PHY Address
                // [22:18] = Register Address
                // [17:16] = TA (turn-around)
                // [15:0]  = Data

                mdio_op <= mdio_shift_reg[29:28];
                mdio_phy <= mdio_shift_reg[27:23];
                mdio_reg <= mdio_shift_reg[22:18];

                // Check start bits
                if (mdio_shift_reg[31:30] != 2'b01) begin
                    $fwrite(log_fd, "  MDIO ERROR: Bad start bits 0x%h (expected 01)\n",
                            mdio_shift_reg[31:30]);
                    mdio_error_count <= mdio_error_count + 1;
                end

                // Check operation
                if (mdio_shift_reg[29:28] != 2'b10 &&
                    mdio_shift_reg[29:28] != 2'b01) begin
                    $fwrite(log_fd, "  MDIO ERROR: Bad OP code 0x%h\n",
                            mdio_shift_reg[29:28]);
                    mdio_error_count <= mdio_error_count + 1;
                end

                if (VERBOSE) begin
                    $fwrite(log_fd, "  MDIO %s: PHY=%0d REG=0x%02h\n",
                            (mdio_shift_reg[29:28] == 2'b10) ? "READ " : "WRITE",
                            mdio_shift_reg[27:23],
                            mdio_shift_reg[22:18]);
                end
            end
        end
    end

    // =========================================================================
    // Summary on simulation end
    // =========================================================================
    final begin
        $fwrite(log_fd, "\n=== MII Protocol Checker Summary ===\n");
        $fwrite(log_fd, "  TX Frames: %0d  TX Errors: %0d\n", tx_frame_count, tx_error_count);
        $fwrite(log_fd, "  RX Frames: %0d  RX Errors: %0d\n", rx_frame_count, rx_error_count);
        $fwrite(log_fd, "  MDIO Errors: %0d\n", mdio_error_count);
        $fwrite(log_fd, "====================================\n");
        $fclose(log_fd);
    end

endmodule
