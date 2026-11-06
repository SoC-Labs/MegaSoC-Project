//-----------------------------------------------------------------------------
// MegaSoC Ethernet PHY bench model (MII loopback + MDIO register model)
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Copyright (C) 2026, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
// Purpose:
//  Simulation-only stand-in for an MII Ethernet PHY on the megasoc_chip_pads
//  ETH_* pins, used by INC_ETH builds of megasoc_tb and the UVM VIP bench.
//
//  MII:  external loopback. Every frame the MAC transmits comes straight back
//        on the receive side: RXD = TXD, RX_DV = TX_EN, RX_ER = TX_ER. TX_CLK
//        and RX_CLK are the same 25 MHz clock (100 Mb/s), running from time
//        0 (the MAC holds its MII-side logic in reset until these clocks
//        toggle). COL and CRS are 0, so the MAC must run full duplex
//        (MODER.FULLD = 1) or it flags lost carrier on every frame.
//        `loopback_en` = 0 cuts the loopback (RX side idle).
//  MDIO: pull-up on the bidirectional pin plus a Clause 22 register model at
//        PHY address PHY_ADDR (other addresses get no response: the bus
//        stays high, read data 0xFFFF). 32 x 16-bit registers:
//          0 BMCR    reset 0x3100, read/write, bit 15 (reset) self-clears
//          1 BMSR    0x786D read-only (100BASE-TX FD capable, link up,
//                    auto-negotiation complete)
//          2 PHYID1  PHY_ID1 read-only (bench value, not a real vendor OUI)
//          3 PHYID2  PHY_ID2 read-only
//          4 ANAR    reset 0x01E1, read/write
//          others    reset 0, read/write
//        Frame: preamble (optional: MIIMODER.NOPRE), ST 01, OP 10 read /
//        01 write, PHYAD, REGAD, TA, 16 data bits, MSB first. The model
//        samples the MAC's bits on rising MDC and drives read bits just after
//        the previous rising MDC edge, as an IEEE 802.3 PHY does.
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

// Compiled only in INC_ETH builds, so the default build has no extra
// top-level module (the file is in the bench flists unconditionally).
`ifdef INC_ETH

module megasoc_eth_phy_model #(
    parameter real      MII_CLK_HALF_NS = 20.0,      // 25 MHz
    parameter [4:0]     PHY_ADDR        = 5'd1,
    parameter [15:0]    PHY_ID1         = 16'h5A5A,
    parameter [15:0]    PHY_ID2         = 16'hC3C0
)(
    output reg          ETH_TX_CLK,
    input  wire [3:0]   ETH_TXD,
    input  wire         ETH_TX_EN,
    input  wire         ETH_TX_ER,
    output reg          ETH_RX_CLK,
    output wire [3:0]   ETH_RXD,
    output wire         ETH_RX_DV,
    output wire         ETH_RX_ER,
    output wire         ETH_COL,
    output wire         ETH_CRS,
    input  wire         ETH_MDC,
    inout  wire         ETH_MDIO
);

//--------------------------------------
// MII clocks and loopback
//--------------------------------------
bit loopback_en = 1'b1;

initial begin
    ETH_TX_CLK = 1'b0;
    forever #(MII_CLK_HALF_NS) ETH_TX_CLK = ~ETH_TX_CLK;
end

always @(ETH_TX_CLK) ETH_RX_CLK = ETH_TX_CLK;

// Small transport delay so RX never races the TX launch edge, whatever
// clock-to-output delay the MAC model has.
assign #2 ETH_RXD   = loopback_en ? ETH_TXD   : 4'h0;
assign #2 ETH_RX_DV = loopback_en ? ETH_TX_EN : 1'b0;
assign #2 ETH_RX_ER = loopback_en ? ETH_TX_ER : 1'b0;

assign ETH_COL = 1'b0;
assign ETH_CRS = 1'b0;

// Wire log: for every frame the MAC transmits, print the length (bytes
// after the SFD, including the FCS) and the first 16 bytes in wire order.
// Nibbles go out low nibble first. This is the bench-side evidence for the
// DMA byte-order check in eth_loopback_tests.
reg  [3:0]  tx_lo_nib;
reg         tx_nib_hi = 1'b0;   // next nibble is the high nibble of a byte
reg         tx_in_frame = 1'b0; // SFD seen
integer     tx_nbytes = 0;
reg  [7:0]  tx_head [0:15];
integer     tx_frames = 0;

always @(posedge ETH_TX_CLK) begin
    if (ETH_TX_EN) begin
        if (!tx_nib_hi) begin
            tx_lo_nib <= ETH_TXD;
            tx_nib_hi <= 1'b1;
        end else begin
            tx_nib_hi <= 1'b0;
            if (tx_in_frame) begin
                if (tx_nbytes < 16) tx_head[tx_nbytes] <= {ETH_TXD, tx_lo_nib};
                tx_nbytes <= tx_nbytes + 1;
            end else if ({ETH_TXD, tx_lo_nib} == 8'hD5) begin
                tx_in_frame <= 1'b1;
                tx_nbytes   <= 0;
            end
        end
    end else begin
        if (tx_in_frame) begin
            tx_frames = tx_frames + 1;
            $display("[%0t] ETH_PHY_MODEL: TX frame %0d, %0d bytes after SFD (incl. FCS), first bytes on the wire: %02h %02h %02h %02h %02h %02h  %02h %02h %02h %02h %02h %02h  %02h %02h  %02h %02h",
                     $time, tx_frames, tx_nbytes,
                     tx_head[0], tx_head[1], tx_head[2], tx_head[3], tx_head[4], tx_head[5],
                     tx_head[6], tx_head[7], tx_head[8], tx_head[9], tx_head[10], tx_head[11],
                     tx_head[12], tx_head[13], tx_head[14], tx_head[15]);
        end
        tx_in_frame <= 1'b0;
        tx_nib_hi   <= 1'b0;
        tx_nbytes   <= 0;
    end
end

//--------------------------------------
// MDIO
//--------------------------------------
pullup (ETH_MDIO);

reg        mdio_oe  = 1'b0;
reg        mdio_out = 1'b1;
assign ETH_MDIO = mdio_oe ? mdio_out : 1'bz;

reg [15:0] regs [0:31];

typedef enum {S_IDLE, S_ST, S_HDR, S_RD_TA, S_RD_DATA, S_WR_TA, S_WR_DATA} mdio_state_e;
mdio_state_e state = S_IDLE;

reg  [11:0] hdr;        // OP[1:0], PHYAD[4:0], REGAD[4:0]
reg  [4:0]  cnt;
reg  [15:0] shreg;
reg  [4:0]  regad;
reg         for_me;

integer i;
initial begin
    for (i = 0; i < 32; i = i + 1) regs[i] = 16'h0000;
    regs[0] = 16'h3100;
    regs[1] = 16'h786D;
    regs[2] = PHY_ID1;
    regs[3] = PHY_ID2;
    regs[4] = 16'h01E1;
end

function automatic bit reg_writable(input [4:0] a);
    return !(a == 5'd1 || a == 5'd2 || a == 5'd3);
endfunction

// Sample on rising MDC; any drive change happens 10 ns after the edge.
always @(posedge ETH_MDC) begin : mdio_fsm
    logic b;
    b = (ETH_MDIO === 1'b0) ? 1'b0 : 1'b1;   // pulled-up bus: Z/X read as 1
    case (state)
        S_IDLE:    if (b == 1'b0) state <= S_ST;          // ST bit 0 (after idle/preamble 1s)
        S_ST:      if (b == 1'b1) begin state <= S_HDR; cnt <= 5'd0; end
                   else           state <= S_IDLE;
        S_HDR: begin
            hdr <= {hdr[10:0], b};
            cnt <= cnt + 5'd1;
            if (cnt == 5'd11) begin
                regad  <= {hdr[3:0], b};
                for_me <= (hdr[8:4] == PHY_ADDR);
                cnt    <= 5'd0;
                if (hdr[10:9] == 2'b10) begin              // read
                    state <= S_RD_TA;
                    shreg <= regs[{hdr[3:0], b}];
                end else if (hdr[10:9] == 2'b01) begin     // write
                    state <= S_WR_TA;
                end else
                    state <= S_IDLE;
            end
        end
        // Read: TA bit 1 both sides Z; TA bit 2 PHY drives 0 (set up here,
        // after the rising edge that sampled TA bit 1's predecessor).
        S_RD_TA: begin
            if (for_me) begin mdio_out <= #10 1'b0; mdio_oe <= #10 1'b1; end
            state <= S_RD_DATA;
            cnt   <= 5'd0;
        end
        S_RD_DATA: begin
            if (for_me) mdio_out <= #10 shreg[15];
            shreg <= {shreg[14:0], 1'b0};
            cnt   <= cnt + 5'd1;
            if (cnt == 5'd16) begin
                mdio_oe <= #10 1'b0;                      // release after D0
                state   <= S_IDLE;
            end
        end
        S_WR_TA: begin                                    // MAC drives 1,0
            cnt <= cnt + 5'd1;
            if (cnt == 5'd1) begin state <= S_WR_DATA; cnt <= 5'd0; end
        end
        S_WR_DATA: begin
            shreg <= {shreg[14:0], b};
            cnt   <= cnt + 5'd1;
            if (cnt == 5'd15) begin
                if (for_me && reg_writable(regad)) begin
                    regs[regad] <= (regad == 5'd0) ? ({shreg[14:0], b} & 16'h7FFF)   // BMCR reset self-clears
                                                   : {shreg[14:0], b};
                    $display("[%0t] ETH_PHY_MODEL: MDIO write reg %0d = 0x%04h", $time, regad, {shreg[14:0], b});
                end
                state <= S_IDLE;
            end
        end
    endcase
end

// Read data is driven one bit per MDC period: TA bit 2 then D15..D0. The
// S_RD_TA edge drives TA2; S_RD_DATA edges cnt 0..15 drive D15..D0; the edge
// with cnt 16 releases the bus.

always @(posedge ETH_MDC)
    if (state == S_HDR && cnt == 5'd11 && hdr[10:9] == 2'b10 && hdr[8:4] == PHY_ADDR)
        $display("[%0t] ETH_PHY_MODEL: MDIO read  reg %0d = 0x%04h", $time,
                 {hdr[3:0], ((ETH_MDIO === 1'b0) ? 1'b0 : 1'b1)}, regs[{hdr[3:0], ((ETH_MDIO === 1'b0) ? 1'b0 : 1'b1)}]);

endmodule

`endif // INC_ETH
