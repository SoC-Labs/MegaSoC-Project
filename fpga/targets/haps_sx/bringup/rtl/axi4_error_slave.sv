//-----------------------------------------------------------------------------
// AXI4 Error Slave
// Returns DECERR (2'b11) for all read and write transactions.
// Properly handles AXI4 burst protocol (ARLEN for reads, sinks W beats
// before issuing B response for writes).
//
// Use on unused AXI ports (e.g. DRAM when no controller is present)
// so the CPU doesn't hang waiting for a response that never comes.
//
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//   Anastasios Dimitriou (ad1u25@soton.ac.uk)
//
// Copyright 2021-4, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------

module axi4_error_slave #(
    parameter ID_W   = 9,
    parameter DATA_W = 64,
    parameter ADDR_W = 33
)(
    input  wire ACLK,
    input  wire ARESETn,

    // AXI4 Write Address Channel
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

    // AXI4 Write Data Channel
    input  wire             WVALID,
    output wire             WREADY,
    input  wire [DATA_W-1:0] WDATA,
    input  wire [(DATA_W/8)-1:0] WSTRB,
    input  wire             WLAST,

    // AXI4 Write Response Channel
    output reg              BVALID,
    input  wire             BREADY,
    output reg  [ID_W-1:0]  BID,
    output wire [1:0]       BRESP,

    // AXI4 Read Address Channel
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

    // AXI4 Read Data Channel
    output reg              RVALID,
    input  wire             RREADY,
    output reg  [ID_W-1:0]  RID,
    output wire [DATA_W-1:0] RDATA,
    output wire [1:0]       RRESP,
    output reg              RLAST
);

    // Always return DECERR
    assign BRESP = 2'b11;
    assign RRESP = 2'b11;
    assign RDATA = {DATA_W{1'b0}};

    // -----------------------------------------------------------------------
    // Write path: accept AW, sink all W beats, respond B with DECERR
    // -----------------------------------------------------------------------
    localparam [1:0] W_IDLE = 2'd0,
                     W_SINK = 2'd1,
                     W_RESP = 2'd2;

    reg [1:0]       w_state;
    reg [ID_W-1:0]  w_id;

    assign AWREADY = (w_state == W_IDLE);
    // 2026-09-21: W_IDLE now additionally requires AWVALID.
    //
    // AXI4 explicitly allows a master to drive W beats before, or without, the
    // matching AW. With WREADY asserted unconditionally in W_IDLE, a WLAST
    // arriving ahead of AWVALID was accepted and discarded; when AW then
    // arrived, W_IDLE saw AWVALID && AWREADY with WVALID low, moved to W_SINK,
    // and waited forever for a WLAST that had already been consumed. BVALID
    // never asserted and the master hung permanently - the exact failure this
    // module exists to prevent.
    //
    // Waiting for AWVALID before asserting WREADY is legal (a slave may not
    // wait for WVALID before asserting AWREADY, but the converse is allowed).
    assign WREADY  = ((w_state == W_IDLE) && AWVALID) || (w_state == W_SINK);

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            w_state <= W_IDLE;
            w_id    <= {ID_W{1'b0}};
            BVALID  <= 1'b0;
            BID     <= {ID_W{1'b0}};
        end else begin
            case (w_state)
                W_IDLE: begin
                    BVALID <= 1'b0;
                    if (AWVALID && AWREADY) begin
                        w_id <= AWID;
                        if (WVALID && WLAST) begin
                            w_state <= W_RESP;
                            BVALID  <= 1'b1;
                            BID     <= AWID;
                        end else begin
                            w_state <= W_SINK;
                        end
                    end
                end

                W_SINK: begin
                    if (WVALID && WLAST) begin
                        w_state <= W_RESP;
                        BVALID  <= 1'b1;
                        BID     <= w_id;
                    end
                end

                W_RESP: begin
                    if (BVALID && BREADY) begin
                        BVALID  <= 1'b0;
                        w_state <= W_IDLE;
                    end
                end

                default: w_state <= W_IDLE;
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // Read path: accept AR, respond DECERR for every beat in the burst
    // -----------------------------------------------------------------------
    localparam R_IDLE = 1'b0,
               R_RESP = 1'b1;

    reg        r_state;
    reg [7:0]  r_cnt;

    assign ARREADY = (r_state == R_IDLE);

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            r_state <= R_IDLE;
            r_cnt   <= 8'd0;
            RVALID  <= 1'b0;
            RID     <= {ID_W{1'b0}};
            RLAST   <= 1'b0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    RVALID <= 1'b0;
                    RLAST  <= 1'b0;
                    if (ARVALID && ARREADY) begin
                        r_state <= R_RESP;
                        RID     <= ARID;
                        r_cnt   <= ARLEN;
                        RVALID  <= 1'b1;
                        RLAST   <= (ARLEN == 8'd0);
                    end
                end

                R_RESP: begin
                    if (RVALID && RREADY) begin
                        if (RLAST) begin
                            RVALID  <= 1'b0;
                            RLAST   <= 1'b0;
                            r_state <= R_IDLE;
                        end else begin
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
