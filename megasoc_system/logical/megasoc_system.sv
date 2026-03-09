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
    input  wire         UARTRXD0,
    output wire         UARTTXD0,
    output wire         UARTTXEN0,

    input  wire         UARTRXD1,
    output wire         UARTTXD1,
    output wire         UARTTXEN1,

    // PL011 UART
    input  wire             PL011_nUARTCTS,
    input  wire             PL011_nUARTDCD,
    input  wire             PL011_nUARTDSR,
    input  wire             PL011_nUARTRI,
    input  wire             PL011_UARTRXD,
    output wire             PL011_UARTTXD,
    output wire             PL011_nUARTOut2,
    output wire             PL011_nUARTOut1,
    output wire             PL011_nUARTRTS,
    output wire             PL011_nUARTDTR,

    // FT1248 Signals
    input  wire [3:0]   iodata4_i,
    output wire [3:0]   iodata4_o,
    output wire [3:0]   iodata4_e,
    output wire [3:0]   iodata4_t,
    output wire         ioreq1_o,
    output wire         ioreq2_o,
    input  wire         ioack_i,

    // SPI Bus to Pads
    output wire         SPI_SSn,
    output wire         SPI_SCLK,
    output wire         SPI_MOSI,
    input  wire         SPI_MISO,

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
    output wire [15:0]  P1_FUNC,

    // LPDDR4 Signals
    output wire             DDR4_RESET_N,
    output wire             DDR4_CK_T,
    output wire             DDR4_CK_C,
    output wire             DDR4_CKE,
    output wire             DDR4_CS_N,
    output wire [5:0]       DDR4_ADR,
    output wire             DDR4_ODT,
    inout  wire [1:0]       DDR4_DQS_T,
    inout  wire [1:0]       DDR4_DQS_C,
    inout  wire [15:0]      DDR4_DQ,
    inout  wire [1:0]       DDR4_DM_DBI_N,
    inout  wire             DDR4_ALERT_N,
    inout  wire             DDR4_VREF,
    input  wire             DDR4_ZN_SENSE,
    output wire             DDR4_ZN,

    // SDIO PHY to MAC Signals
    output wire             SDIO_o_cfg_ddr,
    output wire             SDIO_o_cfg_ds,
    output wire             SDIO_o_cfg_dscmd,
    output wire [4:0]       SDIO_o_cfg_sample_shift,
    output wire [7:0]       SDIO_o_sdclk,
    output wire             SDIO_o_cmd_en,
    output wire             SDIO_o_cmd_tristate,
    output wire [1:0]       SDIO_o_cmd_data,
    output wire             SDIO_o_data_en,
    output wire             SDIO_o_data_tristate,
    output wire             SDIO_o_rx_en,
    output wire [31:0]      SDIO_o_tx_data,
    input  wire [1:0]       SDIO_i_cmd_strb,
    input  wire [1:0]       SDIO_i_cmd_data,
    input  wire             SDIO_i_cmd_collision,
    input  wire             SDIO_i_card_busy,
    input  wire [1:0]       SDIO_i_rx_strb,
    input  wire [15:0]      SDIO_i_rx_data,
    input  wire             SDIO_i_crcack,
    input  wire             SDIO_i_crcnak,
    output wire             SD_O_1P8V,
    input  wire             SDIO_AC_VALID,
    input  wire [1:0]       SDIO_AC_DATA,
    input  wire             SDIO_AD_VALID,
    input  wire [31:0]      SDIO_AD_DATA
);

// Update 24/09/2025 No "system" DMA needed as not yet getting ethernet or PCIe added
// // DMA 350 APB Interface Wires
// wire [31:0]     PADDR_DMA_CTRL;
// wire [31:0]     PWDATA_DMA_CTRL;
// wire            PWRITE_DMA_CTRL;
// wire [2:0]      PPROT_DMA_CTRL;
// wire [3:0]      PSTRB_DMA_CTRL;
// wire            PENABLE_DMA_CTRL;
// wire            PSELx_DMA_CTRL;
// wire [31:0]     PRDATA_DMA_CTRL;
// wire            PSLVERR_DMA_CTRL;
// wire            PREADY_DMA_CTRL;

// // DMA 350 AXI Interface Wires
// wire [1:0]      AWID_DMA350;
// wire [43:0]     AWADDR_DMA350;
// wire [7:0]      AWLEN_DMA350;
// wire [2:0]      AWSIZE_DMA350;
// wire [1:0]      AWBURST_DMA350;
// wire            AWLOCK_DMA350;
// wire [3:0]      AWCACHE_DMA350;
// wire [2:0]      AWPROT_DMA350;
// wire            AWVALID_DMA350;
// wire            AWREADY_DMA350;

// wire [127:0]    WDATA_DMA350;
// wire [15:0]     WSTRB_DMA350;
// wire            WLAST_DMA350;
// wire            WVALID_DMA350;
// wire            WREADY_DMA350;

// wire [1:0]      BID_DMA350;
// wire [1:0]      BRESP_DMA350;
// wire            BVALID_DMA350;
// wire            BREADY_DMA350;

// wire [1:0]      ARID_DMA350;
// wire [43:0]     ARADDR_DMA350;
// wire [7:0]      ARLEN_DMA350;
// wire [2:0]      ARSIZE_DMA350;
// wire [1:0]      ARBURST_DMA350;
// wire            ARLOCK_DMA350;
// wire [3:0]      ARCACHE_DMA350;
// wire [2:0]      ARPROT_DMA350;
// wire            ARVALID_DMA350;
// wire            ARREADY_DMA350;

// wire [1:0]      RID_DMA350;
// wire [127:0]    RDATA_DMA350;
// wire [1:0]      RRESP_DMA350;
// wire            RLAST_DMA350;
// wire            RVALID_DMA350;
// wire            RREADY_DMA350;

// wire [3:0]      DMA350_irq_channel;
// wire            DMA350_irq_comb_nonsec;

wire [7:0]      EXP_IRQs;

axi4 #(.DATA_W(64), .ID_W(9), .ADDR_W(32)) EXP_M_AXI();
axi4 #(.DATA_W(64), .ID_W(3), .ADDR_W(32)) EXP_S_AXI();

megasoc_tech_wrapper u_megasoc_tech_wrapper(
    .SYS_CLK(CLK_IN),
    .SYS_CLKEN(1'b1),
    .RT_CLK(RT_CLK),
    .SYS_RESETn(nRESET),

    // Millisoc system AXI Manager
    .EXP_M_AXI(EXP_M_AXI),

    // Millisoc system AXI Subordinate
    .EXP_S_AXI(EXP_S_AXI),

    .EXP_IRQs(EXP_IRQs),

    // Update 24/09/2025 No "system" DMA needed as not yet getting ethernet or PCIe added
    // .PADDR_DMA_CTRL(PADDR_DMA_CTRL),
    // .PWDATA_DMA_CTRL(PWDATA_DMA_CTRL),
    // .PWRITE_DMA_CTRL(PWRITE_DMA_CTRL),
    // .PPROT_DMA_CTRL(PPROT_DMA_CTRL),
    // .PSTRB_DMA_CTRL(PSTRB_DMA_CTRL),
    // .PENABLE_DMA_CTRL(PENABLE_DMA_CTRL),
    // .PSELx_DMA_CTRL(PSELx_DMA_CTRL),
    // .PRDATA_DMA_CTRL(PRDATA_DMA_CTRL),
    // .PSLVERR_DMA_CTRL(PSLVERR_DMA_CTRL),
    // .PREADY_DMA_CTRL(PREADY_DMA_CTRL),

    // .AWID_DMA350(AWID_DMA350),
    // .AWADDR_DMA350(AWADDR_DMA350),
    // .AWLEN_DMA350(AWLEN_DMA350),
    // .AWSIZE_DMA350(AWSIZE_DMA350),
    // .AWBURST_DMA350(AWBURST_DMA350),
    // .AWLOCK_DMA350(AWLOCK_DMA350),
    // .AWCACHE_DMA350(AWCACHE_DMA350),
    // .AWPROT_DMA350(AWPROT_DMA350),
    // .AWVALID_DMA350(AWVALID_DMA350),
    // .AWREADY_DMA350(AWREADY_DMA350),
    // .WDATA_DMA350(WDATA_DMA350),
    // .WSTRB_DMA350(WSTRB_DMA350),
    // .WLAST_DMA350(WLAST_DMA350),
    // .WVALID_DMA350(WVALID_DMA350),
    // .WREADY_DMA350(WREADY_DMA350),
    // .BID_DMA350(BID_DMA350),
    // .BRESP_DMA350(BRESP_DMA350),
    // .BVALID_DMA350(BVALID_DMA350),
    // .BREADY_DMA350(BREADY_DMA350),
    // .ARID_DMA350(ARID_DMA350),
    // .ARADDR_DMA350(ARADDR_DMA350),
    // .ARLEN_DMA350(ARLEN_DMA350),
    // .ARSIZE_DMA350(ARSIZE_DMA350),
    // .ARBURST_DMA350(ARBURST_DMA350),
    // .ARLOCK_DMA350(ARLOCK_DMA350),
    // .ARCACHE_DMA350(ARCACHE_DMA350),
    // .ARPROT_DMA350(ARPROT_DMA350),
    // .ARVALID_DMA350(ARVALID_DMA350),
    // .ARREADY_DMA350(ARREADY_DMA350),
    // .RID_DMA350(RID_DMA350),
    // .RDATA_DMA350(RDATA_DMA350),
    // .RRESP_DMA350(RRESP_DMA350),
    // .RLAST_DMA350(RLAST_DMA350),
    // .RVALID_DMA350(RVALID_DMA350),
    // .RREADY_DMA350(RREADY_DMA350),

    // .DMA350_irq_channel(DMA350_irq_channel),
    // .DMA350_irq_comb_nonsec(DMA350_irq_comb_nonsec),

    .QSPI_SCLK(QSPI_SCLK),
    .QSPI_nCS(QSPI_nCS),
    .QSPI_IO_o(QSPI_IO_o),
    .QSPI_IO_i(QSPI_IO_i),
    .QSPI_IO_e(QSPI_IO_e),

    .UARTRXD0(UARTRXD0),
    .UARTTXD0(UARTTXD0),
    .UARTTXEN0(UARTTXEN0),

    .UARTRXD1(UARTRXD1),
    .UARTTXD1(UARTTXD1),
    .UARTTXEN1(UARTTXEN1),

    .PL011_nUARTCTS(PL011_nUARTCTS),
    .PL011_nUARTDCD(PL011_nUARTDCD),
    .PL011_nUARTDSR(PL011_nUARTDSR),
    .PL011_nUARTRI(PL011_nUARTRI),
    .PL011_UARTRXD(PL011_UARTRXD),
    .PL011_SIRIN(1'b0),
    .PL011_UARTTXD(PL011_UARTTXD),
    .PL011_nSIROUT(),
    .PL011_nUARTOut2(PL011_nUARTOut2),
    .PL011_nUARTOut1(PL011_nUARTOut1),
    .PL011_nUARTRTS(PL011_nUARTRTS),
    .PL011_nUARTDTR(PL011_nUARTDTR),

    .iodata4_i(iodata4_i),
    .iodata4_o(iodata4_o),
    .iodata4_e(iodata4_e),
    .iodata4_t(iodata4_t),
    .ioreq1_o(ioreq1_o),
    .ioreq2_o(ioreq2_o),
    .ioack_i(ioack_i),

    .SPI_SSn(SPI_SSn),
    .SPI_SCLK(SPI_SCLK),
    .SPI_MOSI(SPI_MOSI),
    .SPI_MISO(SPI_MISO),

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
    .P1_FUNC(P1_FUNC),

    .DDR4_RESET_N(DDR4_RESET_N),
    .DDR4_CK_T(DDR4_CK_T),
    .DDR4_CK_C(DDR4_CK_C),
    .DDR4_CKE(DDR4_CKE),
    .DDR4_CS_N(DDR4_CS_N),
    .DDR4_ADR(DDR4_ADR),
    .DDR4_ODT(DDR4_ODT),
    .DDR4_DQS_T(DDR4_DQS_T),
    .DDR4_DQS_C(DDR4_DQS_C),
    .DDR4_DQ(DDR4_DQ),
    .DDR4_DM_DBI_N(DDR4_DM_DBI_N),
    .DDR4_ALERT_N(DDR4_ALERT_N),
    .DDR4_VREF(DDR4_VREF),
    .DDR4_ZN_SENSE(DDR4_ZN_SENSE),
    .DDR4_ZN(DDR4_ZN),

    .SDIO_o_cfg_ddr(SDIO_o_cfg_ddr),
    .SDIO_o_cfg_ds(SDIO_o_cfg_ds),
    .SDIO_o_cfg_dscmd(SDIO_o_cfg_dscmd),
    .SDIO_o_cfg_sample_shift(SDIO_o_cfg_sample_shift),
    .SDIO_o_sdclk(SDIO_o_sdclk),
    .SDIO_o_cmd_en(SDIO_o_cmd_en),
    .SDIO_o_cmd_tristate(SDIO_o_cmd_tristate),
    .SDIO_o_cmd_data(SDIO_o_cmd_data),
    .SDIO_o_data_en(SDIO_o_data_en),
    .SDIO_o_data_tristate(SDIO_o_data_tristate),
    .SDIO_o_rx_en(SDIO_o_rx_en),
    .SDIO_o_tx_data(SDIO_o_tx_data),
    .SDIO_i_cmd_strb(SDIO_i_cmd_strb),
    .SDIO_i_cmd_data(SDIO_i_cmd_data),
    .SDIO_i_cmd_collision(SDIO_i_cmd_collision),
    .SDIO_i_card_busy(SDIO_i_card_busy),
    .SDIO_i_rx_strb(SDIO_i_rx_strb),
    .SDIO_i_rx_data(SDIO_i_rx_data),
    .SDIO_i_crcack(SDIO_i_crcack),
    .SDIO_i_crcnak(SDIO_i_crcnak),
    .SD_O_1P8V(SD_O_1P8V),
    .SDIO_AC_VALID(SDIO_AC_VALID),
    .SDIO_AC_DATA(SDIO_AC_DATA),
    .SDIO_AD_VALID(SDIO_AD_VALID),
    .SDIO_AD_DATA(SDIO_AD_DATA)

);

// Update 24/09/2025 No "system" DMA needed as not yet getting ethernet or PCIe added
// megasoc_tech_system_wrapper u_megasoc_tech_system_wrapper(
//     .CLK(CLK_IN),
//     .RESETn(nRESET),

//     .DMA350_PWAKEUP(1'b1),
//     .DMA350_PDEBUG(1'b0),
//     .DMA350_PSEL(PSELx_DMA_CTRL),
//     .DMA350_PENABLE(PENABLE_DMA_CTRL),
//     .DMA350_PPROT(PPROT_DMA_CTRL),
//     .DMA350_PWRITE(PWRITE_DMA_CTRL),
//     .DMA350_PADDR(PADDR_DMA_CTRL[12:0]),
//     .DMA350_PWDATA(PWDATA_DMA_CTRL),
//     .DMA350_PSTRB(PSTRB_DMA_CTRL),
//     .DMA350_PREADY(PREADY_DMA_CTRL),
//     .DMA350_PSLVERR(PSLVERR_DMA_CTRL),
//     .DMA350_PRDATA(PRDATA_DMA_CTRL),

//     .DMA350_AWAKEUP_M0(),
//     .DMA350_AWVALID_M0(AWVALID_DMA350),
//     .DMA350_AWADDR_M0(AWADDR_DMA350),
//     .DMA350_AWBURST_M0(AWBURST_DMA350),
//     .DMA350_AWID_M0(AWID_DMA350),
//     .DMA350_AWLEN_M0(AWLEN_DMA350),
//     .DMA350_AWSIZE_M0(AWSIZE_DMA350),
//     .DMA350_AWQOS_M0(),
//     .DMA350_AWPROT_M0(AWPROT_DMA350),
//     .DMA350_AWREADY_M0(AWREADY_DMA350),
//     .DMA350_AWCACHE_M0(AWCACHE_DMA350),
//     .DMA350_AWINNER_M0(),
//     .DMA350_AWDOMAIN_M0(),

//     .DMA350_ARVALID_M0(ARVALID_DMA350),
//     .DMA350_ARADDR_M0(ARADDR_DMA350),
//     .DMA350_ARBURST_M0(ARBURST_DMA350),
//     .DMA350_ARID_M0(ARID_DMA350),
//     .DMA350_ARLEN_M0(ARLEN_DMA350),
//     .DMA350_ARSIZE_M0(ARSIZE_DMA350),
//     .DMA350_ARQOS_M0(),
//     .DMA350_ARPROT_M0(ARPROT_DMA350),
//     .DMA350_ARREADY_M0(ARREADY_DMA350),
//     .DMA350_ARCACHE_M0(ARCACHE_DMA350),
//     .DMA350_ARINNER_M0(),
//     .DMA350_ARDOMAIN_M0(),
//     .DMA350_ARCMDLINK_M0(),

//     .DMA350_WVALID_M0(WVALID_DMA350),
//     .DMA350_WLAST_M0(WLAST_DMA350),
//     .DMA350_WSTRB_M0(WSTRB_DMA350),
//     .DMA350_WDATA_M0(WDATA_DMA350),
//     .DMA350_WREADY_M0(WREADY_DMA350),

//     .DMA350_RVALID_M0(RVALID_DMA350),
//     .DMA350_RID_M0(RID_DMA350),
//     .DMA350_RLAST_M0(RLAST_DMA350),
//     .DMA350_RDATA_M0(RDATA_DMA350),
//     .DMA350_RPOISON_M0(2'b00),
//     .DMA350_RRESP_M0(RRESP_DMA350),
//     .DMA350_RREADY_M0(RREADY_DMA350),

//     .DMA350_BVALID_M0(BVALID_DMA350),
//     .DMA350_BID_M0(BID_DMA350),
//     .DMA350_BRESP_M0(BRESP_DMA350),
//     .DMA350_BREADY_M0(BREADY_DMA350),

//     .DMA350_irq_channel(DMA350_irq_channel),
//     .DMA350_irq_comb_nonsec(DMA350_irq_comb_nonsec)
// );


`ifdef INC_EXP
expansion_subsystem_wrapper u_megasoc_expansion_wrapper(
    .sys_clk(CLK_IN),
    .resetn(nRESET),
    .exp_clk(CLK_IN),
    .exp_clken(1'b1),
    .expresetn(nRESET),

    // System Clock domain control
    .CSYSREQ_CD_sys(1'b1),
    .CSYSACK_CD_sys(),
    .CACTIVE_CD_sys(),

    // Expansion Clock domain control
    .CSYSREQ_CD_exp(1'b1),
    .CSYSACK_CD_exp(),
    .CACTIVE_CD_exp(),

    // AXI Expansion input port
    .AXI_EXP_SS_awid(EXP_M_AXI.AWID), // 7 bits
    .AXI_EXP_SS_awaddr(EXP_M_AXI.AWADDR),
    .AXI_EXP_SS_awlen(EXP_M_AXI.AWLEN),
    .AXI_EXP_SS_awsize(EXP_M_AXI.AWSIZE),
    .AXI_EXP_SS_awburst(EXP_M_AXI.AWBURST),
    .AXI_EXP_SS_awlock(EXP_M_AXI.AWLOCK),
    .AXI_EXP_SS_awcache(EXP_M_AXI.AWCACHE),
    .AXI_EXP_SS_awprot(EXP_M_AXI.AWPROT),
    .AXI_EXP_SS_awvalid(EXP_M_AXI.AWVALID),
    .AXI_EXP_SS_awready(EXP_M_AXI.AWREADY),
    .AXI_EXP_SS_wdata(EXP_M_AXI.WDATA),
    .AXI_EXP_SS_wstrb(EXP_M_AXI.WSTRB),
    .AXI_EXP_SS_wlast(EXP_M_AXI.WLAST),
    .AXI_EXP_SS_wvalid(EXP_M_AXI.WVALID),
    .AXI_EXP_SS_wready(EXP_M_AXI.WREADY),
    .AXI_EXP_SS_bid(EXP_M_AXI.BID),
    .AXI_EXP_SS_bresp(EXP_M_AXI.BRESP),
    .AXI_EXP_SS_bvalid(EXP_M_AXI.BVALID),
    .AXI_EXP_SS_bready(EXP_M_AXI.BREADY),
    .AXI_EXP_SS_arid(EXP_M_AXI.ARID),
    .AXI_EXP_SS_araddr(EXP_M_AXI.ARADDR),
    .AXI_EXP_SS_arlen(EXP_M_AXI.ARLEN),
    .AXI_EXP_SS_arsize(EXP_M_AXI.ARSIZE),
    .AXI_EXP_SS_arburst(EXP_M_AXI.ARBURST),
    .AXI_EXP_SS_arlock(EXP_M_AXI.ARLOCK),
    .AXI_EXP_SS_arcache(EXP_M_AXI.ARCACHE),
    .AXI_EXP_SS_arprot(EXP_M_AXI.ARPROT),
    .AXI_EXP_SS_arvalid(EXP_M_AXI.ARVALID),
    .AXI_EXP_SS_arready(EXP_M_AXI.ARREADY),
    .AXI_EXP_SS_rid(EXP_M_AXI.RID),
    .AXI_EXP_SS_rdata(EXP_M_AXI.RDATA),
    .AXI_EXP_SS_rresp(EXP_M_AXI.RRESP),
    .AXI_EXP_SS_rlast(EXP_M_AXI.RLAST),
    .AXI_EXP_SS_rvalid(EXP_M_AXI.RVALID),
    .AXI_EXP_SS_rready(EXP_M_AXI.RREADY),

    // AXI System output port
    .AXI_SYS_awid(EXP_S_AXI.AWID),
    .AXI_SYS_awaddr(EXP_S_AXI.AWADDR),
    .AXI_SYS_awlen(EXP_S_AXI.AWLEN),
    .AXI_SYS_awsize(EXP_S_AXI.AWSIZE),
    .AXI_SYS_awburst(EXP_S_AXI.AWBURST),
    .AXI_SYS_awlock(EXP_S_AXI.AWLOCK),
    .AXI_SYS_awcache(EXP_S_AXI.AWCACHE),
    .AXI_SYS_awprot(EXP_S_AXI.AWPROT),
    .AXI_SYS_awvalid(EXP_S_AXI.AWVALID),
    .AXI_SYS_awready(EXP_S_AXI.AWREADY),
    .AXI_SYS_wdata(EXP_S_AXI.WDATA),
    .AXI_SYS_wstrb(EXP_S_AXI.WSTRB),
    .AXI_SYS_wlast(EXP_S_AXI.WLAST),
    .AXI_SYS_wvalid(EXP_S_AXI.WVALID),
    .AXI_SYS_wready(EXP_S_AXI.WREADY),
    .AXI_SYS_bid(EXP_S_AXI.BID),
    .AXI_SYS_bresp(EXP_S_AXI.BRESP),
    .AXI_SYS_bvalid(EXP_S_AXI.BVALID),
    .AXI_SYS_bready(EXP_S_AXI.BREADY),
    .AXI_SYS_arid(EXP_S_AXI.ARID),
    .AXI_SYS_araddr(EXP_S_AXI.ARADDR),
    .AXI_SYS_arlen(EXP_S_AXI.ARLEN),
    .AXI_SYS_arsize(EXP_S_AXI.ARSIZE),
    .AXI_SYS_arburst(EXP_S_AXI.ARBURST),
    .AXI_SYS_arlock(EXP_S_AXI.ARLOCK),
    .AXI_SYS_arcache(EXP_S_AXI.ARCACHE),
    .AXI_SYS_arprot(EXP_S_AXI.ARPROT),
    .AXI_SYS_arvalid(EXP_S_AXI.ARVALID),
    .AXI_SYS_arready(EXP_S_AXI.ARREADY),
    .AXI_SYS_rid(EXP_S_AXI.RID),
    .AXI_SYS_rdata(EXP_S_AXI.RDATA),
    .AXI_SYS_rresp(EXP_S_AXI.RRESP),
    .AXI_SYS_rlast(EXP_S_AXI.RLAST),
    .AXI_SYS_rvalid(EXP_S_AXI.RVALID),
    .AXI_SYS_rready(EXP_S_AXI.RREADY),

    // Interrupts
    .irq_dma_channel(EXP_IRQs[3:0]),
    .irq_dma_comb_nonsec(EXP_IRQs[4]),
    .acc_irqs(EXP_IRQs[7:5])
);
`else
    // EXP_M_AXI Tie off's
    assign EXP_M_AXI.AWREADY = 1'b1;
    assign EXP_M_AXI.WREADY = 1'b1;
    assign EXP_M_AXI.BID = 9'd0;
    assign EXP_M_AXI.BRESP = 2'b11;
    assign EXP_M_AXI.BVALID = 1'b1;
    assign EXP_M_AXI.ARREADY = 1'b1;
    assign EXP_M_AXI.RID = 9'd0;
    assign EXP_M_AXI.RDATA = 64'hDEAFBEEFDEADBEED;
    assign EXP_M_AXI.RRESP = 2'b11;
    assign EXP_M_AXI.RLAST = 1'b0;
    assign EXP_M_AXI.RVALID = 1'b0;

    // EXP_S_AXI Tie off's
    assign EXP_S_AXI.AWID = 3'h0;
    assign EXP_S_AXI.AWADDR = 32'd0;
    assign EXP_S_AXI.AWLEN = 8'd0;
    assign EXP_S_AXI.AWSIZE = 3'h0;
    assign EXP_S_AXI.AWBURST = 2'h0;
    assign EXP_S_AXI.AWLOCK = 1'b0;
    assign EXP_S_AXI.AWCACHE = 4'h0;
    assign EXP_S_AXI.AWPROT = 3'h0;
    assign EXP_S_AXI.AWVALID = 1'b0;

    assign EXP_S_AXI.WDATA = 64'd0;
    assign EXP_S_AXI.WSTRB = 8'd0;
    assign EXP_S_AXI.WLAST = 1'b0;
    assign EXP_S_AXI.WVALID = 1'b0;

    assign EXP_S_AXI.BREADY = 1'b0;

    assign EXP_S_AXI.ARID = 3'h0;
    assign EXP_S_AXI.ARADDR = 32'd0;
    assign EXP_S_AXI.ARLEN = 8'd0;
    assign EXP_S_AXI.ARSIZE = 3'h0;
    assign EXP_S_AXI.ARBURST = 2'h0;
    assign EXP_S_AXI.ARLOCK = 1'b0;
    assign EXP_S_AXI.ARCACHE = 4'h0;
    assign EXP_S_AXI.ARPROT = 3'h0;
    assign EXP_S_AXI.ARVALID = 1'b0;
    assign EXP_S_AXI.RREADY = 1'b0;
`endif
endmodule
