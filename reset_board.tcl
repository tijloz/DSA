# 
# Board Reset Script
# 

create_project -in_memory -part xc7z020clg400-1

set_property board_part_repo_paths Board_Files [current_project]
set_property board_part digilentinc.com:arty-z7-20:part0:1.0 [current_project]

open_hw
connect_hw_server
open_hw_target
current_hw_device [get_hw_devices xc7z020_1]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7z020_1] 0]
create_hw_cfgmem -hw_device [lindex [get_hw_devices] 1] -mem_dev [lindex [get_cfgmem_parts {s25fl128s-3.3v-qspi-x4-single}] 0]
#set_property PROBES.FILE {} [get_hw_devices xc7z020_1]
#set_property FULL_PROBES.FILE {} [get_hw_devices xc7z020_1]
refresh_hw_device [lindex [get_hw_devices xc7z020_1] 0]
#set opTemp [get_property TEMPERATURE [lindex [get_hw_sysmons] 0]
