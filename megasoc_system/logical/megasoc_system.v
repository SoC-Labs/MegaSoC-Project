//-----------------------------------------------------------------------------
// MegaSoC System
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// Daniel Newbrook (d.newbrook@soton.ac.uk)
// 
// Copyright � 2021-4, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
// Modules instantiated:
//  megasoc_tech_wrapper
//  expansion_subsystem_wrapper

`include "gen_defines.v"
module megasoc_system(
    input wire          CLK_IN,
    input wire          nRESET,

    // QSPI Signals
    output wire         QSPI_SCLK,
    output wire         QSPI_nCS,
    output wire [3:0]   QSPI_IO_o,
    input  wire [3:0]   QSPI_IO_i,
    output wire [3:0]   QSPI_IO_e,

    // UART signals
    input  wire         UARTRXD,
    output wire         UARTTXD,
    output wire         UARTTXEN,

    // DAP-LITE external signals
    input  wire         nTRST,
    input  wire         SWCLKTCK,
    input  wire         SWDITMS,
    input  wire         TDI,
    output wire         TDO,
    output wire         nTDOEN,
    output wire         SWDO,
    output wire         SWDOEN


);

wire [1:0]      AXI_SYS_EXP_awid;
wire [31:0]     AXI_SYS_EXP_awaddr;
wire [7:0]      AXI_SYS_EXP_awlen;
wire [2:0]      AXI_SYS_EXP_awsize;
wire [1:0]      AXI_SYS_EXP_awburst;
wire            AXI_SYS_EXP_awlock;
wire [3:0]      AXI_SYS_EXP_awcache;
wire [2:0]      AXI_SYS_EXP_awprot;
wire            AXI_SYS_EXP_awvalid;
wire            AXI_SYS_EXP_awready;
wire [63:0]     AXI_SYS_EXP_wdata;
wire [7:0]      AXI_SYS_EXP_wstrb;
wire            AXI_SYS_EXP_wlast;
wire            AXI_SYS_EXP_wvalid;
wire            AXI_SYS_EXP_wready;
wire  [1:0]     AXI_SYS_EXP_bid;
wire  [1:0]     AXI_SYS_EXP_bresp;
wire            AXI_SYS_EXP_bvalid;
wire            AXI_SYS_EXP_bready;
wire [1:0]      AXI_SYS_EXP_arid;
wire [31:0]     AXI_SYS_EXP_araddr;
wire [7:0]      AXI_SYS_EXP_arlen;
wire [2:0]      AXI_SYS_EXP_arsize;
wire [1:0]      AXI_SYS_EXP_arburst;
wire            AXI_SYS_EXP_arlock;
wire [3:0]      AXI_SYS_EXP_arcache;
wire [2:0]      AXI_SYS_EXP_arprot;
wire            AXI_SYS_EXP_arvalid;
wire            AXI_SYS_EXP_arready;
wire  [1:0]     AXI_SYS_EXP_rid;
wire  [63:0]    AXI_SYS_EXP_rdata;
wire  [1:0]     AXI_SYS_EXP_rresp;
wire            AXI_SYS_EXP_rlast;
wire            AXI_SYS_EXP_rvalid;
wire            AXI_SYS_EXP_rready;

wire            AXI_EXP_SYS_awid;
wire  [31:0]    AXI_EXP_SYS_awaddr;
wire  [7:0]     AXI_EXP_SYS_awlen;
wire  [2:0]     AXI_EXP_SYS_awsize;
wire  [1:0]     AXI_EXP_SYS_awburst;
wire            AXI_EXP_SYS_awlock;
wire  [3:0]     AXI_EXP_SYS_awcache;
wire  [2:0]     AXI_EXP_SYS_awprot;
wire            AXI_EXP_SYS_awvalid;
wire            AXI_EXP_SYS_awready;
wire  [63:0]    AXI_EXP_SYS_wdata;
wire  [7:0]     AXI_EXP_SYS_wstrb;
wire            AXI_EXP_SYS_wlast;
wire            AXI_EXP_SYS_wvalid;
wire            AXI_EXP_SYS_wready;
wire            AXI_EXP_SYS_bid;
wire [1:0]      AXI_EXP_SYS_bresp;
wire            AXI_EXP_SYS_bvalid;
wire            AXI_EXP_SYS_bready;
wire            AXI_EXP_SYS_arid;
wire  [31:0]    AXI_EXP_SYS_araddr;
wire  [7:0]     AXI_EXP_SYS_arlen;
wire  [2:0]     AXI_EXP_SYS_arsize;
wire  [1:0]     AXI_EXP_SYS_arburst;
wire            AXI_EXP_SYS_arlock;
wire  [3:0]     AXI_EXP_SYS_arcache;
wire  [2:0]     AXI_EXP_SYS_arprot;
wire            AXI_EXP_SYS_arvalid;
wire            AXI_EXP_SYS_arready;
wire            AXI_EXP_SYS_rid;
wire [63:0]     AXI_EXP_SYS_rdata;
wire [1:0]      AXI_EXP_SYS_rresp;
wire            AXI_EXP_SYS_rlast;
wire            AXI_EXP_SYS_rvalid;
wire            AXI_EXP_SYS_rready;

megasoc_tech_wrapper u_megasoc_tech_wrapper(
    .SYS_CLK(CLK_IN),
    .SYS_CLKEN(1'b1),
    .SYS_RESETn(nRESET),

    // Millisoc system AXI Manager
    .AXI_SYS_EXP_awid(AXI_SYS_EXP_awid),
    .AXI_SYS_EXP_awaddr(AXI_SYS_EXP_awaddr),
    .AXI_SYS_EXP_awlen(AXI_SYS_EXP_awlen),
    .AXI_SYS_EXP_awsize(AXI_SYS_EXP_awsize),
    .AXI_SYS_EXP_awburst(AXI_SYS_EXP_awburst),
    .AXI_SYS_EXP_awlock(AXI_SYS_EXP_awlock),
    .AXI_SYS_EXP_awcache(AXI_SYS_EXP_awcache),
    .AXI_SYS_EXP_awprot(AXI_SYS_EXP_awprot),
    .AXI_SYS_EXP_awvalid(AXI_SYS_EXP_awvalid),
    .AXI_SYS_EXP_awready(AXI_SYS_EXP_awready),
    .AXI_SYS_EXP_wdata(AXI_SYS_EXP_wdata),
    .AXI_SYS_EXP_wstrb(AXI_SYS_EXP_wstrb),
    .AXI_SYS_EXP_wlast(AXI_SYS_EXP_wlast),
    .AXI_SYS_EXP_wvalid(AXI_SYS_EXP_wvalid),
    .AXI_SYS_EXP_wready(AXI_SYS_EXP_wready),
    .AXI_SYS_EXP_bid(AXI_SYS_EXP_bid),
    .AXI_SYS_EXP_bresp(AXI_SYS_EXP_bresp),
    .AXI_SYS_EXP_bvalid(AXI_SYS_EXP_bvalid),
    .AXI_SYS_EXP_bready(AXI_SYS_EXP_bready),
    .AXI_SYS_EXP_arid(AXI_SYS_EXP_arid),
    .AXI_SYS_EXP_araddr(AXI_SYS_EXP_araddr),
    .AXI_SYS_EXP_arlen(AXI_SYS_EXP_arlen),
    .AXI_SYS_EXP_arsize(AXI_SYS_EXP_arsize),
    .AXI_SYS_EXP_arburst(AXI_SYS_EXP_arburst),
    .AXI_SYS_EXP_arlock(AXI_SYS_EXP_arlock),
    .AXI_SYS_EXP_arcache(AXI_SYS_EXP_arcache),
    .AXI_SYS_EXP_arprot(AXI_SYS_EXP_arprot),
    .AXI_SYS_EXP_arvalid(AXI_SYS_EXP_arvalid),
    .AXI_SYS_EXP_arready(AXI_SYS_EXP_arready),
    .AXI_SYS_EXP_rid(AXI_SYS_EXP_rid),
    .AXI_SYS_EXP_rdata(AXI_SYS_EXP_rdata),
    .AXI_SYS_EXP_rresp(AXI_SYS_EXP_rresp),
    .AXI_SYS_EXP_rlast(AXI_SYS_EXP_rlast),
    .AXI_SYS_EXP_rvalid(AXI_SYS_EXP_rvalid),
    .AXI_SYS_EXP_rready(AXI_SYS_EXP_rready),
    

    // Millisoc system AXI Subordinate
    .AXI_EXP_SYS_awid(AXI_EXP_SYS_awid),
    .AXI_EXP_SYS_awaddr(AXI_EXP_SYS_awaddr),
    .AXI_EXP_SYS_awlen(AXI_EXP_SYS_awlen),
    .AXI_EXP_SYS_awsize(AXI_EXP_SYS_awsize),
    .AXI_EXP_SYS_awburst(AXI_EXP_SYS_awburst),
    .AXI_EXP_SYS_awlock(AXI_EXP_SYS_awlock),
    .AXI_EXP_SYS_awcache(AXI_EXP_SYS_awcache),
    .AXI_EXP_SYS_awprot(AXI_EXP_SYS_awprot),
    .AXI_EXP_SYS_awvalid(AXI_EXP_SYS_awvalid),
    .AXI_EXP_SYS_awready(AXI_EXP_SYS_awready),
    .AXI_EXP_SYS_wdata(AXI_EXP_SYS_wdata),
    .AXI_EXP_SYS_wstrb(AXI_EXP_SYS_wstrb),
    .AXI_EXP_SYS_wlast(AXI_EXP_SYS_wlast),
    .AXI_EXP_SYS_wvalid(AXI_EXP_SYS_wvalid),
    .AXI_EXP_SYS_wready(AXI_EXP_SYS_wready),
    .AXI_EXP_SYS_bid(AXI_EXP_SYS_bid),
    .AXI_EXP_SYS_bresp(AXI_EXP_SYS_bresp),
    .AXI_EXP_SYS_bvalid(AXI_EXP_SYS_bvalid),
    .AXI_EXP_SYS_bready(AXI_EXP_SYS_bready),
    .AXI_EXP_SYS_arid(AXI_EXP_SYS_arid),
    .AXI_EXP_SYS_araddr(AXI_EXP_SYS_araddr),
    .AXI_EXP_SYS_arlen(AXI_EXP_SYS_arlen),
    .AXI_EXP_SYS_arsize(AXI_EXP_SYS_arsize),
    .AXI_EXP_SYS_arburst(AXI_EXP_SYS_arburst),
    .AXI_EXP_SYS_arlock(AXI_EXP_SYS_arlock),
    .AXI_EXP_SYS_arcache(AXI_EXP_SYS_arcache),
    .AXI_EXP_SYS_arprot(AXI_EXP_SYS_arprot),
    .AXI_EXP_SYS_arvalid(AXI_EXP_SYS_arvalid),
    .AXI_EXP_SYS_arready(AXI_EXP_SYS_arready),
    .AXI_EXP_SYS_rid(AXI_EXP_SYS_rid),
    .AXI_EXP_SYS_rdata(AXI_EXP_SYS_rdata),
    .AXI_EXP_SYS_rresp(AXI_EXP_SYS_rresp),
    .AXI_EXP_SYS_rlast(AXI_EXP_SYS_rlast),
    .AXI_EXP_SYS_rvalid(AXI_EXP_SYS_rvalid),
    .AXI_EXP_SYS_rready(AXI_EXP_SYS_rready),
    .QSPI_SCLK(QSPI_SCLK),
    .QSPI_nCS(QSPI_nCS),
    .QSPI_IO_o(QSPI_IO_o),
    .QSPI_IO_i(QSPI_IO_i),
    .QSPI_IO_e(QSPI_IO_e),
    .UARTRXD(UARTRXD),
    .UARTTXD(UARTTXD),
    .UARTTXEN(UARTTXEN),
    .nTRST(nTRST),
    .SWCLKTCK(SWCLKTCK),
    .SWDITMS(SWDITMS),
    .TDI(TDI),
    .TDO(TDO),
    .nTDOEN(nTDOEN),
    .SWDO(SWDO),
    .SWDOEN(SWDOEN)
);

`ifdef INC_EXP
expansion_subsystem_wrapper u_megasoc_expansion_wrapper(
    .sys_clk(),
    .resetn(),
    .exp_clk(),
    .exp_clken(),
    .expresetn(),

    // System Clock domain control
    .CSYSREQ_CD_sys(),
    .CSYSACK_CD_sys(),
    .CACTIVE_CD_sys(),

    // Expansion Clock domain control
    .CSYSREQ_CD_exp(),
    .CSYSACK_CD_exp(),
    .CACTIVE_CD_exp(),

    // AXI Expansion input port 
    .AXI_EXP_SS_awid(AXI_SYS_EXP_awid),
    .AXI_EXP_SS_awaddr(AXI_SYS_EXP_awaddr),
    .AXI_EXP_SS_awlen(AXI_SYS_EXP_awlen),
    .AXI_EXP_SS_awsize(AXI_SYS_EXP_awsize),
    .AXI_EXP_SS_awburst(AXI_SYS_EXP_awburst),
    .AXI_EXP_SS_awlock(AXI_SYS_EXP_awlock),
    .AXI_EXP_SS_awcache(AXI_SYS_EXP_awcache),
    .AXI_EXP_SS_awprot(AXI_SYS_EXP_awprot),
    .AXI_EXP_SS_awvalid(AXI_SYS_EXP_awvalid),
    .AXI_EXP_SS_awready(AXI_SYS_EXP_awready),
    .AXI_EXP_SS_wdata(AXI_SYS_EXP_wdata),
    .AXI_EXP_SS_wstrb(AXI_SYS_EXP_wstrb),
    .AXI_EXP_SS_wlast(AXI_SYS_EXP_wlast),
    .AXI_EXP_SS_wvalid(AXI_SYS_EXP_wvalid),
    .AXI_EXP_SS_wready(AXI_SYS_EXP_wready),
    .AXI_EXP_SS_bid(AXI_SYS_EXP_bid),
    .AXI_EXP_SS_bresp(AXI_SYS_EXP_bresp),
    .AXI_EXP_SS_bvalid(AXI_SYS_EXP_bvalid),
    .AXI_EXP_SS_bready(AXI_SYS_EXP_bready),
    .AXI_EXP_SS_arid(AXI_SYS_EXP_arid),
    .AXI_EXP_SS_araddr(AXI_SYS_EXP_araddr),
    .AXI_EXP_SS_arlen(AXI_SYS_EXP_arlen),
    .AXI_EXP_SS_arsize(AXI_SYS_EXP_arsize),
    .AXI_EXP_SS_arburst(AXI_SYS_EXP_arburst),
    .AXI_EXP_SS_arlock(AXI_SYS_EXP_arlock),
    .AXI_EXP_SS_arcache(AXI_SYS_EXP_arcache),
    .AXI_EXP_SS_arprot(AXI_SYS_EXP_arprot),
    .AXI_EXP_SS_arvalid(AXI_SYS_EXP_arvalid),
    .AXI_EXP_SS_arready(AXI_SYS_EXP_arready),
    .AXI_EXP_SS_rid(AXI_SYS_EXP_rid),
    .AXI_EXP_SS_rdata(AXI_SYS_EXP_rdata),
    .AXI_EXP_SS_rresp(AXI_SYS_EXP_rresp),
    .AXI_EXP_SS_rlast(AXI_SYS_EXP_rlast),
    .AXI_EXP_SS_rvalid(AXI_SYS_EXP_rvalid),
    .AXI_EXP_SS_rready(AXI_SYS_EXP_rready),

    // AXI System output port
    .AXI_SYS_awid(AXI_EXP_SYS_awid),
    .AXI_SYS_awaddr(AXI_EXP_SYS_awaddr),
    .AXI_SYS_awlen(AXI_EXP_SYS_awlen),
    .AXI_SYS_awsize(AXI_EXP_SYS_awsize),
    .AXI_SYS_awburst(AXI_EXP_SYS_awburst),
    .AXI_SYS_awlock(AXI_EXP_SYS_awlock),
    .AXI_SYS_awcache(AXI_EXP_SYS_awcache),
    .AXI_SYS_awprot(AXI_EXP_SYS_awprot),
    .AXI_SYS_awvalid(AXI_EXP_SYS_awvalid),
    .AXI_SYS_awready(AXI_EXP_SYS_awready),
    .AXI_SYS_wdata(AXI_EXP_SYS_wdata),
    .AXI_SYS_wstrb(AXI_EXP_SYS_wstrb),
    .AXI_SYS_wlast(AXI_EXP_SYS_wlast),
    .AXI_SYS_wvalid(AXI_EXP_SYS_wvalid),
    .AXI_SYS_wready(AXI_EXP_SYS_wready),
    .AXI_SYS_bid(AXI_EXP_SYS_bid),
    .AXI_SYS_bresp(AXI_EXP_SYS_bresp),
    .AXI_SYS_bvalid(AXI_EXP_SYS_bvalid),
    .AXI_SYS_bready(AXI_EXP_SYS_bready),
    .AXI_SYS_arid(AXI_EXP_SYS_arid),
    .AXI_SYS_araddr(AXI_EXP_SYS_araddr),
    .AXI_SYS_arlen(AXI_EXP_SYS_arlen),
    .AXI_SYS_arsize(AXI_EXP_SYS_arsize),
    .AXI_SYS_arburst(AXI_EXP_SYS_arburst),
    .AXI_SYS_arlock(AXI_EXP_SYS_arlock),
    .AXI_SYS_arcache(AXI_EXP_SYS_arcache),
    .AXI_SYS_arprot(AXI_EXP_SYS_arprot),
    .AXI_SYS_arvalid(AXI_EXP_SYS_arvalid),
    .AXI_SYS_arready(AXI_EXP_SYS_arready),
    .AXI_SYS_rid(AXI_EXP_SYS_rid),
    .AXI_SYS_rdata(AXI_EXP_SYS_rdata),
    .AXI_SYS_rresp(AXI_EXP_SYS_rresp),
    .AXI_SYS_rlast(AXI_EXP_SYS_rlast),
    .AXI_SYS_rvalid(AXI_EXP_SYS_rvalid),
    .AXI_SYS_rready(AXI_EXP_SYS_rready),

    // Interrupts
    .irq_dma_channel(),
    .irq_dma_comb_nonsec()
);
`else 
    assign AXI_EXP_SYS_rready=1'b0;
`endif
endmodule
