`include "svt_dfi.uvm.pkg"
`include "svt_dfi_mc.uvm.pkg"

`include "cust_svt_dfi_configuration.sv"

module dfi_monitor(
    input  wire         dfi_clk,
    input  wire         phy_clk,
    input  wire [5:0]   dfi_address_p,
    input  wire [5:0]   dfi_address_p1,
    input  wire [5:0]   dfi_address_p2,
    input  wire [5:0]   dfi_address_p3
);

  // Import UVM
  import uvm_pkg::*;
  
  // Import SVT UVM
  import svt_uvm_pkg::*;

  // Import SVT MEM UVM
  import svt_mem_uvm_pkg::*;

  // Import the DFI and MC VIPs
  import svt_dfi_uvm_pkg::*;
  import svt_dfi_mc_uvm_pkg::*;


// DFI interface for 1:4 frequency ratio interface for DFI PASSIVE PHY */
svt_dfi_1_to_4_ratio_frequency_if dfi_1_to_4_freq_if();

assign dfi_1_to_4_freq_if.dfi_clk = dfi_clk ;
assign dfi_1_to_4_freq_if.dfi_phy_clk = phy_clk ;
assign dfi_1_to_4_freq_if.dfi_address_p =  dfi_address_p ;
assign dfi_1_to_4_freq_if.dfi_address_p1 = dfi_address_p1 ;
assign dfi_1_to_4_freq_if.dfi_address_p2 = dfi_address_p2 ;
assign dfi_1_to_4_freq_if.dfi_address_p3 = dfi_address_p3 ;

initial begin
    uvm_config_db#(svt_dfi_1_to_4_ratio_frequency_vif)::set(uvm_root::get(), "uvm_test_top.dfi_env_h", "dfi_1_to_4_freq_if", dfi_1_to_4_freq_if);
    uvm_config_db#(svt_dfi_agent_configuration)::set(this,"dfi_agent","cfg",dfi_agent_cfg.phy_cfg);

    uvm_config_db#(cust_svt_dfi_configuration)::set(this, "dfi_env_h","dfi_agent_cfg", this.cfg);
    dfi_env_h =  ::type_id::create("dfi_env_h", this);
end


endmodule
