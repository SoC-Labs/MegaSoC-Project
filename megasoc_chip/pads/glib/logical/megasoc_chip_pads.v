//-----------------------------------------------------------------------------
// MegaSoC Chip Pads for Generic Libraries
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// Daniel Newbrook (d.newbrook@soton.ac.uk)
// 
// Copyright � 2021-4, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
// Modules instantiated:
//  megasoc_chip

module megasoc_chip_pads(
`ifdef POWER_PINS
    inout wire      VDD,
    inout wire      VSS,
    inout wire      AVDD,
    inout wire      AVSS,
    inout wire      VDDACC,
`endif 
    // Clocks and Reset
    input  wire         REF_CLK_XTAL1,
    output wire         REF_CLK_XTAL2,
    input  wire         RT_CLK_XTAL1,
    output wire         RT_CLK_XTAL2,
    input  wire         PORESTn,
    input  wire         nSRST,

    // GPIO
    inout  wire [15:0]  GPIO_P0,
    inout  wire [15:0]  GPIO_P1,

    // SPI Bus to Pads
    output wire             SPI_SSn,
    output wire             SPI_SCLK,
    output wire             SPI_MOSI,
    input  wire             SPI_MISO,


    // SWD/JTAG TRACE - for Mictor 38
    output wire         TDO_SWO, 
    input  wire         RTCK,
    input  wire         TDI,
    input  wire         TCK_SWCLK, 
    inout  wire         TMS_SWDIO, 
    input  wire         nTRST,
    output wire [15:0]  TRACEDATA,
    input  wire         TRACECLK,
    input  wire         TRACECTL,
    input  wire         DBGRQ,
    output wire         DBGACK,

    // QSPI Interface
    output wire         QSPI_SCLK,
    inout  wire [3:0]   QSPI_IO,
    output wire         QSPI_nCS,

    // EXTIO 
    output wire         EXTIO_REQ1,     // SCLK
    output wire         EXTIO_REQ2,     // SS_N
    input  wire         EXTIO_ACK,    // MISO
    inout  wire [3:0]   EXTIO_DATA   // MIOSIO 

    // Ethernet

    // DDR

    // USB


);

// QSPI
wire [3:0]   QSPI_IO_o;
wire [3:0]   QSPI_IO_i;
wire [3:0]   QSPI_IO_e;

assign QSPI_IO[0] = QSPI_IO_e[0] ? QSPI_IO_o[0] : 1'bz;
assign QSPI_IO[1] = QSPI_IO_e[1] ? QSPI_IO_o[1] : 1'bz;
assign QSPI_IO[2] = QSPI_IO_e[2] ? QSPI_IO_o[2] : 1'bz;
assign QSPI_IO[3] = QSPI_IO_e[3] ? QSPI_IO_o[3] : 1'bz;

assign QSPI_IO_i[0] = QSPI_IO[0];
assign QSPI_IO_i[1] = QSPI_IO[1];
assign QSPI_IO_i[2] = QSPI_IO[2];
assign QSPI_IO_i[3] = QSPI_IO[3];

// FT1248 
wire [3:0]               iodata4_i;
wire [3:0]               iodata4_o;
wire [3:0]               iodata4_e;
wire [3:0]               iodata4_t;
wire                     ioreq1_o;
wire                     ioreq2_o;
wire                     ioack_i;



assign EXTIO_DATA[0] = iodata4_e[0] ? iodata4_o[0] : 1'bz;
assign EXTIO_DATA[1] = iodata4_e[1] ? iodata4_o[1] : 1'bz;
assign EXTIO_DATA[2] = iodata4_e[2] ? iodata4_o[2] : 1'bz;
assign EXTIO_DATA[3] = iodata4_e[3] ? iodata4_o[3] : 1'bz;

assign iodata4_i[0]=EXTIO_DATA[0];
assign iodata4_i[1]=EXTIO_DATA[1];
assign iodata4_i[2]=EXTIO_DATA[2];
assign iodata4_i[3]=EXTIO_DATA[3];


assign EXTIO_REQ1 = ioreq1_o;
assign EXTIO_REQ2 = ioreq2_o;
assign ioack_i = EXTIO_ACK;

assign REF_CLK_XTAL2 = REF_CLK_XTAL1;
assign RT_CLK_XTAL2 = RT_CLK_XTAL1;

megasoc_chip u_megasoc_chip(
    
    .CLK_IN(REF_CLK_XTAL1), //System Clock input
    .RT_CLK(RT_CLK_XTAL1),  // Real Time Clock input

    .nRESET(PORESTn),       // Main Power on Reset

    // QSPI Interface
    .QSPI_SCLK(QSPI_SCLK),  // Flash QSPI Clock
    .QSPI_nCS(QSPI_nCS),    // Flash QSPI chip select
    .QSPI_IO_o(QSPI_IO_o),  // Flash QSPI output
    .QSPI_IO_i(QSPI_IO_i),  // Flash QSPI input
    .QSPI_IO_e(QSPI_IO_e),  // Flash QSPI output enable

    // Uart Interface
    .UARTRXD(),
    .UARTTXD(),
    .UARTTXEN(),

    // EXTIO STDIO and DATA interface
    .iodata4_i(iodata4_i),  // EXTIO (STDIO and DATA) data input
    .iodata4_o(iodata4_o),  // EXTIO (STDIO and DATA) data output
    .iodata4_e(iodata4_e),  // EXTIO (STDIO and DATA) data output enable
    .iodata4_t(iodata4_t),  // EXTIO (STDIO and DATA) data output not enable
    .ioreq1_o(ioreq1_o),    // EXTIO (STDIO and DATA) request 1
    .ioreq2_o(ioreq2_o),    // EXTIO (STDIO and DATA) request 2
    .ioack_i(ioack_i),      // EXTIO (STDIO and DATA) ackknowledge

    .SPI_SSn(SPI_SSn),
    .SPI_SCLK(SPI_SCLK),
    .SPI_MOSI(SPI_MOSI),
    .SPI_MISO(SPI_MISO),

    // Debug Interface
    .nTRST(),
    .SWCLKTCK(),
    .SWDITMS(),
    .TDI(),
    .TDO(),
    .nTDOEN(),
    .SWDO(),
    .SWDOEN()
);


endmodule