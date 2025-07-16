# Import verilog and setup libraries

set_host_options -max_cores 8 -num_processes 8

# Set paths !!! Please edit for your system !!!
set cln16fcll_tech_path /research/AAA/phys_ip_library/arm/tsmc/cln16fcll001/arm_tech/r3p0

set cln16fcll_tech_file $cln16fcll_tech_path/ndm/9m_2xa1xd3xe2z_utrdl/sc9mcpp96c_tech.tf
set TLU_dir             $cln16fcll_tech_path/synopsys_tluplus/9m_2xa1xd3xe2z_utrdl

set TLU_cbest $TLU_dir/cbest.tluplus
set TLU_cworst $TLU_dir/cworst.tluplus
set TLU_rcbest $TLU_dir/rcbest.tluplus
set TLU_rcworst $TLU_dir/rcworst.tluplus
set TLU_map $TLU_dir/tluplus.map


#Create the design library 
create_lib cortexa53.dlib \
    -technology $cln16fcll_tech_file \
    -ref_libs {../libs/cln16fcll ../libs/CA53_L1_btac2 ../libs/CA53_L1_btac1 ../libs/CA53_L1_tlb ../libs/CA53_L1_dirty ../libs/CA53_L1_dtag ../libs/CA53_L1_ddata ../libs/CA53_L1_itag ../libs/CA53_L1_idata ../libs/CA53_L1_tag ../libs/CA53_L2_tag ../libs/CA53_L2_data ../libs/CA53_L2_vict}

# Read in the verilog for
source $env(SOCLABS_PROJECT_DIR)/imp/ASIC/CA53/flist/ca53_fc_flist.tcl

elaborate CORTEXA53
set_top_module CORTEXA53

#redirect -tee -file ./lib_cell_summary.log {report_lib -cell_summary cln28ht}
#redirect -tee -file ./lib_cell_pmk_summary.log {report_lib -cell_summary cln28ht_pmk}
#redirect -tee -file ./lib_cell_ret_summary.log {report_lib -cell_summary cln28ht_ret}
#redirect -tee -file ./lib_cell_bump_summary.log {report_lib -cell_summary bump_lib}
read_parasitic_tech -name cbest   -tlup $TLU_cbest -layermap $TLU_map 
read_parasitic_tech -name cworst  -tlup $TLU_cworst -layermap $TLU_map 
read_parasitic_tech -name rcbest  -tlup $TLU_rcbest -layermap $TLU_map 
read_parasitic_tech -name rcworst -tlup $TLU_rcworst -layermap $TLU_map 

save_lib cortexa53.dlib
# close_lib cortexa53.dlib
