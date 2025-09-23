//-----------------------------------------------------------------------------
// MegaSoC Chip Pads for TSMC 28nm node
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
    inout [15:0]        P1

    // Ethernet

    // DDR

    // USB


);

wire CLK_IN;
wire RT_CLK;

wire SOC_QSPI_SCLK;
wire SOC_QSPI_nCS;
wire [3:0] SOC_QSPI_IO_o;
wire [3:0] SOC_QSPI_IO_i;
wire [3:0] SOC_QSPI_IO_e;

megasoc_chip u_megasoc_chip(
    .CLK_IN(CLK_IN),
    .RT_CLK(RT_CLK),

    .nRESET(PORESTn),

    // QSPI Interface
    .QSPI_SCLK(SOC_QSPI_SCLK),
    .QSPI_nCS(SOC_QSPI_nCS),
    .QSPI_IO_o(SOC_QSPI_IO_o),
    .QSPI_IO_i(SOC_QSPI_IO_i),
    .QSPI_IO_e(SOC_QSPI_IO_e)
);

POSC1N_18_18_NT_DR_H u_RT_CLK_OSC(
    .PADO(RT_CLK_XTAL2),
    .PADI(RT_CLK_XTAL1),
    .E0(1'b1),
    .TE(1'b0),
    .DS(),
    .CK(RT_CLK),
    .CK_IOV(),
    .SNS(),
    .PO(),
    .POE(1'b0),
    .RTO()
);

POSCP_18_18_NT_DR_H u_CLK_OSC(
    .PADO(REF_CLK_XTAL1),
    .PADI(REF_CLK_XTAL2),
    .E0(1'b1),
    .TE(1'b0),
    .SP(1'b1), //1.8V
    .SF0(1'b1),
    .SF1(1'b1), // Freq 24.1MHz to 48MHz
    .CK(CLK_IN),
    .CK_IOV(),
    .SNS(),
    .PO(),
    .POE(1'b0),
    .RTO()
);

PINCNPS_18_18_NT_DR_H u_PAD_PORESTn(
    .IE(1'b1),
    .IS(1'b1),
    .Y(),
    .PAD(PORESTn),
    .SNS(),
    .PO(),
    .POE(1'b0),
    .RTO()
);

PINCNPS_18_18_NT_DR_H u_PAD_nSRST(
    .IE(1'b1),
    .IS(1'b1),
    .Y(),
    .PAD(nSRST),
    .SNS(),
    .PO(),
    .POE(1'b0),
    .RTO()
);

// QSPI Interface
PBIDIRN_18_18_FS_DR_H u_PAD_QSPI_SCLK(
    .OE(1'b1),
    .A(SOC_QSPI_SCLK),
    .IE(1'b0),
    .IS(1'b0),
    .Y(),
    .PE(1'b0),
    .PS(1'b0),
    .PAD(QSPI_SCLK),
    .SNS(),
    .SR(1'b0),
    .DS0(1'b1),
    .DS1(1'b1),
    .PO(1'b0),
    .POE(),
    .RTO()
);

PBIDIRN_18_18_FS_DR_H u_PAD_QSPI_nCS(
    .OE(1'b1),
    .A(SOC_QSPI_nCS),
    .IE(1'b0),
    .IS(1'b0),
    .Y(),
    .PE(1'b0),
    .PS(1'b0),
    .PAD(QSPI_nCS),
    .SNS(),
    .SR(1'b0),
    .DS0(1'b1),
    .DS1(1'b1),
    .PO(1'b0),
    .POE(),
    .RTO()
);

PBIDIRN_18_18_FS_DR_H u_PAD_QSPI_IO_0(
    .OE(SOC_QSPI_IO_e[0]),
    .A(SOC_QSPI_IO_o[0]),
    .IE(~SOC_QSPI_IO_e[0]),
    .IS(1'b0),
    .Y(SOC_QSPI_IO_i[0]),
    .PE(1'b0),
    .PS(1'b0),
    .PAD(QSPI_IO[0]),
    .SNS(),
    .SR(1'b0),
    .DS0(1'b1),
    .DS1(1'b1),
    .PO(1'b0),
    .POE(),
    .RTO()
);

PBIDIRN_18_18_FS_DR_H u_PAD_QSPI_IO_1(
    .OE(SOC_QSPI_IO_e[1]),
    .A(SOC_QSPI_IO_o[1]),
    .IE(~SOC_QSPI_IO_e[1]),
    .IS(1'b0),
    .Y(SOC_QSPI_IO_i[1]),
    .PE(1'b0),
    .PS(1'b0),
    .PAD(QSPI_IO[1]),
    .SNS(),
    .SR(1'b0),
    .DS0(1'b1),
    .DS1(1'b1),
    .PO(1'b0),
    .POE(),
    .RTO()
);

PBIDIRN_18_18_FS_DR_H u_PAD_QSPI_IO_2(
    .OE(SOC_QSPI_IO_e[2]),
    .A(SOC_QSPI_IO_o[2]),
    .IE(~SOC_QSPI_IO_e[2]),
    .IS(1'b0),
    .Y(SOC_QSPI_IO_i[2]),
    .PE(1'b0),
    .PS(1'b0),
    .PAD(QSPI_IO[2]),
    .SNS(),
    .SR(1'b0),
    .DS0(1'b1),
    .DS1(1'b1),
    .PO(1'b0),
    .POE(),
    .RTO()
);

PBIDIRN_18_18_FS_DR_H u_PAD_QSPI_IO_3(
    .OE(SOC_QSPI_IO_e[3]),
    .A(SOC_QSPI_IO_o[3]),
    .IE(~SOC_QSPI_IO_e[3]),
    .IS(1'b0),
    .Y(SOC_QSPI_IO_i[3]),
    .PE(1'b0),
    .PS(1'b0),
    .PAD(QSPI_IO[3]),
    .SNS(),
    .SR(1'b0),
    .DS0(1'b1),
    .DS1(1'b1),
    .PO(1'b0),
    .POE(),
    .RTO()
);

endmodule
