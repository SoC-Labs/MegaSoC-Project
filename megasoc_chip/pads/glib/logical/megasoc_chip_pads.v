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

    // FT1248 
    output wire         FT_CLK,     // SCLK
    output wire         FT_SSN,     // SS_N
    input  wire         FT_MISO,    // MISO
    inout  wire         FT_MIOSIO   // MIOSIO 

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
wire        FT_MIOSIO_O;
wire        FT_MIOSIO_E;
wire        FT_MIOSIO_Z;
wire        FT_MIOSIO_I;

assign FT_MIOSIO = FT_MIOSIO_E ? FT_MIOSIO_O : 1'bz;

assign FT_MIOSIO_I = FT_MIOSIO;

assign REF_CLK_XTAL2 = REF_CLK_XTAL1;
assign RT_CLK_XTAL2 = RT_CLK_XTAL1;

megasoc_chip u_megasoc_chip(
    .CLK_IN(REF_CLK_XTAL1),
    .RT_CLK(RT_CLK_XTAL1),
    .nRESET(PORESTn),
    .QSPI_SCLK(QSPI_SCLK),
    .QSPI_nCS(QSPI_nCS),
    .QSPI_IO_o(QSPI_IO_o),
    .QSPI_IO_i(QSPI_IO_i),
    .QSPI_IO_e(QSPI_IO_e),

    .UARTRXD(),
    .UARTTXD(),
    .UARTTXEN(),

    .FT_CLK_O(FT_CLK),
    .FT_SSN_O(FT_SSN),
    .FT_MISO_I(FT_MISO),
    .FT_MIOSIO_O(FT_MIOSIO_O),
    .FT_MIOSIO_E(FT_MIOSIO_E),
    .FT_MIOSIO_Z(FT_MIOSIO_Z),
    .FT_MIOSIO_I(FT_MIOSIO_I),

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