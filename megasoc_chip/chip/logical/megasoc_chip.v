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
    input  wire             DDR_nEVENT,

    output wire             SDIO_CK,
    output wire             SDIO_CMD_tri,
    output wire             SDIO_CMD_o,
    input  wire             SDIO_CMD_i,
    output wire [3:0]       SDIO_DAT_tri,
    output wire [3:0]       SDIO_DAT_o,
    input  wire [3:0]       SDIO_DAT_i,
    output wire             SD_O_1P8V

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

wire        SDIO_o_cfg_ddr;
wire        SDIO_o_cfg_ds;
wire        SDIO_o_cfg_dscmd;
wire [4:0]  SDIO_o_cfg_sample_shift;
wire [7:0]  SDIO_o_sdclk;
wire        SDIO_o_cmd_en;
wire        SDIO_o_cmd_tristate;
wire [1:0]  SDIO_o_cmd_data;
wire        SDIO_o_data_en;
wire        SDIO_o_data_tristate;
wire        SDIO_o_rx_en;
wire [31:0] SDIO_o_tx_data;
wire [1:0]  SDIO_i_cmd_strb;
wire [1:0]  SDIO_i_cmd_data;
wire        SDIO_i_cmd_collision;
wire        SDIO_i_card_busy;
wire [1:0]  SDIO_i_rx_strb;
wire [15:0] SDIO_i_rx_data;
wire        SDIO_i_crcack;
wire        SDIO_i_crcnak;
wire        SDIO_AC_VALID;
wire [1:0]  SDIO_AC_DATA;
wire        SDIO_AD_VALID;
wire [31:0] SDIO_AD_DATA;

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
    .DDR_nEVENT(DDR_nEVENT),

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

`define VERILATOR
sdfrontend #(
    .OPT_SERDES(1'b0),
    .OPT_DDR(1'b0),
    .OPT_COLLISION(1'b0),
    .OPT_CRCTOKEN(1'b1),
    .NUMIO(4)
) u_sdio_frontend (
    .i_clk(CPU_CLK),
    .i_hsclk(CPU_CLK),
    .i_reset(~nRESET),
    .i_cfg_ddr(SDIO_o_cfg_ddr),
    .i_cfg_ds(SDIO_o_cfg_ds),
    .i_cfg_dscmd(SDIO_o_cfg_dscmd),
    .i_sample_shift(SDIO_o_cfg_sample_shift),
    .i_sdclk(SDIO_o_sdclk),
    .i_cmd_en(SDIO_o_cmd_en),
    .i_cmd_tristate(SDIO_o_cmd_tristate),
    .i_cmd_data(SDIO_o_cmd_data),
    .i_data_en(SDIO_o_data_en),
    .i_rx_en(SDIO_o_rx_en),
    .i_data_tristate(SDIO_o_data_tristate),
    .i_tx_data(SDIO_o_tx_data),
    .o_data_busy(SDIO_i_card_busy),
    .o_cmd_strb(SDIO_i_cmd_strb),
    .o_cmd_data(SDIO_i_cmd_data),
    .o_cmd_collision(SDIO_i_cmd_collision),
    .o_crcack(SDIO_i_crcack),
    .o_crcnak(SDIO_i_crcnak),
    .o_rx_strb(SDIO_i_rx_strb),
    .o_rx_data(SDIO_i_rx_data),
    .MAC_VALID(SDIO_AC_VALID),
    .MAC_DATA(SDIO_AC_DATA),
    .MAD_VALID(SDIO_AD_VALID),
    .MAD_DATA(SDIO_AD_DATA),

    .o_ck(SDIO_CK),
    .i_ds(1'b0),
    .io_cmd_tristate(SDIO_CMD_tri),
    .o_cmd(SDIO_CMD_o),
    .i_cmd(SDIO_CMD_i),
    .io_dat_tristate(SDIO_DAT_tri),
    .o_dat(SDIO_DAT_o),
    .i_dat(SDIO_DAT_i),

    .o_debug()
);

endmodule
