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
    output wire         QSPI_nCS

    // Ethernet

    // DDR

    // USB


);

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

assign REF_CLK_XTAL2 = REF_CLK_XTAL1;

megasoc_chip u_megasoc_chip(
    .CLK_IN(REF_CLK_XTAL1),
    .nRESET(PORESTn),
    .QSPI_SCLK(QSPI_SCLK),
    .QSPI_nCS(QSPI_nCS),
    .QSPI_IO_o(QSPI_IO_o),
    .QSPI_IO_i(QSPI_IO_i),
    .QSPI_IO_e(QSPI_IO_e),
    .UARTRXD(),
    .UARTTXD(),
    .UARTTXEN(),
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