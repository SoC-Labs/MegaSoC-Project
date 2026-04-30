`include "svt_dfi.uvm.pkg"
`include "svt_dfi_mc.uvm.pkg"

  // Import UVM
  import uvm_pkg::*;
  
  // Import SVT UVM
  import svt_uvm_pkg::*;

  // Import SVT MEM UVM
  import svt_mem_uvm_pkg::*;

  // Import the DFI and MC VIPs
  import svt_dfi_uvm_pkg::*;
  import svt_dfi_mc_uvm_pkg::*;


class cust_svt_dfi_configuration extends uvm_object;
    function new(string name = "cust_svt_dfi_configuration");
    super.new(name);
    phy_cfg.dram_type = svt_dfi_types::LPDDR4;
    dfi_mc_cfg.dram_type= svt_dfi_types::LPDDR4;
    endfunction:new
endclass: cust_svt_dfi_configuration
