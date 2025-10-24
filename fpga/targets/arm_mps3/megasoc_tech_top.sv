`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.09.2025 09:15:14
// Design Name: 
// Module Name: megasoc_tech_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module megasoc_tech_top(
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
    output wire [15:0]  P1_FUNC

    );
    
    
axi4 #(.DATA_W(64), .ID_W(7), .ADDR_W(32)) EXP_M_AXI();
axi4 #(.DATA_W(64), .ID_W(3), .ADDR_W(32)) EXP_S_AXI();

wire [7:0] EXP_IRQs;
assign EXP_IRQs = 8'h00;

    
megasoc_tech_wrapper u_megasoc_tech(
    .SYS_CLK(CLK_IN),
    .SYS_CLKEN(1'b1),
    .RT_CLK(RT_CLK),
    .SYS_RESETn(nRESET),

    // Millisoc system AXI Manager
    .EXP_M_AXI(EXP_M_AXI),

    // Millisoc system AXI Subordinate
    .EXP_S_AXI(EXP_S_AXI),

    .EXP_IRQs(EXP_IRQs),
    
    .PRDATA_DMA_CTRL(32'hDEADCAFE),
    .PSLVERR_DMA_CTRL(1'b0),
    .PREADY_DMA_CTRL(1'b1),

    .AWID_DMA350(2'b00),
    .AWADDR_DMA350(44'd0),
    .AWLEN_DMA350(8'd0),
    .AWSIZE_DMA350(3'h0),
    .AWBURST_DMA350(2'h0),
    .AWLOCK_DMA350(1'b0),
    .AWCACHE_DMA350(4'h0),
    .AWPROT_DMA350(3'h0),
    .AWVALID_DMA350(1'b0),
    
    .WDATA_DMA350(128'd0),
    .WSTRB_DMA350(16'd0),
    .WLAST_DMA350(1'b0),
    .WVALID_DMA350(1'b0),
    
    .BREADY_DMA350(1'b0),
    
    .ARID_DMA350(2'h0),
    .ARADDR_DMA350(44'd0),
    .ARLEN_DMA350(8'd0),
    .ARSIZE_DMA350(3'h0),
    .ARBURST_DMA350(2'h0),
    .ARLOCK_DMA350(1'b0),
    .ARCACHE_DMA350(4'h0),
    .ARPROT_DMA350(3'h0),
    .ARVALID_DMA350(1'b0),
    
    .RREADY_DMA350(1'b0),

    .DMA350_irq_channel(4'h0),
    .DMA350_irq_comb_nonsec(1'b0),

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
    .P1_FUNC(P1_FUNC)

);

assign EXP_M_AXI.AWREADY=1'b0;
assign EXP_M_AXI.WREADY=1'b0;
assign EXP_M_AXI.BVALID=1'b0;
assign EXP_M_AXI.ARREADY=1'b0;
assign EXP_M_AXI.RVALID=1'b0;

assign EXP_S_AXI.AWVALID=1'b0;
assign EXP_S_AXI.ARVALID=1'b0;
assign EXP_S_AXI.WVALID=1'b0;
assign EXP_S_AXI.BREADY=1'b0;
assign EXP_S_AXI.RREADY=1'b0;



endmodule
