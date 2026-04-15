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
`define INC_SYNOPSYS_LPDDR4
`define DWC_DDRPHY_NUM_DBYTES_2
`define DWC_DDRPHY_NUM_ANIBS_3
`define DWC_DDRPHY_CUST_PHYREV=0
`define DWC_DDRPHY_CUST_PUBREV=0
`define DWC_PUB_RID=9248
`define DWC_DDRPHY_NUM_TOP_SCAN_CHAINS=110

module megasoc_chip_pads(
    // Clocks and Reset
    input  wire         REF_CLK,
    input  wire         RT_CLK,
    input  wire         PORESTn,

    // SWD/JTAG TRACE - for Mictor 38
    output wire         TDO_SWO,
    input  wire         RTCK,
    input  wire         TDI,
    input  wire         TCK_SWCLK,
    inout  wire         TMS_SWDIO,
    input  wire         nTRST,

    // QSPI Interface
    output wire         QSPI_SCLK,
    inout  wire [3:0]   QSPI_IO,
    output wire         QSPI_nCS,

    // GPIO
    inout [15:0]        P0,
    inout [15:0]        P1,

    // PL011 UART
    input  wire         PL011_nUARTCTS,
    input  wire         PL011_nUARTDCD,
    input  wire         PL011_nUARTDSR,
    input  wire         PL011_nUARTRI,
    input  wire         PL011_UARTRXD,
    output wire         PL011_UARTTXD,
    output wire         PL011_nUARTOut2,
    output wire         PL011_nUARTOut1,
    output wire         PL011_nUARTRTS,
    output wire         PL011_nUARTDTR,

    // LPDDR4 Signals
    output wire         DDR4_RESET_N,
    output wire         DDR4_CK_T,
    output wire         DDR4_CK_C,
    output wire [1:0]   DDR4_CKE,
    output wire         DDR4_CS_N,
    output wire [5:0]   DDR4_ADR,
    output wire         DDR4_ODT,
    inout  wire [1:0]   DDR4_DQS_T,
    inout  wire [1:0]   DDR4_DQS_C,
    inout  wire [15:0]  DDR4_DQ,
    inout  wire [1:0]   DDR4_DM_DBI_N,
    inout  wire         DDR4_ALERT_N,
    inout  wire         DDR4_VREF,
    input  wire         DDR4_ZN_SENSE,
    output wire         DDR4_ZN,

    // SDIO
    output wire         SDIO_CK,
    inout  wire         SDIO_CMD,
    inout  wire [3:0]   SDIO_DAT,
    output wire         SD_O_1P8V

);

wire SOC_CLK_IN;
wire SOC_RT_CLK;

wire SOC_PORESTn;

// QSPI Internal Wires
wire SOC_QSPI_SCLK;
wire SOC_QSPI_nCS;
wire [3:0] SOC_QSPI_IO_o;
wire [3:0] SOC_QSPI_IO_i;
wire [3:0] SOC_QSPI_IO_e;

// SWD/JTAG Internal wires
wire         SOC_nTRST;
wire         SOC_SWCLKTCK;
wire         SOC_SWDITMS;
wire         SOC_TDI;
wire         SOC_TDO;
wire         SOC_nTDOEN;
wire         SOC_SWDO;
wire         SOC_SWDOEN;

// GPIO Internal wires
wire [15:0]  SOC_PAD_P0_IN;
wire [15:0]  SOC_PAD_P0_OUT;
wire [15:0]  SOC_PAD_P0_EN;

wire [15:0]  SOC_PAD_P1_IN;
wire [15:0]  SOC_PAD_P1_OUT;
wire [15:0]  SOC_PAD_P1_EN;

// PL011 UART internal wires
wire        SOC_PL011_nUARTCTS;
wire        SOC_PL011_nUARTDCD;
wire        SOC_PL011_nUARTDSR;
wire        SOC_PL011_nUARTRI;
wire        SOC_PL011_UARTRXD;

wire        SOC_PL011_UARTTXD;
wire        SOC_PL011_nUARTOut2;
wire        SOC_PL011_nUARTOut1;
wire        SOC_PL011_nUARTRTS;
wire        SOC_PL011_nUARTDTR;

// SDIO internal wires
wire             SOC_SDIO_CK;
wire             SOC_SDIO_CMD_tri;
wire             SOC_SDIO_CMD_o;
wire             SOC_SDIO_CMD_i;
wire [3:0]       SOC_SDIO_DAT_tri;
wire [3:0]       SOC_SDIO_DAT_o;
wire [3:0]       SOC_SDIO_DAT_i;
wire             SOC_SD_O_1P8V;

megasoc_chip u_megasoc_chip(
    .CLK_IN(SOC_CLK_IN),
    .RT_CLK(SOC_RT_CLK),

    .nRESET(SOC_PORESTn),

    // QSPI Interface
    .QSPI_SCLK(SOC_QSPI_SCLK),
    .QSPI_nCS(SOC_QSPI_nCS),
    .QSPI_IO_o(SOC_QSPI_IO_o),
    .QSPI_IO_i(SOC_QSPI_IO_i),
    .QSPI_IO_e(SOC_QSPI_IO_e),

    .nTRST(SOC_nTRST),
    .SWCLKTCK(SOC_SWCLKTCK),
    .SWDITMS(SOC_SWDITMS),
    .TDI(SOC_TDI),
    .TDO(SOC_TDO),
    .nTDOEN(SOC_nTDOEN),
    .SWDO(SOC_SWDO),
    .SWDOEN(SOC_SWDOEN),

    .PAD_P0_IN(SOC_PAD_P0_IN),
    .PAD_P0_OUT(SOC_PAD_P0_OUT),
    .PAD_P0_EN(SOC_PAD_P0_EN),
    .PAD_P1_IN(SOC_PAD_P1_IN),
    .PAD_P1_OUT(SOC_PAD_P1_OUT),
    .PAD_P1_EN(SOC_PAD_P1_EN),

    .PL011_nUARTCTS(SOC_PL011_nUARTCTS),
    .PL011_nUARTDCD(SOC_PL011_nUARTDCD),
    .PL011_nUARTDSR(SOC_PL011_nUARTDSR),
    .PL011_nUARTRI(SOC_PL011_nUARTRI),
    .PL011_UARTRXD(SOC_PL011_UARTRXD),
    .PL011_UARTTXD(SOC_PL011_UARTTXD),
    .PL011_nUARTOut2(SOC_PL011_nUARTOut2),
    .PL011_nUARTOut1(SOC_PL011_nUARTOut1),
    .PL011_nUARTRTS(SOC_PL011_nUARTRTS),
    .PL011_nUARTDTR(SOC_PL011_nUARTDTR),

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

    .SDIO_CK(SOC_SDIO_CK),
    .SDIO_CMD_tri(SOC_SDIO_CMD_tri),
    .SDIO_CMD_o(SOC_SDIO_CMD_o),
    .SDIO_CMD_i(SOC_SDIO_CMD_i),
    .SDIO_DAT_tri(SOC_SDIO_DAT_tri),
    .SDIO_DAT_o(SOC_SDIO_DAT_o),
    .SDIO_DAT_i(SOC_SDIO_DAT_i),
    .SD_O_1P8V(SOC_SD_O_1P8V)
);

wire RET;

PCBRTE_H u_PAD_RET(
    .IRTE(1'b0),
    .RTE(RET)
);

PDDWUWSWCDGS_H u_PAD_CLK_IN (
    .C(SOC_CLK_IN),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b0),
    .I(1'b0),
    .IE(1'b1),
    .OEN(1'b1),
    .PAD(REF_CLK),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_RT_CLK_IN (
    .C(SOC_RT_CLK),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b0),
    .I(1'b0),
    .IE(1'b1),
    .OEN(1'b1),
    .PAD(RT_CLK),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_PORSETn_IN (
    .C(SOC_PORESTn),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b0),
    .I(1'b0),
    .IE(1'b1),
    .OEN(1'b1),
    .PAD(PORESTn),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

// SWD/JTAG Pads
PDDWUWSWCDGS_H u_PAD_SWDIOTMS (
    .C(SOC_SWDITMS),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_SWDO),
    .IE(~SOC_SWDOEN),
    .OEN(~SOC_SWDOEN),
    .PAD(TMS_SWDIO),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_SWCLKTCK_IN (
    .C(SOC_SWCLKTCK),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b0),
    .I(1'b0),
    .IE(1'b0),
    .OEN(1'b0),
    .PAD(TCK_SWCLK),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b0),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_nTRST_IN (
    .C(SOC_nTRST),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b0),
    .I(1'b0),
    .IE(1'b1),
    .OEN(1'b1),
    .PAD(nTRST),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_TDI_IN (
    .C(SOC_TDI),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b0),
    .I(1'b0),
    .IE(1'b1),
    .OEN(1'b1),
    .PAD(TDI),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_TDO (
    .C(),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_TDO),
    .IE(1'b0),
    .OEN(1'b0),
    .PAD(TDO_SWO),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b0),
    .RTE(RET));


// QSPI Pads
PDDWUWSWCDGS_H u_PAD_QSPI_SCLK_OUT (
    .C(),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_QSPI_SCLK),
    .IE(1'b0),
    .OEN(1'b0),
    .PAD(QSPI_SCLK),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b0),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_QSPI_nCS_OUT (
    .C(),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_QSPI_nCS),
    .IE(1'b0),
    .OEN(1'b0),
    .PAD(QSPI_nCS),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b0),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_QSPI_IO_0 (
    .C(SOC_QSPI_IO_i[0]),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_QSPI_IO_o[0]),
    .IE(~SOC_QSPI_IO_e[0]),
    .OEN(~SOC_QSPI_IO_e[0]),
    .PAD(QSPI_IO[0]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_QSPI_IO_1 (
    .C(SOC_QSPI_IO_i[1]),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_QSPI_IO_o[1]),
    .IE(~SOC_QSPI_IO_e[1]),
    .OEN(~SOC_QSPI_IO_e[1]),
    .PAD(QSPI_IO[1]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_QSPI_IO_2 (
    .C(SOC_QSPI_IO_i[2]),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_QSPI_IO_o[2]),
    .IE(~SOC_QSPI_IO_e[2]),
    .OEN(~SOC_QSPI_IO_e[2]),
    .PAD(QSPI_IO[2]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_QSPI_IO_3 (
    .C(SOC_QSPI_IO_i[3]),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_QSPI_IO_o[3]),
    .IE(~SOC_QSPI_IO_e[3]),
    .OEN(~SOC_QSPI_IO_e[3]),
    .PAD(QSPI_IO[3]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));


// GPIO P0/1
PDDWUWSWCDGS_H u_PAD_P0_0 (
    .C(SOC_PAD_P0_IN[0]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[0]),
    .IE(~SOC_PAD_P0_EN[0]),
    .OEN(~SOC_PAD_P0_EN[0]),
    .PAD(P0[0]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_1 (
    .C(SOC_PAD_P0_IN[1]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[1]),
    .IE(~SOC_PAD_P0_EN[1]),
    .OEN(~SOC_PAD_P0_EN[1]),
    .PAD(P0[1]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_2 (
    .C(SOC_PAD_P0_IN[2]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[2]),
    .IE(~SOC_PAD_P0_EN[2]),
    .OEN(~SOC_PAD_P0_EN[2]),
    .PAD(P0[2]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_3 (
    .C(SOC_PAD_P0_IN[3]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[3]),
    .IE(~SOC_PAD_P0_EN[3]),
    .OEN(~SOC_PAD_P0_EN[3]),
    .PAD(P0[3]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_4 (
    .C(SOC_PAD_P0_IN[4]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[4]),
    .IE(~SOC_PAD_P0_EN[4]),
    .OEN(~SOC_PAD_P0_EN[4]),
    .PAD(P0[4]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_5 (
    .C(SOC_PAD_P0_IN[5]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[5]),
    .IE(~SOC_PAD_P0_EN[5]),
    .OEN(~SOC_PAD_P0_EN[5]),
    .PAD(P0[5]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_6 (
    .C(SOC_PAD_P0_IN[6]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[6]),
    .IE(~SOC_PAD_P0_EN[6]),
    .OEN(~SOC_PAD_P0_EN[6]),
    .PAD(P0[6]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_7 (
    .C(SOC_PAD_P0_IN[7]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[7]),
    .IE(~SOC_PAD_P0_EN[7]),
    .OEN(~SOC_PAD_P0_EN[7]),
    .PAD(P0[7]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_8 (
    .C(SOC_PAD_P0_IN[8]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[8]),
    .IE(~SOC_PAD_P0_EN[8]),
    .OEN(~SOC_PAD_P0_EN[8]),
    .PAD(P0[8]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_9 (
    .C(SOC_PAD_P0_IN[9]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[9]),
    .IE(~SOC_PAD_P0_EN[9]),
    .OEN(~SOC_PAD_P0_EN[9]),
    .PAD(P0[9]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_10 (
    .C(SOC_PAD_P0_IN[10]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[10]),
    .IE(~SOC_PAD_P0_EN[10]),
    .OEN(~SOC_PAD_P0_EN[10]),
    .PAD(P0[10]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_11 (
    .C(SOC_PAD_P0_IN[11]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[11]),
    .IE(~SOC_PAD_P0_EN[11]),
    .OEN(~SOC_PAD_P0_EN[11]),
    .PAD(P0[11]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_12 (
    .C(SOC_PAD_P0_IN[12]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[12]),
    .IE(~SOC_PAD_P0_EN[12]),
    .OEN(~SOC_PAD_P0_EN[12]),
    .PAD(P0[12]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_13 (
    .C(SOC_PAD_P0_IN[13]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[13]),
    .IE(~SOC_PAD_P0_EN[13]),
    .OEN(~SOC_PAD_P0_EN[13]),
    .PAD(P0[13]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_14 (
    .C(SOC_PAD_P0_IN[14]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[14]),
    .IE(~SOC_PAD_P0_EN[14]),
    .OEN(~SOC_PAD_P0_EN[14]),
    .PAD(P0[14]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P0_15 (
    .C(SOC_PAD_P0_IN[15]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P0_OUT[15]),
    .IE(~SOC_PAD_P0_EN[15]),
    .OEN(~SOC_PAD_P0_EN[15]),
    .PAD(P0[15]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));


PDDWUWSWCDGS_H u_PAD_P1_0 (
    .C(SOC_PAD_P1_IN[0]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[0]),
    .IE(~SOC_PAD_P1_EN[0]),
    .OEN(~SOC_PAD_P1_EN[0]),
    .PAD(P1[0]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_1 (
    .C(SOC_PAD_P1_IN[1]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[1]),
    .IE(~SOC_PAD_P1_EN[1]),
    .OEN(~SOC_PAD_P1_EN[1]),
    .PAD(P1[1]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_2 (
    .C(SOC_PAD_P1_IN[2]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[2]),
    .IE(~SOC_PAD_P1_EN[2]),
    .OEN(~SOC_PAD_P1_EN[2]),
    .PAD(P1[2]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_3 (
    .C(SOC_PAD_P1_IN[3]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[3]),
    .IE(~SOC_PAD_P1_EN[3]),
    .OEN(~SOC_PAD_P1_EN[3]),
    .PAD(P1[3]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_4 (
    .C(SOC_PAD_P1_IN[4]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[4]),
    .IE(~SOC_PAD_P1_EN[4]),
    .OEN(~SOC_PAD_P1_EN[4]),
    .PAD(P1[4]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_5 (
    .C(SOC_PAD_P1_IN[5]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[5]),
    .IE(~SOC_PAD_P1_EN[5]),
    .OEN(~SOC_PAD_P1_EN[5]),
    .PAD(P1[5]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_6 (
    .C(SOC_PAD_P1_IN[6]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[6]),
    .IE(~SOC_PAD_P1_EN[6]),
    .OEN(~SOC_PAD_P1_EN[6]),
    .PAD(P1[6]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_7 (
    .C(SOC_PAD_P1_IN[7]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[7]),
    .IE(~SOC_PAD_P1_EN[7]),
    .OEN(~SOC_PAD_P1_EN[7]),
    .PAD(P1[7]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_8 (
    .C(SOC_PAD_P1_IN[8]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[8]),
    .IE(~SOC_PAD_P1_EN[8]),
    .OEN(~SOC_PAD_P1_EN[8]),
    .PAD(P1[8]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_9 (
    .C(SOC_PAD_P1_IN[9]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[9]),
    .IE(~SOC_PAD_P1_EN[9]),
    .OEN(~SOC_PAD_P1_EN[9]),
    .PAD(P1[9]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_10 (
    .C(SOC_PAD_P1_IN[10]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[10]),
    .IE(~SOC_PAD_P1_EN[10]),
    .OEN(~SOC_PAD_P1_EN[10]),
    .PAD(P1[10]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_11 (
    .C(SOC_PAD_P1_IN[11]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[11]),
    .IE(~SOC_PAD_P1_EN[11]),
    .OEN(~SOC_PAD_P1_EN[11]),
    .PAD(P1[11]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_12 (
    .C(SOC_PAD_P1_IN[12]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[12]),
    .IE(~SOC_PAD_P1_EN[12]),
    .OEN(~SOC_PAD_P1_EN[12]),
    .PAD(P1[12]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_13 (
    .C(SOC_PAD_P1_IN[13]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[13]),
    .IE(~SOC_PAD_P1_EN[13]),
    .OEN(~SOC_PAD_P1_EN[13]),
    .PAD(P1[13]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_14 (
    .C(SOC_PAD_P1_IN[14]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[14]),
    .IE(~SOC_PAD_P1_EN[14]),
    .OEN(~SOC_PAD_P1_EN[14]),
    .PAD(P1[14]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_P1_15 (
    .C(SOC_PAD_P1_IN[15]),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b1),
    .I(SOC_PAD_P1_OUT[15]),
    .IE(~SOC_PAD_P1_EN[15]),
    .OEN(~SOC_PAD_P1_EN[15]),
    .PAD(P1[15]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

// PL011 UART Pads
PDDWUWSWCDGS_H u_PAD_PL011_nUARTCTS_IN (
    .C(SOC_PL011_nUARTCTS),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b0),
    .I(1'b0),
    .IE(1'b1),
    .OEN(1'b1),
    .PAD(PL011_nUARTCTS),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_PL011_nUARTDCD_IN (
    .C(SOC_PL011_nUARTDCD),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b0),
    .I(1'b0),
    .IE(1'b1),
    .OEN(1'b1),
    .PAD(PL011_nUARTDCD),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_PL011_nUARTDSR_IN (
    .C(SOC_PL011_nUARTDSR),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b0),
    .I(1'b0),
    .IE(1'b1),
    .OEN(1'b1),
    .PAD(PL011_nUARTDSR),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_PL011_nUARTRI_IN (
    .C(SOC_PL011_nUARTRI),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b0),
    .I(1'b0),
    .IE(1'b1),
    .OEN(1'b1),
    .PAD(PL011_nUARTRI),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_PL011_UARTRXD_IN (
    .C(SOC_PL011_UARTRXD),
    .DS0(1'b0),
    .DS1(1'b0),
    .DS2(1'b0),
    .DS3(1'b0),
    .I(1'b0),
    .IE(1'b1),
    .OEN(1'b1),
    .PAD(PL011_UARTRXD),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_PL011_UARTTXD_OUT (
    .C(),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_PL011_UARTTXD),
    .IE(1'b0),
    .OEN(1'b0),
    .PAD(PL011_UARTTXD),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b0),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_PL011_nUARTOut2_OUT (
    .C(),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_PL011_nUARTOut2),
    .IE(1'b0),
    .OEN(1'b0),
    .PAD(PL011_nUARTOut2),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b0),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_PL011_nUARTOut1_OUT (
    .C(),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_PL011_nUARTOut1),
    .IE(1'b0),
    .OEN(1'b0),
    .PAD(PL011_nUARTOut1),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b0),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_PL011_nUARTRTS_OUT (
    .C(),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_PL011_nUARTRTS),
    .IE(1'b0),
    .OEN(1'b0),
    .PAD(PL011_nUARTRTS),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b0),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_PL011_nUARTDTR_OUT (
    .C(),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_PL011_nUARTDTR),
    .IE(1'b0),
    .OEN(1'b0),
    .PAD(PL011_nUARTDTR),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b0),
    .RTE(RET));


// SDIO Pads
PDDWUWSWCDGS_H u_PAD_SDIO_CK_OUT (
    .C(),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_SDIO_CK),
    .IE(1'b0),
    .OEN(1'b0),
    .PAD(SDIO_CK),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b0),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_SDIO_CMD (
    .C(SOC_SDIO_CMD_i),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_SDIO_CMD_o),
    .IE(~SOC_SDIO_CMD_tri),
    .OEN(~SOC_SDIO_CMD_tri),
    .PAD(SDIO_CMD),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_SDIO_DAT_0 (
    .C(SOC_SDIO_DAT_i[0]),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_SDIO_DAT_o[0]),
    .IE(~SOC_SDIO_DAT_tri[0]),
    .OEN(~SOC_SDIO_DAT_tri[0]),
    .PAD(SDIO_DAT[0]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_SDIO_DAT_1 (
    .C(SOC_SDIO_DAT_i[1]),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_SDIO_DAT_o[1]),
    .IE(~SOC_SDIO_DAT_tri[1]),
    .OEN(~SOC_SDIO_DAT_tri[1]),
    .PAD(SDIO_DAT[1]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_SDIO_DAT_2 (
    .C(SOC_SDIO_DAT_i[2]),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_SDIO_DAT_o[2]),
    .IE(~SOC_SDIO_DAT_tri[2]),
    .OEN(~SOC_SDIO_DAT_tri[2]),
    .PAD(SDIO_DAT[2]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));
PDDWUWSWCDGS_H u_PAD_SDIO_DAT_3 (
    .C(SOC_SDIO_DAT_i[3]),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_SDIO_DAT_o[3]),
    .IE(~SOC_SDIO_DAT_tri[3]),
    .OEN(~SOC_SDIO_DAT_tri[3]),
    .PAD(SDIO_DAT[3]),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b1),
    .RTE(RET));

PDDWUWSWCDGS_H u_PAD_SD_O_1P8V_OUT (
    .C(),
    .DS0(1'b1),
    .DS1(1'b1),
    .DS2(1'b1),
    .DS3(1'b1),
    .I(SOC_SD_O_1P8V),
    .IE(1'b0),
    .OEN(1'b0),
    .PAD(SD_O_1P8V),
    .PU(1'b0),
    .PD(1'b0),
    .ST(1'b0),
    .RTE(RET));

endmodule
