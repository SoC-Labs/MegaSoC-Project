
`ifndef GUARD_LPDDR4_SVT_VIP_UTIL_V
`define GUARD_LPDDR4_SVT_VIP_UTIL_V

`include "lpddr4_svt_macros_util.v"

// ----------------------------------------------------------------------------------------------------
/**
 * Utility method to call get_data_prop for a specific VIP instance
 * @param component    : The string corresponding to instance name for the VIP within test_top.
 * @param handle       : Specifies controller or memory instance handle of the testbench 
 * @param prop_name    : Property name of data object like cmd, data etc. 
 * @param array_ix     : Specifies array index for array properties like data, data_mask etc. 
 * @param expisvalid   : Expected 'is_valid' return value. Normally this will be 1. 0 for error conditions.
 * @param prop_val     : Returned property value. 
 * @param is_valid     : Flag indicating the success (1) or failure (0) of the operation.
 */
task vip_get_data_prop;
  input        reg [80*8:0] component;
  input        integer handle;
  input        string  prop_name;
  input        int array_ix;
  input        reg expisvalid;
  output       reg [80*8:0] prop_val;
  output       reg is_valid;
  reg [80*8:0] msgstr;
  begin
    if (component == "controller") begin
      test_top.controller.get_data_prop(is_valid, handle, prop_name, prop_val, array_ix);
    end 
    else if (component == "memory") begin
      test_top.memory.get_data_prop(is_valid, handle, prop_name, prop_val, array_ix);
    end 
    else begin
      $display("%m: ERROR - The input argument component(%0s) is not recognized. Currently supported argument values are controller and memory.",component);
      return;
    end
    $swrite(msgstr, "%0s.get_data_prop(is_valid, handle,%0s, %0d, %0d);",component,prop_name,prop_val,array_ix);
    check_for_1(is_valid, msgstr, `ERROR_SEV);
  end
endtask : vip_get_data_prop

// ----------------------------------------------------------------------------------------------------
/**
 * Utility method to call cmd_mem_load_part_cfg for a specific VIP instnace
 * Loads a part number from the specified catalog.
 * 
 * The following are the only legal macro constants for the mem_package argument:
 * <ul>
 *  <li>\`SVT_LPDDR_CMD_CATALOG_PACKAGE_DRAM</li>
 * </ul>
 * 
 * The following are the only legal macro constants for the mem_vendor argument:
 * <ul>
 *  <li>\`SVT_LPDDR_CMD_CATALOG_VENDOR_JEDEC</li>
 * </ul>
 * 
 * @param is_valid     : Functions as a <i>return</i> value that indicates the success
 *                       of the cmd_mem_load_part_cfg operation.
 * @param mem_class    : Determines which memory class to select the part number from
 * @param mem_package  : Determines which package category to select the part number from
 * @param mem_vendor   : Determines which vendor category to selct the part number from
 * @param part_name    : Specifies the part name to load
 */
task cmd_mem_load_part_cfg;
  output  bit    is_valid;
  input   reg [80*8:0] component;
  input   int    mem_class;
  input   int    mem_package;
  input   int    mem_vendor;
  input   string part_name;
  begin
    if (component == "memory") 
      test_top.memory.cmd_mem_load_part_cfg(is_valid,mem_class,mem_package,mem_vendor,part_name);
    else if (component == "controller") 
      test_top.controller.cmd_mem_load_part_cfg(is_valid,mem_class,mem_package,mem_vendor,part_name);
    else
      $display("%m: ERROR - The specified component %0s is not valid.",component);
  end
   
endtask : cmd_mem_load_part_cfg

// ----------------------------------------------------------------------------------------------------
/**
 * Utility method to call set_data_prop for a specific VIP instance.
 * @param component   : The string corresponding to instance name for the VIP within test_top.
 * @param handle      : Specifies controller or memory instance handle of the testbench 
 * @param prop_name   : Property name of data object like cmd, data etc. 
 * @param array_ix    : Specifies array index for array properties like data, data_mask etc. 
 * @param prop_val    : Property value that needs to be set. 
 * @param expisvalid  : Expected 'is_valid' return value.  Normally this will be 1. 0 for error conditions.
 * @param is_valid    : Flag indicating the success (1) or failure (0) of the operation.
 */
task vip_set_data_prop;
  input        reg [80*8:0] component;
  input        integer handle;
  input        string prop_name;
  input        reg [80*8:0] prop_val;
  input        integer array_ix;
  input        reg expisvalid;
  output       reg is_valid;
  reg [80*8:0] msgstr;
  begin
    if (component == "controller") begin
      test_top.controller.set_data_prop(is_valid, handle, prop_name, prop_val, array_ix);
    end 
    else if (component == "memory") begin
      test_top.memory.set_data_prop(is_valid, handle, prop_name, prop_val, array_ix);
    end 
    else begin
      $display("%m: ERROR - The input argument component(%0s) is not recognized.  Currently supported argument values are controller and memory.",component);
      return;
    end
    $swrite(msgstr, "%0s.set_data_prop(is_valid, handle,%0s, %0d, %0d);",component,prop_name,prop_val,array_ix);
    check_for_1(is_valid, msgstr, `ERROR_SEV);
  end
endtask : vip_set_data_prop

// ----------------------------------------------------------------------------------------------------
/**
 * Waits for the indicated event to occur. 
 * @param component  : The string corresponding to instance name for the VIP within test_top.
 * @param event_name : Named events supported by the VIP. The name should be of the form of
                       "NOTIFY_.....
 * @param is_valid   :  Flag indicating the success (1) or failure (0) of the operation.
 */
task vip_notify_wait_for;
  input       reg [80*8:0] component;
  input       string event_name;
  output      bit is_valid;
  begin
    if (component == "controller") begin
      test_top.controller.notify_wait_for(is_valid, event_name);
    end 
    else if (component == "memory") begin
      test_top.memory.notify_wait_for(is_valid, event_name);
    end
    else begin
      $display("%m: ERROR - The input argument component(%0s) is not recognized.  Currently supported argument values are controller and memory.",component);
    end
  end
endtask : vip_notify_wait_for

// ----------------------------------------------------------------------------------------------------
/**
 * Utility method to call display_data for a specific VIP instance
 * @param component : The string corresponding to instance name for the VIP within test_top.
 * @param handle    : Handle to the VIP instance for which data is to be displayed.
 * @param str       : This corresponds to prefix that will be displayed in the beginning of every line, 
 *                    when displaying the data objects.
 * @param is_valid  : Flag indicating the success (1) or failure (0) of the operation.
 */
task vip_display_data;
  input       reg [80*8:0] component;
  input       integer handle;
  input       string str;
  reg         is_valid;
  reg [80*8:0] msgstr;
  begin
    if (component == "controller") begin
      test_top.controller.display_data(is_valid, handle, str);
    end 
    else if (component == "memory") begin
      test_top.memory.display_data(is_valid, handle, str);
    end
    else begin
      $display("%m: ERROR - The input argument component(%0s) is not recognized.  Currently supported argument values are controller and memory.",component);
      return;
    end
    $swrite(msgstr, "%0s.display_data(is_valid, handle, str",component);
    check_for_1(is_valid, msgstr, `ERROR_SEV);
  end
endtask : vip_display_data

// ----------------------------------------------------------------------------------------------------
/**
 * Utility method to call apply_data for a specific VIP instance
 * @param component : The string corresponding to instance name for the VIP within test_top.
 * @param handle    : Handle to the VIP instance for which data is to be applied.
 */
task vip_apply_data;
  input       reg [80*8:0] component;
  input       integer handle;
  reg         is_valid;
  reg [80*8:0] msgstr;
  begin
    if (component == "controller") begin
      test_top.controller.apply_data(is_valid, handle, 1);
    end 
    else if (component == "memory") begin
      test_top.memory.apply_data(is_valid, handle, 1);
    end
    else begin
      $display("%m: ERROR - The input argument component(%0s) is not recognized.  Currently supported argument values are controller and memory.",component);
      return;
    end
    $swrite(msgstr, "%0s.apply_data(is_valid, handle, 1",component);
    check_for_1(is_valid, msgstr, `ERROR_SEV);
  end
endtask : vip_apply_data

// ----------------------------------------------------------------------------------------------------
/**
 * Utility method to call new_data for a specific VIP instance
 * @param component : The string corresponding to instance name for the VIP within test_top.
 * @param data_type : This is a string that identifies the type of the object to be created.
 * @param handle    : Handle to the VIP instance that needs to be constructed.
 */
task vip_new_data;
  input       reg [80*8:0] component;
  input       string  datatype;
  output      integer handle;
  reg         is_valid;
  reg [80*8:0] msgstr;
  begin
    if (component == "controller") begin
      test_top.controller.new_data(is_valid, handle, datatype);
    end 
    else if (component == "memory") begin
      test_top.memory.new_data(is_valid, handle, datatype);
    end
    else begin
      $display("%m: ERROR - The input argument component(%0s) is not recognized.  Currently supported argument values are controller and memory.",component);
      return;
    end
    $swrite(msgstr, "%0s.new_data(is_valid, handle, datatype",component);
    check_for_1(is_valid, msgstr, `ERROR_SEV);
  end
endtask : vip_new_data

// ----------------------------------------------------------------------------------------------------
/**
 * Utility method to call callback_wait_for for a specific VIP instance
 *
 * @param component      : The string corresponding to instance name for the VIP within test_top.
 * @param cb_notify_name : Named callbacks supported by the VIP. The
 *                         name should be of the form "NOTIFY_CB_...".
 * @param handle         : Handle to the VIP instance which implements this callback.
 * @param is_valid       : Flag indicating the success (1) or failure (0) of the operation.
 *
 */
task vip_callback_wait_for;
  input       reg [80*8:0] component;
  input       string cb_notify_name;
  inout       integer handle;
  output      bit is_valid;
  begin
    if (component == "controller") 
      test_top.controller.cmd_callback_wait_for(is_valid, handle, cb_notify_name);
    else if (component == "memory") 
      test_top.memory.cmd_callback_wait_for(is_valid, handle, cb_notify_name);
    else begin
      $display("%m: ERROR - The input argument component(%0s) is not recognized.  Currently supported argument values are controller and memory.",component);
    end
  end
endtask : vip_callback_wait_for

// ----------------------------------------------------------------------------------------------------
/**
 * Utility method to call callback_proceed for a specific VIP instance
 * @param component      : The string corresponding to instance name for the VIP within test_top.
 * @param cb_notify_name : Named callbacks supported by the VIP. The
 *                         name should be of the form "NOTIFY_CB_...".
 * @param handle         : Handle to the VIP instance which implements this callback.
 * @param is_valid       : Flag indicating the success (1) or failure (0) of the operation.
 *
 */
task vip_callback_proceed;
  input       reg [80*8:0] component;
  input       string cb_notify_name;
  inout       integer handle;
  output      bit is_valid;
  begin
    if (component == "controller") begin
      test_top.controller.cmd_callback_proceed(is_valid, handle, cb_notify_name);
    end 
    else if (component == "memory") begin
      test_top.memory.cmd_callback_proceed(is_valid, handle, cb_notify_name);
    end
    else begin
      $display("%m: ERROR - The input argument component(%0s) is not recognized.  Currently supported argument values are controller, module,",component);
    end
  end
endtask : vip_callback_proceed

// ----------------------------------------------------------------------------------------------------
/**
 * Used to create the deep copy of active data object.
 * @param component     : The string corresponding to instance name for the VIP within test_top.
 * @param src_handle    : Handle to the VIP instance from which copy is made.
 * @param handle        : Handle to the VIP instance to which copy is made.
 */
task vip_copy_data;
  input       reg [80*8:0] component;
  input       integer src_handle;
  output      integer handle;
  reg         is_valid;
  begin
    is_valid = 0;
    if (component == "controller") begin
      test_top.controller.copy_data(is_valid, handle, src_handle);
    end 
    else if (component == "memory") begin
      test_top.memory.copy_data(is_valid, handle, src_handle);
    end
    else begin
      $display("%m: ERROR - The input argument component(%0s) is not recognized.  Currently supported argument values are controller and memory.",component);
    end
    check_for_1(is_valid, "copy for given data can not be created", `ERROR_SEV);
  end
endtask : vip_copy_data

// ----------------------------------------------------------------------------------------------------
/**
 * Used to start the module internal run phase.
 * @param component : The string corresponding to instance name for the VIP within test_top.
 */
task vip_start;
  input       reg [80*8:0] component;
  begin
    if (component == "controller") begin
      test_top.controller.start();
    end 
    else if (component == "memory") begin
      test_top.memory.start();
    end
    else begin
      $display("%m: ERROR - The input argument component(%0s) is not recognized.  Currently supported argument values are controller and memory.",component);
    end
  end
endtask : vip_start

// ----------------------------------------------------------------------------------------------------
/**
 * Used to stop the module internal run phase.
 * @param component : The string corresponding to instance name for the VIP within test_top.
 */
task vip_stop;
  input       reg [80*8:0] component;
  begin
    if (component == "controller") begin
      test_top.controller.stop();
    end 
    else if (component == "memory") begin
      test_top.memory.stop();
    end
    else begin
      $display("%m: ERROR - The input argument component(%0s) is not recognized.  Currently supported argument values are controller and memory.",component);
    end
  end
endtask : vip_stop

//---------------------------------------------------------------------------
/**
 * @groupname membackdoor
 * Command Support:
 * Initialize the specified address range in the memory with the specified
 * pattern. Supported patterns are: constant value, incrementing values,
 * decrementing values, walk left, walk right. For user-defined patterns, the
 * backdoor should be used.
 * Only virtual initialization is supported.
 * 
 * The following macros are the only supported values for the pattern argument:
 * <ul>
 *  <li>\`SVT_MEM_INITIALIZE_CONST</li>
 *  <li>\`SVT_MEM_INITIALIZE_INCR</li>
 *  <li>\`SVT_MEM_INITIALIZE_DECR</li>
 *  <li>\`SVT_MEM_INITIALIZE_WALK_LEFT</li>
 *  <li>\`SVT_MEM_INITIALIZE_WALK_RIGHT</li>
 * </ul>
 * 
 * @param pattern initialization pattern.
 * @param base_data Starting data value used with each pattern
 * @param start_addr start address of the region to be initialized.
 * @param end_addr end address of the region to be initilized.
 */
task cmd_mem_initialize;
  output bit is_valid;
  input  reg [80*8:0] component;
  input  int pattern; 
  input  bit [`SVT_LPDDR_MAX_DQ_WIDTH-1:0] base_data;
  input  bit [`SVT_LPDDR_MAX_ADDR_WIDTH-1:0] start_addr;
  input  bit [`SVT_LPDDR_MAX_ADDR_WIDTH-1:0] end_addr;
  begin
    if (component == "memory") begin 
      test_top.memory.cmd_mem_initialize(is_valid,pattern,base_data,start_addr,end_addr);
      if(is_valid) begin
        $display("%m:INFO - The memory is initialized with Data = 0x%0h, start_address = 0x%0h, end_address = 0x%0h ",base_data,start_addr,end_addr);
      end
    end  
    else
      $display("%m: ERROR - The received component %0s is not valid.",component);
  end
endtask

//------------------------------------------------------------------------------
/**
 * @groupname membackdoor
 * Command Support:
 * Retrieve the data value from the memory at the provided address.
 *
 * @param is_valid Functions as a <i>return</i> value ('0' if the value was
 * not found in the memory).
 *
 * @param addr Address to obtain the data from
 * @param data Value of the data retrieved
 */
task cmd_mem_peek;
  output bit is_valid;
  input  reg [80*8:0] component;
  input   bit [`SVT_LPDDR_MAX_ADDR_WIDTH-1:0] addr;
  output  bit [`SVT_LPDDR_MAX_DQ_WIDTH-1:0] data;
  begin
    if (component == "memory") begin 
      test_top.memory.cmd_mem_peek(is_valid,addr,data);
      if(is_valid) begin
        $display("%m:INFO - Backdoor Read Data = 0x%0h,address = 0x%0h ",data,addr);
      end
      else begin
        $display("%m:ERROR- There is no data written on address = 0x%h Read Data = 0x%0h",addr,data);
      end
    end
    else
      $display("%m: ERROR - The received component %0s is not valid.",component);
  end
endtask

//------------------------------------------------------------------------------
/**
 * @groupname membackdoor
 * Command Support:
 * Set the data value in the memory at the provided address.
 *
 * @param is_valid Functions as a <i>return</i> value ('0' if the value was
 * not found in the memory).
 *
 * @param addr Address to obtain the data from
 *
 * @param data Value of the data retrieved
 */
task cmd_mem_poke;
  output bit is_valid;
  input  reg [80*8:0] component;
  input  bit [`SVT_LPDDR_MAX_ADDR_WIDTH-1:0] addr;
  input  bit [`SVT_LPDDR_MAX_DQ_WIDTH-1:0] data;
  begin
    if (component == "memory") begin 
      test_top.memory.cmd_mem_poke(is_valid,addr,data);
      if(is_valid) begin
        $display("%m:INFO - Backdoor Write Data = 0x%0h,address = 0x%0h ",data,addr);
      end
      else begin
        $display("%m:ERROR- No data written on Address = 0x%h Write Data = 0x%0h ",addr,data);
      end
    end
    else
      $display("%m: ERROR - The received component %0s is not valid.",component);
  end
endtask

// ----------------------------------------------------------------------------------------------------
/**
 * Utility method to get 
 *   - The combined error count corresponding to SVT_CMD_ERROR_SEVERITY and SVT_CMD_FATAL_SEVERITY
 *   - The warning count corresponding to SVT_CMD_WARNING_SEVERITY
 *  .
 * @param component    : The string corresponding to VIP instance
 * @param err_out_val  : Output value of combined error count corresponding
 *                       to SVT_CMD_ERROR_SEVERITY and SVT_CMD_FATAL_SEVERITY
 * @param warn_out_val : Output value of count corresponding to SVT_CMD_WARNING_SEVERITY
 */
task get_warning_error_count;
  input      reg [80*8:0] component;
  output     integer err_out_val;
  output     integer warn_out_val;
  integer    error_val;
  integer    fatal_val;
  integer    warning_val;
  reg        is_valid;
  begin
    `GET_DATA_PROP_W_CHECK(component, `SVT_CMD_NULL_HANDLE, "fatal_count", fatal_val, 0, 1, `FATAL_SEV)
    `GET_DATA_PROP_W_CHECK(component, `SVT_CMD_NULL_HANDLE, "error_count", error_val, 0, 1, `FATAL_SEV)
    `GET_DATA_PROP_W_CHECK(component, `SVT_CMD_NULL_HANDLE, "warning_count", warning_val, 0, 1, `FATAL_SEV)
    err_out_val = fatal_val + error_val;
    warn_out_val = warning_val;
  end
endtask : get_warning_error_count

`endif // GUARD_LPDDR4_SVT_VIP_UTIL_V


