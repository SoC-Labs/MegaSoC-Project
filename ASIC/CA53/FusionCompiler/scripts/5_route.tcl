set_host_options -max_cores 16 -num_processes 16
set REPORT_DIR $env(SOCLABS_PROJECT_DIR)/imp/ASIC/CA53/reports
set LOG_DIR $env(SOCLABS_PROJECT_DIR)/imp/ASIC/CA53/logs

route_auto
redirect -tee -file $REPORT_DIR/timing_05_route_max.rep {report_timing -delay_type max}
redirect -tee -file $REPORT_DIR/timing_05_route_min.rep {report_timing -delay_type min}

save_lib cortexa53.dlib
