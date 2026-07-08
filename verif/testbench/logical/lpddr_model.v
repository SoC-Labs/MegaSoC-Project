
/**
 * Abstract:
 *     Top level Verilog LPDDR testbench.
 *     The LPDDR model and controller instance of VIP is setup with LPDDR JEDEC CHIP interface
 */
/** Include the defines for LPDDR */
`include "svt_lpddr_defines.svi"

/** Include svt_mem.uvm package */
`include "svt_mem.uvm.pkg"

/** Import the required packages */
import uvm_pkg::*;
import svt_uvm_pkg::*;
import svt_mem_uvm_pkg::*;

/** Include Memory Agent files */
`include "svt_lpddr_agent_hdl.sv"

/** Include Controller Agent files */
`include "svt_lpddr_controller_agent_hdl.sv"


module lpddr_model(
    input wire ck_c,
    input wire ck_t,
    input wire cke,
    input wire cs_n,
    input wire odt,
    input wire[5:0] ca,
    input wire [1:0] dm,
    inout wire [1:0] dqs_t,
    inout wire [1:0] dqs_c,
    inout wire [15:0] dq,
    input wire reset_n
);


  // Unconnected Interface Signals
  wire                                          cs_p_unconn;
  wire                                            zq_unconn;
  wire [(`SVT_LPDDR4_MAX_DMI_WIDTH-1):0]         dmi_unconn;

 defparam memory.vip_type=`SVT_LPDDR_VIP_TYPE_LPDDR4;
  svt_lpddr_agent_hdl memory(
                             .ck_c    (ck_c),
                             .ck_t    (ck_t),
                             .cke     (cke),
                             .cs_n    (cs_n),
                             .odt     (odt),
                             .ca      (ca),
                             .dm      (dm),
                             .dqs_t   (dqs_t),
                             .dqs_c   (dqs_c),
                             .dq      (dq),
                             .cs_p    (cs_p_unconn),
                             .reset_n (reset_n),
                             .zq      (zq_unconn),
                             .dmi     (dmi_unconn)
                            );

initial
begin
    #10 initialize_inst();
    #10 memory.start();
end


/** This method will configure the LPDDR components. */
task initialize_inst;
  integer          cfg_handle;
  integer          timing_cfg_handle;
  reg              is_valid;
  integer          verbosity;
  integer          verbosity_val;
  reg              msg_valid;
  static string    lpddr4_part_number ;
  static string    lpddr4A_part_number ;
  bit              lpddr4_ext;
  begin 

    //check for lpddr4A config.
    if ($value$plusargs("LPDDR4_EXT=%s", lpddr4_ext)) begin
		if (lpddr4_ext == 1'b1) begin 
    		// Overwriting the part name if it is supplied from command line else
    		// loading it with a default value.
    		if ($value$plusargs("PART_NUMBER=%s", lpddr4A_part_number)) 
    		  begin
    		    $display("  **** Overwriting part name to %s via command line ****",lpddr4A_part_number);
    		  end
    		else
    		  lpddr4A_part_number = "jedec_lpddr4A_12G_x16_1066_1_875";
		end
		else begin
    		// Overwriting the part name if it is supplied from command line else
    		// loading it with a default value.
    		if ($value$plusargs("PART_NUMBER=%s", lpddr4_part_number)) 
    		  begin
    		    $display("  **** Overwriting part name to %s via command line ****",lpddr4_part_number);
    		  end
    		else
    		  lpddr4_part_number = "jedec_lpddr4_12G_x16_1066_1_875";
		end
    end
    // Overwriting the part name if it is supplied from command line else
    // loading it with a default value.
    else if ($value$plusargs("PART_NUMBER=%s", lpddr4_part_number)) 
      begin
        $display("  **** Overwriting part name to %s via command line ****",lpddr4_part_number);
      end
    else
      lpddr4_part_number = "jedec_lpddr4_12G_x16_1066_1_875";

    // Assign the desired values to the top level configuration properties using the utility task "update_vip"
    if (lpddr4_ext ==1'b1) begin
    	memory.cmd_mem_load_part_cfg(is_valid,
                          `SVT_LPDDR_CMD_CATALOG_LPDDR4A,
                          `SVT_LPDDR_CMD_CATALOG_PACKAGE_DRAM,
                          `SVT_LPDDR_CMD_CATALOG_VENDOR_JEDEC,
                          lpddr4A_part_number );
    end
    else begin
    	memory.cmd_mem_load_part_cfg(is_valid,
                          `SVT_LPDDR_CMD_CATALOG_LPDDR4,
                          `SVT_LPDDR_CMD_CATALOG_PACKAGE_DRAM,
                          `SVT_LPDDR_CMD_CATALOG_VENDOR_JEDEC,
                          lpddr4_part_number );
    end
        // To update the timing configuration

    memory.get_data_prop(is_valid, `SVT_CMD_NULL_HANDLE, "timing_cfg", timing_cfg_handle, 0);
    //`GET_DATA_PROP_W_CHECK("memory", `SVT_CMD_NULL_HANDLE, "timing_cfg", timing_cfg_handle, 0, 1, `FATAL_SEV)
    $display("  TB @%0d %m - vip_get_data_prop() returned 'timing_cfg_handle' = %0d for mem_agent instance", $time, timing_cfg_handle);

    // Assign the desired values to the top level timing configuration properties
    memory.set_data_prop(is_valid, timing_cfg_handle, "clock_rate", SVT_MEM_667MHz, 0);
    memory.set_data_prop(is_valid, timing_cfg_handle, "tinit0_ms", $realtobits(0.001), 0);
    memory.set_data_prop(is_valid, timing_cfg_handle, "tinit1_ns", $realtobits(10.0), 0);
    memory.set_data_prop(is_valid, timing_cfg_handle, "tinit2_ck", 'd2, 0);
    memory.set_data_prop(is_valid, timing_cfg_handle, "tinit3_us", $realtobits(2.0), 0);
    memory.set_data_prop(is_valid, timing_cfg_handle, "tinit4_us", $realtobits(1.0), 0);
    memory.set_data_prop(is_valid, timing_cfg_handle, "tinit5_us", $realtobits(10.0), 0);
    memory.set_data_prop(is_valid, timing_cfg_handle, "scaled_timing_flag", 1, 0);
    memory.set_data_prop(is_valid, timing_cfg_handle, "tckb_ns", $realtobits(18.000000), 0);

 //   // This method will disable the specified check
 //   `ENABLE_CHECK("memory","err_check.common_err_check","tckb_during_initialization_for_mrw_mrr_cmd_check",0,`FATAL_SEV)
//
 //   // This method will disable the specified check
 //   `ENABLE_CHECK("memory","err_check.common_err_check","invalid_precharge_command_in_idle_state_check",0,`FATAL_SEV)

    // This will call Agent's apply_data() to set timing_cfg
    memory.apply_data(is_valid, timing_cfg_handle);

    $display("  **** Writing memory configuration  ****");
    memory.get_data_prop(is_valid, `SVT_CMD_NULL_HANDLE, "cfg", cfg_handle, 0);
    //`SET_DATA_PROP_W_CHECK("memory", cfg_handle, "bypass_initialization", 1'b1 , 0, 1, `FATAL_SEV)
    memory.display_data(is_valid, cfg_handle, "Final LPDDR memory Configuraton: ");
  end
endtask : initialize_inst

endmodule
