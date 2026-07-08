
`ifndef GUARD_LPDDR4_SVT_MACROS_UTIL_V
`define GUARD_LPDDR4_SVT_MACROS_UTIL_V

// Do not override if the timeout is already defined in testcase.
`ifndef TIME_OUT_VAL
 `define TIME_OUT_VAL #150_000_000
`endif

// Defines for utility methods
`define INFO_SEV 0
`define WARNING_SEV 1
`define ERROR_SEV 2
`define FATAL_SEV 3

// =============================================================================
/**
* Macro to get the value of a parameter in configuration or data object using
* vip_get_data_prop() commands. This macro includes checks for the returned
* validity flag, and error response if the property/action was not valid.
*
* This macro takes the following arguments :
*
* @param component  :  The string indicating the VIP instance. 
* @param handle     :  Integer handle that references the configuration or data object
* @param propname   :  Data object property name, like "lpddr_configuration", "lpddr_transaction", etc.
* @param propval    :  This is the returned property value.
* @param propidx    :  Index used if propname refers to an array type property
* @param expisvalid :  Expected 'is_valid' return value. Normally this will be 1. 0 for error conditions.
* @param failaction :  Determines how to treat the action if the 'is_valid' return value is 0.
*               This may be `FATAL_SEV or `WARNING_SEV. `WARNING_SEV will cause the test to
*               ignore the failure `FATAL_SEV will exit the simulation.
*/

`define GET_DATA_PROP_W_CHECK(component,handle,propname,propval,propidx,expisvalid,failaction) \
  vip_get_data_prop(component,handle,propname,propidx,expisvalid,propval,is_valid); \
  if (is_valid != expisvalid) begin \
    if (failaction == `FATAL_SEV) begin \
      $display("%m: FATAL - Aborting Simulation..."); \
      $finish; \
    end \
  end

// =============================================================================
/**
* Macros to set the value of a parameter in configuration or data object using
* vip_set_data_prop() commands. This macro includes checks for the returned
* validity flag, and error response if the property/action was not valid.
*
* This macro takes the following arguments :
*
* @param component  :  The string indicating the VIP instance. 
* @param handle     :  Integer handle that references the configuration or data object
* @param propname   :  Data object property name, like "lpddr_configuration", "lpddr_transaction", etc.
* @param propval    :  Value to be set. 
* @param propidx    :  Index used if propname refers to an array type property
* @param expisvalid :  Expected 'is_valid' return value. Normally this will be 1. 0 for error conditions.
* @param failaction :  Determines how to treat the action if the 'is_valid' return value is 0.
*               This may be `FATAL_SEV or `WARNING_SEV. `WARNING_SEV will cause the test to
*               ignore the failure `FATAL_SEV will exit the simulation.
*/

`define SET_DATA_PROP_W_CHECK(component,handle,propname,propval,propidx,expisvalid,failaction) \
  vip_set_data_prop(component,handle,propname,propval,propidx,expisvalid,is_valid); \
  if (is_valid != expisvalid) begin \
    if (failaction == `FATAL_SEV) begin \
      $display("%m: FATAL - Aborting Simulation..."); \
      $finish; \
    end \
  end

// =============================================================================
/**
* Macro to disable or enable the specified err_check instance using the 
* vip_get_data_prop(), vip_set_data_prop() & vip_apply_data() commands. 
*
* This macro takes the following arguments :
*
* @param component  :  The string indicating the VIP instance. 
* @param chkcontpath    :  String defining the hierarchical path of the check container which includes the check.
* @param chkname    :  The string indicating the checker rule to be modified.
* @param propval    :  Value to be set, if value is 0 then disables the check else enables the check. 
* @param failaction :  Determines how to treat the action if the 'is_valid' return value is 0.
*               This may be `FATAL_SEV or `WARNING_SEV. `WARNING_SEV will cause the test to
*               ignore the failure `FATAL_SEV will exit the simulation.
*/

`define ENABLE_CHECK(component,chkcontpath,chkname,propval,failaction) \
  begin \
    integer chkhandle; \
    `GET_DATA_PROP_W_CHECK(component, `SVT_CMD_NULL_HANDLE, chkcontpath, chkhandle, 0, 1, failaction) \
    `SET_DATA_PROP_W_CHECK(component, chkhandle, {chkname,".is_enabled"}, propval, 0, 1, failaction) \
    vip_apply_data(component,chkhandle); \
  end 

`endif // GUARD_LPDDR4_SVT_MACROS_UTIL_V
