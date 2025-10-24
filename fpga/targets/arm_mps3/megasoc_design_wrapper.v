`timescale 1 ps / 1 ps

module megasoc_design_wrapper(
//------------------------------------------------------
// Port declarations
//------------------------------------------------------

// DDR
    // output wire         c0_ddr4_act_n,
    // output wire [16:0]  c0_ddr4_adr,
    // output wire [1:0]   c0_ddr4_ba,
    // output wire [0:0]   c0_ddr4_bg,
    // output wire [0:0]   c0_ddr4_cke,
    // output wire [0:0]   c0_ddr4_odt,
    // output wire [0:0]   c0_ddr4_cs_n,
    // output wire [0:0]   c0_ddr4_ck_t,
    // output wire [0:0]   c0_ddr4_ck_c,
    // output wire         c0_ddr4_reset_n,
    // inout  wire [7:0]   c0_ddr4_dm_dbi_n,
    // inout  wire [63:0]  c0_ddr4_dq,
    // inout  wire [7:0]   c0_ddr4_dqs_t,
    // inout  wire [7:0]   c0_ddr4_dqs_c,
    // input  wire         c0_sys_clk_p,
    // input  wire         c0_sys_clk_n,
    // input  wire         DDR_nALERT,
    // output wire         DDR_PARITY,
    // input               DDR_nEVENT,
    // output  wire        DDR_SCL,
    // inout   wire        DDR_SDA,
	
// SMB
//-----------
    output wire [6:0]   SMBF_ADDR,
    output wire         SMBF_FIFOSEL,
    inout  wire [15:0]  SMBF_DATA,
    output wire         SMBF_nOE,
    output wire         SMBF_nWE,
    output wire         SMBF_nRST,

    output wire         ETH_nCS,
    output wire         ETH_nOE,
    input  wire         ETH_INT,

    output wire         USB_nCS,
    output wire         USB_DACK,
    input  wire         USB_DREQ,
    input  wire         USB_INT,

// HDMI
//-----------
    output wire [23:0]  MMB_DATA,
    output wire         MMB_DE,
    output wire         MMB_HS,
    output wire         MMB_VS,
    output wire         MMB_IDCLK,
    output wire         MMB_SCK,
    output wire         MMB_WS,
    output wire [3:0]   MMB_SD,

    output wire         HDMI_CSCL,
    inout  wire         HDMI_CSDA,
    input  wire         HDMI_INT,

// Audio
//-----------
    output wire         AUD_MCLK,
    output wire         AUD_SCLK,
    output wire         AUD_LRCK,
    output wire         AUD_SDIN,
    input  wire         AUD_SDOUT,

    output wire         AUD_nRST,
    output wire         AUD_SCL,
    inout  wire         AUD_SDA,

// EMMC
//-----------
    inout  wire [7:0]   EMMC_DAT,
    inout  wire         EMMC_CMD,
    output wire         EMMC_CLK,
    output wire         EMMC_nRST,
    input  wire         EMMC_DS,

// CLCD
//-----------
    inout  wire [17:10] CLCD_PD,
    output wire         CLCD_RD,
    output wire         CLCD_RS,
    output wire         CLCD_CS,
    output wire         CLCD_WR_SCL,
    output wire         CLCD_BL,
    output wire         CLCD_RST,

    output wire         CLCD_TSCL,
    inout  wire         CLCD_TSDA,
    input  wire         CLCD_TINT,
    output wire         CLCD_TNC,

// UART
//-----------
    output wire [3:0]   UART_TX_F,

    input  wire [3:0]   UART_RX_F,

// DEBUG
//-----------
    input  wire         CS_TDI,
    output wire         CS_TDO,        // SWV     / JTAG TDO
    inout  wire         CS_TMS,        // SWD I/O / JTAG TMS
    input  wire         CS_TCK,        // SWD Clk / JTAG TCK
    input  wire         CS_nSRST,
    input  wire         CS_nTRST,
    input  wire         CS_nDET,

    output wire [15:0]  CS_T_D,        // Trace data
    output wire         CS_T_CLK,      // Trace clock
    output wire         CS_T_CTL,      // Trace control

// LED SW
//-----------
    output wire [9:0]   USER_nLED,
    input  wire [7:0]   USER_SW,
    input  wire [1:0]   USER_nPB,

// OSCCLK
//-----------
    input  wire [5:0]   OSCCLK,

// FMC
//-----------
    // input  wire [1:0]   CLK_M2C_P,
    // input  wire [1:0]   CLK_M2C_N,

    // input  wire         FMC_CLK_DIR,

    // inout  wire [3:2]   CLK_BIDIR_P,
    // inout  wire [3:2]   CLK_BIDIR_N,

    // inout  wire [23:0]  HA_P, // HA CLK=0,1,17
    // inout  wire [23:0]  HA_N,

    // inout  wire [21:0]  HB_P, // HB CLK=0,6,17
    // inout  wire [21:0]  HB_N,

    // inout  wire [33:0]  LA_P, // LA CLK=0,1,17,18
    // inout  wire [33:0]  LA_N,

    // input  wire [1:0]   GBTCLK_M2C_P,
    // input  wire [1:0]   GBTCLK_M2C_N,
// `ifdef GTH
    // input  wire [9:0]   DP_M2C_P,
    // input  wire [9:0]   DP_M2C_N,

    // output wire [9:0]   DP_C2M_P,
    // output wire [9:0]   DP_C2M_N,
// `endif
    // input  wire         FMC_nPRSNT,

    // input  wire         GTX_CLK_N,
    // input  wire         GTX_CLK_P,

    // input  wire         SATA_CLK_N,
    // input  wire         SATA_CLK_P,

// Quad SPI
//-----------	
	inout wire      	QSPI_D0,
	inout wire      	QSPI_D1,
	inout wire      	QSPI_D2,
	inout wire      	QSPI_D3,
	output wire     	QSPI_SCLK,
	output wire     	QSPI_nCS,

// USER SD
//-----------
    inout  wire [3:0]   USD_DAT,
    inout  wire         USD_CMD,
    output wire         USD_CLK,
    input  wire         USD_NCD,

// RESET
//-----------
    input  wire         CB_nPOR,
    input  wire         CB_nRST,
    input  wire         CB_RUN,

    input  wire         IOFPGA_NRST,
    input  wire         IOFPGA_NSPIR,

    output wire         IOFPGA_SYSWDT,
    input  wire         PB_IRQ,
    output wire         WDOG_RREQ,

// SCC
//-----------
    output wire         CFG_DATAOUT,
    input  wire         CFG_LOAD,
    input  wire         CFG_nRST,
    input  wire         CFG_CLK,
    input  wire         CFG_DATAIN,
    input  wire         CFG_WnR,

// MCC SMB
//-----------
    input  wire [25:16] SMBM_A,
    inout  wire [15:0]  SMBM_D,
    input  wire [4:1]   SMBM_nE,
    input  wire         SMBM_CLK,
    input  wire [1:0]   SMBM_nBL,
    input  wire         SMBM_nOE,
    input  wire         SMBM_nWE,
    output wire         SMBM_nWAIT,

// SHIELD
//-----------
    inout  wire [17:0]  SH0_IO,
    inout  wire [17:0]  SH1_IO,
    output wire         SH_nRST,

    output wire         SH_ADC_CS,
    output wire         SH_ADC_CK,
    output wire         SH_ADC_DI,
    input  wire         SH_ADC_DO
//   (PMOD0_0,
//    PMOD0_1,
//    PMOD0_2,
//    PMOD0_3,
//    PMOD0_4,
//    PMOD0_5,
//    PMOD0_6,
//    PMOD0_7
    );
//    PMOD1_0,
//    PMOD1_1,
//    PMOD1_2,
//    PMOD1_3,
//    PMOD1_4,
//    PMOD1_5,
//    PMOD1_6,
//    PMOD1_7,
//    dip_switch_4bits_tri_i,
//    led_4bits_tri_o);



//REFCLK24MHZ                 24        MHz
//******************************************************************************
BUFG uBUFG_REFCLK24MHZ    (.I(OSCCLK[0]), .O(REFCLK24MHZ));

//ACLK  Big CPU        50        MHz
//******************************************************************************
BUFG uBUFG_iACLK        (.I(OSCCLK[1]), .O(ACLK));        //Big CPU        50        MHz
BUFG uBUFG_iBCLK        (.I(OSCCLK[2]), .O(BCLK)); 
//******************************************************************************
// SMBMCLK     Micro SMB            25    MHz
//******************************************************************************
BUFG uBUFG_SMBM        (.I(SMBM_CLK),     .O(iSMBMCLK));    //Micro SMB

//******************************************************************************
// Main body of code
// =================
//******************************************************************************
  assign SMBF_FIFOSEL  = 1'b0;
  assign SMBF_ADDR	   = {7{1'b0}};
  assign CLCD_BL       = 1'b0;                     // Extinguish LCD back light
  // Minimum design tie-offs
  assign MMB_IDCLK     = 1'b0;
  assign EMMC_CLK      = 1'b0;
  assign IOFPGA_SYSWDT = 1'b0;
  assign WDOG_RREQ     = 1'b0;
  assign SMBM_nWAIT    = 1'b1;
  assign CFG_DATAOUT   = 1'b0;
  wire nRST;
  assign nRST = USER_nPB[0];
  assign USER_nLED[0] = nRST;

    wire SWDITMS_0;
    wire SWDOEN_0;
    wire SWDO_0;

    assign CS_TMS = (SWDOEN_0==1'b1) ? SWDO_0 : 1'bz;
    assign SWDITMS_0 = CS_TMS;
    
    wire [3:0] QSPI_IO_e;
    wire [3:0] QSPI_IO_i;
    wire [3:0] QSPI_IO_o;
    
	assign QSPI_D0 = (QSPI_IO_e[0]==1'b1)? QSPI_IO_o[0]:1'bz;
	assign QSPI_D1 = (QSPI_IO_e[1]==1'b1)? QSPI_IO_o[1]:1'bz;
	assign QSPI_D2 = (QSPI_IO_e[2]==1'b1)? QSPI_IO_o[2]:1'bz;
	assign QSPI_D3 = (QSPI_IO_e[3]==1'b1)? QSPI_IO_o[3]:1'bz;

    assign QSPI_IO_i[0] = QSPI_D0;
    assign QSPI_IO_i[1] = QSPI_D1;
    assign QSPI_IO_i[2] = QSPI_D2;
    assign QSPI_IO_i[3] = QSPI_D3;

wire [3:0] iodata4_i;
wire [3:0] iodata4_o;
wire [3:0] iodata4_e;
wire [3:0] iodata4_t;
wire       ioreq1_a;
wire       ioreq2_a;
wire       ioack_o;
  megasoc_tech_top megasoc_design_i
       (.CLK_IN(ACLK),
        .nRESET(nRST),

        .QSPI_IO_e(QSPI_IO_e),
        .QSPI_IO_i(QSPI_IO_i),
        .QSPI_IO_o(QSPI_IO_o),
        .QSPI_SCLK(QSPI_SCLK),
        .QSPI_nCS(QSPI_nCS),

        .UARTRXD0(UART_RX_F[1]),
        .UARTTXD0(UART_TX_F[1]),

        .SWCLKTCK(CS_TCK),
        .SWDITMS(SWDITMS_0),
        .SWDOEN(SWDOEN_0),
        .SWDO(SWDO_0),
        .TDI(CS_TDI),
        .TDO(CS_TDO),
        .nTDOEN(),
        .nTRST(CS_nTRST),
        
        .iodata4_i(iodata4_o),
        .iodata4_o(iodata4_i),
        .iodata4_e(),
        .iodata4_t(),
        .ioreq1_o(ioreq1_a),
        .ioreq2_o(ioreq2_a),
        .ioack_i(ioack_o)
    );

    wire m_axis_tready;
    wire [7:0] m_axis_tdata;
    wire m_axis_tvalid;
    
    wire s_axis_tvalid;
    wire [7:0] s_axis_tdata;
    wire s_axis_tready;

    uart u_uart(
        .clk(ACLK),
        .rxd(UART_RX_F[2]),
        .txd(UART_TX_F[2]),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tready(s_axis_tready)
    );
    
    extio8x4_axis_target u_extio_target(
        .clk(ACLK),
        .resetn(nRST),
        .testmode(1'b0),
 
        .axis_rx0_tready(m_axis_tready),
        .axis_rx0_tvalid(m_axis_tvalid),
        .axis_rx0_tdata8(m_axis_tdata),
        .axis_rx1_tready(),
        .axis_rx1_tvalid(1'b0),
        .axis_rx1_tdata8(8'h00),
        .axis_tx0_tready(s_axis_tready),
        .axis_tx0_tvalid(s_axis_tvalid),
        .axis_tx0_tdata8(s_axis_tdata),
        .axis_tx1_tready(1'b0),
        .axis_tx1_tvalid(),
        .axis_tx1_tdata8(),

        .iodata4_i(iodata4_i),
        .iodata4_o(iodata4_o),
        .iodata4_e(),
        .iodata4_t(),
        .ioreq1_a(ioreq1_a),
        .ioreq2_a(ioreq2_a),
        .ioack_o(ioack_o)
    );
endmodule
