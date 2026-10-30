set D [file dirname [info script]]
create_project brsim $D/brsim_proj -part xcvu19p-fsva3824-2-e -force
proc setp {ip d} { if {[catch {set_property -dict $d $ip} err]} { puts "SETPROP FAILED: $d -> [string range $err 0 300]"; exit 1 } }
create_ip -name axi_clock_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_cc_dram
setp [get_ips axi_cc_dram] {CONFIG.PROTOCOL {AXI4} CONFIG.ID_WIDTH {9} CONFIG.ADDR_WIDTH {34} CONFIG.DATA_WIDTH {64} CONFIG.ACLK_ASYNC {1} CONFIG.SYNCHRONIZATION_STAGES {3}}
setp [get_ips axi_cc_dram] {CONFIG.SI_CLK.FREQ_HZ {20000000}}
setp [get_ips axi_cc_dram] {CONFIG.MI_CLK.FREQ_HZ {266500000}}
create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip -version 2.1 -module_name axi_dw_dram
setp [get_ips axi_dw_dram] {CONFIG.PROTOCOL {AXI4} CONFIG.SI_DATA_WIDTH {64} CONFIG.MI_DATA_WIDTH {512} CONFIG.SI_ID_WIDTH {9} CONFIG.ADDR_WIDTH {34} CONFIG.FIFO_MODE {0}}
setp [get_ips axi_dw_dram] {CONFIG.SI_CLK.FREQ_HZ {266500000}}
generate_target {instantiation_template simulation synthesis} [get_ips]
add_files -norecurse [list /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.srcs/sources_1/new/haps_ddr4_bridge.sv $D/ddr4_0_sim_model.sv]
set_property file_type SystemVerilog [get_files *.sv]
add_files -fileset sim_1 -norecurse $D/tb_bridge.sv
set_property file_type SystemVerilog [get_files tb_bridge.sv]
set_property top tb_bridge [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {false} -objects [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "===BRSIM=== project ready"
launch_simulation
puts "===BRSIM=== simulation finished"
close_sim
exit
