# -----------------------------------------------------------------------------
# The confidential and proprietary information contained in this file may
# only be used by a person authorised under and to the extent permitted
# by a subsisting licensing agreement from ARM Limited.
#
#            (C) COPYRIGHT 2012-2014 ARM Limited.
#                ALL RIGHTS RESERVED
#
# This entire notice must be reproduced on all copies of this file
# and copies of this file may only be made by a person if such person is
# permitted to do so under the terms of a subsisting license agreement
# from ARM Limited.
#
#      SVN Information
#
#      Checked In          : $Date: 2014-02-11 14:05:52 +0000 (Tue, 11 Feb 2014) $
#
#      Revision            : $Revision: 269995 $
#
#      Release Information : CORTEXA53-r0p4-00rel0
#
# -----------------------------------------------------------------------------
set_units -time ns;

set clock_period 2.0 ;	# 850 MHz

# -----------------------------------------------------------------------------
# Function: Setup design clocks
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Source clocks 
# -----------------------------------------------------------------------------

create_clock -name CLKIN -period ${clock_period} [get_ports {CLKIN} ]

# -----------------------------------------------------------------------------
# Generated clocks
# -----------------------------------------------------------------------------

## Create clock startpoints in DC to enable hierarchy reporting by clock group
#if { $synopsys_program_name == "dc_shell" } { 
#	# Add a buffer on the clock entering large hierarchical blocks 
#	insert_buffer -new_net_names ck_l2data  -new_cell_names ck_l2data_sp  [get_pins -regexp {u_ca53_l2/g_l2_rams[._]{1}u_ca53_l2_datarams/clk}] ${driving_cell}
#	insert_buffer -new_net_names ck_l2tag 	-new_cell_names ck_l2tag_sp 	[get_pins -regexp {u_ca53_l2/g_l2_rams[._]{1}u_ca53_l2_tagrams/clk}] 	${driving_cell}
#
#	# Stop the buffer from being removed
#	set_dont_touch [get_cells { u_ca53_l2/ck_l2data_sp \
#															u_ca53_l2/ck_l2tag_sp}] true
#}
#
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
#  The confidential and proprietary information contained in this file may
#  only be used by a person authorised under and to the extent permitted
#  by a subsisting licensing agreement from ARM Limited.
#
#             (C) COPYRIGHT 2012-2014 ARM Limited.
#                 ALL RIGHTS RESERVED
#
#  This entire notice must be reproduced on all copies of this file
#  and copies of this file may only be made by a person if such person is
#  permitted to do so under the terms of a subsisting license agreement
#  from ARM Limited.
#
#       SVN Information
#
#       Checked In          : $Date: 2013-02-25 16:02:55 +0000 (Mon, 25 Feb 2013) $
#
#       Revision            : $Revision: 239121 $
#
#       Release Information : CORTEXA53-r0p4-00rel0
#
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Function: IO timing constraints file 
# -----------------------------------------------------------------------------

