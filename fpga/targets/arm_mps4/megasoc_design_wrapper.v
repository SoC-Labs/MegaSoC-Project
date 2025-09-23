`timescale 1 ps / 1 ps

module megasoc_design_wrapper(
//------------------------------------------------------
// Port declarations
//------------------------------------------------------
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
    input  wire [5:0]   OSCCLKA,

// Quad SPI
//-----------	
	inout wire [3:0]  	QSPI_D,
	output wire     	QSPI_SCLK,
	output wire     	QSPI_nCS,

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

// SHIELD
//-----------
    inout  wire [15:0]  SH0_IO,
    inout  wire [15:0]  SH1_IO,
    output wire         SH_nRST,

    output wire         SH_ADC_CS,
    output wire         SH_ADC_CK_R,
    output wire         SH_ADC_DI,
    input  wire         SH_ADC_DO
    );


wire REFCLK24MHZ;
wire ACLK;
wire BCLK;

//REFCLK24MHZ                 24        MHz
//******************************************************************************
BUFG uBUFG_REFCLK24MHZ    (.I(OSCCLKA[0]), .O(REFCLK24MHZ));

//ACLK  Big CPU        50        MHz
//******************************************************************************
BUFG uBUFG_iACLK        (.I(OSCCLKA[1]), .O(ACLK));        //Big CPU        50        MHz
BUFG uBUFG_iBCLK        (.I(OSCCLKA[2]), .O(BCLK)); 

//******************************************************************************
// Main body of code
// =================
//******************************************************************************

  wire nRST;
  reg  rst_sync0, rst_sync1, rst_sync2;
  assign nRST_in = CB_nRST || CS_nSRST;
  assign nRST = rst_sync2;

  always @(posedge ACLK)
    if (~nRST_in) begin
      rst_sync0 <= 1'b0;
      rst_sync1 <= 1'b0;
    end else begin
      rst_sync0 <= 1'b1;
      rst_sync1 <= rst_sync0;
      rst_sync2 <= rst_sync1;
    end

    wire SWDITMS_0;
    wire SWDOEN_0;
    wire SWDO_0;

    assign CS_TMS = (SWDOEN_0==1'b1) ? SWDO_0 : 1'bz;
    assign SWDITMS_0 = CS_TMS;
    
    wire [3:0] QSPI_IO_e;
    wire [3:0] QSPI_IO_i;
    wire [3:0] QSPI_IO_o;
    
	assign QSPI_D[0] = (QSPI_IO_e[0]==1'b1)? QSPI_IO_o[0]:1'bz;
	assign QSPI_D[1] = (QSPI_IO_e[1]==1'b1)? QSPI_IO_o[1]:1'bz;
	assign QSPI_D[2] = (QSPI_IO_e[2]==1'b1)? QSPI_IO_o[2]:1'bz;
	assign QSPI_D[3] = (QSPI_IO_e[3]==1'b1)? QSPI_IO_o[3]:1'bz;

    assign QSPI_IO_i[0] = QSPI_D[0];
    assign QSPI_IO_i[1] = QSPI_D[1];
    assign QSPI_IO_i[2] = QSPI_D[2];
    assign QSPI_IO_i[3] = QSPI_D[3];

  megasoc_design megasoc_design_i
       (.CLK_IN_0(ACLK),
        .nRESET_0(nRST),

        .QSPI_IO_e_0(QSPI_IO_e),
        .QSPI_IO_i_0(QSPI_IO_i),
        .QSPI_IO_o_0(QSPI_IO_o),
        .QSPI_SCLK_0(QSPI_SCLK),
        .QSPI_nCS_0(QSPI_nCS),

        .UARTRXD_0(UART_RX_F[1]),
        .UARTTXD_0(UART_TX_F[1]),

        .SWCLKTCK_0(CS_TCK),
        .SWDITMS_0(SWDITMS_0),
        .SWDOEN_0(SWDOEN_0),
        .SWDO_0(SWDO_0),
        .TDI_0(CS_TDI),
        .TDO_0(CS_TDO),
        .nTDOEN_0(),
        .nTRST_0(CS_nTRST));

endmodule
