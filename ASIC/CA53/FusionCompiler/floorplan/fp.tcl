################################################################################
#
# Created by fc write_floorplan on Wed Aug 20 19:40:20 2025
#
################################################################################


set _dirName__0 [file dirname [file normalize [info script]]]

################################################################################
# Read DEF
################################################################################

read_def  ${_dirName__0}/floorplan.def

################################################################################
# Macros
################################################################################

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_h1 }]
set_attribute -quiet -objects $cellInst -name orientation -value MX
set_attribute -quiet -objects $cellInst -name origin -value { 999.7800 201.5040 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_h1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_h0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 999.7800 0.0000 }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_h0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_l1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 999.7800 201.5040 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_l1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_l0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 937.3650 100.7520 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_l0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_h1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 999.7800 302.2560 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_h1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_h0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 937.3650 201.5040 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_h0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_l1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 937.3650 0.0000 }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_l1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_l0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 937.3650 302.2560 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_l0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_itag_ram0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 868.5180 471.5680 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_itag_ram0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_itag_ram1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 896.3730 471.5680 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_itag_ram1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 564.1670 926.3030 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 626.5820 926.3030 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank2 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 564.1670 827.5670 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank2 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank3 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 688.9970 926.3030 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank3 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank4 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 564.1670 728.8310 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank4 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank5 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 626.5820 827.5670 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank5 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank6 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 626.5820 728.8310 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank6 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank7 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 688.9970 827.5670 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank7 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 844.3410 864.1020 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 815.6760 864.1020 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank2 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 844.3410 811.7340 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank2 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank3 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 815.6760 811.7340 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank3 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddirty_ram }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 873.3130 647.5700 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddirty_ram }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 827.8170 194.0300 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 796.2720 194.0300 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank2 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 764.7270 194.0300 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank2 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank3 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 733.1820 194.0300 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank3 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_btac_stg0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 965.9070 470.7410 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_btac_stg0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_btac_stg1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 994.5720 470.7410 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_btac_stg1 }

set cellInst [get_cells { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 614.2110 543.0990 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way0 }

set cellInst [get_cells { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 592.1160 543.0990 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way1 }

set cellInst [get_cells { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way2 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 592.1160 392.7680 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way2 }

set cellInst [get_cells { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way3 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 614.2110 392.7680 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way3 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 353.5200 443.3310 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way0 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 433.8900 600.4350 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way1 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way2 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 353.5200 548.0670 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way2 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way3 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 393.7050 548.0670 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way3 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way4 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 313.3350 495.6990 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way4 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way5 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 353.5200 495.6990 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way5 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way6 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 393.7050 390.9630 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way6 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way7 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 393.7050 495.6990 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way7 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way8 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 353.5200 390.9630 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way8 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way9 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 393.7050 443.3310 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way9 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way10 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 313.3350 390.9630 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way10 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way11 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 313.3350 443.3310 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way11 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way12 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 313.3350 600.4350 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way12 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way13 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 353.5200 600.4350 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way13 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way14 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 313.3350 548.0670 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way14 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way15 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 393.7050 600.4350 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way15 }

set cellInst [get_cells { u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_victimram \
    }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 435.4200 390.9630 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_victimram }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_0_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 136.5750 176.9890 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_0_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_0_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 273.1500 176.9890 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_0_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_1_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 409.7250 326.1250 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_1_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_1_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 273.1500 925.1260 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_1_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_2_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 409.7250 176.9890 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_2_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_2_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 409.7250 925.1260 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_2_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_3_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 273.1500 775.7620 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_3_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_3_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 409.7250 775.7620 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_3_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_4_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 136.5750 925.1260 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_4_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_4_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 136.5750 474.4420 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_4_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_5_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 273.1500 474.4420 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_5_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_5_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 273.1500 326.1250 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_5_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_6_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 136.5750 624.3970 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_6_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_6_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 273.1500 624.3970 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_6_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_7_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 136.5750 326.1250 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_7_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_7_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 136.5750 775.7620 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_7_high }


################################################################################
# User attributes of macros
################################################################################

define_user_attribute -classes cell -type boolean SNPS_MuxEO

################################################################################
# Bounds and user attributes of bound shapes
################################################################################

remove_bounds -all


################################################################################
# User attributes of bounds
################################################################################


################################################################################
# Blockages
################################################################################

remove_routing_blockages -all -force

remove_placement_blockages -all -force

remove_pin_blockages -all

remove_shaping_blockages -all

################################################################################
# User attributes of blockages
################################################################################

################################################################################
# Module Boundaries
################################################################################

set hbCells [get_cells -quiet -filter hierarchy_type==boundary -hierarchical]
if [sizeof_collection $hbCells] {
   set_cell_hierarchy_type -type normal $hbCells
}


################################################################################
# User attributes of current block
################################################################################

define_user_attribute -classes design -type string LEF58_EDGETYPE
define_user_attribute -classes design -type double \
    achieved_target_routing_density
define_user_attribute -classes design -type int buf_inv_counts
define_user_attribute -classes design -type double expanded_util
define_user_attribute -classes design -type int ldp_flow_stage
define_user_attribute -classes design -type string sqs_step
define_user_attribute -classes design -type string write_qor_data
set_attribute [current_design] sqs_step synthesis
set_attribute [current_design] write_qor_data {qor_strategy {high_effort_timing \
    1 reduced_effort 0 default 0 stage synthesis metric timing}}
set_attribute [current_design] achieved_target_routing_density 0.0
set_attribute [current_design] expanded_util 0.53

