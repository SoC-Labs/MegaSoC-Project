//-----------------------------------------------------------------------------
// MegaSoC SDIO VIP Testbench Top
//
// Additive verification infrastructure only. Instantiates megasoc_chip_pads
// (and therefore megasoc_chip) completely unmodified -- identical to
// verif/testbench/logical/megasoc_tb.sv -- and connects the Synopsys
// VC-VIP-SOC eMMC/SD card agent at the existing SDIO_CK/SDIO_CMD/SDIO_DAT
// pins in place of mdl_sdio.v. mdl_sdio.v and the rest of
// megasoc_tech/logical/sdspi/bench/verilog/ are untouched and remain a
// fully independent verification path.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

`include "svt_emmc.uvm.pkg"
`include "svt_emmc_if.svi"
`include "svt_emmc_phy_link_if.svi"
`include "uvm_pkg.sv"

`include "sim_done_if.sv"

module tb_top();

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import svt_uvm_pkg::*;
  import svt_mem_uvm_pkg::*;
  import svt_emmc_uvm_pkg::*;

  // sdio_base_test.sv (and the card_cfg.sv / sdio_card_env.sv files it
  // `includes) must be brought in here, after the imports above -- not
  // at file scope -- so its class declarations can see uvm_test,
  // svt_emmc_card_agent_configuration etc. Matches the reference
  // example's top.sv/top_test.sv placement.
  `include "sdio_base_test.sv"
  `include "sdio_vip_tc3_test.sv"

  // vplan MEGASOC-BOOT-006 (full boot via SD card image into DRAM): preloads
  // the card model with the boot image. Same placement rules as above.
  `include "sdio_full_boot_test.sv"

`define CORTEXA53_UNIVENT_DPI_CAPTURE
`define CORTEXA53_UNIVENT

  wire COM_CLK;
  wire EXT_CLK; // 100 MHz crystal clock
  wire RT_CLK;  // 32.768 kHz crystal clock
  wire nRESET;

  // LPDDR4 DRAM (INC_LPDDR4 builds), connected as in megasoc_tb.sv: 400 MHz
  // controller/DFI clock and the Synopsys LPDDR VIP device model (x16, rank
  // 0, ODT unused, ALERT_N pulled up, VREF high). Tied low otherwise.
  reg          DDR_CLK = 1'b0;
  wire         LPDDR4_RESET_N;
  wire         LPDDR4_CK_T;
  wire         LPDDR4_CK_C;
  wire [1:0]   LPDDR4_CKE;
  wire [1:0]   LPDDR4_CS;
  wire [5:0]   LPDDR4_CA;
  wire         LPDDR4_ODT;
  wire [1:0]   LPDDR4_DQS_T;
  wire [1:0]   LPDDR4_DQS_C;
  wire [15:0]  LPDDR4_DQ;
  wire [1:0]   LPDDR4_DMI;
  wire         LPDDR4_ALERT_N;
  wire         LPDDR4_VREF;
  wire         LPDDR4_ZN;

`ifdef INC_LPDDR4
  always #1.25 DDR_CLK = ~DDR_CLK;

  pullup(LPDDR4_ALERT_N);
  // Supply strength, so the PHY model cannot turn VREF into X
  assign (supply1, supply0) LPDDR4_VREF = 1'b1;

  lpddr_model u_lpddr4_memory(
    .ck_t    (LPDDR4_CK_T),
    .ck_c    (LPDDR4_CK_C),
    .cke     (LPDDR4_CKE[0]),
    .cs      (LPDDR4_CS[0]),
    .odt     (1'b0),
    .ca      (LPDDR4_CA),
    .dm      (LPDDR4_DMI),
    .dqs_t   (LPDDR4_DQS_T),
    .dqs_c   (LPDDR4_DQS_C),
    .dq      (LPDDR4_DQ),
    .reset_n (LPDDR4_RESET_N)
  );

  // DRAM bring-up markers for the run log (same text as megasoc_tb.sv)
  always @(LPDDR4_RESET_N) $display("[%0t] LPDDR4_MON: RESET_N = %b", $time, LPDDR4_RESET_N);
  always @(LPDDR4_CKE[0])  if ($isunknown(LPDDR4_CKE[0])) $display("[%0t] LPDDR4_MON: CKE[0] = x <-- UNKNOWN", $time);
`endif

  wire         QSPI_SCLK;
  wire [3:0]   QSPI_IO;
  wire         QSPI_nCS;
  wire         nRESET_early;
  wire [15:0]  P0;
  wire [15:0]  P1;

  wire         SDIO_CK;
  wire         SDIO_DS;
  wire         SDIO_CMD;
  wire [3:0]   SDIO_DAT;
  wire         SD_O_1P8V;

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
    $readmemh("app_ram.v8-a.hex", `MEGASOC_SRAM.mem, 32'h0000_0000);
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
    .SD_O_1P8V(SD_O_1P8V),

    // LPDDR4 DRAM (idle unless INC_LPDDR4)
    .DDR_CLK_IN(DDR_CLK),
    .LPDDR4_RESET_N(LPDDR4_RESET_N),
    .LPDDR4_CK_T(LPDDR4_CK_T),
    .LPDDR4_CK_C(LPDDR4_CK_C),
    .LPDDR4_CKE(LPDDR4_CKE),
    .LPDDR4_CS(LPDDR4_CS),
    .LPDDR4_CA(LPDDR4_CA),
    .LPDDR4_ODT(LPDDR4_ODT),
    .LPDDR4_DQS_T(LPDDR4_DQS_T),
    .LPDDR4_DQS_C(LPDDR4_DQS_C),
    .LPDDR4_DQ(LPDDR4_DQ),
    .LPDDR4_DMI(LPDDR4_DMI),
    .LPDDR4_ALERT_N(LPDDR4_ALERT_N),
    .LPDDR4_VREF(LPDDR4_VREF),
    .LPDDR4_ZN_SENSE(1'b0),
    .LPDDR4_ZN(LPDDR4_ZN)
  );

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

  //---------------------------------------------------------------------
  // VC-VIP-SOC eMMC/SD card agent, connected in place of mdl_sdio.v.
  // Card-only: there is no host_if/host_agent anywhere in this file or
  // in sdio_card_env.sv. The real host is megasoc_chip's SDIO controller
  // RTL, driven only via AXI-Lite by the embedded software image loaded
  // above -- this interface never drives SDIO_CMD/SDIO_DAT from a UVM
  // host sequence.
  //---------------------------------------------------------------------
  bit vip_if_clk;
  parameter VIP_IF_CLK_PERIOD_NS = 20; // 50 MHz helper clock for VIP-internal sampling only -- distinct from the DUT-generated SDIO_CK bus clock
  initial begin
    vip_if_clk = 0;
    forever #(VIP_IF_CLK_PERIOD_NS/2) vip_if_clk = ~vip_if_clk;
  end

  svt_emmc_if card_if (vip_if_clk);

  bit card_vss1, card_vss2, card_vdd;
  initial begin
    card_if.rst_n = 1;
    card_vss1 = 1;
    card_vss2 = 1;
    card_vdd  = 0;
    #`SVT_EMMC_RESET_LOW_TO_HIGH_DURATION_NS;
    card_vss1 = 0;
    card_vss2 = 0;
    card_vdd  = 1;
  end
  assign card_if.vss1_vss     = card_vss1;
  assign card_if.vss2         = card_vss2;
  assign card_if.vdd_vdd1_vcc = card_vdd;

  // SD pin mapping (4-bit mode; dat1/dat2/dat3 carry IRQ/CS functions in
  // other protocols but are plain data lines here since card_type == SD).
  // SDIO_CMD/SDIO_DAT are genuine open-drain tri-state nets (pad driver +
  // pullup + card driver all sharing one electrical node) -- merge them
  // with tran, the same primitive megasoc_tb.sv already uses for its GPIO
  // loopback (tran P0_0(P0[0],P0[8]);). A pair of reciprocal `assign`s
  // here would add two more unconditional drivers on top of the real
  // ones instead of sharing a single node, and was the root cause of the
  // card agent never observing any bus traffic in the first VIP run.
  assign card_if.clk_sclk = SDIO_CK;
  tran sdio_cmd_short  (SDIO_CMD,    card_if.cmd_di);
  tran sdio_dat0_short (SDIO_DAT[0], card_if.dat0_rclk_plus);
  tran sdio_dat1_short (SDIO_DAT[1], card_if.dat1_rclk_minus_irq);
  tran sdio_dat2_short (SDIO_DAT[2], card_if.dat2_rw_irq);
  tran sdio_dat3_short (SDIO_DAT[3], card_if.cd_dat3_cs);

  pullup(SDIO_CMD);
  pullup(SDIO_DAT[0]);
  pullup(SDIO_DAT[1]);
  pullup(SDIO_DAT[2]);
  pullup(SDIO_DAT[3]);

  initial begin
    uvm_config_db#(svt_emmc_vif)::set(uvm_root::get(), "uvm_test_top.sd_env", "sd_card_vif", card_if);
  end

  //---------------------------------------------------------------------
  // Bridge embedded-software completion (TEST_PASS()/TEST_FAIL(), which
  // both end in UartEndSimulation() sending a 0x04 EOT byte) into a UVM
  // virtual interface. This is the only thing sdio_base_test's main_phase
  // waits on before dropping its objection -- see sim_done_if.sv for why.
  //
  // Two independent latches feed this, below:
  //   1. megasoc_uart_capture's SIMULATIONEND pulse (sim_end_pulse) --
  //      decodes the 0x04 bit-by-bit off the real apb_uart_0 TXD pin.
  //   2. extio_eof (megasoc_axi_stream_io_8_rxd_to_file's EOF marker on
  //      the AXI-stream "ADP" path) -- the one that actually fires under
  //      this bench's +define+CORTEX_A53 +define+USE_TARMAC compile
  //      configuration; see BENCH.md changelog for the full root-cause
  //      trace (megasoc_uart_capture's whole baud_clk domain is dead: the
  //      Cortex-A53 "univent" DPI capture redirects the software's UART
  //      output through the ADP path instead of the real UART peripheral,
  //      so apb_uart_0's TXD/BAUDTICK never toggle). #2 is latched next to
  //      its own signal declaration further down this file; both write the
  //      same `done` bit so either path working is sufficient.
  //---------------------------------------------------------------------
  sim_done_if u_sim_done_if();

  initial u_sim_done_if.done = 1'b0;

  initial begin
    uvm_config_db#(virtual sim_done_if)::set(null, "*", "sim_done_vif", u_sim_done_if);
  end

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

  wire BAUDx16;
  assign BAUDx16 = `MEGASOC_UART.BAUDTICK;

  wire UARTXD =  `MEGASOC_UART.TXD;
  reg  UARTXD_del;
  always @(negedge nRESET or posedge BAUDx16) begin
    if (!nRESET)
      UARTXD_del <= 1'b0;
    else
      UARTXD_del <= UARTXD;
  end

  wire UARTXD_edge = UARTXD_del ^ UARTXD;

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

  wire sim_end_pulse;

  megasoc_uart_capture #(.LOGFILENAME("logs/uart.log"), .VERBOSE(1)) u_uart_capture(
    .RESETn(nRESET),
    .CLK(baud_clk),
    .RXD(UARTXD),
    .DEBUG_TESTER_ENABLE  (),
    .SIMULATIONEND        (sim_end_pulse),
    .AUXCTRL              ()
  );

  always @(posedge sim_end_pulse) begin
    u_sim_done_if.done <= 1'b1;
  end

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

  extio8x4_axis_target u_extio8x4_axis_target(
    .clk             ( COM_CLK             ),
    .resetn          ( nRESET            ),
    .testmode        ( 1'b0            ),
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
    .iodata4_i       ( iodata4_i       ),
    .iodata4_o       ( iodata4_o       ),
    .iodata4_e       ( iodata4_e       ),
    .iodata4_t       ( iodata4_t       ),
    .ioreq1_a        ( ioreq1          ),
    .ioreq2_a        ( ioreq2          ),
    .ioack_o         ( ioack           )
  );

  bufif0 #1 (P1[8], iodata4_o[0] , iodata4_t[0]);
  bufif0 #1 (P1[9], iodata4_o[1] , iodata4_t[1]);
  bufif0 #1 (P1[10], iodata4_o[2] , iodata4_t[2]);
  bufif0 #1 (P1[11], iodata4_o[3] , iodata4_t[3]);
  assign iodata4_i = P1[11:8];
  assign ioreq1 = P1[12];
  assign ioreq2 = P1[13];
  assign P1[14] = ioack;
  assign axis_rx1_tvalid = 1'b0;

  wire extio_eof;

  megasoc_axi_stream_io_8_rxd_to_file#(
    .RXDFILENAME("logs/extadp_out.log"),
    .VERBOSE(1)
  ) u_megasoc_axi_stream_io_stream_adp_rxd_to_file (
    .aclk         (COM_CLK),
    .aresetn      (nRESET),
    .eof_received (extio_eof),
    .rxd8_ready   (axis_tx0_tready),
    .rxd8_valid   (axis_tx0_tvalid),
    .rxd8_data    (axis_tx0_tdata8)
  );

  //---------------------------------------------------------------------
  // Second, working path into sim_done_vif.done: extio_eof.
  //
  // Root cause (see BENCH.md changelog): under this bench's compile
  // configuration (+define+CORTEX_A53 +define+USE_TARMAC), the embedded
  // software's UartPutc()-driven output (including UartEndSimulation()'s
  // trailing 0x04 EOT byte) never toggles the real apb_uart_0 TXD pin --
  // confirmed by instrumentation: BAUDTICK/TXD/rx_shift_reg inside
  // megasoc_uart_capture stay at their reset values for the entire run, so
  // sim_end_pulse (SIMULATIONEND) never fires and the block above never
  // latches done. The Cortex-A53 "univent" DPI capture (`define
  // CORTEXA53_UNIVENT/_DPI_CAPTURE above) instead redirects that same
  // console text through this AXI-stream "ADP" path -- confirmed by
  // logs/extadp_out.log actually containing the firmware's printf output.
  // megasoc_axi_stream_io_8_rxd_to_file (this instance) applies the exact
  // same "0x04 ends the stream" rule as megasoc_uart_capture and asserts
  // extio_eof accordingly; this is the same proven mechanism
  // megasoc_tb.sv / megasoc_smoke_checker.sv already rely on (as
  // "test_done") for every other MegaSoC firmware test under this CPU
  // model, so it is the reliable one here too. Latch done from whichever
  // path fires first/at all.
  //---------------------------------------------------------------------
  always @(posedge extio_eof) begin
    u_sim_done_if.done <= 1'b1;
  end

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
  initial begin
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

  initial begin
    run_test();
  end

endmodule
