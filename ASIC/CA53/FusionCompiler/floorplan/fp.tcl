################################################################################
#
# Created by fc write_floorplan on Fri Mar 21 07:46:39 2025
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
set_attribute -quiet -objects $cellInst -name origin -value { 937.5210 201.5040 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_h1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_h0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 937.5210 0.0000 }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_h0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_l1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 937.5210 201.5040 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_l1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_l0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 875.1060 100.7520 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank0_l0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_h1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 937.5210 302.2560 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_h1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_h0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 875.1060 201.5040 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_h0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_l1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 875.1060 0.0000 }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_l1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_l0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 875.1060 302.2560 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_idata_bank1_l0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_itag_ram0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 840.6630 430.2640 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_itag_ram0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_itag_ram1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 868.5180 430.2640 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_itag_ram1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 579.5450 894.8160 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 641.9600 894.8160 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank2 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 579.5450 796.0800 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank2 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank3 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 704.3750 894.8160 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank3 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank4 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 579.5450 697.3440 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank4 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank5 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 641.9600 796.0800 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank5 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank6 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 641.9600 697.3440 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank6 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank7 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 704.3750 796.0800 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddata_bank7 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 816.4140 864.1020 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 787.7490 864.1020 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank2 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 816.4140 811.7340 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank2 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank3 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 787.7490 811.7340 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_dtag_bank3 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddirty_ram }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 810.8980 647.5700 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_ddirty_ram }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 633.8420 232.9270 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 602.2970 232.9270 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank1 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank2 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 570.7520 232.9270 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank2 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank3 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 539.2070 232.9270 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_tlb_bank3 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_btac_stg0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 938.0520 429.4370 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_btac_stg0 }

set cellInst [get_cells { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_btac_stg1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R0
set_attribute -quiet -objects $cellInst -name origin -value { 966.7170 429.4370 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    g_ca53_cpu[0].u_ca53_cpu/u_ca53_caches_tlb_rams/u_btac_stg1 }

set cellInst [get_cells { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 521.8680 564.8770 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way0 }

set cellInst [get_cells { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 502.6530 564.8770 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way1 }

set cellInst [get_cells { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way2 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 500.3310 414.5460 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way2 }

set cellInst [get_cells { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way3 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 519.5460 414.5460 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/u_ca53scu_l1d_tagrams/g_l1d_cpu0_rams.u_l1d_tagram_cpu0_way3 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way0 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 353.5200 439.4400 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way0 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way1 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 433.8900 596.5440 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way1 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way2 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 353.5200 544.1760 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way2 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way3 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 393.7050 544.1760 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way3 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way4 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 313.3350 491.8080 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way4 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way5 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 353.5200 491.8080 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way5 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way6 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 393.7050 387.0720 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way6 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way7 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 393.7050 491.8080 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way7 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way8 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 353.5200 387.0720 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way8 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way9 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 393.7050 439.4400 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way9 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way10 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 313.3350 387.0720 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way10 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way11 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 313.3350 439.4400 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way11 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way12 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 313.3350 596.5440 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way12 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way13 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 353.5200 596.5440 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way13 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way14 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 313.3350 544.1760 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way14 }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way15 }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 393.7050 596.5440 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_tagram_way15 }

set cellInst [get_cells { u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_victimram \
    }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 435.4200 387.0720 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_tagrams/u_l2_victimram }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_0_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 136.5750 149.1360 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_0_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_0_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 273.1500 149.1360 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_0_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_1_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 409.7250 298.2720 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_1_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_1_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 273.1500 894.8160 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_1_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_2_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 409.7250 149.1360 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_2_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_2_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 409.7250 894.8160 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_2_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_3_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 273.1500 745.6800 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_3_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_3_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 409.7250 745.6800 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_3_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_4_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 136.5750 894.8160 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_4_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_4_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 136.5750 447.4080 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_4_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_5_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 273.1500 447.4080 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_5_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_5_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 273.1500 298.2720 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_5_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_6_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 136.5750 596.5440 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_6_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_6_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 273.1500 596.5440 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_6_high }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_7_low }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 136.5750 298.2720 \
    }
set_attribute -quiet -objects $cellInst -name status -value placed
create_keepout_margin -type hard -outer { 0.0762 0.0000 0.0762 0.0000 } { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_7_low }

set cellInst [get_cells { \
    u_ca53_l2/g_l2_rams.u_ca53_l2_datarams/u_l2_dataram_7_high }]
set_attribute -quiet -objects $cellInst -name orientation -value R180
set_attribute -quiet -objects $cellInst -name origin -value { 136.5750 745.6800 \
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
# Module Boundaries
################################################################################

set hbCells [get_cells -quiet -filter hierarchy_type==boundary -hierarchical]
if [sizeof_collection $hbCells] {
   set_cell_hierarchy_type -type normal $hbCells
}


################################################################################
# I/O guides
################################################################################

remove_io_guides -all


################################################################################
# User attributes of I/O guides
################################################################################


################################################################################
# User attributes of current block
################################################################################

define_user_attribute -classes design -type string LEF58_EDGETYPE
define_user_attribute -classes design -type double \
    achieved_target_routing_density
define_user_attribute -classes design -type int buf_inv_counts
define_user_attribute -classes design -type double expanded_util
define_user_attribute -classes design -type int ldp_flow_stage
set_attribute [current_design] expanded_util 0.79
set_attribute [current_design] achieved_target_routing_density 0.82

