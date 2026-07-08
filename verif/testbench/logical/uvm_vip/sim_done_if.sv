`ifndef GUARD_SDIO_VIP_SIM_DONE_IF_SV
`define GUARD_SDIO_VIP_SIM_DONE_IF_SV

/**
 * Bridges a single plain-Verilog level signal into UVM as a virtual
 * interface. tb_top.sv latches megasoc_uart_capture's SIMULATIONEND pulse
 * (raised when the embedded SDIO test software calls TEST_PASS()/
 * TEST_FAIL() -> UartEndSimulation()) into "done" on this interface.
 *
 * The card agent is reactive and never raises/drops phase objections
 * itself (see emmc_svt_uvm_getting_started.pdf 1.3 and the FAQ on
 * "test ends at time 0"). The UVM test's main_phase blocks on this
 * interface and only drops its objection once the embedded software's
 * own AXI-Lite-driven test sequence has actually finished and reported
 * pass/fail -- not when the card monitor happens to go idle.
 */
interface sim_done_if;
  logic done;
endinterface : sim_done_if

`endif // GUARD_SDIO_VIP_SIM_DONE_IF_SV
