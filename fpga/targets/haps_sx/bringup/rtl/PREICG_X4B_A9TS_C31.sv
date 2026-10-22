`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2026 12:14:04 PM
// Design Name: Anastasios Dimitriou
// Module Name: PREICG_X4B_A9TS_C31
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Switched from latch+AND behavioral model to BUFGCE. The
//   original model synthesized as a raw LUT driving downstream clock pins
//   directly (no dedicated clock buffer) - flagged by Vivado methodology
//   DRC as TIMING-14 "LUT on the clock tree" across ~100+ instances
//   throughout the CA53/GIC/SCU, and confirmed as the dominant contributor
//   to 20k+ failing setup timing paths once the design was properly
//   analyzed at 100 MHz. BUFGCE is the correct FPGA primitive for
//   glitch-free clock gating: dedicated global clock routing, correct
//   static timing analysis, no LUT-based clock-tree distortion.
// Revision 0.03 - Blanket BUFGCE conversion did not scale: with ~100-140
//   instances of this cell throughout the CA53/GIC/SCU, converting every
//   one to an independent global BUFGCE clock domain exhausted available
//   clock routing tracks in congested clock regions (Place 30-678),
//   which is distinct from, and far scarcer than, raw BUFGCE site count.
//   Added a USE_BUFGCE parameter (default 0 = original behavioral model,
//   fine for the many small low-fanout instances) so only the handful of
//   genuinely high-fanout, structurally critical instances can be
//   selectively promoted to BUFGCE via defparam from
//   megasoc_tech_wrapper.sv, without touching the licensed CA53 core's
//   own instantiation sites.
// Revision 0.04 - 2026-09-14: the USE_BUFGCE=0 default (still the vast
//   majority of instances - 20 of 24 device-wide BUFGCEs end up sourced by
//   this behavioral model's LUT output, not a clean buffer) turned out to
//   have its own cost, found independently by an external constraints
//   review and confirmed on real hardware: once the blanket XDC hold
//   waiver was removed, the design showed 157k-168k failing hold/removal
//   endpoints, and the single worst path traced directly to a
//   combinational-LUT-fed BUFGCE in exactly this hierarchy. Neither prior
//   option is safe to use unconditionally: real gating (this file's
//   original intent) puts a LUT in the clock path; USE_BUFGCE=1 for every
//   instance re-triggers the Rev 0.03 routing congestion. Added a third,
//   untried option: FPGA_BYPASS_GATING, which passes CK straight through
//   with no combinational logic and no dedicated buffer at all - clock
//   gating has no functional meaning on an FPGA (it's a power-saving
//   feature only, irrelevant until an ASIC pass cares about it), so for
//   bring-up there is no correctness reason to keep any instance gated.
//   Defaults to 1 (bypass) for that reason; set to 0 via defparam to get
//   the original behavior back for a specific instance if ever needed
//   (e.g. a power-realistic build later). Takes priority over USE_BUFGCE.
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`default_nettype none

// -----------------------------------------------------------------------------
// FPGA implementation of ARM/TSMC integrated clock gate cell PREICG_X4B_A9TS_C31.
// Defaults to FPGA_BYPASS_GATING=1 (straight passthrough, no LUT, no BUFGCE -
// see Revision 0.04 above). Set FPGA_BYPASS_GATING=0 via defparam to fall back
// to the original behavioral latch+AND model, or further to USE_BUFGCE=1 on
// top of that for the handful of high-fanout instances that need a real
// dedicated global clock buffer - see megasoc_tech_wrapper.sv for which
// instances and why.
// -----------------------------------------------------------------------------
module PREICG_X4B_A9TS_C31 #(
  parameter USE_BUFGCE = 0,
  parameter FPGA_BYPASS_GATING = 1
) (
  output wire ECK,  // gated clock output
  input  wire E,    // functional enable
  input  wire SE,   // scan enable (forces clock on)
  input  wire CK    // input clock
);

  generate
    if (FPGA_BYPASS_GATING) begin : g_bypass
      assign ECK = CK;
    end else if (USE_BUFGCE) begin : g_bufgce
      BUFGCE u_bufgce (
        .I  (CK),
        .CE (E | SE),
        .O  (ECK)
      );
    end else begin : g_behavioral
      // Typical ICG behavior: latch enable when CK is low, then AND with CK.
      reg en_lat;

      always @(*) begin
        if (CK == 1'b0)
          en_lat = (E | SE);
      end

      assign ECK = CK & en_lat;
    end
  endgenerate

endmodule

`default_nettype wire