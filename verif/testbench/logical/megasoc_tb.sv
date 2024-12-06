//-----------------------------------------------------------------------------
// MegaSoC Chip testbench
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// Daniel Newbrook (d.newbrook@soton.ac.uk)
// 
// Copyright � 2021-4, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
// Modules instantiated:
//  megasoc_chip_pads
`timescale 1ns/1ps

module megasoc_tb();

`define CORTEXA53_UNIVENT_DPI_CAPTURE
`define CORTEXA53_UNIVENT 

wire EXT_CLK; // 100 MHz crystal clock 
wire RT_CLK; // 32.768 kHz crystal clock
wire nRESET;

wire         QSPI_SCLK;
wire [3:0]   QSPI_IO;
wire         QSPI_nCS;
wire         FT_CLK;   
wire         FT_SSN;   
wire         FT_MISO;  
wire         FT_MIOSIO;

wire        ft_miosio_i;
wire        ft_miosio_o;
wire        ft_miosio_z;

assign ft_miosio_i = FT_MIOSIO;
bufif1 #1 (FT_MIOSIO, ft_miosio_o, !ft_miosio_z);


megasoc_clkreset u_megasoc_clkreset(
    .CLK(EXT_CLK),
    .CLK_RT(RT_CLK),
    .NRST(nRESET)
);

`define MEGASOC_TECH_WRAPPER u_megasoc_chip_pads.u_megasoc_chip.u_megasoc_system.u_megasoc_tech_wrapper
`define MEGASOC_ROM `MEGASOC_TECH_WRAPPER.u_ROM_wrapper.u_ROM
`define MEGASOC_SRAM `MEGASOC_TECH_WRAPPER.u_SRAM_wrapper.u_SRAM

initial begin 
    //$readmemh("bootloader.hex", `MEGASOC_ROM.mem, 32'h0000_0000);
    $readmemh("app_ram.v8-a.hex", `MEGASOC_SRAM.mem, 32'h0000_0000);
    #1 $readmemh("app_flash.v8-a.hex", FLASH.I0.memory);

end

megasoc_chip_pads u_megasoc_chip_pads(
    .REF_CLK_XTAL1(EXT_CLK),
    .REF_CLK_XTAL2(),
    .RT_CLK_XTAL1(RT_CLK),
    .RT_CLK_XTAL2(),
    .PORESTn(nRESET),
    .nSRST(nRESET),
    .GPIO_P0(),
    .GPIO_P1(),
    .TDO_SWO(), 
    .RTCK(),
    .TDI(),
    .TCK_SWCLK(), 
    .TMS_SWDIO(), 
    .nTRST(),
    .TRACEDATA(),
    .TRACECLK(),
    .TRACECTL(),
    .DBGRQ(),
    .DBGACK(),
    .QSPI_SCLK(QSPI_SCLK),
    .QSPI_IO(QSPI_IO),
    .QSPI_nCS(QSPI_nCS),
    .FT_CLK(FT_CLK),
    .FT_SSN(FT_SSN),
    .FT_MISO(FT_MISO),
    .FT_MIOSIO(FT_MIOSIO)
);

sst26vf064b FLASH(
    .SCK(QSPI_SCLK),
    .SIO(QSPI_IO),
    .CEb(QSPI_nCS)
);

`define MEGASOC_PERIPHERALS u_megasoc_chip_pads.u_megasoc_chip.u_megasoc_system.u_megasoc_tech_wrapper.u_megasoc_peripheral_subsystem
`define MEGASOC_UART `MEGASOC_PERIPHERALS.u_apb_uart_0

// Clock 100 MHz
// Baudrate 115200
wire BAUDx16;
assign BAUDx16 = `MEGASOC_UART.BAUDTICK;


wire UARTXD =  `MEGASOC_UART.TXD;
reg  UARTXD_del;
always @(negedge nRESET or posedge BAUDx16) begin
    if (!nRESET)
        UARTXD_del <= 1'b0;
    else
        UARTXD_del <= UARTXD; // delay one BAUD_TICK-time
end

wire UARTXD_edge = UARTXD_del ^ UARTXD; // edge detect


reg [3:0] pllq;
always @(negedge nRESET or posedge BAUDx16) begin 
    if(~nRESET) 
        pllq <= 4'h0;
    else begin 
        if (UARTXD_edge)
            pllq[3:0] <= 4'b0110;
        else 
            pllq[3:0] <= pllq[3:0] -1'b1;
    end
end

wire baud_clk = pllq[3];

wire uart_clk;

megasoc_uart_capture #(.LOGFILENAME("logs/uart.log"), .VERBOSE(1)) u_uart_capture(
    .RESETn(nRESET),
    .CLK(baud_clk),
    .RXD(UARTXD),
    .DEBUG_TESTER_ENABLE  (),
    .SIMULATIONEND        (),      // This signal set to 1 at the end of simulation.
    .AUXCTRL              ()
);


`define MEGASOC_QSPI_SUBSYSTEM `MEGASOC_TECH_WRAPPER.u_sl_ahb_qspi

megasoc_qspi_capture #(
    .FILENAME("logs/qspi_ahb.log"),
    .SYS_ADDR_W(22),
    .SYS_DATA_W(32)
) u_megasoc_qspi_capture (
    .HCLK(`MEGASOC_QSPI_SUBSYSTEM.HCLK),
    .HRESETn(`MEGASOC_QSPI_SUBSYSTEM.HRESETn),
    .HSEL_i(`MEGASOC_QSPI_SUBSYSTEM.HSELx),
    .HADDR_i(`MEGASOC_QSPI_SUBSYSTEM.HADDR),
    .HTRANS_i(`MEGASOC_QSPI_SUBSYSTEM.HTRANS),
    .HSIZE_i(`MEGASOC_QSPI_SUBSYSTEM.HSIZE),
    .HPROT_i(`MEGASOC_QSPI_SUBSYSTEM.HPROT),
    .HWRITE_i(`MEGASOC_QSPI_SUBSYSTEM.HWRITE),
    .HREADY_i(`MEGASOC_QSPI_SUBSYSTEM.HREADY),
    .HWDATA_i(`MEGASOC_QSPI_SUBSYSTEM.HWDATA),
    .HREADYOUT_o(`MEGASOC_QSPI_SUBSYSTEM.HREADYOUT),
    .HRDATA_o(`MEGASOC_QSPI_SUBSYSTEM.HRDATA),
    .HRESP_o(`MEGASOC_QSPI_SUBSYSTEM.HRESP)
);


wire rxd8_tvalid;
wire rxd8_tready;
wire[7:0] rxd8_tdata;

megasoc_ft1248x1_to_axi_streamio_v1_0 u_ft1248_to_axi_stream(
    .ft_clk_i(FT_CLK),
    .ft_ssn_i(FT_SSN),
    .ft_miso_o(FT_MISO),
    .ft_miosio_i(ft_miosio_i),
    .ft_miosio_o(ft_miosio_o),
    .ft_miosio_z(ft_miosio_z),
    .aclk(EXT_CLK),
    .aresetn(nRESET),
    .txd_tvalid_o(rxd8_tvalid),
    .txd_tdata8_o(rxd8_tdata),
    .txd_tready_i(rxd8_tready),
    .rxd_tready_o(),
    .rxd_tdata8_i(8'h00),
    .rxd_tvalid_i(1'b0)
);


megasoc_axi_stream_io_8_rxd_to_file#(
    .RXDFILENAME("logs/ft1248_out.log")
) u_megasoc_axi_stream_io_8_rxd_to_file (
    .aclk         (EXT_CLK),
    .aresetn      (nRESET),
    .eof_received ( ),
    .rxd8_ready   (rxd8_tready),
    .rxd8_valid   (rxd8_tvalid),
    .rxd8_data    (rxd8_tdata)
  );


wire ft_clk2uart;
wire ft_rxd2uart;
wire ft_txd2uart;

megasoc_ft1248x1_track
  u_megasoc_ft1248x1_track
  (
  .ft_clk_i     (FT_CLK),
  .ft_ssn_i     (FT_SSN),
  .ft_miso_i    (FT_MISO),
  .ft_miosio_i  (ft_miosio_i),
  .aclk         (EXT_CLK),
  .aresetn      (nRESET),
  .FTDI_CLK2UART_o      (ft_clk2uart),  // Clock (baud rate)
  .FTDI_OP2UART_o       (ft_rxd2uart),  // Received data to UART capture
  .FTDI_IP2UART_o       (ft_txd2uart)   // Transmitted data to UART capture
  );

  megasoc_uart_capture  #(.LOGFILENAME("logs/ft1248_op.log"), .VERBOSE(1))
    u_megasoc_uart_capture1(
    .RESETn               (nRESET),
    .CLK                  (ft_clk2uart),
    .RXD                  (ft_rxd2uart),
    .DEBUG_TESTER_ENABLE  ( ), //debug_test_en2), //driven by u_nanosoc_track_tb_iostream
    .SIMULATIONEND        (),      // This signal set to 1 at the end of simulation.
    .AUXCTRL              ()
  );


endmodule
