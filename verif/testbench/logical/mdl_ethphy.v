//-----------------------------------------------------------------------------
// mdl_ethphy.v — Behavioral MII PHY Model for MegaSoC Ethernet Verification
//
// Provides:
//   1. TX clock generation (25 MHz for 100 Mbps, 2.5 MHz for 10 Mbps)
//   2. MDIO slave — responds to standard register reads/writes
//   3. MII TX capture — logs transmitted frames to file
//   4. MII RX injection — sends pre-loaded frames to the MAC
//   5. Collision and carrier sense modelling (loopback-ready)
//
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module mdl_ethphy #(
    parameter TX_CLK_FREQ_HZ = 25_000_000,  // 25 MHz for 100 Mbps MII
    parameter RX_CLK_FREQ_HZ = 25_000_000,
    parameter TX_LOGFILE     = "logs/eth_tx.log",
    parameter VERBOSE        = 1
)(
    // MII TX (from MAC — DUT drives, PHY receives)
    input  wire        mtx_clk_o,   // MAC provides TX clock (we receive it)
    output reg         mrx_clk_o,   // PHY provides RX clock (we drive it)
    input  wire [3:0]  mtxd_i,      // TX data from MAC
    input  wire        mtxen_i,     // TX enable from MAC
    input  wire        mtxerr_i,    // TX error from MAC

    // MII RX (to MAC — PHY drives, MAC receives)
    output reg  [3:0]  mrxd_o,      // RX data to MAC
    output reg         mrxdv_o,     // RX data valid to MAC
    output reg         mrxerr_o,    // RX error to MAC

    // MII Common
    output reg         mcoll_o,     // Collision detect
    output reg         mcrs_o,      // Carrier sense

    // MII Management (MDIO — bidirectional)
    input  wire        mdc_i,       // MDC clock from MAC
    input  wire        md_o,        // MDIO data from MAC
    input  wire        md_padoe_i,  // MDIO output enable from MAC
    output reg         md_i,        // MDIO data to MAC

    // PTP reference clock output
    output wire        ptp_ref_clk,

    // Control
    input  wire        resetn
);

    // =========================================================================
    // TX Clock Generation
    // =========================================================================
    // For MII, the PHY provides both TX and RX clocks.
    // In our testbench, the DUT's ethmac drives mtx_clk_pad_i from the pad,
    // but the clock actually originates from the PHY. We generate it here.
    reg mtx_clk_gen;
    initial mtx_clk_gen = 0;
    always #(1_000_000_000.0 / (2 * TX_CLK_FREQ_HZ)) mtx_clk_gen = ~mtx_clk_gen;

    // The DUT's MII TX clock is this generated clock (connected via wire in TB)
    // We also generate RX clock identically for non-loopback modes
    initial mrx_clk_o = 0;
    always #(1_000_000_000.0 / (2 * RX_CLK_FREQ_HZ)) mrx_clk_o = ~mrx_clk_o;

    // =========================================================================
    // PTP Reference Clock — 125 MHz
    // =========================================================================
    reg ptp_ref_clk_gen;
    initial ptp_ref_clk_gen = 0;
    always #4 ptp_ref_clk_gen = ~ptp_ref_clk_gen;  // 125 MHz = 8 ns period
    assign ptp_ref_clk = ptp_ref_clk_gen;

    // =========================================================================
    // MDIO Slave — Standard IEEE 802.3 Clause 22 Registers
    // =========================================================================

    // MDIO FSM — simplified IEEE 802.3 Clause 22
    // Sample MDIO on MDC rising edge, count 32 bits total
    localparam MDIO_IDLE  = 5'd0;
    localparam MDIO_SAMPL = 5'd1;
    localparam MDIO_PROC  = 5'd2;

    reg [4:0]  mdio_state;
    reg [6:0]  mdio_bit_cnt;
    reg [31:0] mdio_shift_reg;
    reg        mdio_read_op;
    reg [4:0]  mdio_phy_addr;

    wire [4:0] mdio_phy_addr_f = mdio_shift_reg[27:23];
    wire [4:0] mdio_reg_addr_f = mdio_shift_reg[22:18];

    // Registers
    reg [15:0] bmcr;    // 0x00
    reg [15:0] bmsr;    // 0x01
    reg [15:0] phyid1;  // 0x02
    reg [15:0] phyid2;  // 0x03
    reg [15:0] anar;    // 0x04
    reg [15:0] anlpar;  // 0x05
    reg [15:0] aner;    // 0x06

    wire loopback_mode;

    wire [15:0] mdio_reg_mux;
    assign mdio_reg_mux = (mdio_reg_addr_f == 5'h00) ? bmcr   :
                          (mdio_reg_addr_f == 5'h01) ? bmsr   :
                          (mdio_reg_addr_f == 5'h02) ? phyid1 :
                          (mdio_reg_addr_f == 5'h03) ? phyid2 :
                          (mdio_reg_addr_f == 5'h04) ? anar   :
                          (mdio_reg_addr_f == 5'h05) ? anlpar :
                          (mdio_reg_addr_f == 5'h06) ? aner   :
                          16'h0000;

    initial begin
        mdio_state    = MDIO_IDLE;
        mdio_bit_cnt  = 0;
        mdio_shift_reg = 0;
        mdio_read_op   = 0;
        mdio_phy_addr  = 5'd1;
        md_i           = 1'bz;

        bmcr   = 16'h3100;
        bmsr   = 16'h7809;
        phyid1 = 16'h2000;
        phyid2 = 16'h1234;
        anar   = 16'h01E1;
        anlpar = 16'h0041;
        aner   = 16'h0006;
    end

    always @(posedge mdc_i or negedge resetn) begin
        if (!resetn) begin
            mdio_state    <= MDIO_IDLE;
            mdio_bit_cnt  <= 0;
            mdio_shift_reg <= 0;
            md_i           <= 1'bz;
        end else begin
            case (mdio_state)
                MDIO_IDLE: begin
                    md_i <= 1'bz;
                    if (md_o) begin
                        // Start bit detected (MDIO=1 on rising MDC)
                        mdio_shift_reg <= 32'd0;
                        mdio_bit_cnt   <= 0;
                        mdio_state     <= MDIO_SAMPL;
                    end
                end

                MDIO_SAMPL: begin
                    // Shift in MDIO data, count 32 bits total (2 start + 2 op + 5 phy + 5 reg + 2 ta + 16 data)
                    mdio_shift_reg <= {mdio_shift_reg[30:0], md_o};
                    mdio_bit_cnt <= mdio_bit_cnt + 1;

                    if (mdio_bit_cnt == 31) begin
                        // Full 32-bit frame received
                        mdio_read_op <= (mdio_shift_reg[29:28] == 2'b10);
                        mdio_phy_addr <= mdio_shift_reg[27:23];
                        mdio_state <= MDIO_PROC;
                    end
                end

                MDIO_PROC: begin
                    // Process the received frame
                    if (mdio_read_op) begin
                        // Read: drive data back onto MDIO
                        // TA bits (2) then DATA (16) = 18 bits to drive
                        // Bit 32: TA Z, Bit 33: TA 0, Bits 34-49: Data
                        if (mdio_bit_cnt < 50) begin
                            if (mdio_bit_cnt == 32) begin
                                md_i <= 1'bz;           // TA: high-Z
                            end else if (mdio_bit_cnt == 33) begin
                                md_i <= 1'b0;           // TA: driven low
                            end else begin
                                md_i <= mdio_reg_mux[15 - (mdio_bit_cnt - 34)]; // Data
                            end
                            mdio_bit_cnt <= mdio_bit_cnt + 1;
                        end else begin
                            mdio_state <= MDIO_IDLE;
                            md_i <= 1'bz;
                            if (VERBOSE)
                                $display("[%0t] MDIO READ: PHY=%0d REG=0x%02h DATA=0x%04h",
                                    $time, mdio_phy_addr, mdio_reg_addr_f, mdio_reg_mux);
                        end
                    end else begin
                        // Write: data already in shift_reg[15:0]
                        bmcr   <= (mdio_reg_addr_f == 5'h00) ? mdio_shift_reg[15:0] : bmcr;
                        anar   <= (mdio_reg_addr_f == 5'h04) ? mdio_shift_reg[15:0] : anar;
                        mdio_state <= MDIO_IDLE;
                        if (VERBOSE)
                            $display("[%0t] MDIO WRITE: PHY=%0d REG=0x%02h DATA=0x%04h",
                                $time, mdio_phy_addr, mdio_reg_addr_f, mdio_shift_reg[15:0]);
                    end
                end

                default: mdio_state <= MDIO_IDLE;
            endcase
        end
    end

    // =========================================================================
    // MII TX Capture — log frames transmitted by MAC
    // =========================================================================
    integer tx_log_fd;
    reg [3:0] tx_nibble_buf [0:2047];
    integer   tx_nibble_cnt;
    reg       tx_in_frame;

    initial begin
        tx_log_fd = $fopen(TX_LOGFILE, "w");
        tx_nibble_cnt = 0;
        tx_in_frame = 0;
    end

    always @(posedge mtx_clk_o or negedge resetn) begin
        if (!resetn) begin
            tx_nibble_cnt <= 0;
            tx_in_frame   <= 0;
        end else begin
            if (mtxen_i) begin
                if (!tx_in_frame) begin
                    tx_in_frame <= 1;
                    tx_nibble_cnt <= 0;
                    $fwrite(tx_log_fd, "\n--- TX Frame Start [%0t] ---\n", $time);
                end
                tx_nibble_buf[tx_nibble_cnt] <= mtxd_i;
                tx_nibble_cnt <= tx_nibble_cnt + 1;
                if (VERBOSE)
                    $fwrite(tx_log_fd, "  nibble[%0d] = %h\n", tx_nibble_cnt, mtxd_i);
            end else if (tx_in_frame) begin
                // Frame ended
                tx_in_frame <= 0;
                $fwrite(tx_log_fd, "--- TX Frame End: %0d nibbles ---\n", tx_nibble_cnt);
                $fflush(tx_log_fd);
                tx_nibble_cnt <= 0;
            end
        end
    end

    // =========================================================================
    // MII RX Injection — send frames to MAC
    // =========================================================================
    // Frames are injected via send_rx_frame task or loaded from hex file.
    // Each frame is preceded by 7 bytes preamble (0x55) + SFD (0xD5).
    // Frame data is driven nibble-by-nibble on mrx_clk_o rising edges.

    reg [7:0] rx_frame_buf [0:2047];  // byte-wide frame buffer
    integer   rx_frame_len;            // frame length in bytes

    // RX injection state
    reg       rx_active;
    reg [3:0] rx_nibble_data;
    reg       rx_nibble_valid;

    initial begin
        mrxd_o   = 4'h0;
        mrxdv_o  = 1'b0;
        mrxerr_o = 1'b0;
        rx_active    = 0;
        rx_nibble_valid = 0;
    end

    // MII RX bit period = 40 ns for 100 Mbps (25 MHz clock)
    localparam MII_RX_BIT_PERIOD_NS = 40;
    // Drive MII RX signals on mrx_clk_o rising edges
    always @(posedge mrx_clk_o or negedge resetn) begin
        if (!resetn) begin
            mrxd_o   <= 4'h0;
            mrxdv_o  <= 1'b0;
            mrxerr_o <= 1'b0;
        end else if (loopback_mode) begin
            // Loopback overrides RX injection
            mrxd_o   <= mtxd_i;
            mrxdv_o  <= mtxen_i;
            mrxerr_o <= mtxerr_i;
        end else if (rx_nibble_valid) begin
            mrxd_o  <= rx_nibble_data;
            mrxdv_o <= 1'b1;
        end else if (rx_active) begin
            mrxdv_o <= 1'b0;
        end
    end

    // Task: send_rx_frame
    // Drives a frame onto MII RX with preamble + SFD.
    // frame_bytes: array of frame data bytes (excluding preamble/SFD/CRC).
    // frame_len:   number of bytes in frame.
    // inject_crc:  if 1, compute and append 4-byte CRC32 automatically.
    task send_rx_frame;
        input integer frame_len;
        input integer inject_crc;
        integer i, bit_idx;
        reg [31:0] crc;
        reg [7:0] byte_val;
        begin
            if (VERBOSE)
                $display("[%0t] MII RX: Injecting %0d byte frame", $time, frame_len);

            // Initialize CRC (all 1s)
            crc = 32'hFFFFFFFF;

            // Preamble: 7 bytes of 0x55
            for (i = 0; i < 7; i = i + 1) begin
                @(posedge mrx_clk_o);
                rx_nibble_data  <= 4'h5;
                rx_nibble_valid <= 1'b1;
                @(posedge mrx_clk_o);
                rx_nibble_data  <= 4'h5;
            end

            // SFD: 0xD5
            @(posedge mrx_clk_o);
            rx_nibble_data  <= 4'hD;
            @(posedge mrx_clk_o);
            rx_nibble_data  <= 4'h5;

            // Frame data
            for (i = 0; i < frame_len; i = i + 1) begin
                byte_val = rx_frame_buf[i];
                // CRC update (bit-by-bit, reflected)
                begin : crc_block
                    integer b;
                    reg crc_bit;
                    reg data_bit;
                    for (b = 0; b < 8; b = b + 1) begin
                        data_bit = byte_val[b];
                        crc_bit = crc[0] ^ data_bit;
                        crc[0]   = crc[1];
                        crc[1]   = crc[2];
                        crc[2]   = crc[3] ^ crc_bit;
                        crc[3]   = crc[4];
                        crc[4]   = crc[5];
                        crc[5]   = crc[6];
                        crc[6]   = crc[7];
                        crc[7]   = crc[8];
                        crc[8]   = crc[9];
                        crc[9]   = crc[10];
                        crc[10]  = crc[11] ^ crc_bit;
                        crc[11]  = crc[12];
                        crc[12]  = crc[13];
                        crc[13]  = crc[14];
                        crc[14]  = crc[15];
                        crc[15]  = crc[16] ^ crc_bit;
                        crc[16]  = crc[17];
                        crc[17]  = crc[18];
                        crc[18]  = crc[19];
                        crc[19]  = crc[20];
                        crc[20]  = crc[21];
                        crc[21]  = crc[22];
                        crc[22]  = crc[23] ^ crc_bit;
                        crc[23]  = crc[24];
                        crc[24]  = crc[25];
                        crc[25]  = crc[26];
                        crc[26]  = crc[27];
                        crc[27]  = crc[28];
                        crc[28]  = crc[29];
                        crc[29]  = crc[30];
                        crc[30]  = crc[31] ^ crc_bit;
                        crc[31]  = crc_bit;
                    end
                end
                // Drive upper nibble
                @(posedge mrx_clk_o);
                rx_nibble_data  <= byte_val[7:4];
                rx_nibble_valid <= 1'b1;
                // Drive lower nibble
                @(posedge mrx_clk_o);
                rx_nibble_data  <= byte_val[3:0];
            end

            // Append CRC32 if requested
            if (inject_crc) begin
                crc = ~crc;
                // CRC byte 0 (bits [7:0])
                @(posedge mrx_clk_o);
                rx_nibble_data  <= crc[3:0];
                @(posedge mrx_clk_o);
                rx_nibble_data  <= crc[7:4];
                // CRC byte 1 (bits [15:8])
                @(posedge mrx_clk_o);
                rx_nibble_data  <= crc[11:8];
                @(posedge mrx_clk_o);
                rx_nibble_data  <= crc[15:12];
                // CRC byte 2 (bits [23:16])
                @(posedge mrx_clk_o);
                rx_nibble_data  <= crc[19:16];
                @(posedge mrx_clk_o);
                rx_nibble_data  <= crc[23:20];
                // CRC byte 3 (bits [31:24])
                @(posedge mrx_clk_o);
                rx_nibble_data  <= crc[27:24];
                @(posedge mrx_clk_o);
                rx_nibble_data  <= crc[31:28];
            end

            // End of frame — deassert DV
            @(posedge mrx_clk_o);
            rx_nibble_valid <= 1'b0;
            rx_nibble_data  <= 4'h0;
            @(posedge mrx_clk_o);

            if (VERBOSE)
                $display("[%0t] MII RX: Frame injection complete", $time);
        end
    endtask

    // =========================================================================
    // RX Frame Loading — load from hex file at start of simulation
    // =========================================================================
    // File format: one byte per line (hex), blank lines and // comments ignored.
    // The first frame in the file is injected after a configurable delay.
    // Set RX_FRAME_FILE to "" to disable automatic injection.
    parameter RX_FRAME_FILE = "";
    parameter RX_INJECT_DELAY_NS = 1_000_000; // 1 us after reset release

    initial begin
        integer fd, status, byte_count;
        reg [7:0] tmp_byte;

        if (RX_FRAME_FILE != "") begin
            fd = $fopen(RX_FRAME_FILE, "r");
            if (fd != 0) begin
                byte_count = 0;
                while (!$feof(fd) && byte_count < 2048) begin
                    status = $fscanf(fd, "%h\n", tmp_byte);
                    if (status == 1) begin
                        rx_frame_buf[byte_count] = tmp_byte;
                        byte_count = byte_count + 1;
                    end
                end
                $fclose(fd);
                rx_frame_len = byte_count;

                // Wait for reset release then inject
                @(posedge resetn);
                #(RX_INJECT_DELAY_NS);

                if (rx_frame_len > 0) begin
                    send_rx_frame(rx_frame_len, 1);  // 1 = auto-append CRC
                end
            end else begin
                $display("[%0t] MII RX: WARNING - Could not open %s", $time, RX_FRAME_FILE);
            end
        end
    end

    // =========================================================================
    // Collision / Carrier Sense — tie low for half-duplex testing
    // =========================================================================
    initial begin
        mcoll_o = 1'b0;
        mcrs_o  = 1'b0;
    end

    // =========================================================================
    // Loopback Mode — when BMCR[14] is set, echo TX back as RX
    // =========================================================================
    assign loopback_mode = bmcr[14];

    // Cleanup
    final begin
        $fclose(tx_log_fd);
    end

endmodule
