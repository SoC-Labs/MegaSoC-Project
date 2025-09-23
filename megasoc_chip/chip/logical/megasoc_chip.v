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

    // DAP-lite Signals
    input  wire         nTRST,
    input  wire         SWCLKTCK,
    input  wire         SWDITMS,
    input  wire         TDI,
    output wire         TDO,
    output wire         nTDOEN,
    output wire         SWDO,
    output wire         SWDOEN,

    input  wire [15:0]  PAD_P0_IN,
    output wire [15:0]  PAD_P0_OUT,
    output wire [15:0]  PAD_P0_EN,

    input  wire [15:0]  PAD_P1_IN,
    output wire [15:0]  PAD_P1_OUT,
    output wire [15:0]  PAD_P1_EN,

    // DDR4 signals
    output wire             DDR4_CK_T,
    output wire             DDR4_CK_C,

    output wire [16:0]      DDR4_ADR,
    output wire [1:0]       DDR4_BA,
    output wire [1:0]       DDR4_BG,

    output wire             DDR4_ACT_n,
    output wire [1:0]       DDR4_CKE,
    output wire [1:0]       DDR4_CS_N,
    output wire [1:0]       DDR4_ODT,
    output wire             DDR_PARITY,

    inout  wire [63:0]      DDR4_DQ,
    inout  wire [7:0]       DDR4_DM_DBI_N,
    inout  wire [7:0]       DDR4_DQS_T,
    inout  wire [7:0]       DDR4_DQS_C,

    output wire             DDR4_RESET_N,

    input  wire             DDR_nALERT,
    input  wire             DDR_nEVENT

);

wire CPU_CLK;
wire SYS_CLK;

megasoc_clock_ctrl u_megasoc_clock_ctrl(
    .CLK_IN(CLK_IN),
    .PORESTn(nRESET),
    .PADDR(),
    .PWDATA(),
    .PWRITE(),
    .PPROT(),
    .PSTRB(),
    .PENABLE(),
    .PSELx(),
    .PRDATA(),
    .PSLVERR(),
    .PREADY(),
    .SYS_CLK(),
    .CPU_CLK(CPU_CLK)
);


wire [15:0] SOC_P0_IN;
wire [15:0] SOC_P0_OUT;
wire [15:0] SOC_P0_EN;
wire [15:0] SOC_P0_FUNC;
wire [15:0] SOC_P0_ALT_IN;
wire [15:0] SOC_P0_ALT_OUT;
wire [15:0] SOC_P0_ALT_EN;

wire [15:0] SOC_P1_IN;
wire [15:0] SOC_P1_OUT;
wire [15:0] SOC_P1_EN;
wire [15:0] SOC_P1_FUNC;
wire [15:0] SOC_P1_ALT_IN;
wire [15:0] SOC_P1_ALT_OUT;
wire [15:0] SOC_P1_ALT_EN;

wire        UARTRXD0;
wire        UARTTXD0;
wire        UARTTXEN0;

wire        UARTRXD1;
wire        UARTTXD1;
wire        UARTTXEN1;

wire        SPI_SSn;
wire        SPI_SCLK;
wire        SPI_MOSI;
wire        SPI_MISO;

wire [3:0]  iodata4_i;
wire [3:0]  iodata4_o;
wire [3:0]  iodata4_e;
wire [3:0]  iodata4_t;
wire        ioreq1_o;
wire        ioreq2_o;
wire        ioack_i;

// UART0 RX to P1[0]
assign UARTRXD0 = SOC_P1_ALT_IN[0];
assign SOC_P1_ALT_EN[0]=1'b0;
assign SOC_P1_ALT_OUT[0] = 1'b0;

// UART0 TX to P1[1]
assign SOC_P1_ALT_OUT[1] = UARTTXD0;
assign SOC_P1_ALT_EN[1] = UARTTXEN0;

// UART1 RX to P1[2]
assign UARTRXD1 = SOC_P1_ALT_IN[2];
assign SOC_P1_ALT_EN[2]=1'b0;
assign SOC_P1_ALT_OUT[2] = 1'b0;

// UART0 TX to P1[3]
assign SOC_P1_ALT_OUT[3] = UARTTXD1;
assign SOC_P1_ALT_EN[3] = UARTTXEN1;

// SPI SSn to P1[4]
assign SOC_P1_ALT_OUT[4] = SPI_SSn;
assign SOC_P1_ALT_EN[4] = 1'b1;

// SPI SCLK to P1[5]
assign SOC_P1_ALT_OUT[5] = SPI_SCLK;
assign SOC_P1_ALT_EN[5] = 1'b1;

// SPI MOSI to P1[6]
assign SOC_P1_ALT_OUT[6] = SPI_MOSI;
assign SOC_P1_ALT_EN[6] = 1'b1;

// SPI MISO to P1[7]
assign SPI_MISO = SOC_P1_ALT_IN[7];
assign SOC_P1_ALT_EN[7]=1'b0;
assign SOC_P1_ALT_OUT[7] = 1'b0;

// EXTIO DATA[0] to P1[8]
assign iodata4_i[0] = SOC_P1_ALT_IN[8];
assign SOC_P1_ALT_EN[8] = iodata4_e[0];
assign SOC_P1_ALT_OUT[8] = iodata4_o[0];

// EXTIO DATA[1] to P1[9]
assign iodata4_i[1] = SOC_P1_ALT_IN[9];
assign SOC_P1_ALT_EN[9] = iodata4_e[1];
assign SOC_P1_ALT_OUT[9] = iodata4_o[1];

// EXTIO DATA[2] to P1[10]
assign iodata4_i[2] = SOC_P1_ALT_IN[10];
assign SOC_P1_ALT_EN[10] = iodata4_e[2];
assign SOC_P1_ALT_OUT[10] = iodata4_o[2];

// EXTIO DATA[3] to P1[11]
assign iodata4_i[3] = SOC_P1_ALT_IN[11];
assign SOC_P1_ALT_EN[11] = iodata4_e[3];
assign SOC_P1_ALT_OUT[11] = iodata4_o[3];

// EXTIO REQ1 MOSI to P1[12]
assign SOC_P1_ALT_OUT[12] = ioreq1_o;
assign SOC_P1_ALT_EN[12] = 1'b1;

// EXTIO REQ2 MOSI to P1[13]
assign SOC_P1_ALT_OUT[13] = ioreq2_o;
assign SOC_P1_ALT_EN[13] = 1'b1;

// EXTIO ACK MOSI to P1[14]
assign ioack_i = SOC_P1_ALT_IN[14];
assign SOC_P1_ALT_EN[14]=1'b0;
assign SOC_P1_ALT_OUT[14] = 1'b0;

assign SOC_P1_ALT_EN[15] = 1'b0;
assign SOC_P1_ALT_OUT[15] = 1'b0;

assign SOC_P0_ALT_EN = 16'd0;
assign SOC_P0_ALT_OUT = 16'd0;

megasoc_system u_megasoc_system(
    .CLK_IN(CPU_CLK),
    .RT_CLK(RT_CLK),
    .nRESET(nRESET),

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

    .P0_IN(SOC_P0_IN),
    .P0_OUT(SOC_P0_OUT),
    .P0_EN(SOC_P0_EN),
    .P0_FUNC(SOC_P0_FUNC),
    .P1_IN(SOC_P1_IN),
    .P1_OUT(SOC_P1_OUT),
    .P1_EN(SOC_P1_EN),
    .P1_FUNC(SOC_P1_FUNC),

    .DDR4_CK_T(DDR4_CK_T),
    .DDR4_CK_C(DDR4_CK_C),
    .DDR4_ADR(DDR4_ADR),
    .DDR4_BA(DDR4_BA),
    .DDR4_BG(DDR4_BG),
    .DDR4_ACT_n(DDR4_ACT_n),
    .DDR4_CKE(DDR4_CKE),
    .DDR4_CS_N(DDR4_CS_N),
    .DDR4_ODT(DDR4_ODT),
    .DDR_PARITY(DDR_PARITY),
    .DDR4_DQ(DDR4_DQ),
    .DDR4_DM_DBI_N(DDR4_DM_DBI_N),
    .DDR4_DQS_T(DDR4_DQS_T),
    .DDR4_DQS_C(DDR4_DQS_C),
    .DDR4_RESET_N(DDR4_RESET_N),
    .DDR_nALERT(DDR_nALERT),
    .DDR_nEVENT(DDR_nEVENT)

);

megasoc_chip_pin_mux u_pin_mux(
    .SOC_P0_IN(SOC_P0_IN),
    .SOC_P0_OUT(SOC_P0_OUT),
    .SOC_P0_EN(SOC_P0_EN),
    .SOC_P0_FUNC(SOC_P0_FUNC),
    .SOC_P0_ALT_IN(SOC_P0_ALT_IN),
    .SOC_P0_ALT_OUT(SOC_P0_ALT_OUT),
    .SOC_P0_ALT_EN(SOC_P0_ALT_EN),

    .SOC_P1_IN(SOC_P1_IN),
    .SOC_P1_OUT(SOC_P1_OUT),
    .SOC_P1_EN(SOC_P1_EN),
    .SOC_P1_FUNC(SOC_P1_FUNC),
    .SOC_P1_ALT_IN(SOC_P1_ALT_IN),
    .SOC_P1_ALT_OUT(SOC_P1_ALT_OUT),
    .SOC_P1_ALT_EN(SOC_P1_ALT_EN),

    .PAD_P0_IN(PAD_P0_IN),
    .PAD_P0_OUT(PAD_P0_OUT),
    .PAD_P0_EN(PAD_P0_EN),

    .PAD_P1_IN(PAD_P1_IN),
    .PAD_P1_OUT(PAD_P1_OUT),
    .PAD_P1_EN(PAD_P1_EN)
);

endmodule