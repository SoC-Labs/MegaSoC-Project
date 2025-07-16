# Main flow for Synopsys fusion compiler 
set_host_options -max_cores 8 -num_processes 8
set REPORT_DIR $env(SOCLABS_PROJECT_DIR)/imp/ASIC/CA53/reports
set LOG_DIR $env(SOCLABS_PROJECT_DIR)/imp/ASIC/CA53/logs

# Design setup: read libraries and RTL 
redirect -tee -file $LOG_DIR/01_design_setup.log {source ./design_setup.tcl}
