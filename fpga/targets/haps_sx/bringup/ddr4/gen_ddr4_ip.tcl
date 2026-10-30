set D /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/ddr4
create_project ddr4_ip $D/ddr4_ip -part xcvu19p-fsva3824-2-e -force
create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 -module_name ddr4_0
set ip [get_ips ddr4_0]
proc setp {ip d} { if {[catch {set_property -dict $d $ip} err]} { puts "SETPROP FAILED: $d -> [string range $err 0 300]" } else { puts "set $d" } }
# Reference: HAPS-ZynqMP-Daughter-Board docs/reference/ddr4-configuration.md (vendor c2c_ddr design). Speed first: the IP
# validates DIMM type and part against the current tCK.
setp $ip {CONFIG.C0.DDR4_TimePeriod {938}}
setp $ip {CONFIG.C0.DDR4_MemoryType {SODIMMs}}
setp $ip {CONFIG.C0.DDR4_MemoryPart {MTA16ATF2G64HZ-2G3}}
puts "INPUT CLOCK PERIODS offered: [list_property_value CONFIG.C0.DDR4_InputClockPeriod $ip]"
setp $ip {CONFIG.C0.DDR4_InputClockPeriod {3335}}
setp $ip {CONFIG.C0.DDR4_DataWidth {64}}
setp $ip {CONFIG.C0.DDR4_Ecc {false}}
setp $ip {CONFIG.C0.DDR4_CasLatency {15}}
setp $ip {CONFIG.C0.DDR4_CasWriteLatency {11}}
setp $ip {CONFIG.C0.DDR4_DataMask {DM_NO_DBI}}
setp $ip {CONFIG.C0.DDR4_PhyClockRatio {4:1}}
setp $ip {CONFIG.C0.DDR4_Mem_Add_Map {ROW_COLUMN_BANK}}
setp $ip {CONFIG.C0.DDR4_AxiSelection {true}}
setp $ip {CONFIG.C0.DDR4_AxiDataWidth {512}}
setp $ip {CONFIG.C0.DDR4_AxiAddressWidth {34}}
setp $ip {CONFIG.C0.DDR4_AxiIDWidth {1}}
setp $ip {CONFIG.C0.DDR4_AxiNarrowBurst {true}}
setp $ip {CONFIG.C0.DDR4_AxiArbitrationScheme {RD_PRI_REG}}
setp $ip {CONFIG.C0.DDR4_Ordering {Normal}}
setp $ip {CONFIG.C0.DDR4_System_Clock {Differential}}
setp $ip {CONFIG.Debug_Signal {Disable}}
set fh [open $D/ddr4_0_props_configured.txt w]; puts $fh [report_property -return_string $ip]; close $fh
generate_target {instantiation_template synthesis implementation} $ip
open_example_project -force -in_process -dir $D $ip
puts "EXAMPLE PROJECT: [current_project] at [get_property DIRECTORY [current_project]]"
puts "TOP: [get_property top [current_fileset]]"
puts "XDC FILES: [get_files -quiet *.xdc]"
puts "IP GEN DONE"
