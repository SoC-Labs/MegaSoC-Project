// tb_busy.v - 25 Nov 2026. Unit bench for the card-busy detection of sdfrontend after a transmitted data block
// (MBT-72 / MBT-75). The real sdckgen makes the SD clock; a small card model answers the end of the host's block with
// the CRC status token (2 clocks, start, 3 status bits, end) and then holds DAT0 low for BUSY_US microseconds.
// Reports whether o_data_busy ever read 0 while the card was still busy.
`timescale 1ns/1ps
module tb_busy;
  parameter [7:0] CKSPD   = 8'd3;      // 3 = sysclk/4
  parameter       BUSY_US = 230;       // card busy after the token
  parameter       TOKEN   = 1;         // 1 = accepted (010), 2 = CRC error (101), 0 = no token
  parameter       MODE    = 0;         // 0 = data block, 1 = R1b command (no data), 2 = read then nothing
  reg clk = 0, reset = 1;
  always #25 clk = ~clk;               // 20 MHz as on the HAPS
  wire ckstb, hlfck, clk90; wire [7:0] ckwide, ckspd_o;
  sdckgen u_ck (.i_clk(clk), .i_reset(reset), .i_cfg_clk90(1'b0), .i_cfg_ckspd(CKSPD), .i_cfg_shutdown(1'b0),
                .o_ckstb(ckstb), .o_hlfck(hlfck), .o_ckwide(ckwide), .o_clk90(clk90), .o_ckspd(ckspd_o));
  reg data_en = 0, rx_en = 0, cmd_en = 0;
  reg card_d0 = 1, card_oe = 0, card_busy = 0;
  wire [3:0] o_dat, dat_tri; wire o_ck, busy, crcack, crcnak;
  wire [3:0] i_dat = { 3'b111, (!dat_tri[0]) ? o_dat[0] : (card_oe ? card_d0 : 1'b1) };
  sdfrontend #(.OPT_SERDES(1'b0), .OPT_DDR(1'b0), .OPT_COLLISION(1'b0), .OPT_CRCTOKEN(1'b1), .NUMIO(4)) dut (
    .i_clk(clk), .i_hsclk(1'b0), .i_reset(reset), .i_cfg_ddr(1'b0), .i_cfg_ds(1'b0), .i_cfg_dscmd(1'b0),
    .i_sample_shift(5'd0), .i_sdclk(ckwide), .i_cmd_en(cmd_en), .i_cmd_tristate(!cmd_en), .i_cmd_data(2'b11),
    .i_data_en(data_en), .i_rx_en(rx_en), .i_data_tristate(!data_en), .i_tx_data(32'hffff_ffff),
    .o_data_busy(busy), .o_cmd_strb(), .o_cmd_data(), .o_cmd_collision(), .o_crcack(crcack), .o_crcnak(crcnak),
    .o_rx_strb(), .o_rx_data(), .MAC_VALID(), .MAC_DATA(), .MAD_VALID(), .MAD_DATA(),
    .o_ck(o_ck), .i_ds(1'b0), .io_cmd_tristate(), .o_cmd(), .i_cmd(1'b1),
    .io_dat_tristate(dat_tri), .o_dat(o_dat), .i_dat(i_dat), .o_debug());
  // ---- measurements
  integer missed = 0, acks = 0, naks = 0;
  real t_end = 0, t_busy0 = 0, t_busy1 = 0, t_rdy = 0, t_first_miss = 0;
  reg seen_busy_after = 0;
  always @(posedge clk) begin
    if (crcack) acks = acks + 1;
    if (crcnak) naks = naks + 1;
    // the card's busy is "missed" if the front end reports ready while DAT0 is held low by the card.
    // Allow 3 system clocks for the input path at the start of busy.
    if (card_busy && ($realtime - t_busy0) > 200.0 && !busy) begin
      if (missed == 0) t_first_miss = $realtime;
      missed = missed + 1;
    end
    if (t_busy1 != 0 && t_rdy == 0 && !busy) t_rdy = $realtime;
  end
  // ---- card
  task card_token_and_busy;
    begin
      if (TOKEN != 0) begin
        repeat (2) @(posedge o_ck);
        @(negedge o_ck); card_oe = 1; card_d0 = 0;
        @(negedge o_ck); card_d0 = (TOKEN == 2);
        @(negedge o_ck); card_d0 = (TOKEN == 1);
        @(negedge o_ck); card_d0 = (TOKEN == 2);
        @(negedge o_ck); card_d0 = 1;
        @(negedge o_ck);
      end
      if (TOKEN == 1) begin
        card_d0 = 0; card_busy = 1; t_busy0 = $realtime;
        #(BUSY_US * 1000.0);
        @(negedge o_ck); card_d0 = 1; card_busy = 0; t_busy1 = $realtime;
        @(negedge o_ck);
      end else begin t_busy1 = $realtime; end
      card_oe = 0;
    end
  endtask
  integer k;
  initial begin
    repeat (8) @(posedge clk); reset = 0; repeat (40) @(posedge clk);
    if (MODE == 0) begin
      @(posedge clk); while (!ckstb) @(posedge clk);
      data_en <= 1;
      for (k = 0; k < 64; k = k + 1) begin @(posedge clk); while (!ckstb) @(posedge clk); end
      data_en <= 0; t_end = $realtime;
      card_token_and_busy;
    end else if (MODE == 1) begin
      @(posedge clk); while (!ckstb) @(posedge clk);
      cmd_en <= 1;
      for (k = 0; k < 48; k = k + 1) begin @(posedge clk); while (!ckstb) @(posedge clk); end
      cmd_en <= 0; t_end = $realtime;
      repeat (2) @(negedge o_ck);
      card_oe = 1; card_d0 = 0; card_busy = 1; t_busy0 = $realtime;
      #(BUSY_US * 1000.0);
      @(negedge o_ck); card_d0 = 1; card_busy = 0; t_busy1 = $realtime;
      @(negedge o_ck); card_oe = 0;
    end
    repeat (400) @(posedge clk);
    while (busy && ($realtime - t_busy1) < 400000.0) @(posedge clk);
    repeat (20) @(posedge clk);
    $display("RESULT mode=%0d ckspd=0x%02x token=%0d busy_us=%0d | ack=%0d nak=%0d | ready-while-busy clocks=%0d%s | busy released by front end %0.1f us after the card%s",
      MODE, CKSPD, TOKEN, BUSY_US, acks, naks, missed,
      (missed != 0) ? " (BUSY MISSED)" : "", (t_rdy - t_busy1) / 1000.0, (busy) ? " (STILL BUSY at end)" : "");
    if (missed != 0) $display("       first ready-while-busy %0.1f us after the end of the host block, %0.1f us into the card's busy",
      (t_first_miss - t_end) / 1000.0, (t_first_miss - t_busy0) / 1000.0);
    $finish;
  end
  initial begin #(60_000_000_000.0); $display("RESULT TIMEOUT"); $finish; end
endmodule
