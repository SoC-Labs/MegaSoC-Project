set_host_options -max_cores 16 -num_processes 16
set REPORT_DIR $env(SOCLABS_PROJECT_DIR)/imp/ASIC/CA53/reports
set LOG_DIR $env(SOCLABS_PROJECT_DIR)/imp/ASIC/CA53/logs

current_corner default
set_operating_conditions -max_library cln16fcll -max ffgnp_cbestccbestt_min_0p88v_m40c -min_library cln16fcll -min ssgnp_cworstccworstt_max_0p72v_125c
set_process_number -early 1 -late 1 -corners default
set_temperature 125 -min -40 -corners default
set_voltage 0.72 -min 0.88 -corners default


# Compile fusion takes about 6.5 hrs to run
compile_fusion 
save_lib cortexa53.dlib

redirect -tee -file $REPORT_DIR/timing_03_compile_fusion_max.rep {report_timing -delay_type max}
redirect -tee -file $REPORT_DIR/timing_03_compile_fusion_min.rep {report_timing -delay_type min}

save_lib cortexa53.dlib
