//-----------------------------------------------------------------------------
// Expansion Subsystem Expansion Region
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// Daniel Newbrook (d.newbrook@soton.ac.uk)
// 
// Copyright � 2021-4, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------

module expansion_region(
    input  wire         clk,
    input  wire         resetn,
    input  wire [2:0]   AWID_AXI_EXPANSION,
    input  wire [31:0]  AWADDR_AXI_EXPANSION,
    input  wire [7:0]   AWLEN_AXI_EXPANSION,
    input  wire [2:0]   AWSIZE_AXI_EXPANSION,
    input  wire [1:0]   AWBURST_AXI_EXPANSION,
    input  wire         AWLOCK_AXI_EXPANSION,
    input  wire [3:0]   AWCACHE_AXI_EXPANSION,
    input  wire [2:0]   AWPROT_AXI_EXPANSION,
    input  wire         AWVALID_AXI_EXPANSION,
    output wire         AWREADY_AXI_EXPANSION,
    input  wire [127:0] WDATA_AXI_EXPANSION,
    input  wire [15:0]  WSTRB_AXI_EXPANSION,
    input  wire         WLAST_AXI_EXPANSION,
    input  wire         WVALID_AXI_EXPANSION,
    output wire         WREADY_AXI_EXPANSION,
    output wire  [2:0]  BID_AXI_EXPANSION,
    output wire  [1:0]  BRESP_AXI_EXPANSION,
    output wire         BVALID_AXI_EXPANSION,
    input  wire         BREADY_AXI_EXPANSION,
    input  wire [2:0]   ARID_AXI_EXPANSION,
    input  wire [31:0]  ARADDR_AXI_EXPANSION,
    input  wire [7:0]   ARLEN_AXI_EXPANSION,
    input  wire [2:0]   ARSIZE_AXI_EXPANSION,
    input  wire [1:0]   ARBURST_AXI_EXPANSION,
    input  wire         ARLOCK_AXI_EXPANSION,
    input  wire [3:0]   ARCACHE_AXI_EXPANSION,
    input  wire [2:0]   ARPROT_AXI_EXPANSION,
    input  wire         ARVALID_AXI_EXPANSION,
    output wire         ARREADY_AXI_EXPANSION,
    output wire [2:0]   RID_AXI_EXPANSION,
    output wire [127:0] RDATA_AXI_EXPANSION,
    output wire [1:0]   RRESP_AXI_EXPANSION,
    output wire         RLAST_AXI_EXPANSION,
    output wire         RVALID_AXI_EXPANSION,
    input  wire         RREADY_AXI_EXPANSION

);

assign AWREADY_AXI_EXPANSION=1'b1;
assign WREADY_AXI_EXPANSION = 1'b1;
assign BID_AXI_EXPANSION = 3'h0;
assign BRESP_AXI_EXPANSION = 2'h0;
assign BVALID_AXI_EXPANSION = 1'b1;
assign ARREADY_AXI_EXPANSION = 1'b1;
assign RID_AXI_EXPANSION = 3'h0;
assign RDATA_AXI_EXPANSION = 128'd0;
assign RRESP_AXI_EXPANSION = 2'h0;
assign RLAST_AXI_EXPANSION = 1'b1;


endmodule