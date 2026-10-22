`timescale 1ns / 1ps
`default_nettype none

//------------------------------------------------------------------------
// debug_uart_probe
//
// Self-contained hardware UART event logger, entirely independent of the
// JTAG/ILA debug path and of the SoC's own CPU/software. Watches a bus of
// probe signals; on every bit-level transition, timestamps it (cycle
// count since reset release) and queues a short ASCII text line,
// transmitted over a dedicated UART TX pin at 8N1.
//
// Motivation: at 20 MHz, this board's ILA/JTAG debug-hub readback is
// confirmed corrupted (Xicom 50-38/50-41 - frozen probes, simultaneous
// glitches on unrelated signals in the same capture). UART itself tested
// clean via loopback at 20 MHz, so this routes the same signals we'd
// otherwise be watching on the ILA out over UART instead, sidestepping
// the JTAG path entirely. It also isn't limited to a fixed sample-buffer
// depth the way the ILA is - it just keeps logging for as long as the
// design runs.
//
// Output format (2026-09-28 rev, adopted for build 39 on 2026-10-02: whole-bus change log), one line per change
// of the probe bus, e.g.:
//   T00000080:0000010B=
// = at cycle (hex, 32-bit) 0x00000080 since reset release the ENTIRE bus
//   (bit i = signal ID i, zero-padded to 32 bits) became 0x0000010B. The
//   last character is '=' normally, or '!' if one or more bus changes were
//   DROPPED OR DELAYED (FIFO full) since the previous line - i.e. this line
//   is honest about a late timestamp / missing intermediate history. The old per-bit priority encoder
//   (starvation, lost edges, stale timestamps) is gone.
//
// One line is 21 characters (~1.8 ms at 115200 baud). Changes arriving
// faster than that fill the 64-entry FIFO and are counted as dropped, but
// every logged line still carries the true current bus value.
// 2026-10-02: adopted for build 39. The per-signal logger (builds up to 38)
// reports the value captured at a bit's FIRST edge and loses any later edge
// while the bit is queued (bug register F6). On hardware that meant every
// reset-release rise and every early-boot milestone (ROM data, first SRAM
// write) was lost behind the ~1.4 ms per-line drain. Whole-bus lines carry
// the true current value of every bit, so a flag's final state can never be
// missed; with the per-transaction signals taken off the bus the FIFO does
// not fill and short pulses are captured too.
//------------------------------------------------------------------------
module debug_uart_probe #(
  parameter integer CLK_FREQ_HZ   = 20_000_000,
  parameter integer BAUD_RATE     = 115200,
  parameter integer NUM_SIGNALS   = 21,
  parameter integer FIFO_DEPTH_L2 = 6              // 64 entries
)(
  input  wire                    clk,
  input  wire                    resetn,           // active low
  input  wire [NUM_SIGNALS-1:0]  probe_bus,
  output wire                    uart_tx
);

  localparam integer BAUD_DIV = CLK_FREQ_HZ / BAUD_RATE;

  // -----------------------------------------------------------------------
  // Free-running cycle counter, since reset release
  //
  // 2026-08-05: widened from 16 to 32 bits. A 16-bit counter wraps every
  // 65,536 cycles - and this module's own ext_gt_qreqn pulse generator (in
  // megasoc_tech_wrapper.sv) has a 20-bit (1,048,576-cycle) period, which
  // is an EXACT multiple (16x) of 65,536. Every real recurrence of that
  // pulse (~52ms apart at 20MHz) landed on the exact same 16-bit-wrapped
  // timestamp, making genuinely-separate, correctly-working periodic
  // events look like an identical, endlessly-repeating capture - this was
  // mistaken for a reset loop before the aliasing was understood. 32 bits
  // wraps every ~214s at 20MHz, long enough not to matter in practice.
  // -----------------------------------------------------------------------
  reg [31:0] cycle_cnt;
  always @(posedge clk or negedge resetn)
    if (!resetn) cycle_cnt <= 32'd0;
    else         cycle_cnt <= cycle_cnt + 32'd1;

  // -----------------------------------------------------------------------
  // Whole-bus change detector
  // -----------------------------------------------------------------------
  localparam integer BUS_W = 32;
  reg [NUM_SIGNALS-1:0] last_pushed;      // last value actually written to FIFO
  reg                   dropped;          // change(s) lost since last push

  // Event FIFO: {cycle_cnt[31:0], bus[31:0], dropped}
  localparam integer EVT_W = 32 + BUS_W + 1;
  reg [EVT_W-1:0] fifo_mem [0:(1<<FIFO_DEPTH_L2)-1];
  reg [FIFO_DEPTH_L2-1:0] wr_ptr, rd_ptr;
  wire fifo_empty = (wr_ptr == rd_ptr);
  wire fifo_full  = ((wr_ptr + 1'b1) == rd_ptr);
  wire [EVT_W-1:0] fifo_rd_data = fifo_mem[rd_ptr];

  wire pending_any     = (probe_bus != last_pushed);   // logged value is stale
  wire fifo_push       = pending_any && !fifo_full;
  wire [BUS_W-1:0] bus_padded = BUS_W'(probe_bus);   // zero-extend; valid for NUM_SIGNALS == BUS_W too
  wire [EVT_W-1:0] fifo_push_data = {cycle_cnt, bus_padded, dropped};

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      last_pushed <= {NUM_SIGNALS{1'b0}};
      dropped     <= 1'b0;
      wr_ptr      <= {FIFO_DEPTH_L2{1'b0}};
    end else begin
      if (fifo_push) begin
        wr_ptr      <= wr_ptr + 1'b1;
        last_pushed <= probe_bus;
        dropped     <= 1'b0;
      end else if (pending_any && fifo_full) begin
        // change is waiting on a full FIFO: its timestamp will be late and
        // intermediate values may be lost - flag the line honestly
        dropped     <= 1'b1;
      end
    end
  end

  // Isolated in its own reset-free always block deliberately - mixing a
  // memory-array write with reset-bearing scalar registers in one always
  // block caused Vivado to infer ambiguous set/reset priority on
  // fifo_mem_reg (Synth 8-7137, "may cause simulation mismatches").
  always @(posedge clk) begin
    if (fifo_push) begin
      fifo_mem[wr_ptr] <= fifo_push_data;
    end
  end

  // -----------------------------------------------------------------------
  // Low-level 8N1 UART bit transmitter
  // -----------------------------------------------------------------------
  reg [3:0] bit_idx;
  reg [9:0] tx_shift;
  reg       tx_running;
  reg [$clog2(BAUD_DIV+1)-1:0] baud_cnt;
  reg [7:0] tx_byte;
  reg       tx_start;

  wire tx_busy = tx_running;
  assign uart_tx = tx_running ? tx_shift[0] : 1'b1;   // idle high

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      tx_running <= 1'b0;
      baud_cnt   <= 0;
      bit_idx    <= 4'd0;
      tx_shift   <= 10'h3FF;
    end else if (tx_start && !tx_running) begin
      tx_shift   <= {1'b1, tx_byte, 1'b0};            // stop, data[7:0], start
      tx_running <= 1'b1;
      baud_cnt   <= 0;
      bit_idx    <= 4'd0;
    end else if (tx_running) begin
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

  // -----------------------------------------------------------------------
  // Hex-nibble to ASCII
  // -----------------------------------------------------------------------
  function automatic [7:0] hex_ascii(input [3:0] nibble);
    hex_ascii = (nibble < 4'd10) ? (8'h30 + {4'h0, nibble})
                                  : (8'h41 + {4'h0, (nibble - 4'd10)});
  endfunction

  // -----------------------------------------------------------------------
  // Line formatter + FIFO drain sequencer:
  //   "T" cccccccc ":" bbbbbbbb ("=" | "!") CR LF   (21 chars)
  // -----------------------------------------------------------------------
  localparam S_IDLE = 2'd0, S_LOAD = 2'd1, S_SEND = 2'd2;
  localparam [4:0] LAST_CHAR = 5'd20;
  reg [1:0]      tx_state;
  reg [4:0]      char_idx;
  reg [31:0]     line_cycle;
  reg [BUS_W-1:0] line_bus;
  reg            line_drop;

  always @(*) begin
    case (char_idx)
      5'd0:    tx_byte = "T";
      5'd1:    tx_byte = hex_ascii(line_cycle[31:28]);
      5'd2:    tx_byte = hex_ascii(line_cycle[27:24]);
      5'd3:    tx_byte = hex_ascii(line_cycle[23:20]);
      5'd4:    tx_byte = hex_ascii(line_cycle[19:16]);
      5'd5:    tx_byte = hex_ascii(line_cycle[15:12]);
      5'd6:    tx_byte = hex_ascii(line_cycle[11:8]);
      5'd7:    tx_byte = hex_ascii(line_cycle[7:4]);
      5'd8:    tx_byte = hex_ascii(line_cycle[3:0]);
      5'd9:    tx_byte = ":";
      5'd10:   tx_byte = hex_ascii(line_bus[31:28]);
      5'd11:   tx_byte = hex_ascii(line_bus[27:24]);
      5'd12:   tx_byte = hex_ascii(line_bus[23:20]);
      5'd13:   tx_byte = hex_ascii(line_bus[19:16]);
      5'd14:   tx_byte = hex_ascii(line_bus[15:12]);
      5'd15:   tx_byte = hex_ascii(line_bus[11:8]);
      5'd16:   tx_byte = hex_ascii(line_bus[7:4]);
      5'd17:   tx_byte = hex_ascii(line_bus[3:0]);
      5'd18:   tx_byte = line_drop ? "!" : "=";
      5'd19:   tx_byte = 8'h0D;                        // CR
      5'd20:   tx_byte = 8'h0A;                        // LF
      default: tx_byte = 8'h00;
    endcase
  end

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      tx_state   <= S_IDLE;
      char_idx   <= 5'd0;
      tx_start   <= 1'b0;
      rd_ptr     <= {FIFO_DEPTH_L2{1'b0}};
      line_cycle <= 32'd0;
      line_bus   <= {BUS_W{1'b0}};
      line_drop  <= 1'b0;
    end else begin
      tx_start <= 1'b0;

      case (tx_state)
        S_IDLE: begin
          if (!fifo_empty) begin
            {line_cycle, line_bus, line_drop} <= fifo_rd_data;
            rd_ptr   <= rd_ptr + 1'b1;
            char_idx <= 5'd0;
            tx_state <= S_LOAD;
          end
        end
        S_LOAD: begin
          tx_start <= 1'b1;
          tx_state <= S_SEND;
        end
        S_SEND: begin
          if (!tx_busy && !tx_start) begin
            if (char_idx == LAST_CHAR) begin
              tx_state <= S_IDLE;
            end else begin
              char_idx <= char_idx + 1'b1;
              tx_state <= S_LOAD;
            end
          end
        end
        default: tx_state <= S_IDLE;
      endcase
    end
  end

endmodule

`default_nettype wire
