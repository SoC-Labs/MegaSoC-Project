//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.1 (lin64) Build 5076996 Wed May 22 18:36:09 MDT 2024
//Date        : Fri Nov 15 14:43:17 2024
//Host        : srv03335 running 64-bit Red Hat Enterprise Linux release 8.10 (Ootpa)
//Command     : generate_target megasoc_design_wrapper.bd
//Design      : megasoc_design_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module megasoc_design_wrapper
   (
	inout wire      	QSPI_D0,
	inout wire      	QSPI_D1,
	inout wire      	QSPI_D2,
	inout wire      	QSPI_D3,
	output wire     	QSPI_SCLK,
	output wire     	QSPI_nCS,
    
    input  wire         CS_TDI,
    output wire         CS_TDO,        // SWV     / JTAG TDO
    inout  wire         CS_TMS,        // SWD I/O / JTAG TMS
    input  wire         CS_TCK,        // SWD Clk / JTAG TCK
    input  wire         CS_nSRST,
    input  wire         CS_nTRST,
    input  wire         CS_nDET



   );
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

  megasoc_design megasoc_design_i
       (.CLK_IN_0(CLK_IN_0),
        .nRESET_0(nRESET_0),

        .QSPI_IO_e_0(QSPI_IO_e),
        .QSPI_IO_i_0(QSPI_IO_i),
        .QSPI_IO_o_0(QSPI_IO_o),
        .QSPI_SCLK_0(QSPI_SCLK),
        .QSPI_nCS_0(QSPI_nCS),

        .SWCLKTCK_0(CS_TCK),
        .SWDITMS_0(SWDITMS_0),
        .SWDOEN_0(SWDOEN_0),
        .SWDO_0(SWDO_0),
        .TDI_0(CS_TDI),
        .TDO_0(CS_TDO),

        .UARTRXD_0(),
        .UARTTXD_0(),
        .UARTTXEN_0(),

        .nTDOEN_0(nTDOEN_0),
        .nTRST_0(CS_nTRST));
endmodule
