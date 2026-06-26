`ifndef GUARD_SDIO_CARD_ENV_SV
`define GUARD_SDIO_CARD_ENV_SV

/**
 * Card-only verification environment for the VC-VIP-SOC eMMC/SD VIP.
 *
 * Unlike the reference tb_emmc_svt_sd_uvm_basic_sys example (which builds
 * both a host_agent and a card_agent against a dummy DUT), the "host" here
 * is megasoc_chip's real ZipCPU SDIO controller RTL. It is not a UVM
 * component and is never built here. This class declares no host_agent
 * variable at all -- not merely an unused/disabled one -- so there is no
 * way for a second driver to contend on SDIO_CMD/SDIO_DAT.
 */
class sdio_card_env extends uvm_env;

  /** EMMC virtual chip interface for the card side only */
  svt_emmc_vif card_vif;

  /** The only agent this environment builds */
  svt_emmc_card_agent card_agent;

  /** Card agent configuration, supplied by the test */
  svt_emmc_card_agent_configuration card_cfg;

  `uvm_component_utils(sdio_card_env)

  function new(string name = "sdio_card_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!(uvm_config_db#(svt_emmc_card_agent_configuration)::get(this, "", "card_cfg", card_cfg)) || card_cfg == null) begin
      `uvm_fatal("build_phase", "Card configuration is not provided.");
    end

    if (!(uvm_config_db#(svt_emmc_vif)::get(this, "", "sd_card_vif", card_vif)) || card_vif == null) begin
      `uvm_fatal("build_phase", "Card virtual interface is not provided.");
    end
    card_cfg.emmc_if = card_vif;

    uvm_config_db#(svt_emmc_card_agent_configuration)::set(this, "card_agent", "cfg", card_cfg);

    card_agent = svt_emmc_card_agent::type_id::create("card_agent", this);
  endfunction : build_phase

endclass : sdio_card_env

`endif // GUARD_SDIO_CARD_ENV_SV
