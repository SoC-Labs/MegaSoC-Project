
load_upf ../inputs/simple.upf

#source ./power_plan.tcl 
connect_pg_net -create_nets_only
connect_pg_net -automatic

create_pg_ring_pattern ring_pattern -nets {VDD VSS} -horizontal_layer M6 -vertical_layer M5 -horizontal_width {5} -vertical_width {5} -horizontal_spacing {2} -vertical_spacing {2}
set_pg_strategy core_ring -pattern {{name: ring_pattern} {nets: {VDD VSS}} {offset: {3 3}}} -core 
compile_pg -strategies core_ring -ignore_drc

create_pg_mesh_pattern mesh_pattern -layers {{{vertical_layer: M5} {width: 4} {pitch: 30.566} {offset: 21.5}} {{horizontal_layer: M6} {width: 4} {pitch: 30} {offset: 20}}} -via_rule {{intersection : all}}                                                
set_pg_strategy M5M6_mesh -core -pattern {{name: mesh_pattern} {nets: {VDD VSS}}} \
        -extension {{stop : first_target}}
compile_pg -strategies M5M6_mesh -ignore_drc

create_pg_std_cell_conn_pattern std_pattern -layers {M2} -check_std_cell_drc false -mark_as_follow_pin false -rail_width {0.14 0.14}
set_pg_strategy std_cell_strat -pattern {{name: std_pattern} {nets: {VDD VSS}}} -core
compile_pg -strategies std_cell_strat -ignore_drc

