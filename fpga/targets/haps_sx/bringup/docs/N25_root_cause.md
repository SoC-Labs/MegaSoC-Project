# N25 root cause (found 2026-10-21 00:45 by RTL simulation of the FPGA design)
Bisection (VCS, scratchpad/n25/sim): swapping ONLY the L2 tag RAM integration file between Arm's TSMC example
(tsmc_cln28hpm_L1_32I_32D_L2_1M/ca53_l2_tagrams.v, used on the FPGA since build 42) and Arm's generic one decides
whether the core survives SCTLR.I = 1 (C1 hang / C2,C3,mixB pass). All 11 FPGA macro models match Arm's generic RAM
cycle-for-cycle in unit tests; power-up contents (zeros/ones/X) do not matter (g0, g1b pass; o2 hangs).
Mechanism: the TSMC example is written for a 1 MB L2: `.A(l2_tagram_addr_i[9:0])`, no masking. The configured core
has L2_CACHE_SIZE = 4'b0001 (256 KB, CORTEXA53.v:257). Arm's generic integration masks the set index:
`l2_tagram_addr_masked = l2_tagram_addr_i & {l2_size, ...}`. With the unmasked version, the SCU's upper index bits
(don't-care for a 256 KB L2) send tag writes and tag look-ups to different RAM words, so the L2 never behaves,
and the first I-cache line fill through the L2 after enable_caches() never completes correctly.
Why only now: with caches off the L2 tag RAMs are never used. Silicon uses SoC Labs' own mem_integrations for a
256 KB L2 (and their FPGA integration mem_integrations/FPGA uses AW=12 RAMs), so the ASIC is not affected.
Fix (build 54): generic ca53_l2_tagrams.v + new/ca53_generic_ram_fpga.v (Arm's generic RAM, X-free, BRAM-like).
The earlier L2 data RAM latency fix (build 53) and the TSMC-faithful model behaviour (Q holds through writes,
defined power-up) stay. Verified in simulation (F1) before the build.
