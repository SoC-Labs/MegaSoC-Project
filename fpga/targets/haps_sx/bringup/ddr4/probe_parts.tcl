set D /home/ad1u25/megasoc_project/FPGA_Tasos/haps_top/ddr4
create_project ddr4_probe $D/ddr4_probe -part xcvu19p-fsva3824-2-e -force
create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 -module_name ddr4_p
set ip [get_ips ddr4_p]
set_property CONFIG.C0.DDR4_TimePeriod 938 $ip
set_property CONFIG.C0.DDR4_MemoryType SODIMMs $ip
puts "MemoryType now: [get_property CONFIG.C0.DDR4_MemoryType $ip]  default part now: [get_property CONFIG.C0.DDR4_MemoryPart $ip]"
if {[catch {set_property CONFIG.C0.DDR4_MemoryPart MTA16ATF2G64HZ-2G3 $ip} err]} { puts "PART ERR: $err" } else { puts "PART OK: [get_property CONFIG.C0.DDR4_MemoryPart $ip]" }
foreach tp {833 938 1071 1250} {
  catch {set_property CONFIG.C0.DDR4_TimePeriod $tp $ip}
  if {[catch {set_property CONFIG.C0.DDR4_MemoryPart MTA16ATF2G64HZ-2G3 $ip} err]} { puts "tCK $tp: part rejected: [string range $err 0 160]" } else { puts "tCK $tp: part accepted" }
}
puts "list_property_value MemoryType: [list_property_value CONFIG.C0.DDR4_MemoryType $ip]"
puts "PROBE DONE"
