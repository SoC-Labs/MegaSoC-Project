set_units -time ns;

create_clock -name HCLK -period 2.0 [get_ports HCLK]
create_clock -name PCLK -period 2.0 [get_ports PCLK]

set_input_delay 0.2 -clock [get_clocks HCLK]  [all_inputs]
set_input_delay 0.2 -clock [get_clocks PCLK]  [all_inputs]

set_output_delay 0.2 -clock [get_clocks HCLK] [all_outputs]
set_output_delay 0.2 -clock [get_clocks PCLK] [all_outputs]