`timescale 1ns/1ps
// Testbench for the FPGA top (haps_top) as built: 20 MHz differential clock, reset button, UART idle, QSPI pulled up.
// Console = the bytes software writes to UART0's DATA register (baud independent), printed as they occur.
module tb_haps;
  reg clk_p = 0; always #25 clk_p = ~clk_p; wire clk_n = ~clk_p;
  reg reset_n = 0;
  wire uart_tx, hb, pl011_tx, dbg_tx, qspi_sclk, qspi_ncs;
  tri1 [3:0] qspi_io;
  haps_top dut (.HAPS_CLK_IN_P(clk_p), .HAPS_CLK_IN_N(clk_n), .HAPS_RESET_N(reset_n), .UART_TX(uart_tx), .UART_RX(1'b1), .HB(hb),
                .PL011_TX(pl011_tx), .DEBUG_UART_TX(dbg_tx), .QSPI_SCLK(qspi_sclk), .QSPI_nCS(qspi_ncs), .QSPI_IO(qspi_io));
  `define UART0 dut.u_soc.u_megasoc_system.u_megasoc_tech_wrapper.u_megasoc_peripheral_subsystem.u_apb_uart_0
  integer nchar = 0;
  time last_char_t = 0;
  always @(posedge `UART0.PCLK) if (`UART0.PSEL && `UART0.PENABLE && `UART0.PWRITE && `UART0.PADDR[11:2] == 10'h0) begin
    $write("%c", `UART0.PWDATA[7:0]); $fflush(); nchar++; last_char_t = $time;
    if (`UART0.PWDATA[7:0] == 8'h04) begin $display("\n[tb] end marker at %0t", $time); #1000; $finish; end
  end

  // ---- hang diagnosis: bus and cache RAM activity after the last console byte ----
  `define TW dut.u_soc.u_megasoc_system.u_megasoc_tech_wrapper
  `define CORE dut.u_soc.u_megasoc_system.u_megasoc_tech_wrapper.u_megasoc_cpu_ss.u_cortexa53
  `define L1RAMS `CORE.g_ca53_cpu[0].u_ca53_cpu.u_ca53_caches_tlb_rams
  `define L2DRAMS `CORE.u_ca53_l2.g_l2_rams.u_ca53_l2_datarams
  integer n_trace = 0, n_ar_a = 0, n_r_a = 0, n_aw_a = 0, n_w = 0, n_b = 0, n_aw_stall = 0, n_w_stall = 0, n_ar_stall = 0;
  integer n_ar = 0, n_r = 0, n_icd = 0, n_ict = 0, n_l2d = 0, n_aw = 0;
  reg armed = 0;
  always @(posedge `TW.SYS_CLK) begin
    if (`TW.CPU_AXI.ARVALID && `TW.CPU_AXI.ARREADY) begin n_ar++; if (armed) n_ar_a++; if (armed && n_ar_a < 400) $display("[ar] t=%0t addr=%h len=%0d size=%0d burst=%0d id=%0d", $time, `TW.CPU_AXI.ARADDR, `TW.CPU_AXI.ARLEN, `TW.CPU_AXI.ARSIZE, `TW.CPU_AXI.ARBURST, `TW.CPU_AXI.ARID); end
    if (`TW.CPU_AXI.RVALID && `TW.CPU_AXI.RREADY) begin n_r++; if (armed) n_r_a++; if (armed && n_r_a < 400) $display("[r ] t=%0t resp=%0d last=%0d id=%0d data=%h", $time, `TW.CPU_AXI.RRESP, `TW.CPU_AXI.RLAST, `TW.CPU_AXI.RID, `TW.CPU_AXI.RDATA); end
    if (`TW.CPU_AXI.AWVALID && `TW.CPU_AXI.AWREADY) begin n_aw++; if (armed) n_aw_a++; if (armed && n_aw_a < 400) $display("[aw] t=%0t addr=%h len=%0d size=%0d burst=%0d id=%0d", $time, `TW.CPU_AXI.AWADDR, `TW.CPU_AXI.AWLEN, `TW.CPU_AXI.AWSIZE, `TW.CPU_AXI.AWBURST, `TW.CPU_AXI.AWID); end
    if (`TW.CPU_AXI.WVALID && `TW.CPU_AXI.WREADY) begin n_w++; if (armed && n_w < 400) $display("[w ] t=%0t last=%0d strb=%h", $time, `TW.CPU_AXI.WLAST, `TW.CPU_AXI.WSTRB); end
    if (`TW.CPU_AXI.BVALID && `TW.CPU_AXI.BREADY) begin n_b++; if (armed && n_b < 400) $display("[b ] t=%0t resp=%0d id=%0d", $time, `TW.CPU_AXI.BRESP, `TW.CPU_AXI.BID); end
    if (armed && `TW.CPU_AXI.AWVALID && !`TW.CPU_AXI.AWREADY) n_aw_stall++;
    if (armed && `TW.CPU_AXI.WVALID && !`TW.CPU_AXI.WREADY) n_w_stall++;
    if (armed && `TW.CPU_AXI.ARVALID && !`TW.CPU_AXI.ARREADY) n_ar_stall++;
    if (|`L1RAMS.ic_dataram_en_i) begin n_icd++; if (armed && n_trace < 150) begin n_trace++; $display("[icd] t=%0t en=%b addr0=%h wr=%b strb=%h rd0=%h", $time, `L1RAMS.ic_dataram_en_i, `L1RAMS.ic_dataram_addr0_i, `L1RAMS.ic_dataram_wr_i, `L1RAMS.ic_dataram_strb0_i, `L1RAMS.ic_dataram_rdata0_o); end end
    if (|`L1RAMS.ic_tagram_en_i) begin if (armed && n_trace < 150) begin n_trace++; $display("[ict] t=%0t en=%b addr=%h wr=%b rd0=%h rd1=%h", $time, `L1RAMS.ic_tagram_en_i, `L1RAMS.ic_tagram_addr_i, `L1RAMS.ic_tagram_wr_i, `L1RAMS.ic_tagram_rdata0_o, `L1RAMS.ic_tagram_rdata1_o); end end
    if (|`L1RAMS.ic_tagram_en_i) n_ict++;
    if (|`L2DRAMS.l2_dataram_en_i) n_l2d++;
  end
  // arm the detailed trace at the 139th console byte (end of the "step 2: SCTLR.I = 1 ... " line), dump 60 us of the core
  always @(nchar) if (nchar == 269 && !armed) begin
    armed = 1; $display("\n[tb] ARMED at %0t: ar=%0d r=%0d aw=%0d icdata_en=%0d ictag_en=%0d l2data_en=%0d", $time, n_ar, n_r, n_aw, n_icd, n_ict, n_l2d);
    
    #60_000_000;
    $display("\n[tb] after 60 us: ar=%0d r=%0d aw=%0d icdata_en=%0d ictag_en=%0d l2data_en=%0d", n_ar, n_r, n_aw, n_icd, n_ict, n_l2d);
    // hang detection: stop when the console has been silent for 20 ms of SoC time (a passing run ends at the end marker)
    forever begin #1_000_000; $display("[tb] t=%0t chars=%0d ar=%0d r=%0d aw=%0d w=%0d b=%0d | stalls aw=%0d w=%0d ar=%0d | AWVALID=%b AWREADY=%b WVALID=%b WREADY=%b BVALID=%b ARVALID=%b ARREADY=%b RVALID=%b", $time, nchar, n_ar, n_r, n_aw, n_w, n_b, n_aw_stall, n_w_stall, n_ar_stall, `TW.CPU_AXI.AWVALID, `TW.CPU_AXI.AWREADY, `TW.CPU_AXI.WVALID, `TW.CPU_AXI.WREADY, `TW.CPU_AXI.BVALID, `TW.CPU_AXI.ARVALID, `TW.CPU_AXI.ARREADY, `TW.CPU_AXI.RVALID); if ($time - last_char_t > 300_000_000) begin $display("\n[tb] HANG: no console byte for 300 ms, last at %0t, chars=%0d", last_char_t, nchar); $finish; end end
  end
  // progress heartbeat and the core's SCTLR_EL3 cache bits once per 2 ms
  initial begin
    reset_n = 0; #2000; reset_n = 1;
    $display("[tb] reset released at %0t", $time);
    forever begin #2_000_000; $display("[tb] t=%0t  chars=%0d", $time, nchar); end
  end
  initial begin #2_000_000_000; $display("\n[tb] TIMEOUT at %0t after %0d chars", $time, nchar); $finish; end
endmodule
