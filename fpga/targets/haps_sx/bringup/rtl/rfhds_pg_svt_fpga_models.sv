//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2026 02:46:49 PM
// Design Name: Anastasios Dimitriou 
// Module Name: rfhds_pg_svt_fpga_models
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// rfhds_pg_svt_fpga_models.sv
// -----------------------------------------------------------------------------
// FPGA simulation models for TSMC SRAM macros used by Cortex-A53 RTL wrappers.
//
// Functional (not timing-accurate):
// - active-low CEN (chip enable)
// - active-low WEN (scalar or per-bit vector mask)
// - optional active-low GWEN (global write enable)
// - RFHSD_* models: 1-cycle synchronous read
// - SRAMHDE_* model (L2 data slice): 1-cycle synchronous read (build 53; the 2-cycle version was the N25 cache hang)
//
// All DFT/test/assist ports are ignored and driven to safe constants.
// -----------------------------------------------------------------------------

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Generic synchronous SRAM with optional global write enable and optional bit mask
// 1-cycle read latency
// -----------------------------------------------------------------------------
module _sync_sram_masked #(
  parameter int DEPTH = 256,
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32,
  parameter bit HAS_GWEN = 0,
  parameter bit WEN_IS_VECTOR = 0,
  parameter bit INIT_ONES = 0      // power-up contents all ones (Cortex-A53 L1 I-cache tag RAMs: state bits 11 = invalid)
)(
  input  logic                 CLK,
  input  logic [ADDR_W-1:0]     A,
  output logic [DATA_W-1:0]     Q,
  input  logic [DATA_W-1:0]     D,
  input  logic                 CEN,     // active-low enable
  input  logic [DATA_W-1:0]     WEN,     // active-low bit mask when vector, else use WEN[0]
  input  logic                 GWEN     // active-low global write enable (if used)
);

  logic [DATA_W-1:0] mem [0:DEPTH-1];
  // 2026-10-21 (build 54, ticket N25): power-up contents. FPGA block RAM comes up as zeros unless initialised.
  // The A53 I-cache tag RAM encodes "invalid" as state bits [30:29] = 11 and the core does NOT rewrite the tag
  // RAM at reset or on IC IALLU, so an all-zero tag RAM means "every line valid, tag 0, non-secure" - the ROM at
  // address 0 then false-hits in the I-cache as soon as SCTLR.I is set (the hang since build 42). Arm's own
  // generic model initialises these RAMs to all ones (ca53_generic_ram reset_high). Vivado honours this initial
  // block as the BRAM/LUTRAM INIT values; in simulation it also replaces the X start-up of every other array.
  initial begin for (int i = 0; i < DEPTH; i++) mem[i] = INIT_ONES ? '1 : '0; end

  function automatic bit write_allowed();
    if (HAS_GWEN) begin
      return (GWEN == 1'b0);
    end else begin
      return 1'b1;
    end
  endfunction

  always @(posedge CLK) begin   // was always_ff; plain always so a simulation-only initial block may preset the array
    if (CEN == 1'b0) begin
      // WRITE
      if (write_allowed()) begin
        if (WEN_IS_VECTOR) begin
          // active-low per-bit write enable
          for (int i = 0; i < DATA_W; i++) begin
            if (WEN[i] == 1'b0) mem[A][i] <= D[i];
          end
        end else begin
          // scalar write enable on WEN[0] (active-low)
          if (WEN[0] == 1'b0) mem[A] <= D;
        end
      end

      // READ (sync, 1-cycle)
      // 2026-10-21 (build 54, N25): Q is updated by READ cycles only and HOLDS through write cycles, like the
      // TSMC register-file macros (and unlike the earlier version, which loaded Q with the old contents of the
      // written word). Arm's generic model drives X during a write cycle, so a core dependency on Q holding its
      // last read value across a write is invisible in simulation with that model but real on the FPGA.
      if (!(write_allowed() && (WEN_IS_VECTOR ? (WEN != {DATA_W{1'b1}}) : (WEN[0] == 1'b0))))
        Q <= mem[A];
    end
  end

endmodule

// -----------------------------------------------------------------------------
// SRAMHDE-style synchronous SRAM with 2-cycle read latency (for L2 data RAMs)
// -----------------------------------------------------------------------------
// UNUSED since build 53 (kept for the record / simulation comparison): the mistaken 2-cycle variant
module _sync_sram_2cycle #(
  parameter int DEPTH = 16384,
  parameter int ADDR_W = 14,
  parameter int DATA_W = 36
)(
  input  logic                 CLK,
  input  logic [ADDR_W-1:0]     A,
  output logic [DATA_W-1:0]     Q,
  input  logic [DATA_W-1:0]     D,
  input  logic                 CEN,   // active-low enable
  input  logic                 WEN    // active-low write enable (whole word)
);

  logic [DATA_W-1:0] mem [0:DEPTH-1];
  logic [DATA_W-1:0] r1, r2;

  // 2026-09-21: the second pipeline stage must NOT be gated by this cycle's
  // CEN.
  //
  // Previously `r2 <= r1` sat inside `if (CEN == 1'b0)`, so a read at cycle N
  // loaded r1 at N+1, and unless another access happened to be presented in
  // that very next cycle, r2 never advanced and Q never presented the data -
  // it kept showing whatever the last back-to-back access had left there. Any
  // isolated read silently returned stale data. This model backs the 16
  // SRAMHDE_PG_SVT_16384x36M16WM0 instances that make up the CA53's L2 data
  // banks, so that is squarely in the instruction/data return path.
  //
  // A real 2-cycle SRAM macro clocks its output register from the access that
  // is already in flight, which is what cen_d reproduces here.
  logic cen_d;

  always @(posedge CLK) begin   // was always_ff; plain always so a simulation-only initial block may preset the array
    cen_d <= CEN;
    if (CEN == 1'b0) begin
      if (WEN == 1'b0) begin
        mem[A] <= D;
      end
      r1 <= mem[A];
    end
    if (cen_d == 1'b0) begin
      r2 <= r1;
    end
  end

  always_comb Q = r2;

endmodule

// -----------------------------------------------------------------------------
// RFHSD_PG_SVT_* macro wrappers (1-cycle read)
// -----------------------------------------------------------------------------

// 2048 x 21, WEN[20:0] + GWEN
module RFHSD_PG_SVT_2048x21M8WM1 (
  input  wire         CLK,
  input  wire [10:0]   A,
  output wire [20:0]   Q,
  input  wire [20:0]   D,
  input  wire         CEN,
  input  wire [20:0]   WEN,
  input  wire [2:0]    EMA,
  input  wire [1:0]    EMAW,
  input  wire         EMAS,
  input  wire         GWEN,
  output wire         GWENY,
  input  wire         TGWEN,
  input  wire [10:0]   TA,
  input  wire [20:0]   TD,
  output wire         SO,
  output wire         CENY,
  output wire [20:0]   WENY,
  output wire [10:0]   AY,
  input  wire         TEN,
  input  wire         TCEN,
  input  wire [20:0]   TWEN,
  input  wire [1:0]    SI,
  input  wire         SE,
  input  wire         DFTRAMBYP,
  input  wire         RET1N,
  input  wire         RET2N,
  input  wire         PGEN
);
  logic [20:0] q_int;

  _sync_sram_masked #(
    .DEPTH(2048), .ADDR_W(11), .DATA_W(21),
    .HAS_GWEN(1), .WEN_IS_VECTOR(1)
  ) u (
    .CLK(CLK), .A(A), .Q(q_int), .D(D),
    .CEN(CEN), .WEN(WEN), .GWEN(GWEN)
  );

  assign Q = q_int;
  assign GWENY = 1'b0;
  assign SO    = 1'b0;
  assign CENY  = 1'b0;
  assign WENY  = '0;
  assign AY    = '0;
endmodule

// 256 x 32, scalar WEN
module RFHSD_PG_SVT_256x32M4WM0 (
  input  wire        CLK,
  input  wire [7:0]  A,
  output wire [31:0] Q,
  input  wire [31:0] D,
  input  wire        CEN,
  input  wire        WEN,
  input  wire [2:0]  EMA,
  input  wire [1:0]  EMAW,
  input  wire        EMAS,
  input  wire [7:0]  TA,
  input  wire [31:0] TD,
  output wire        SO,
  output wire        CENY,
  output wire        WENY,
  output wire [7:0]  AY,
  input  wire        TEN,
  input  wire        TCEN,
  input  wire        TWEN,
  input  wire [1:0]  SI,
  input  wire        SE,
  input  wire        DFTRAMBYP,
  input  wire        RET1N,
  input  wire        RET2N,
  input  wire        PGEN
);
  logic [31:0] q_int;

  _sync_sram_masked #(
    .DEPTH(256), .INIT_ONES(1), .ADDR_W(8), .DATA_W(32),
    .HAS_GWEN(0), .WEN_IS_VECTOR(0)
  ) u (
    .CLK(CLK), .A(A), .Q(q_int), .D(D),
    .CEN(CEN), .WEN({31'b1, WEN}), .GWEN(1'b1)
  );

  assign Q = q_int;
  assign SO = 1'b0; assign CENY = 1'b0; assign WENY = 1'b0; assign AY = '0;
endmodule

// 1024 x 39, scalar WEN
module RFHSD_PG_SVT_1024x39M4WM0 (
  input  wire        CLK,
  input  wire [9:0]  A,
  output wire [38:0] Q,
  input  wire [38:0] D,
  input  wire        CEN,
  input  wire        WEN,
  input  wire [2:0]  EMA,
  input  wire [1:0]  EMAW,
  input  wire        EMAS,
  input  wire [9:0]  TA,
  input  wire [38:0] TD,
  output wire        SO,
  output wire        CENY,
  output wire        WENY,
  output wire [9:0]  AY,
  input  wire        TEN,
  input  wire        TCEN,
  input  wire        TWEN,
  input  wire [1:0]  SI,
  input  wire        SE,
  input  wire        DFTRAMBYP,
  input  wire        RET1N,
  input  wire        RET2N,
  input  wire        PGEN
);
  logic [38:0] q_int;

  _sync_sram_masked #(
    .DEPTH(1024), .ADDR_W(10), .DATA_W(39),
    .HAS_GWEN(0), .WEN_IS_VECTOR(0)
  ) u (
    .CLK(CLK), .A(A), .Q(q_int), .D(D),
    .CEN(CEN), .WEN({38'b1, WEN}), .GWEN(1'b1)
  );

  assign Q = q_int;
  assign SO = 1'b0; assign CENY = 1'b0; assign WENY = 1'b0; assign AY = '0;
endmodule

// 128 x 32, scalar WEN
module RFHSD_PG_SVT_128x32M2WM0 (
  input  wire        CLK,
  input  wire [6:0]  A,
  output wire [31:0] Q,
  input  wire [31:0] D,
  input  wire        CEN,
  input  wire        WEN,
  input  wire [2:0]  EMA,
  input  wire [1:0]  EMAW,
  input  wire        EMAS,
  input  wire [6:0]  TA,
  input  wire [31:0] TD,
  output wire        SO,
  output wire        CENY,
  output wire        WENY,
  output wire [6:0]  AY,
  input  wire        TEN,
  input  wire        TCEN,
  input  wire        TWEN,
  input  wire [1:0]  SI,
  input  wire        SE,
  input  wire        DFTRAMBYP,
  input  wire        RET1N,
  input  wire        RET2N,
  input  wire        PGEN
);
  logic [31:0] q_int;

  _sync_sram_masked #(
    .DEPTH(128), .ADDR_W(7), .DATA_W(32),
    .HAS_GWEN(0), .WEN_IS_VECTOR(0)
  ) u (
    .CLK(CLK), .A(A), .Q(q_int), .D(D),
    .CEN(CEN), .WEN({31'b1, WEN}), .GWEN(1'b1)
  );

  assign Q = q_int;
  assign SO = 1'b0; assign CENY = 1'b0; assign WENY = 1'b0; assign AY = '0;
endmodule

// 256 x 12, WEN[11:0] + GWEN
module RFHSD_PG_SVT_256x12M4WM1 (
  input  wire         CLK,
  input  wire [7:0]   A,
  output wire [11:0]  Q,
  input  wire [11:0]  D,
  input  wire         CEN,
  input  wire [11:0]  WEN,
  input  wire [2:0]   EMA,
  input  wire [1:0]   EMAW,
  input  wire         EMAS,
  input  wire         GWEN,
  output wire         GWENY,
  input  wire         TGWEN,
  input  wire [7:0]   TA,
  input  wire [11:0]  TD,
  output wire         SO,
  output wire         CENY,
  output wire [11:0]  WENY,
  output wire [7:0]   AY,
  input  wire         TEN,
  input  wire         TCEN,
  input  wire [11:0]  TWEN,
  input  wire [1:0]   SI,
  input  wire         SE,
  input  wire         DFTRAMBYP,
  input  wire         RET1N,
  input  wire         RET2N,
  input  wire         PGEN
);
  logic [11:0] q_int;

  _sync_sram_masked #(
    .DEPTH(256), .ADDR_W(8), .DATA_W(12),
    .HAS_GWEN(1), .WEN_IS_VECTOR(1)
  ) u (
    .CLK(CLK), .A(A), .Q(q_int), .D(D),
    .CEN(CEN), .WEN(WEN), .GWEN(GWEN)
  );

  assign Q = q_int;
  assign GWENY=1'b0; assign SO=1'b0; assign CENY=1'b0; assign WENY='0; assign AY='0;
endmodule

// 160 x 118, scalar WEN
module RFHSD_PG_SVT_160x118M2WM0 (
  input  wire          CLK,
  input  wire [7:0]    A,
  output wire [117:0]  Q,
  input  wire [117:0]  D,
  input  wire          CEN,
  input  wire          WEN,
  input  wire [2:0]    EMA,
  input  wire [1:0]    EMAW,
  input  wire          EMAS,
  input  wire [7:0]    TA,
  input  wire [117:0]  TD,
  output wire          SO,
  output wire          CENY,
  output wire          WENY,
  output wire [7:0]    AY,
  input  wire          TEN,
  input  wire          TCEN,
  input  wire          TWEN,
  input  wire [1:0]    SI,
  input  wire          SE,
  input  wire          DFTRAMBYP,
  input  wire          RET1N,
  input  wire          RET2N,
  input  wire          PGEN
);
  logic [117:0] q_int;

  _sync_sram_masked #(
    .DEPTH(160), .ADDR_W(8), .DATA_W(118),
    .HAS_GWEN(0), .WEN_IS_VECTOR(0)
  ) u (
    .CLK(CLK), .A(A), .Q(q_int), .D(D),
    .CEN(CEN), .WEN({117'b1, WEN}), .GWEN(1'b1)
  );

  assign Q = q_int;
  assign SO = 1'b0; assign CENY = 1'b0; assign WENY = 1'b0; assign AY = '0;
endmodule

// 128 x 50, scalar WEN
module RFHSD_PG_SVT_128x50M2WM0 (
  input  wire        CLK,
  input  wire [6:0]  A,
  output wire [49:0] Q,
  input  wire [49:0] D,
  input  wire        CEN,
  input  wire        WEN,
  input  wire [2:0]  EMA,
  input  wire [1:0]  EMAW,
  input  wire        EMAS,
  input  wire [6:0]  TA,
  input  wire [49:0] TD,
  output wire        SO,
  output wire        CENY,
  output wire        WENY,
  output wire [6:0]  AY,
  input  wire        TEN,
  input  wire        TCEN,
  input  wire        TWEN,
  input  wire [1:0]  SI,
  input  wire        SE,
  input  wire        DFTRAMBYP,
  input  wire        RET1N,
  input  wire        RET2N,
  input  wire        PGEN
);
  logic [49:0] q_int;

  _sync_sram_masked #(
    .DEPTH(128), .ADDR_W(7), .DATA_W(50),
    .HAS_GWEN(0), .WEN_IS_VECTOR(0)
  ) u (
    .CLK(CLK), .A(A), .Q(q_int), .D(D),
    .CEN(CEN), .WEN({49'b1, WEN}), .GWEN(1'b1)
  );

  assign Q = q_int;
  assign SO = 1'b0; assign CENY = 1'b0; assign WENY = 1'b0; assign AY = '0;
endmodule

// 128 x 59, scalar WEN
module RFHSD_PG_SVT_128x59M4WM0 (
  input  wire        CLK,
  input  wire [6:0]  A,
  output wire [58:0] Q,
  input  wire [58:0] D,
  input  wire        CEN,
  input  wire        WEN,
  input  wire [2:0]  EMA,
  input  wire [1:0]  EMAW,
  input  wire        EMAS,
  input  wire [6:0]  TA,
  input  wire [58:0] TD,
  output wire        SO,
  output wire        CENY,
  output wire        WENY,
  output wire [6:0]  AY,
  input  wire        TEN,
  input  wire        TCEN,
  input  wire        TWEN,
  input  wire [1:0]  SI,
  input  wire        SE,
  input  wire        DFTRAMBYP,
  input  wire        RET1N,
  input  wire        RET2N,
  input  wire        PGEN
);
  logic [58:0] q_int;

  _sync_sram_masked #(
    .DEPTH(128), .ADDR_W(7), .DATA_W(59),
    .HAS_GWEN(0), .WEN_IS_VECTOR(0)
  ) u (
    .CLK(CLK), .A(A), .Q(q_int), .D(D),
    .CEN(CEN), .WEN({58'b1, WEN}), .GWEN(1'b1)
  );

  assign Q = q_int;
  assign SO = 1'b0; assign CENY = 1'b0; assign WENY = 1'b0; assign AY = '0;
endmodule

// 1024 x 37, scalar WEN
module RFHSD_PG_SVT_1024x37M4WM0 (
  input  wire        CLK,
  input  wire [9:0]  A,
  output wire [36:0] Q,
  input  wire [36:0] D,
  input  wire        CEN,
  input  wire        WEN,
  input  wire [2:0]  EMA,
  input  wire [1:0]  EMAW,
  input  wire        EMAS,
  input  wire [9:0]  TA,
  input  wire [36:0] TD,
  output wire        SO,
  output wire        CENY,
  output wire        WENY,
  output wire [9:0]  AY,
  input  wire        TEN,
  input  wire        TCEN,
  input  wire        TWEN,
  input  wire [1:0]  SI,
  input  wire        SE,
  input  wire        DFTRAMBYP,
  input  wire        RET1N,
  input  wire        RET2N,
  input  wire        PGEN
);
  logic [36:0] q_int;

  _sync_sram_masked #(
    .DEPTH(1024), .ADDR_W(10), .DATA_W(37),
    .HAS_GWEN(0), .WEN_IS_VECTOR(0)
  ) u (
    .CLK(CLK), .A(A), .Q(q_int), .D(D),
    .CEN(CEN), .WEN({36'b1, WEN}), .GWEN(1'b1)
  );

  assign Q = q_int;
  assign SO = 1'b0; assign CENY = 1'b0; assign WENY = 1'b0; assign AY = '0;
endmodule

// 1024 x 32, WEN[31:0] + GWEN
module RFHSD_PG_SVT_1024x32M4WM1 (
  input  wire         CLK,
  input  wire [9:0]   A,
  output wire [31:0]  Q,
  input  wire [31:0]  D,
  input  wire         CEN,
  input  wire [31:0]  WEN,
  input  wire         GWEN,
  output wire         GWENY,
  input  wire         TGWEN,
  input  wire [2:0]   EMA,
  input  wire [1:0]   EMAW,
  input  wire         EMAS,
  input  wire [9:0]   TA,
  input  wire [31:0]  TD,
  output wire         SO,
  output wire         CENY,
  output wire [31:0]  WENY,
  output wire [9:0]   AY,
  input  wire         TEN,
  input  wire         TCEN,
  input  wire [31:0]  TWEN,
  input  wire [1:0]   SI,
  input  wire         SE,
  input  wire         DFTRAMBYP,
  input  wire         RET1N,
  input  wire         RET2N,
  input  wire         PGEN
);
  logic [31:0] q_int;

  _sync_sram_masked #(
    .DEPTH(1024), .ADDR_W(10), .DATA_W(32),
    .HAS_GWEN(1), .WEN_IS_VECTOR(1)
  ) u (
    .CLK(CLK), .A(A), .Q(q_int), .D(D),
    .CEN(CEN), .WEN(WEN), .GWEN(GWEN)
  );

  assign Q = q_int;
  assign GWENY = 1'b0;
  assign SO    = 1'b0;
  assign CENY  = 1'b0;
  assign WENY  = '0;
  assign AY    = '0;
endmodule

// 128 x 38, scalar WEN  (NEW)
module RFHSD_PG_SVT_128x38M4WM0 (
  input  wire        CLK,
  input  wire [6:0]  A,
  output wire [37:0] Q,
  input  wire [37:0] D,
  input  wire        CEN,
  input  wire        WEN,
  input  wire [2:0]  EMA,
  input  wire [1:0]  EMAW,
  input  wire        EMAS,
  input  wire [6:0]  TA,
  input  wire [37:0] TD,
  output wire        SO,
  output wire        CENY,
  output wire        WENY,
  output wire [6:0]  AY,
  input  wire        TEN,
  input  wire        TCEN,
  input  wire        TWEN,
  input  wire [1:0]  SI,
  input  wire        SE,
  input  wire        DFTRAMBYP,
  input  wire        RET1N,
  input  wire        RET2N,
  input  wire        PGEN
);
  logic [37:0] q_int;

  _sync_sram_masked #(
    .DEPTH(128), .ADDR_W(7), .DATA_W(38),
    .HAS_GWEN(0), .WEN_IS_VECTOR(0)
  ) u (
    .CLK(CLK), .A(A), .Q(q_int), .D(D),
    .CEN(CEN), .WEN({37'b1, WEN}), .GWEN(1'b1)
  );

  assign Q = q_int;

  assign SO   = 1'b0;
  assign CENY = 1'b0;
  assign WENY = 1'b0;
  assign AY   = '0;
endmodule

// -----------------------------------------------------------------------------
// SRAMHDE_PG_SVT_* macro wrapper(s) (2-cycle read)
// -----------------------------------------------------------------------------

module SRAMHDE_PG_SVT_16384x36M16WM0 (
  input  wire         CLK,
  input  wire [13:0]   A,
  output wire [35:0]   Q,
  input  wire [35:0]   D,
  input  wire         CEN,
  input  wire         WEN,
  input  wire [2:0]    EMA,
  input  wire [1:0]    EMAW,
  input  wire         TEN,
  input  wire         TCEN,
  input  wire         TWEN,
  input  wire [13:0]   TA,
  input  wire [35:0]   TD,
  input  wire         RET1N,
  input  wire         RET2N,
  input  wire         PGEN,
  input  wire [1:0]    SI,
  input  wire         SE,
  input  wire         DFTRAMBYP,
  output wire         SO,
  output wire [13:0]   AY,
  output wire         WENY,
  output wire         CENY
);
  // 2026-10-20 (build 53, ticket N25): ONE-cycle registered read, like every other macro here and like Arm's
  // generic model (ca53_generic_ram: rdata_reg <= mem[addr] on the enable edge). The earlier _sync_sram_2cycle
  // version added a second register stage, misreading the TSMC integration comment "two-cycle latency between
  // the enable input and the data outputs" (which counts enable edge -> core sampling edge). Every L2 data
  // read then returned one cycle late, which only shows once the caches are enabled: the post-banner hang.
  logic [35:0] q_int;
  _sync_sram_masked #(
    .DEPTH(16384), .ADDR_W(14), .DATA_W(36), .HAS_GWEN(0), .WEN_IS_VECTOR(0)
  ) u (
    .CLK(CLK), .A(A), .Q(q_int), .D(D),
    .CEN(CEN), .WEN({{35{1'b1}}, WEN}), .GWEN(1'b1)
  );

  assign Q = q_int;

  assign SO   = 1'b0;
  assign AY   = '0;
  assign WENY = 1'b0;
  assign CENY = 1'b0;
endmodule
