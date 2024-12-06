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
    input  wire         CLK_IN,
    input  wire         RT_CLK, // 32kHz real time clock
    input  wire         nRESET,

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

    // FT1248 Signals
    output wire         FT_CLK_O,    // SCLK
    output wire         FT_SSN_O,    // SS_N
    input  wire         FT_MISO_I,   // MISO
    output wire         FT_MIOSIO_O, // MIOSIO tristate output when enabled
    output wire         FT_MIOSIO_E, // MIOSIO tristate output enable (active hi)
    output wire         FT_MIOSIO_Z, // MIOSIO tristate output enable (active lo)
    input  wire         FT_MIOSIO_I, // MIOSIO tristate input

    // DAP-LITE external signals
    input  wire         nTRST,
    input  wire         SWCLKTCK,
    input  wire         SWDITMS,
    input  wire         TDI,
    output wire         TDO,
    output wire         nTDOEN,
    output wire         SWDO,
    output wire         SWDOEN,

    input  wire [15:0]  P0_IN,
    output wire [15:0]  P0_OUT,
    output wire [15:0]  P0_EN,
    output wire [15:0]  P0_FUNC,

    input  wire [15:0]  P1_IN,
    output wire [15:0]  P1_OUT,
    output wire [15:0]  P1_EN,
    output wire [15:0]  P1_FUNC
);


// DMA 350 APB Interface Wires
wire [31:0]         PADDR_DMA_CTRL;
wire [31:0]         PWDATA_DMA_CTRL;
wire                PWRITE_DMA_CTRL;
wire [2:0]          PPROT_DMA_CTRL;
wire [3:0]          PSTRB_DMA_CTRL;
wire                PENABLE_DMA_CTRL;
wire                PSELx_DMA_CTRL;
wire [31:0]         PRDATA_DMA_CTRL;
wire                PSLVERR_DMA_CTRL;
wire                PREADY_DMA_CTRL;

// DMA 350 AXI Interface Wires
wire [1:0]          AWID_DMA350;
wire [43:0]         AWADDR_DMA350;
wire [7:0]          AWLEN_DMA350;
wire [2:0]          AWSIZE_DMA350;
wire [1:0]          AWBURST_DMA350;
wire                AWLOCK_DMA350;
wire [3:0]          AWCACHE_DMA350;
wire [2:0]          AWPROT_DMA350;
wire                AWVALID_DMA350;
wire                AWREADY_DMA350;

wire [127:0]        WDATA_DMA350;
wire [15:0]         WSTRB_DMA350;
wire                WLAST_DMA350;
wire                WVALID_DMA350;
wire                WREADY_DMA350;

wire [1:0]          BID_DMA350;
wire [1:0]          BRESP_DMA350;
wire                BVALID_DMA350;
wire                BREADY_DMA350;

wire [1:0]          ARID_DMA350;
wire [43:0]         ARADDR_DMA350;
wire [7:0]          ARLEN_DMA350;
wire [2:0]          ARSIZE_DMA350;
wire [1:0]          ARBURST_DMA350;
wire                ARLOCK_DMA350;
wire [3:0]          ARCACHE_DMA350;
wire [2:0]          ARPROT_DMA350;
wire                ARVALID_DMA350;
wire                ARREADY_DMA350;

wire [1:0]          RID_DMA350;
wire [127:0]        RDATA_DMA350;
wire [1:0]          RRESP_DMA350;
wire                RLAST_DMA350;
wire                RVALID_DMA350;
wire                RREADY_DMA350;

wire [3:0]              DMA350_irq_channel;
wire                    DMA350_irq_comb_nonsec;


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
    .RT_CLK(RT_CLK),
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


    .PADDR_DMA_CTRL(PADDR_DMA_CTRL),
    .PWDATA_DMA_CTRL(PWDATA_DMA_CTRL),
    .PWRITE_DMA_CTRL(PWRITE_DMA_CTRL),
    .PPROT_DMA_CTRL(PPROT_DMA_CTRL),
    .PSTRB_DMA_CTRL(PSTRB_DMA_CTRL),
    .PENABLE_DMA_CTRL(PENABLE_DMA_CTRL),
    .PSELx_DMA_CTRL(PSELx_DMA_CTRL),
    .PRDATA_DMA_CTRL(PRDATA_DMA_CTRL),
    .PSLVERR_DMA_CTRL(PSLVERR_DMA_CTRL),
    .PREADY_DMA_CTRL(PREADY_DMA_CTRL),

    .AWID_DMA350(AWID_DMA350),
    .AWADDR_DMA350(AWADDR_DMA350),
    .AWLEN_DMA350(AWLEN_DMA350),
    .AWSIZE_DMA350(AWSIZE_DMA350),
    .AWBURST_DMA350(AWBURST_DMA350),
    .AWLOCK_DMA350(AWLOCK_DMA350),
    .AWCACHE_DMA350(AWCACHE_DMA350),
    .AWPROT_DMA350(AWPROT_DMA350),
    .AWVALID_DMA350(AWVALID_DMA350),
    .AWREADY_DMA350(AWREADY_DMA350),
    .WDATA_DMA350(WDATA_DMA350),
    .WSTRB_DMA350(WSTRB_DMA350),
    .WLAST_DMA350(WLAST_DMA350),
    .WVALID_DMA350(WVALID_DMA350),
    .WREADY_DMA350(WREADY_DMA350),
    .BID_DMA350(BID_DMA350),
    .BRESP_DMA350(BRESP_DMA350),
    .BVALID_DMA350(BVALID_DMA350),
    .BREADY_DMA350(BREADY_DMA350),
    .ARID_DMA350(ARID_DMA350),
    .ARADDR_DMA350(ARADDR_DMA350),
    .ARLEN_DMA350(ARLEN_DMA350),
    .ARSIZE_DMA350(ARSIZE_DMA350),
    .ARBURST_DMA350(ARBURST_DMA350),
    .ARLOCK_DMA350(ARLOCK_DMA350),
    .ARCACHE_DMA350(ARCACHE_DMA350),
    .ARPROT_DMA350(ARPROT_DMA350),
    .ARVALID_DMA350(ARVALID_DMA350),
    .ARREADY_DMA350(ARREADY_DMA350),
    .RID_DMA350(RID_DMA350),
    .RDATA_DMA350(RDATA_DMA350),
    .RRESP_DMA350(RRESP_DMA350),
    .RLAST_DMA350(RLAST_DMA350),
    .RVALID_DMA350(RVALID_DMA350),
    .RREADY_DMA350(RREADY_DMA350),

    .DMA350_irq_channel(DMA350_irq_channel),
    .DMA350_irq_comb_nonsec(DMA350_irq_comb_nonsec),

    .QSPI_SCLK(QSPI_SCLK),
    .QSPI_nCS(QSPI_nCS),
    .QSPI_IO_o(QSPI_IO_o),
    .QSPI_IO_i(QSPI_IO_i),
    .QSPI_IO_e(QSPI_IO_e),
    .UARTRXD(UARTRXD),
    .UARTTXD(UARTTXD),
    .UARTTXEN(UARTTXEN),

    .FT_CLK_O(FT_CLK_O),
    .FT_SSN_O(FT_SSN_O),
    .FT_MISO_I(FT_MISO_I),
    .FT_MIOSIO_O(FT_MIOSIO_O),
    .FT_MIOSIO_E(FT_MIOSIO_E),
    .FT_MIOSIO_Z(FT_MIOSIO_Z),
    .FT_MIOSIO_I(FT_MIOSIO_I),
    
    .nTRST(nTRST),
    .SWCLKTCK(SWCLKTCK),
    .SWDITMS(SWDITMS),
    .TDI(TDI),
    .TDO(TDO),
    .nTDOEN(nTDOEN),
    .SWDO(SWDO),
    .SWDOEN(SWDOEN),

    .P0_IN(P0_IN),
    .P0_OUT(P0_OUT),
    .P0_EN(P0_EN),
    .P0_FUNC(P0_FUNC),
    .P1_IN(P1_IN),
    .P1_OUT(P1_OUT),
    .P1_EN(P1_EN),
    .P1_FUNC(P1_FUNC)
);


megasoc_tech_system_wrapper u_megasoc_tech_system_wrapper(
    .CLK(CLK_IN),
    .RESETn(nRESET),

    .DMA350_PWAKEUP(1'b1),
    .DMA350_PDEBUG(1'b0),
    .DMA350_PSEL(PSELx_DMA_CTRL),
    .DMA350_PENABLE(PENABLE_DMA_CTRL),
    .DMA350_PPROT(PPROT_DMA_CTRL),
    .DMA350_PWRITE(PWRITE_DMA_CTRL),
    .DMA350_PADDR(PADDR_DMA_CTRL),
    .DMA350_PWDATA(PWDATA_DMA_CTRL),
    .DMA350_PSTRB(PSTRB_DMA_CTRL),
    .DMA350_PREADY(PREADY_DMA_CTRL),
    .DMA350_PSLVERR(PSLVERR_DMA_CTRL),
    .DMA350_PRDATA(PRDATA_DMA_CTRL),

    .DMA350_AWAKEUP_M0(),
    .DMA350_AWVALID_M0(AWVALID_DMA350),
    .DMA350_AWADDR_M0(AWADDR_DMA350),
    .DMA350_AWBURST_M0(AWBURST_DMA350),
    .DMA350_AWID_M0(AWID_DMA350),
    .DMA350_AWLEN_M0(AWLEN_DMA350),
    .DMA350_AWSIZE_M0(AWSIZE_DMA350),
    .DMA350_AWQOS_M0(),
    .DMA350_AWPROT_M0(AWPROT_DMA350),
    .DMA350_AWREADY_M0(AWREADY_DMA350),
    .DMA350_AWCACHE_M0(AWCACHE_DMA350),
    .DMA350_AWINNER_M0(),
    .DMA350_AWDOMAIN_M0(),

    .DMA350_ARVALID_M0(ARVALID_DMA350),
    .DMA350_ARADDR_M0(ARADDR_DMA350),
    .DMA350_ARBURST_M0(ARBURST_DMA350),
    .DMA350_ARID_M0(ARID_DMA350),
    .DMA350_ARLEN_M0(ARLEN_DMA350),
    .DMA350_ARSIZE_M0(ARSIZE_DMA350),
    .DMA350_ARQOS_M0(),
    .DMA350_ARPROT_M0(ARPROT_DMA350),
    .DMA350_ARREADY_M0(ARREADY_DMA350),
    .DMA350_ARCACHE_M0(ARCACHE_DMA350),
    .DMA350_ARINNER_M0(),
    .DMA350_ARDOMAIN_M0(),
    .DMA350_ARCMDLINK_M0(),

    .DMA350_WVALID_M0(WVALID_DMA350),
    .DMA350_WLAST_M0(WLAST_DMA350),
    .DMA350_WSTRB_M0(WSTRB_DMA350),
    .DMA350_WDATA_M0(WDATA_DMA350),
    .DMA350_WREADY_M0(WREADY_DMA350),

    .DMA350_RVALID_M0(RVALID_DMA350),
    .DMA350_RID_M0(RID_DMA350),
    .DMA350_RLAST_M0(RLAST_DMA350),
    .DMA350_RDATA_M0(RDATA_DMA350),
    .DMA350_RPOISON_M0(2'b00),
    .DMA350_RRESP_M0(RRESP_DMA350),
    .DMA350_RREADY_M0(RREADY_DMA350),

    .DMA350_BVALID_M0(BVALID_DMA350),
    .DMA350_BID_M0(BID_DMA350),
    .DMA350_BRESP_M0(BRESP_DMA350),
    .DMA350_BREADY_M0(BREADY_DMA350),

    .DMA350_irq_channel(DMA350_irq_channel),
    .DMA350_irq_comb_nonsec(DMA350_irq_comb_nonsec)
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
