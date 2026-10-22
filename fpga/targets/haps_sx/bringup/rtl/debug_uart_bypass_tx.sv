`timescale 1ns / 1ps
`default_nettype none

//------------------------------------------------------------------------
// debug_uart_bypass_tx  (TEMPORARY DIAGNOSTIC MODULE)
//
// Continuously streams the fixed byte 0x55 ('U', alternating 01010101 -
// easy to recognize on a scope or terminal) out uart_tx back-to-back as
// fast as the UART allows, entirely independent of debug_uart_probe's
// FIFO/edge-detect/pending logic and of every probe_bus signal it watches.
//
// Purpose: isolate whether DEBUG_UART_TX's electrical path (pin, PMOD3
// cable, terminal port/baud) actually works, without going anywhere near
// JTAG/ILA (confirmed unreliable at 20MHz) and without depending on any
// of the logic that's the actual subject of investigation.
//
// - "UUUUUUUU..." (or recognizable garbage, if baud is somehow off)
//   appears on the terminal -> electrical/terminal path is fine, the bug
//   is definitely inside debug_uart_probe's own logic.
// - nothing appears at all -> the problem is upstream of any RTL we've
//   been debugging (wrong pin/cable/terminal port), not a logic bug.
//
// Delete this module and haps_top.sv's temporary instantiation of it
// once the bypass test has answered that question.
//------------------------------------------------------------------------
module debug_uart_bypass_tx #(
  parameter integer CLK_FREQ_HZ = 20_000_000,
  parameter integer BAUD_RATE   = 115200
)(
  input  wire clk,
  input  wire resetn,
  output wire uart_tx
);

  localparam integer BAUD_DIV = CLK_FREQ_HZ / BAUD_RATE;

  reg [9:0] tx_shift;
  reg       tx_running;
  reg [$clog2(BAUD_DIV+1)-1:0] baud_cnt;
  reg [3:0] bit_idx;

  assign uart_tx = tx_running ? tx_shift[0] : 1'b1;   // idle high

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      tx_running <= 1'b0;
      baud_cnt   <= 0;
      bit_idx    <= 4'd0;
      tx_shift   <= 10'h3FF;
    end else if (!tx_running) begin
      // immediately kick off the next frame back-to-back - fixed byte
      // 0x55, no pending/FIFO/probe_bus logic involved at all
      tx_shift   <= {1'b1, 8'h55, 1'b0};              // stop, data, start
      tx_running <= 1'b1;
      baud_cnt   <= 0;
      bit_idx    <= 4'd0;
    end else begin
      if (baud_cnt == BAUD_DIV-1) begin
        baud_cnt <= 0;
        if (bit_idx == 4'd9) begin
          tx_running <= 1'b0;
        end else begin
          bit_idx  <= bit_idx + 1'b1;
          tx_shift <= {1'b1, tx_shift[9:1]};
        end
      end else begin
        baud_cnt <= baud_cnt + 1'b1;
      end
    end
  end

endmodule

`default_nettype wire
