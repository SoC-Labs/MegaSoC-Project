
set clock_period 1000 ;	# 1 GHz

# -----------------------------------------------------------------------------
# Source clocks 
# -----------------------------------------------------------------------------

create_clock -name CLKIN -period ${clock_period} [get_ports {CLKIN} ]

# Generated clocks for each cpu's
create_generated_clock -add -name ck_cpu0 -divide_by 1 \
	-source [get_ports CLKIN] -master_clock [get_clocks CLKIN] \
	[get_pins -regexp {g_ca53_cpu[\[_]{1}0[\]._]{2}u_ca53_cpu/clk}]

# Generated clocks for SCU
create_generated_clock -add -name ck_scu -divide_by 1 \
	-source [get_ports CLKIN] -master_clock [get_clocks CLKIN] \
	[get_pins u_ca53_l2/u_ca53_l2noram/u_ca53scu/u_clk/u_clkgate/clk_gated_o]

create_generated_clock -add -name ck_scuslv0 -divide_by 1 \
	-source [get_ports CLKIN] -master_clock [get_clocks CLKIN] \
	[get_pins -regexp {u_ca53_l2/u_ca53_l2noram/u_ca53scu/u_scu_cpuslv0/g_cpuslv[_.]{1}u_inter_clkgate_reqbufs/clk_gated_o}]

# Generated clocks for l2 tag

create_generated_clock -add -name ck_l2tag -divide_by 1 \
	-source [get_ports CLKIN] -master_clock [get_clocks CLKIN] \
	[get_pins -regexp {u_ca53_l2/g_l2_rams[._]{1}u_ca53_l2_tagrams/g_clk_gate[\[_]{1}[0-9]+[\]._]{2}u_tag_clkgate/clk_gated_o}]

# -----------------------------------------------------------------------------
# Virtual clocks 
# -----------------------------------------------------------------------------

create_clock -name VCLK -period ${clock_period}

# -----------------------------------------------------------------------------
# Function: IO timing constraints file 
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Define cycle percentage expressions
# -----------------------------------------------------------------------------

# Temporary variables used during constraint generation e.g. $cycle20, $cycle60
# reduce the i incr value to 1 to create a complete $cycle00 .. $cycle99 range
for {set i 0} {$i < 100} {incr i 5} {
  set cycle[format "%#02d" $i ] [expr 0.01 * ${i} * ${clock_period}]
}

set ports_clock_root {CLKIN {g_ca53_cpu[0].u_ca53_cpu/clk} u_ca53_l2/u_ca53_l2noram/u_ca53scu/u_clk/u_clkgate/clk_gated_o u_ca53_l2/u_ca53_l2noram/u_ca53scu/u_scu_cpuslv0/g_cpuslv.u_inter_clkgate_reqbufs/clk_gated_o {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[0].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[1].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[2].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[3].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[4].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[5].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[6].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[7].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[8].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[9].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[10].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[11].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[12].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[13].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[14].u_tag_clkgate/clk_gated_o} {u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/g_clk_gate[15].u_tag_clkgate/clk_gated_o}}


set_input_delay  $cycle50 -clock VCLK -max [all_inputs] 
set_output_delay $cycle50 -clock VCLK -max [all_outputs]
 
set_input_delay  0 -clock VCLK -min [all_inputs] 
set_output_delay 0 -clock VCLK -min [all_outputs]

# Multicycle DFT
# The number of cycles is determined by test frequency vs. functional frequency
# For example this constraint assumes test is 4 times slower than functional frequency
set_multicycle_path 4 -setup -start -from [get_ports -regexp {DFTSE DFTRAMHOLD DFTRSTDISABLE DFTMCPHOLD DFTRAMBYP DFTSI[0-9]+}]
set_multicycle_path 3 -hold  -start -from [get_ports -regexp {DFTSE DFTRAMHOLD DFTRSTDISABLE DFTMCPHOLD DFTRAMBYP DFTSI[0-9]+}]
set_multicycle_path 4 -setup -end -to 		[get_ports -regexp {DFTSO[0-9]+}]
set_multicycle_path 3 -hold  -end -to 		[get_ports -regexp {DFTSO[0-9]+}]

# Multicycle scan I/O on cpu's
#set_multicycle_path 4 -setup -end -through [get_pins -regexp {g_ca53_cpu[\[_]{1}[0-3]+[\]._]{2}u_ca53_cpu/DFTS[IO]+[0-9]+$}]
#set_multicycle_path 3 -hold  -end -through [get_pins -regexp {g_ca53_cpu[\[_]{1}[0-3]+[\]._]{2}u_ca53_cpu/DFTS[IO]+[0-9]+$}]
# Implementation specific internal multicycle paths - SCU RAMs
#set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53scu_l1d_tagrams*/SO[*]"]
#set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53scu_l1d_tagrams*/SO[*]"]
#set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53scu_l1d_tagrams*/SI[*]"]
#set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53scu_l1d_tagrams*/SI[*]"]

# Implementation specific internal multicycle scan paths - L2 RAMs
#set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_tagrams*/SO[*]"]
#set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_tagrams*/SO[*]"]
#set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_tagrams*/SI[*]"]
#set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_tagrams*/SI[*]"]

# Implementation specific internal multicycle scan paths - L2 RAMs
#set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_datarams*/SO[*]"]
#set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_datarams*/SO[*]"]
#set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_datarams*/SI[*]"]
#set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_l2_datarams*/SI[*]"]

# Implementation specific internal multicycle scan paths - CPU RAMs
#set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_caches_tlb_rams*/SO[*]"]
#set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_caches_tlb_rams*/SO[*]"]
#set_multicycle_path 4 -setup -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_caches_tlb_rams*/SI[*]"]
#set_multicycle_path 3 -hold  -end -through [get_pins -quiet -hierarchical -filter "full_name =~ *u_ca53_caches_tlb_rams*/SI[*]"]

  
# -----------------------------------------------------------------------------
# Multicycle L2 data ram clocks
# -----------------------------------------------------------------------------
# These multicycle values need to be consistent with RTL configuration.
# These example settings assume 1 cycle write, 2 cycle read.
# Any updates to these values need to be accompanied by RTL reconfiguration.
set L2_high_clks {u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_0_high/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_1_high/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_2_high/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_3_high/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_4_high/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_5_high/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_6_high/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_7_high/CLK}

set_multicycle_path 2 -setup -end -from [get_pins $L2_high_clks] -through [get_pins u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_*_high/Q[*]]
set_multicycle_path 1 -hold  -end -from [get_pins $L2_high_clks] -through [get_pins u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_*_high/Q[*]]

set L2_low_clks {u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_0_low/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_1_low/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_2_low/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_3_low/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_4_low/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_5_low/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_6_low/CLK u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_7_low/CLK}
set_multicycle_path 2 -setup -end -from [get_pins $L2_low_clks] -through [get_pins u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_*_low/Q[*]]
set_multicycle_path 1 -hold  -end -from [get_pins $L2_low_clks] -through [get_pins u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_*_low/Q[*]]

# power control
# Multicycle paths for power gate SLEEP signal and isolation control. 
# This is implementation specific and needs to be determined based on power control strategy.
set_multicycle_path 6 -setup -end -from [get_ports nPWRUPCPU*]
set_multicycle_path 5 -hold  -end -from [get_ports nPWRUPCPU*]
set_multicycle_path 6 -setup -end -from [get_ports nPWRUPCORTEXA53*]
set_multicycle_path 5 -hold  -end -from [get_ports nPWRUPCORTEXA53*]
set_multicycle_path 2 -setup -end -from [get_ports nISO*]
set_multicycle_path 1 -hold  -end -from [get_ports nISO*]

# Max delay constraints to ensure SLEEP signal arrives within 6 cycles
set_max_delay [expr 6*${clock_period}] -from [get_ports nPWRUPCPU*]
set_max_delay [expr 6*${clock_period}] -from [get_ports nPWRUPCORTEXA53*]

set_clock_transition [expr $clock_max_transition_factor * $clock_period] [get_clocks]
set_max_transition [expr $max_transition_factor * $clock_period] CORTEXA53