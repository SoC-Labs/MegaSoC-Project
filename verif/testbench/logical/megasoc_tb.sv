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

wire EXT_CLK;
wire nRESET;

wire         QSPI_SCLK;
wire [3:0]   QSPI_IO;
wire         QSPI_nCS;

megasoc_clkreset u_megasoc_clkreset(
    .CLK(EXT_CLK),
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
    .QSPI_nCS(QSPI_nCS)
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

endmodule
