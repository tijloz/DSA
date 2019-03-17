# 
# System Upload Script
# 

connect -url tcp:127.0.0.1:3121
#targets -set -nocase -filter {name =~"xc7z020" && jtag_cable_name =~ "Digilent Arty Z7 *"} -index 1
#rst -srst
source .srcs/sources_1/ip/processing_system7_0/ps7_init.tcl
targets -set -filter {jtag_cable_name =~ "Digilent Arty Z7 *" && level==0} -index 1
fpga -file design.bit
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent Arty Z7 *"} -index 0
loadhw -hw Board_Files/arty-z7-20/A.0/system.hdf -mem-ranges [list {0x40000000 0xbfffffff}]
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent Arty Z7 *"} -index 0
stop
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Arty Z7 *"} -index 0
rst -processor
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Arty Z7 *"} -index 0
dow Board_Files/arty-z7-20/A.0//system.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Arty Z7 *"} -index 0
con
