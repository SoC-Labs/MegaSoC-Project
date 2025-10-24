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
    // Clocks and Reset
    input  wire         REF_CLK_XTAL1,
    output wire         REF_CLK_XTAL2,
    input  wire         RT_CLK_XTAL1,
    output wire         RT_CLK_XTAL2,
    input  wire         PORESTn,
    input  wire         nSRST,

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

    // GPIO
    inout [15:0]        P0,
    inout [15:0]        P1,

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

    // DDR

    // SDIO
    output wire         SDIO_CK,
    inout  wire         SDIO_CMD,
    inout  wire [3:0]   SDIO_DAT,
    output wire         SD_O_1P8V
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

// SDIO
wire         SDIO_CMD_tri;
wire         SDIO_CMD_o;
wire         SDIO_CMD_i;
wire [7:0]   SDIO_DAT_tri;
wire [7:0]   SDIO_DAT_o;
wire [7:0]   SDIO_DAT_i;

assign SDIO_CMD = SDIO_CMD_tri ? 1'bz : SDIO_CMD_o;
assign SDIO_CMD_i = SDIO_CMD;

assign SDIO_DAT[0] = SDIO_DAT_tri[0] ? 1'bz: SDIO_DAT_o[0] ;
assign SDIO_DAT[1] = SDIO_DAT_tri[1] ? 1'bz: SDIO_DAT_o[1] ;
assign SDIO_DAT[2] = SDIO_DAT_tri[2] ? 1'bz: SDIO_DAT_o[2] ;
assign SDIO_DAT[3] = SDIO_DAT_tri[3] ? 1'bz: SDIO_DAT_o[3] ;

assign SDIO_DAT_i[0] = SDIO_DAT[0];
assign SDIO_DAT_i[1] = SDIO_DAT[1];
assign SDIO_DAT_i[2] = SDIO_DAT[2];
assign SDIO_DAT_i[3] = SDIO_DAT[3];

// GPIO
wire [15:0]  PAD_P0_IN;
wire [15:0]  PAD_P0_OUT;
wire [15:0]  PAD_P0_EN;
wire [15:0]  PAD_P1_IN;
wire [15:0]  PAD_P1_OUT;
wire [15:0]  PAD_P1_EN;

genvar i;
generate
    for(i=0;i<16;i++) begin
        assign P0[i] = PAD_P0_EN[i] ? PAD_P0_OUT[i] : 1'bz;
        assign P1[i] = PAD_P1_EN[i] ? PAD_P1_OUT[i] : 1'bz;
        assign PAD_P0_IN[i] = P0[i];
        assign PAD_P1_IN[i] = P1[i];
    end
endgenerate


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

    // Debug Interface
    .nTRST(nTRST),
    .SWCLKTCK(TCK_SWCLK),
    .SWDITMS(),
    .TDI(),
    .TDO(),
    .nTDOEN(),
    .SWDO(),
    .SWDOEN(),

    // GPIO
    .PAD_P0_IN(PAD_P0_IN),
    .PAD_P0_OUT(PAD_P0_OUT),
    .PAD_P0_EN(PAD_P0_EN),

    .PAD_P1_IN(PAD_P1_IN),
    .PAD_P1_OUT(PAD_P1_OUT),
    .PAD_P1_EN(PAD_P1_EN),

    .PL011_nUARTCTS(PL011_nUARTCTS),
    .PL011_nUARTDCD(PL011_nUARTDCD),
    .PL011_nUARTDSR(PL011_nUARTDSR),
    .PL011_nUARTRI(PL011_nUARTRI),
    .PL011_UARTRXD(PL011_UARTRXD),
    .PL011_UARTTXD(PL011_UARTTXD),
    .PL011_nUARTOut2(PL011_nUARTOut2),
    .PL011_nUARTOut1(PL011_nUARTOut1),
    .PL011_nUARTRTS(PL011_nUARTRTS),
    .PL011_nUARTDTR(PL011_nUARTDTR),

    .SDIO_CK(SDIO_CK),
    .SDIO_CMD_tri(SDIO_CMD_tri),
    .SDIO_CMD_o(SDIO_CMD_o),
    .SDIO_CMD_i(SDIO_CMD_i),
    .SDIO_DAT_tri(SDIO_DAT_tri),
    .SDIO_DAT_o(SDIO_DAT_o),
    .SDIO_DAT_i(SDIO_DAT_i),
    .SD_O_1P8V(SD_O_1P8V)
);


endmodule