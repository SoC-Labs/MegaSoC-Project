set_host_options -max_cores 16 -num_processes 16
set REPORT_DIR $env(SOCLABS_PROJECT_DIR)/imp/ASIC/CA53/reports
set LOG_DIR $env(SOCLABS_PROJECT_DIR)/imp/ASIC/CA53/logs


synthesize_clock_trees -clocks {CLKIN VCLK ck_cpu0 ck_l2tag ck_scu ck_scuslv0}

report_timing

redirect -tee -file $REPORT_DIR/timing_04a_CTS_max.rep {report_timing -delay_type max}
redirect -tee -file $REPORT_DIR/timing_04a_CTS_min.rep {report_timing -delay_type min}

save_lib cortexa53.dlib

clock_opt

report_timing

redirect -tee -file $REPORT_DIR/timing_04b_Clockopt_max.rep {report_timing -delay_type max}
redirect -tee -file $REPORT_DIR/timing_04b_Clockopt_min.rep {report_timing -delay_type min}

