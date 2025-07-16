//-----------------------------------------------------------------------------
// MegaSoC Chip
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// Daniel Newbrook (d.newbrook@soton.ac.uk)
// 
// Copyright � 2021-4, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
// Modules instantiated:
//  megasoc_system

module megasoc_chip(
    input  wire         CLK_IN, // Main system clock input
    input  wire         RT_CLK, // 32kHz real time clock
    input  wire         nRESET,

    // QSPI signals
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
    input  wire [3:0]               iodata4_i,
    output wire [3:0]               iodata4_o,
    output wire [3:0]               iodata4_e,
    output wire [3:0]               iodata4_t,
    output wire                     ioreq1_o,
    output wire                     ioreq2_o,
    input  wire                     ioack_i,

    // SPI Bus to Pads
    output wire             SPI_SSn,
    output wire             SPI_SCLK,
    output wire             SPI_MOSI,
    input  wire             SPI_MISO,

    // DAP-lite Signals
    input  wire         nTRST,
    input  wire         SWCLKTCK,
    input  wire         SWDITMS,
    input  wire         TDI,
    output wire         TDO,
    output wire         nTDOEN,
    output wire         SWDO,
    output wire         SWDOEN,

    input  wire [15:0]      PAD_P0_IN,
    output wire [15:0]      PAD_P0_OUT,
    output wire [15:0]      PAD_P0_EN,

    input  wire [15:0]      PAD_P1_IN,
    output wire [15:0]      PAD_P1_OUT,
    output wire [15:0]      PAD_P1_EN
);

wire [15:0]      SOC_P0_IN;
wire [15:0]      SOC_P0_OUT;
wire [15:0]      SOC_P0_EN;
wire [15:0]      SOC_P0_FUNC;
wire [15:0]      SOC_P1_IN;
wire [15:0]      SOC_P1_OUT;
wire [15:0]      SOC_P1_EN;
wire [15:0]      SOC_P1_FUNC;


megasoc_system u_megasoc_system(
    .CLK_IN(CLK_IN),
    .RT_CLK(RT_CLK),
    .nRESET(nRESET),

    .QSPI_SCLK(QSPI_SCLK),
    .QSPI_nCS(QSPI_nCS),
    .QSPI_IO_o(QSPI_IO_o),
    .QSPI_IO_i(QSPI_IO_i),
    .QSPI_IO_e(QSPI_IO_e),

    .UARTRXD(UARTRXD),
    .UARTTXD(UARTTXD),
    .UARTTXEN(UARTTXEN),

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

    .P0_IN(SOC_P0_IN),
    .P0_OUT(SOC_P0_OUT),
    .P0_EN(SOC_P0_EN),
    .P0_FUNC(SOC_P0_FUNC),
    .P1_IN(SOC_P1_IN),
    .P1_OUT(SOC_P1_OUT),
    .P1_EN(SOC_P1_EN),
    .P1_FUNC(SOC_P1_FUNC)
);

megasoc_chip_pin_mux u_pin_mux(
    .SOC_P0_IN(),
    .SOC_P0_OUT(),
    .SOC_P0_EN(),
    .SOC_P0_FUNC(),
    .SOC_P0_ALT(),

    .SOC_P1_IN(),
    .SOC_P1_OUT(),
    .SOC_P1_EN(),
    .SOC_P1_FUNC(),
    .SOC_P1_ALT(),

    .PAD_P0_IN(PAD_P0_IN),
    .PAD_P0_OUT(PAD_P0_OUT),
    .PAD_P0_EN(PAD_P0_EN),
    .PAD_P1_IN(PAD_P1_IN),
    .PAD_P1_OUT(PAD_P1_OUT),
    .PAD_P1_EN(PAD_P1_EN)
);

endmodule