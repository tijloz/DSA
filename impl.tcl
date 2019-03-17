# 
# Implementation script
# 

set_param xicom.use_bs_reader 1
create_project -in_memory -part xc7z020clg400-1

set_param project.singleFileAddWarning.threshold 0
set_property webtalk.parent_dir . [current_project]
set_property parent.project_path . [current_project]
set_property board_part_repo_paths Board_Files [current_project]
set_property board_part digilentinc.com:arty-z7-20:part0:1.0 [current_project]
set_property ip_output_repo . [current_project]
set_property ip_cache_permissions {read write} [current_project]
set_property design_mode GateLvl [current_fileset]

add_files -quiet syn.dcp
read_xdc Board_Files/arty-z7-20/A.0/top_level.xdc
#read_xdc Board_Files/arty-z7-20/A.0/processing_system.xdc
link_design -top top_level -part xc7z020clg400-1

opt_design 
report_drc -file Reports/DRC_Opted.txt

if { [llength [get_debug_cores -quiet] ] > 0 } { implement_debug_core } 

place_design 
report_io -file Reports/DRC_IO_Placed.txt
report_utilization -file Reports/Utilization_Placed.txt
report_control_sets -verbose -file Reports/Control_Sets_Placed.txt

route_design 
report_drc -file Reports/DRC_Routed.txt
report_methodology -file Reports/Methodology_DRC_Routed.txt
report_power -file Reports/Power_Routed.txt
report_route_status -file Reports/Route_Status.txt
report_timing_summary -max_paths 10 -file Reports/Timing_Summary_Routed.txt -warn_on_violation
report_incremental_reuse -file Reports/Incremental_Reuse_Routed.txt
report_clock_utilization -file Reports/Clock_Utilization_Routed.txt
report_bus_skew -file Reports/Bus_Skew_Routed.txt -warn_on_violation

set_param xicom.use_bs_reader 1

catch { write_mem_info -force top_level.mmi }

write_bitstream -force design.bit

catch { write_debug_probes -quiet -force top_level }

catch { file copy -force top_level.ltx debug_nets.ltx }
