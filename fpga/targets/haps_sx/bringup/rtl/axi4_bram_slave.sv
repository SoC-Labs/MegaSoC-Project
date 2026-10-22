//-----------------------------------------------------------------------------
// AXI4 block-RAM slave (FPGA bring-up only)
//
// 2026-10-14: stands in for the DRAM on the HAPS build (NIC-400 target "DRAM",
// 0x8000_0000) so that test programs can be loaded over the console UART by the
// monitor boot ROM and executed from RAM, independent of the QSPI flash.
// Same port list as axi4_error_slave so it is a drop-in replacement.
//
//  * MEM_KB kilobytes of 64-bit block RAM (default 512), one array per byte lane so
//    WSTRB maps onto plain per-lane write enables. Each lane is a separate variable:
//    Vivado refuses a single array above 1 Mbit (Synth 8-4556), so 512 KB = 8 x 512 Kbit.
//  * One outstanding read and one outstanding write; INCR, WRAP and FIXED bursts;
//    narrow transfers return the full 64-bit word (lanes selected by the master).
//  * The window aliases: only ADDR bits [ADDR_BITS+2:3] index the RAM.
//  * Read data registered: RVALID/RDATA one cycle after AR accept / each beat.
//  * Write data may arrive before, with, or after the address (all three verified in tb_bram.sv).
//
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
// Contributors: Anastasios Dimitriou (ad1u25@soton.ac.uk)
//-----------------------------------------------------------------------------
module axi4_bram_slave #(
    parameter ID_W   = 9,
    parameter DATA_W = 64,
    parameter ADDR_W = 33,
    parameter MEM_KB = 512,
    parameter BD_BIT = 19          // address bit that selects the backdoor region (second MEM_KB window)
)(
    input  wire ACLK,
    input  wire ARESETn,
    input  wire             AWVALID,
    output wire             AWREADY,
    input  wire [ID_W-1:0]  AWID,
    input  wire [ADDR_W-1:0] AWADDR,
    input  wire [7:0]       AWLEN,
    input  wire [2:0]       AWSIZE,
    input  wire [1:0]       AWBURST,
    input  wire             AWLOCK,
    input  wire [3:0]       AWCACHE,
    input  wire [2:0]       AWPROT,
    input  wire             WVALID,
    output wire             WREADY,
    input  wire [DATA_W-1:0] WDATA,
    input  wire [(DATA_W/8)-1:0] WSTRB,
    input  wire             WLAST,
    output reg              BVALID,
    input  wire             BREADY,
    output reg  [ID_W-1:0]  BID,
    output wire [1:0]       BRESP,
    input  wire             ARVALID,
    output wire             ARREADY,
    input  wire [ID_W-1:0]  ARID,
    input  wire [ADDR_W-1:0] ARADDR,
    input  wire [7:0]       ARLEN,
    input  wire [2:0]       ARSIZE,
    input  wire [1:0]       ARBURST,
    input  wire             ARLOCK,
    input  wire [3:0]       ARCACHE,
    input  wire [2:0]       ARPROT,
    output reg              RVALID,
    input  wire             RREADY,
    output reg  [ID_W-1:0]  RID,
    output wire [DATA_W-1:0] RDATA,
    output wire [1:0]       RRESP,
    output reg              RLAST,
    // 2026-10-15 (build 49): backdoor to a second memory (the flash emulator's store).
    // Accesses with ADDR[BD_BIT] = 1 go here instead of the internal RAM; same timing
    // (write in the beat cycle, read data registered by the far side in the fetch cycle).
    output wire             bd_we,
    output wire             bd_re,
    output wire [15:0]      bd_addr,
    output wire [63:0]      bd_wdata,
    output wire [7:0]       bd_wstrb,
    input  wire [63:0]      bd_rdata
);
    localparam DEPTH     = MEM_KB * 1024 / 8;
    localparam ADDR_BITS = $clog2(DEPTH);
    assign BRESP = 2'b00;
    assign RRESP = 2'b00;

    // ---- burst address stepping (AXI4 A3.4.1) ----
    function automatic [ADDR_W-1:0] next_addr(input [ADDR_W-1:0] a, input [2:0] size, input [1:0] burst, input [7:0] len);
        reg [ADDR_W-1:0] inc, wrap_mask;
        begin
            inc       = {{(ADDR_W-1){1'b0}}, 1'b1} << size;
            wrap_mask = ((len + 1) << size) - 1;               // len+1 is a power of two for WRAP
            case (burst)
                2'b00:   next_addr = a;                                              // FIXED
                2'b10:   next_addr = (a & ~wrap_mask) | ((a + inc) & wrap_mask);     // WRAP
                default: next_addr = a + inc;                                        // INCR
            endcase
        end
    endfunction

    // ---- memory: 8 byte lanes, one array each (see header) ----
    reg [ADDR_W-1:0] waddr, raddr;
    reg [7:0]        wlen, rlen;
    reg [2:0]        wsize, rsize;
    reg [1:0]        wburst, rburst;
    reg [ID_W-1:0]   wid;
    reg [63:0]       rdata_reg;
    reg              r_sel_bd;
    assign RDATA = r_sel_bd ? bd_rdata : rdata_reg;

    // ---- read fetch strobes (used by both paths) ----
    localparam R_IDLE = 1'b0, R_DATA = 1'b1;
    reg r_state;
    wire              r_fetch_first = ARVALID && ARREADY;
    wire              r_fetch_next  = (r_state == R_DATA) && RVALID && RREADY && !RLAST;
    wire [ADDR_W-1:0] r_fetch_addr  = r_fetch_first ? ARADDR : raddr;
    wire              r_fetch       = r_fetch_first || r_fetch_next;

    // ---- write path ----
    localparam [1:0] W_IDLE = 2'd0, W_DATA = 2'd1, W_RESP = 2'd2;
    reg [1:0] w_state;
    // 2026-10-15 (build 49): reads and writes are serialised (a write burst and a read burst
    // never overlap) because the backdoor to the flash emulator has a single port for both.
    // Write wins when both arrive in the same idle cycle.
    assign AWREADY = (w_state == W_IDLE) && (r_state == R_IDLE);
    assign WREADY  = ((w_state == W_IDLE) && AWVALID && (r_state == R_IDLE)) || (w_state == W_DATA);
    wire [ADDR_W-1:0] w_cur_addr = (w_state == W_IDLE) ? AWADDR : waddr;
    wire              w_beat     = WVALID && WREADY;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            w_state <= W_IDLE; BVALID <= 1'b0; BID <= '0; wid <= '0;
            waddr <= '0; wlen <= '0; wsize <= '0; wburst <= '0;
        end else begin
            case (w_state)
                W_IDLE: begin
                    BVALID <= 1'b0;
                    if (AWVALID && AWREADY) begin
                        wid <= AWID; wlen <= AWLEN; wsize <= AWSIZE; wburst <= AWBURST;
                        // 2026-10-15 (build 48): advance to the second beat only if the first
                        // beat is consumed in this same cycle. Build 47 always advanced here, so
                        // a first beat arriving one or more cycles after the address was stored
                        // at address+size: 16-bit stores to bytes 6-7 and 32-bit stores at +4
                        // landed in the next word (found on hardware with the UART loader).
                        waddr <= WVALID ? next_addr(AWADDR, AWSIZE, AWBURST, AWLEN) : AWADDR;
                        if (WVALID && WLAST) begin
                            w_state <= W_RESP; BVALID <= 1'b1; BID <= AWID;
                        end else begin
                            w_state <= W_DATA;
                        end
                    end
                end
                W_DATA: begin
                    if (w_beat) begin
                        waddr <= next_addr(waddr, wsize, wburst, wlen);
                        if (WLAST) begin w_state <= W_RESP; BVALID <= 1'b1; BID <= wid; end
                    end
                end
                W_RESP: begin
                    if (BVALID && BREADY) begin BVALID <= 1'b0; w_state <= W_IDLE; end
                end
                default: w_state <= W_IDLE;
            endcase
        end
    end

    // ---- read path ----
    reg [7:0] r_cnt;
    assign ARREADY = (r_state == R_IDLE) && (w_state == W_IDLE) && !AWVALID;
    wire [ADDR_BITS-1:0] w_idx = w_cur_addr[ADDR_BITS+2:3];
    wire [ADDR_BITS-1:0] r_idx = r_fetch_addr[ADDR_BITS+2:3];
    wire w_bd = w_cur_addr[BD_BIT];
    wire r_bd = r_fetch_addr[BD_BIT];
    assign bd_we    = w_beat && w_bd;
    assign bd_re    = r_fetch && r_bd;
    assign bd_addr  = r_fetch ? r_fetch_addr[18:3] : w_cur_addr[18:3];   // never both: see AWREADY/ARREADY
    assign bd_wdata = WDATA;
    assign bd_wstrb = WSTRB;
    always @(posedge ACLK) if (r_fetch) r_sel_bd <= r_bd;
    genvar g;
    generate for (g = 0; g < 8; g = g + 1) begin : g_lane
        reg [7:0] lane [0:DEPTH-1];
        `ifdef SIM_ZERO_INIT
        // simulation only: block RAM powers up as zeros; without this a cache line fill of never-written words returns X
        initial for (int zi = 0; zi < (MEM_KB*1024/8); zi++) lane[zi] = 8'h00;
        `endif
        always @(posedge ACLK) begin
            if (w_beat && WSTRB[g] && !w_bd) lane[w_idx] <= WDATA[8*g +: 8];
            if (r_fetch && !r_bd)            rdata_reg[8*g +: 8] <= lane[r_idx];
        end
    end endgenerate
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            r_state <= R_IDLE; RVALID <= 1'b0; RLAST <= 1'b0; RID <= '0; r_cnt <= '0;
            raddr <= '0; rlen <= '0; rsize <= '0; rburst <= '0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    RVALID <= 1'b0; RLAST <= 1'b0;
                    if (r_fetch_first) begin
                        r_state <= R_DATA; RID <= ARID; r_cnt <= ARLEN;
                        rlen <= ARLEN; rsize <= ARSIZE; rburst <= ARBURST;
                        raddr <= next_addr(ARADDR, ARSIZE, ARBURST, ARLEN);
                        RVALID <= 1'b1; RLAST <= (ARLEN == 8'd0);
                    end
                end
                R_DATA: begin
                    if (RVALID && RREADY) begin
                        if (RLAST) begin
                            RVALID <= 1'b0; RLAST <= 1'b0; r_state <= R_IDLE;
                        end else begin
                            raddr <= next_addr(raddr, rsize, rburst, rlen);
                            r_cnt <= r_cnt - 8'd1;
                            RLAST <= (r_cnt == 8'd1);
                        end
                    end
                end
                default: r_state <= R_IDLE;
            endcase
        end
    end
endmodule
