`ifndef GUARD_SDIO_BASE_TEST_SV
`define GUARD_SDIO_BASE_TEST_SV

`include "sdio_card_env.sv"
`include "card_cfg.sv"

`define SDIO_VIP_GLOBAL_TIMEOUT 500ms

/**
 * Base UVM test for the card-only VIP integration.
 *
 * Builds sdio_card_env (card agent only) and applies the locked-in SD
 * operating point from card_cfg.sv. The real ZipCPU SDIO controller RTL
 * inside megasoc_chip is the host -- it is driven purely through the
 * existing AXI-Lite register interface by the embedded test software
 * image loaded into SRAM by tb_top.sv, exactly as the mdl_sdio.v-based
 * sim and TC1-TC14 already do. This test never drives SDIO_CMD/SDIO_DAT
 * itself and never builds a host agent.
 *
 * Because svt_emmc_card_agent is reactive, it never raises or drops a
 * phase objection on its own. main_phase raises the objection up front
 * and blocks on sim_done_vif.done, which tb_top.sv only sets once the
 * embedded software has called TEST_PASS()/TEST_FAIL() and the
 * simulation-end UART sequence has completed. Dropping the objection on
 * any other condition (e.g. the card monitor going idle) would let the
 * test "pass" at time 0 before the RTL has done anything.
 */
class sdio_base_test extends uvm_test;

  svt_emmc_card_agent_configuration card_cfg;
  sdio_card_env                     sd_env;
  virtual sim_done_if                sim_done_vif;

  `uvm_component_utils(sdio_base_test)

  function new(string name = "sdio_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual sim_done_if)::get(this, "", "sim_done_vif", sim_done_vif)) begin
      `uvm_fatal("build_phase", "sim_done_vif is not provided -- cannot detect embedded test completion.");
    end

    card_cfg          = svt_emmc_card_agent_configuration::type_id::create("card_cfg");
    card_cfg.reg_cfg   = svt_emmc_register_configuration::type_id::create("card_reg_cfg");
    card_cfg.timing_cfg = svt_emmc_timing_configuration::type_id::create("card_timing");

    apply_sdio_card_cfg(card_cfg);
    apply_sdio_card_reg_cfg(card_cfg.reg_cfg);
    card_cfg.timing_cfg.fPP_min_MHz = 25;
    card_cfg.timing_cfg.fPP_max_MHz = 50;
    card_cfg.enable_setup_hold_time_checks = 1;

    uvm_config_db#(svt_emmc_card_agent_configuration)::set(this, "sd_env", "card_cfg", this.card_cfg);

    sd_env = sdio_card_env::type_id::create("sd_env", this);

    uvm_config_db#(time)::set(null, "global_timer.*", "timeout", `SDIO_VIP_GLOBAL_TIMEOUT);
  endfunction : build_phase

  task main_phase(uvm_phase phase);
    super.main_phase(phase);

    phase.raise_objection(this, "Waiting for embedded SDIO test software to complete");

    `uvm_info("main_phase", "Objection raised -- waiting for sim_done_vif.done (set on TEST_PASS()/TEST_FAIL())", UVM_LOW)
    wait (sim_done_vif.done == 1'b1);
    `uvm_info("main_phase", "sim_done_vif.done observed -- embedded test software has completed", UVM_LOW)

    phase.drop_objection(this, "Embedded SDIO test software completed");
  endtask : main_phase

  function void final_phase(uvm_phase phase);
    uvm_report_server svr;
    super.final_phase(phase);
    svr = uvm_report_server::get_server();

    if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) > 0) begin
      `uvm_info("final_phase", "\n\nSvtTestEpilog:            Failed\n", UVM_LOW)
    end else begin
      `uvm_info("final_phase", "\n\nSvtTestEpilog:            Passed\n", UVM_LOW)
    end
  endfunction : final_phase

endclass : sdio_base_test

`endif // GUARD_SDIO_BASE_TEST_SV
