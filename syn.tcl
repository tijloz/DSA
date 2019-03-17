# 
# Synthesis script
# 

create_project -in_memory -part xc7z020clg400-1

set_property target_language VHDL [current_project]
set_property board_part_repo_paths Board_Files [current_project]
set_property board_part digilentinc.com:arty-z7-20:part0:1.0 [current_project]

set_property parent.project_path . [current_project]
set_property ip_output_repo IP [current_project]
set_property ip_cache_permissions {read write} [current_project]

source Board_Files/arty-z7-20/A.0/processing_system.tcl
source vhdl.tcl

synth_design -top embedded_system -part xc7z020clg400-1

#create_debug_core u_ila_0 ila
#set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
#set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
#set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
#set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
#set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
#set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
#set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
#set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
#set_property port_width 1 [get_debug_ports u_ila_0/clk]
#connect_debug_port u_ila_0/clk [get_nets [list clk_0_1 ]]
#set_property port_width 1 [get_debug_ports u_ila_0/probe0]
#connect_debug_port u_ila_0/probe0 [get_nets [list dcf_0_1]]
#create_debug_port u_ila_0 probe
#set_property port_width 1 [get_debug_ports u_ila_0/probe1]
#connect_debug_port u_ila_0/probe1 [get_nets [list msf_0_1]]

write_checkpoint -force -noxdef syn.dcp
report_timing_summary -file Reports/Synthesis_Timing.txt
report_utilization -file Reports/Synthesis_Utilization.txt
