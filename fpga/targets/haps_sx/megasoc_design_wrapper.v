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
   (CLK_IN_P,
   CLK_IN_N,
    //QSPI_IO_e_0,
    //QSPI_IO_i_0,
    //QSPI_IO_o_0,
    //QSPI_SCLK_0,
    //QSPI_nCS_0,
    nRESET_0);
    
  input CLK_IN_P;
  input CLK_IN_N;
  //output [3:0]QSPI_IO_e_0;
  //input [3:0]QSPI_IO_i_0;
  //output [3:0]QSPI_IO_o_0;
  //output QSPI_SCLK_0;
  //output QSPI_nCS_0;
  input nRESET_0;

  wire CLK_IN_P;
  wire CLK_IN_N;
  wire [3:0]QSPI_IO_e_0;
  wire [3:0]QSPI_IO_i_0;
  wire [3:0]QSPI_IO_o_0;
  wire QSPI_SCLK_0;
  wire QSPI_nCS_0;
  wire nRESET_0;

  megasoc_design megasoc_design_i
       (.CLK_P(CLK_IN_P),
       .CLK_N(CLK_IN_N),
        .QSPI_IO_e_0(QSPI_IO_e_0),
        .QSPI_IO_i_0(QSPI_IO_i_0),
        .QSPI_IO_o_0(QSPI_IO_o_0),
        .QSPI_SCLK_0(QSPI_SCLK_0),
        .QSPI_nCS_0(QSPI_nCS_0),
        .nRESET_0(nRESET_0)
    );
endmodule
