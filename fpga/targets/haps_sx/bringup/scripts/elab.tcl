open_project /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.xpr
set f /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.srcs/sources_1/new/qspi_flash_emu.sv
if {[llength [get_files -quiet $f]] == 0} { add_files -norecurse $f; set_property file_type SystemVerilog [get_files $f]; puts "===ELAB=== added qspi_flash_emu.sv" } else { puts "===ELAB=== qspi_flash_emu.sv already in project" }

# ---- build 54 (N25): L2 tag RAM integration -> Arm generic (masks the set index by l2_size), FPGA generic RAM model
set f_old1 /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.srcs/sources_1/imports/models/rams/tsmc_cln28hpm_L1_32I_32D_L2_1M/ca53_l2_tagrams.v
set f_old2 /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.srcs/sources_1/imports/models/rams/generic/ca53_generic_ram.v
set f_new1 /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.srcs/sources_1/imports/models/rams/generic/ca53_l2_tagrams.v
set f_new2 /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/haps_top.srcs/sources_1/new/ca53_generic_ram_fpga.v
foreach f [list $f_old1 $f_old2] { if {[llength [get_files -quiet $f]] > 0} { remove_files $f; puts "===B54=== removed $f" } }
foreach f [list $f_new1 $f_new2] { if {[llength [get_files -quiet $f]] == 0} { add_files -norecurse $f; puts "===B54=== added $f" } }
update_compile_order -fileset sources_1
synth_design -rtl -name rtl54 -top haps_top -part xcvu19p-fsva3824-2-e
puts "===ELAB=== OK"
puts "===ELAB=== spi_wbit flops: [llength [get_cells -hier -quiet -filter {NAME =~ *u_qspi_controller*spi_wbit*}]]"
puts "===ELAB=== dram slave cells: [llength [get_cells -hier -quiet -filter {NAME =~ *u_dram_error_slave*}]]"
puts "===ELAB=== probe NUM_SIGNALS: [get_property NUM_SIGNALS [get_cells u_debug_uart_probe]]"
close_design
