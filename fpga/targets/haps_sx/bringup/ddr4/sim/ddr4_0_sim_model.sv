`timescale 1ps/1ps
// Behavioural stand-in for the Xilinx DDR4 IP (same module name and ports as the generated ddr4_0) for simulating
// haps_ddr4_bridge: 266.5 MHz ui_clk, ui_clk_sync_rst for 50 cycles after sys_rst, init_calib_complete 3 us later,
// a 512-bit AXI4 slave with a sparse 64-byte-line memory, one transaction at a time per direction, INCR/WRAP/FIXED
// bursts, byte strobes, and a slow handshake pattern (ready withheld on some cycles) to exercise the converters.
module ddr4_0 (
    input  wire         sys_rst, input wire c0_sys_clk_p, input wire c0_sys_clk_n,
    output wire         c0_init_calib_complete, output wire dbg_clk, output wire [511:0] dbg_bus,
    output wire [16:0]  c0_ddr4_adr, output wire [1:0] c0_ddr4_ba, output wire [1:0] c0_ddr4_cke, output wire [1:0] c0_ddr4_cs_n,
    inout  wire [7:0]   c0_ddr4_dm_dbi_n, inout wire [63:0] c0_ddr4_dq, inout wire [7:0] c0_ddr4_dqs_c, inout wire [7:0] c0_ddr4_dqs_t,
    output wire [1:0]   c0_ddr4_odt, output wire [1:0] c0_ddr4_bg, output wire c0_ddr4_reset_n, output wire c0_ddr4_act_n,
    output wire [1:0]   c0_ddr4_ck_c, output wire [1:0] c0_ddr4_ck_t,
    output wire         c0_ddr4_ui_clk, output wire c0_ddr4_ui_clk_sync_rst, input wire c0_ddr4_aresetn,
    input  wire [0:0]   c0_ddr4_s_axi_awid, input wire [33:0] c0_ddr4_s_axi_awaddr, input wire [7:0] c0_ddr4_s_axi_awlen,
    input  wire [2:0]   c0_ddr4_s_axi_awsize, input wire [1:0] c0_ddr4_s_axi_awburst, input wire [0:0] c0_ddr4_s_axi_awlock,
    input  wire [3:0]   c0_ddr4_s_axi_awcache, input wire [2:0] c0_ddr4_s_axi_awprot, input wire [3:0] c0_ddr4_s_axi_awqos,
    input  wire         c0_ddr4_s_axi_awvalid, output reg c0_ddr4_s_axi_awready,
    input  wire [511:0] c0_ddr4_s_axi_wdata, input wire [63:0] c0_ddr4_s_axi_wstrb, input wire c0_ddr4_s_axi_wlast,
    input  wire         c0_ddr4_s_axi_wvalid, output reg c0_ddr4_s_axi_wready,
    input  wire         c0_ddr4_s_axi_bready, output reg [0:0] c0_ddr4_s_axi_bid, output reg [1:0] c0_ddr4_s_axi_bresp, output reg c0_ddr4_s_axi_bvalid,
    input  wire [0:0]   c0_ddr4_s_axi_arid, input wire [33:0] c0_ddr4_s_axi_araddr, input wire [7:0] c0_ddr4_s_axi_arlen,
    input  wire [2:0]   c0_ddr4_s_axi_arsize, input wire [1:0] c0_ddr4_s_axi_arburst, input wire [0:0] c0_ddr4_s_axi_arlock,
    input  wire [3:0]   c0_ddr4_s_axi_arcache, input wire [2:0] c0_ddr4_s_axi_arprot, input wire [3:0] c0_ddr4_s_axi_arqos,
    input  wire         c0_ddr4_s_axi_arvalid, output reg c0_ddr4_s_axi_arready,
    input  wire         c0_ddr4_s_axi_rready, output reg c0_ddr4_s_axi_rlast, output reg c0_ddr4_s_axi_rvalid,
    output reg [1:0]    c0_ddr4_s_axi_rresp, output reg [0:0] c0_ddr4_s_axi_rid, output reg [511:0] c0_ddr4_s_axi_rdata
);
    // ---- clocks / reset / calibration ----
    reg clk = 0; always #1876 clk = ~clk;          // 3.752 ns
    assign c0_ddr4_ui_clk = clk;
    integer rst_cnt = 0; reg rst_r = 1; reg calib_r = 0; integer cal_cnt = 0;
    always @(posedge clk or posedge sys_rst)
        if (sys_rst) begin rst_cnt <= 0; rst_r <= 1; cal_cnt <= 0; calib_r <= 0; end
        else begin
            if (rst_cnt < 50) rst_cnt <= rst_cnt + 1; else rst_r <= 0;
            if (!rst_r) begin if (cal_cnt < 800) cal_cnt <= cal_cnt + 1; else calib_r <= 1; end   // ~3 us after reset
        end
    assign c0_ddr4_ui_clk_sync_rst = rst_r;
    assign c0_init_calib_complete  = calib_r;
    assign dbg_clk = 1'b0; assign dbg_bus = '0;
    assign c0_ddr4_adr = '0; assign c0_ddr4_ba = '0; assign c0_ddr4_cke = '0; assign c0_ddr4_cs_n = '1; assign c0_ddr4_odt = '0;
    assign c0_ddr4_bg = '0; assign c0_ddr4_reset_n = ~sys_rst; assign c0_ddr4_act_n = 1'b1; assign c0_ddr4_ck_c = '1; assign c0_ddr4_ck_t = '0;

    // ---- memory: 64-byte lines keyed by address[33:6] ----
    logic [511:0] mem [bit [27:0]];
    function automatic [511:0] line_rd(input [33:0] a);
        bit [27:0] k = a[33:6];
        if (mem.exists(k)) return mem[k];
        return {8{32'hC0DE_0000 | k[15:0], 32'hFEED_0000 | k[27:12]}};    // deterministic "unwritten" content
    endfunction
    function automatic [33:0] next_addr(input [33:0] a, input [2:0] size, input [1:0] burst, input [7:0] len);
        reg [33:0] inc, aligned, wrap_mask;
        inc = 34'd1 << size; aligned = (a >> size) << size;
        wrap_mask = ((34'(len) + 1) << size) - 1;
        case (burst)
            2'b00: next_addr = a;
            2'b10: next_addr = (aligned & ~wrap_mask) | ((aligned + inc) & wrap_mask);
            default: next_addr = aligned + inc;
        endcase
    endfunction
    // handshake pacing: ready only on cycles where a 3-bit counter is != 3 (random-ish stalls)
    reg [2:0] pace = 0; always @(posedge clk) pace <= pace + 1;

    // ---- write path ----
    reg [33:0] waddr; reg [7:0] wlen; reg [2:0] wsize; reg [1:0] wburst; reg [0:0] wid;
    reg w_busy = 0, w_resp = 0;
    integer i;
    always @(posedge clk) begin
        if (!c0_ddr4_aresetn) begin
            w_busy <= 0; w_resp <= 0; c0_ddr4_s_axi_awready <= 0; c0_ddr4_s_axi_wready <= 0; c0_ddr4_s_axi_bvalid <= 0;
        end else begin
            c0_ddr4_s_axi_awready <= !w_busy && !w_resp && (pace != 3);
            if (c0_ddr4_s_axi_awvalid && c0_ddr4_s_axi_awready) begin
                waddr <= c0_ddr4_s_axi_awaddr; wlen <= c0_ddr4_s_axi_awlen; wsize <= c0_ddr4_s_axi_awsize;
                wburst <= c0_ddr4_s_axi_awburst; wid <= c0_ddr4_s_axi_awid; w_busy <= 1; c0_ddr4_s_axi_awready <= 0;
                if (c0_ddr4_s_axi_awaddr[33]) $display("%t MODEL: write with address bit 33 set (%h) - bridge should never do this", $time, c0_ddr4_s_axi_awaddr);
            end
            c0_ddr4_s_axi_wready <= w_busy && (pace != 5);
            if (w_busy && c0_ddr4_s_axi_wvalid && c0_ddr4_s_axi_wready) begin
                for (i = 0; i < 64; i = i + 1) if (c0_ddr4_s_axi_wstrb[i]) begin
                    if (!mem.exists(waddr[33:6])) mem[waddr[33:6]] = line_rd(waddr);
                    mem[waddr[33:6]][i*8 +: 8] = c0_ddr4_s_axi_wdata[i*8 +: 8];
                end
                waddr <= next_addr(waddr, wsize, wburst, wlen);
                if (c0_ddr4_s_axi_wlast) begin w_busy <= 0; w_resp <= 1; c0_ddr4_s_axi_wready <= 0; end
            end
            if (w_resp && !c0_ddr4_s_axi_bvalid && (pace != 1)) begin c0_ddr4_s_axi_bvalid <= 1; c0_ddr4_s_axi_bid <= wid; c0_ddr4_s_axi_bresp <= 2'b00; end
            if (c0_ddr4_s_axi_bvalid && c0_ddr4_s_axi_bready) begin c0_ddr4_s_axi_bvalid <= 0; w_resp <= 0; end
        end
    end

    // ---- read path ----
    reg [33:0] raddr; reg [7:0] rlen, rcnt; reg [2:0] rsize; reg [1:0] rburst; reg [0:0] rid_r;
    reg r_busy = 0;
    always @(posedge clk) begin
        if (!c0_ddr4_aresetn) begin
            r_busy <= 0; c0_ddr4_s_axi_arready <= 0; c0_ddr4_s_axi_rvalid <= 0; c0_ddr4_s_axi_rlast <= 0;
        end else begin
            c0_ddr4_s_axi_arready <= !r_busy && (pace != 6);
            if (c0_ddr4_s_axi_arvalid && c0_ddr4_s_axi_arready) begin
                raddr <= c0_ddr4_s_axi_araddr; rlen <= c0_ddr4_s_axi_arlen; rcnt <= 0; rsize <= c0_ddr4_s_axi_arsize;
                rburst <= c0_ddr4_s_axi_arburst; rid_r <= c0_ddr4_s_axi_arid; r_busy <= 1; c0_ddr4_s_axi_arready <= 0;
                if (c0_ddr4_s_axi_araddr[33]) $display("%t MODEL: read with address bit 33 set (%h) - bridge should never do this", $time, c0_ddr4_s_axi_araddr);
            end
            if (r_busy && !c0_ddr4_s_axi_rvalid && (pace != 2)) begin
                c0_ddr4_s_axi_rvalid <= 1; c0_ddr4_s_axi_rdata <= line_rd(raddr); c0_ddr4_s_axi_rresp <= 2'b00;
                c0_ddr4_s_axi_rid <= rid_r; c0_ddr4_s_axi_rlast <= (rcnt == rlen);
            end
            if (c0_ddr4_s_axi_rvalid && c0_ddr4_s_axi_rready) begin
                c0_ddr4_s_axi_rvalid <= 0; raddr <= next_addr(raddr, rsize, rburst, rlen); rcnt <= rcnt + 1;
                if (c0_ddr4_s_axi_rlast) begin r_busy <= 0; c0_ddr4_s_axi_rlast <= 0; end
            end
        end
    end
endmodule
