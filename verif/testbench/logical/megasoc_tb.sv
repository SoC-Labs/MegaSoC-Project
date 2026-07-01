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

wire COM_CLK;
wire EXT_CLK; // 100 MHz crystal clock 
wire RT_CLK; // 32.768 kHz crystal clock
wire nRESET;

wire         QSPI_SCLK;
wire [3:0]   QSPI_IO;
wire         QSPI_nCS;
wire         nRESET_early;
wire [15:0]   P0;
wire [15:0]   P1;

wire         SDIO_CK;
wire         SDIO_DS;
wire         SDIO_CMD;
wire [3:0]   SDIO_DAT;
wire         SD_O_1P8V;

// Loopback PL011
wire         PL011_UARTTXRX;
wire         PL011_nUARTRTSCTS;
wire         PL011_nUARTOut1DCD;
wire         PL011_nUARTDTRDSR;
wire         PL011_nUARTOut2TRI;

megasoc_clkreset u_megasoc_clkreset(
    .CLK(EXT_CLK),
    .CLK_RT(RT_CLK),
    .CLK_COM(COM_CLK),
    .NRST(nRESET),
    .NRST_early(nRESET_early)
);

`define MEGASOC_TECH_WRAPPER u_megasoc_chip_pads.u_megasoc_chip.u_megasoc_system.u_megasoc_tech_wrapper
`define MEGASOC_ROM `MEGASOC_TECH_WRAPPER.u_ROM_wrapper.u_ROM
`define MEGASOC_SRAM `MEGASOC_TECH_WRAPPER.u_SRAM_wrapper.u_SRAM

initial begin 
    //$readmemh("bootloader.hex", `MEGASOC_ROM.mem, 32'h0000_0000);
    $readmemh("app_ram.v8-a.hex", `MEGASOC_SRAM.mem, 32'h0000_0000);
    //#1 $readmemh("app_flash.v8-a.hex", FLASH.I0.memory);

end

megasoc_chip_pads u_megasoc_chip_pads(
    .REF_CLK_XTAL1(EXT_CLK),
    .REF_CLK_XTAL2(),
    .RT_CLK_XTAL1(RT_CLK),
    .RT_CLK_XTAL2(),

    .PORESTn(nRESET),
    .nSRST(nRESET),

    .P0(P0),
    .P1(P1),

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

    .PL011_nUARTCTS(PL011_nUARTRTSCTS),
    .PL011_nUARTDCD(PL011_nUARTOut1DCD),
    .PL011_nUARTDSR(PL011_nUARTDTRDSR),
    .PL011_nUARTRI(PL011_nUARTOut2TRI),
    .PL011_UARTRXD(PL011_UARTTXRX),
    .PL011_UARTTXD(PL011_UARTTXRX),
    .PL011_nUARTOut2(PL011_nUARTOut2TRI),
    .PL011_nUARTOut1(PL011_nUARTOut1DCD),
    .PL011_nUARTRTS(PL011_nUARTRTSCTS),
    .PL011_nUARTDTR(PL011_nUARTDTRDSR),

    .SDIO_CK(SDIO_CK),
    .SDIO_CMD(SDIO_CMD),
    .SDIO_DAT(SDIO_DAT),
    .SD_O_1P8V(SD_O_1P8V)
);

pullup(SDIO_CMD);
pullup(SDIO_DAT[0]);
pullup(SDIO_DAT[1]);
pullup(SDIO_DAT[2]);
pullup(SDIO_DAT[3]);


//sst26vf064b FLASH(
//    .SCK(QSPI_SCLK),
//    .SIO(QSPI_IO),
//    .CEb(QSPI_nCS)
//);

N25Qxxx FLASH(
  .DQ0(QSPI_IO[0]),
  .DQ1(QSPI_IO[1]),
  .C_(QSPI_SCLK),
  .S(QSPI_nCS),
  .Vpp_W_DQ2(QSPI_IO[2]),
  .RESET2(nRESET_early),
  .HOLD_DQ3(QSPI_IO[3]),
  .Vcc('d1800)
);

// mdl_sdio (u_sd_card_model) removed: logical/sdspi was swapped from the
// ZipCPU fork to soclabs/sdio-controller, which does not carry bench/
// models. SDIO verification now goes through the Synopsys VC-VIP-SOC UVM
// testbench (top_VIP.flist / uvm_vip_tb.flist) instead of this BEHAV path.
// See flist/project/megasoc_tb.flist for the matching flist-side removal.

// GPIO P0 Loop
tran P0_0(P0[0],P0[8]);
tran P0_1(P0[1],P0[9]);
tran P0_2(P0[2],P0[10]);
tran P0_3(P0[3],P0[11]);
tran P0_4(P0[4],P0[12]);
tran P0_5(P0[5],P0[13]);
tran P0_6(P0[6],P0[14]);
tran P0_7(P0[7],P0[15]);

// GPIO P1 Loop
tran P1_UART0(P1[0],P1[3]);
tran P1_UART1(P1[1],P1[2]);

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
    .HADDR_i(`MEGASOC_QSPI_SUBSYSTEM.HADDR[21:0]),
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


// 4-channel AXIS interface - Subordinate side
  wire       axis_rx0_tready;
  wire       axis_rx0_tvalid;
  wire [7:0] axis_rx0_tdata8;
  wire       axis_rx1_tready;
  wire       axis_rx1_tvalid;
  wire [7:0] axis_rx1_tdata8;
  wire       axis_tx0_tready;
  wire       axis_tx0_tvalid;
  wire [7:0] axis_tx0_tdata8;
  wire       axis_tx1_tready;
  wire       axis_tx1_tvalid;
  wire [7:0] axis_tx1_tdata8;
// external io interface
  tri  [3:0] iodata4;
  wire [3:0] iodata4_i;
  wire [3:0] iodata4_o;
  wire [3:0] iodata4_e;
  wire [3:0] iodata4_t;
  wire       ioreq1;
  wire       ioreq2;
  wire       ioack;

wire test_done;

always @(posedge EXT_CLK) begin
    if(test_done) begin
        $stop;
    end
end

extio8x4_axis_target u_extio8x4_axis_target(
  .clk             ( COM_CLK             ),
  .resetn          ( nRESET            ),
  .testmode        ( 1'b0            ),
// RX 4-channel AXIS interface
  .axis_rx0_tready ( axis_rx0_tready ),
  .axis_rx0_tvalid ( axis_rx0_tvalid ),
  .axis_rx0_tdata8 ( axis_rx0_tdata8 ),
  .axis_rx1_tready ( axis_rx1_tready ),
  .axis_rx1_tvalid ( axis_rx1_tvalid ),
  .axis_rx1_tdata8 ( axis_rx1_tdata8 ),
  .axis_tx0_tready ( axis_tx0_tready ),
  .axis_tx0_tvalid ( axis_tx0_tvalid ),
  .axis_tx0_tdata8 ( axis_tx0_tdata8 ),
  .axis_tx1_tready ( axis_tx1_tready ),
  .axis_tx1_tvalid ( axis_tx1_tvalid ),
  .axis_tx1_tdata8 ( axis_tx1_tdata8 ),
// external io interface
  .iodata4_i       ( iodata4_i       ),
  .iodata4_o       ( iodata4_o       ),
  .iodata4_e       ( iodata4_e       ),
  .iodata4_t       ( iodata4_t       ),
  .ioreq1_a        ( ioreq1          ),
  .ioreq2_a        ( ioreq2          ),
  .ioack_o         ( ioack           )
);

// EXTIO trace to megaSoC P1 mapping
bufif0 #1 (P1[8], iodata4_o[0] , iodata4_t[0]);
bufif0 #1 (P1[9], iodata4_o[1] , iodata4_t[1]);
bufif0 #1 (P1[10], iodata4_o[2] , iodata4_t[2]);
bufif0 #1 (P1[11], iodata4_o[3] , iodata4_t[3]);
assign iodata4_i = P1[11:8];
assign ioreq1 = P1[12];
assign ioreq2 = P1[13];
assign P1[14] = ioack;
assign axis_rx1_tvalid = 1'b0;

  megasoc_axi_stream_io_8_rxd_to_file#(
    .RXDFILENAME("logs/extadp_out.log"),
    .VERBOSE(1)
  ) u_megasoc_axi_stream_io_stream_adp_rxd_to_file (
    .aclk         (COM_CLK),
    .aresetn      (nRESET),
    .eof_received (test_done),
    .rxd8_ready   (axis_tx0_tready),
    .rxd8_valid   (axis_tx0_tvalid),
    .rxd8_data    (axis_tx0_tdata8)
  );

  megasoc_axi_stream_io_8_rxd_to_file#(
    .RXDFILENAME("logs/extdat_out.log"),
    .VERBOSE(0)
  ) u_megasoc_axi_stream_io_stream_dat_rxd_to_file (
    .aclk         (COM_CLK),
    .aresetn      (nRESET),
    .eof_received (),
    .rxd8_ready   (axis_tx1_tready),
    .rxd8_valid   (axis_tx1_tvalid),
    .rxd8_data    (axis_tx1_tdata8)
  );

  reg ADP_nRESET;
  initial
    begin
      ADP_nRESET <= 1'b0;
    end

  always @(COM_CLK) begin
    if(QSPI_nCS==1'b0)
      ADP_nRESET<=1'b1;
  end


  megasoc_axi_stream_io_8_txd_from_file u_megasoc_axi_stream_io_8_txd_from_file(
    .aclk(COM_CLK),
    .aresetn(ADP_nRESET),
    .txd8_ready(axis_rx0_tready),
    .txd8_valid(axis_rx0_tvalid),
    .txd8_data(axis_rx0_tdata8)
  );

endmodule
