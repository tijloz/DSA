#
# Makefile to simulate and synthesize VHDL designs
#

TMP_DIR=/tmp/$(USER)

TCL = \
	Board_Files/arty-z7-20/A.0/processing_system.tcl

CONSTRAINTS = \
	Board_Files/arty-z7-20/A.0/top_level.xdc

VHDL = \
	config.vhd \
	top_level.vhd \
	util.vhd

all help:
	@echo ""
	@echo "Image Viewer:"
	@echo ""
	@echo "make viewer                    - open image viewer"
	@echo "make mod_viewer                - open modified image viewer"
	@echo ""
	@echo "Reference Design:"
	@echo ""
	@echo "make reference                 - load reference design onto FPGA"
	@echo ""
	@echo "Simulation:"
	@echo ""
	@echo "make julia_demo                - run Julia Set functional demonstration"
	@echo "make julia_cw_1               	- run Julia coursework 1"
	@echo "make julia_cw_2               	- run Julia coursework 2"
	@echo "make julia_cw_3               	- run Julia coursework 3"
	@echo "make julia_cw_1_float         	- run Sphere coursework 1 float converted"
	@echo "make fixed_point_test         	- run fixed_point_test"
	@echo "make test.bin									- generate bin file"
	@echo "make sphere_demo               - run Sphere functional demonstration"
	@echo "make sphere_cw_1               - run Sphere coursework 1 demonstration"
	@echo "make sphere_cw_2               - run Sphere coursework 2 demonstration"
	@echo "make sphere_cw_3               - run Sphere coursework 3 demonstration"
	@echo "make sphere_cw_4               - run Sphere coursework 4 demonstration"
	@echo ""
	@echo "Synthesis:"
	@echo ""
	@echo "make synthesis                 - synthesize design"
	@echo "make implementation            - implement design"
	@echo "make upload                    - upload design to FPGA"
	@echo ""
	@echo "Submission:"
	@echo ""
	@echo "make submission                - create archive for submission"
	@echo ""
	@echo "Cleanup:"
	@echo ""
	@echo "make clean                     - delete temporary files and cleanup directory"
	@echo ""

tx_pipe:
	mkfifo tx_pipe

julia_demo: tx_pipe julia_demo.vhd std_logic_textio.vhd util.vhd

	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd julia_demo.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys julia_demo 2>&1
	ghdl -r julia_demo
	@rm -f julia_demo

sphere_demo: tx_pipe sphere_demo.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd sphere_demo.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys sphere_demo 2>&1
	ghdl -r sphere_demo
	@rm -f sphere_demo

fixed_point_test: tx_pipe fixed_point_test.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd fixed_point_test.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys top_level 2>&1
	ghdl -r top_level
	@rm -f top_level

julia_cw_1: tx_pipe julia_cw_1.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd julia_cw_1.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys top_level 2>&1
	ghdl -r top_level
	@rm -f top_level

julia_cw_1_float: tx_pipe julia_cw_1_float.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd julia_cw_1_float.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys top_level 2>&1
	ghdl -r top_level
	@rm -f top_level

sphere_cw_1: tx_pipe sphere_cw_1.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd sphere_cw_1.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys top_level 2>&1
	ghdl -r top_level
	@rm -f top_level

sphere.bin: sphere_assembler.vhd config_sim.vhd std_logic_textio.vhd util.vhd
	@echo "Assembler running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd sphere_assembler.vhd config_sim.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys assembler 2>&1
	ghdl -r assembler
	@rm -f assembler

# dump: sphere.bin
# 	@hexdump -e '"%02_ad | " 2/1 "%02x" "\n"' sphere.bin

test.bin: test_assembler.vhd config_sim.vhd std_logic_textio.vhd util.vhd
	@echo "Assembler running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd test_assembler.vhd config_sim.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys assembler 2>&1
	ghdl -r assembler
	@rm -f assembler

# dump: test.bin
# 	@hexdump -e '"%02_ad | " 2/1 "%02x" "\n"' test.bin


julia.bin: julia_assembler.vhd config_sim.vhd std_logic_textio.vhd util.vhd
	@echo "Assembler running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd julia_assembler.vhd config_sim.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys assembler 2>&1
	ghdl -r assembler
	@rm -f assembler

dump: julia.bin
	@hexdump -e '"%02_ad | " 2/1 "%02x" "\n"' julia.bin


sphere_cw_2: tx_pipe sphere.bin sphere_cw_2.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd sphere_cw_2.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys top_level 2>&1
	ghdl -r top_level
	@rm -f top_level

julia_cw_2: tx_pipe julia.bin julia_cw_2.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd julia_cw_2.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys top_level 2>&1
	ghdl -r top_level
	@rm -f top_level

sphere_cw_3_wave: tx_pipe sphere.bin simulator.vhd config_sim.vhd sphere_cw_3.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd simulator.vhd config_sim.vhd sphere_cw_3.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys simulator 2>&1
	ghdl -r simulator --wave=$(TMP_DIR)/simulator.ghw --stop-time=10ms
	@rm -f simulator

sphere_cw_3: tx_pipe sphere.bin simulator.vhd config_sim.vhd sphere_cw_3.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd simulator.vhd config_sim.vhd sphere_cw_3.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys simulator 2>&1
	ghdl -r simulator
	@rm -f simulator

julia_cw_3_wave: tx_pipe julia.bin simulator.vhd config_sim.vhd julia_cw_3.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd simulator.vhd config_sim.vhd julia_cw_3.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys simulator 2>&1
	ghdl -r simulator --wave=$(TMP_DIR)/simulator.ghw --stop-time=10ms
	@rm -f simulator

julia_cw_3: tx_pipe julia.bin simulator.vhd config_sim.vhd julia_cw_3.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd simulator.vhd config_sim.vhd julia_cw_3.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys simulator 2>&1
	ghdl -r simulator
	@rm -f simulator

sphere_cw_4_wave: tx_pipe sphere.bin simulator.vhd config_sim.vhd sphere_cw_4.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd simulator.vhd config_sim.vhd sphere_cw_4.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys simulator 2>&1
	ghdl -r simulator --wave=$(TMP_DIR)/simulator.ghw --stop-time=10ms
	@rm -f simulator

sphere_cw_4: tx_pipe sphere.bin simulator.vhd config_sim.vhd sphere_cw_4.vhd std_logic_textio.vhd util.vhd
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i std_logic_textio.vhd util.vhd simulator.vhd config_sim.vhd sphere_cw_4.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys simulator 2>&1
	ghdl -r simulator  --stats --disp-order
	@rm -f simulator

julia.hex: julia.asm assembler.vhd mnemonics.vhd util.vhd
	@echo "Assembler running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i assembler.vhd mnemonics.vhd util.vhd
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys assembler 2>&1
#	ghdl -r assembler --wave=$(TMP_DIR)/assembler.ghw
	ghdl -r assembler
	@rm -f assembler

viewer view: tx_pipe
	nohup ./img_viewer > /dev/null &

vhdl.tcl: Makefile
	@echo "#" > vhdl.tcl
	@echo "# VHDL Source Files" >> vhdl.tcl
	@echo "#" >> vhdl.tcl
	@for f in Board_Files/arty-z7-20/A.0/embedded_system.vhd $(VHDL); \
	do \
	    echo "read_vhdl $${f}" >> vhdl.tcl; \
	done

simulation sim: tx_pipe julia.hex simulator.vhd $(VHDL)
	@echo "Simulation running..."

	@[ -d $(TMP_DIR) ] || mkdir $(TMP_DIR)

	ghdl -i simulator.vhd $(VHDL)
	ghdl -m -Punisim --warn-unused -fexplicit --ieee=synopsys simulator 2>&1
#	ghdl -r simulator --wave=$(TMP_DIR)/simulator.ghw
	ghdl -r simulator
	@rm -f simulator

gtkwave:
	gtkwave $(TMP_DIR)/simulator.ghw simulator.sav &

reference ref: tx_pipe
	./ref_design.sh

synthesis syn syn.dcp: tx_pipe conf.sh syn.sh syn.tcl vhdl.tcl Board_Files/arty-z7-20/A.0/embedded_system.vhd $(VHDL) $(CONSTRAINTS) $(TCL)
	./syn.sh

implementation impl design.bit: syn.dcp conf.sh impl.sh impl.tcl
	./impl.sh

upload up: design.bit conf.sh upload.sh upload.tcl
	./upload.sh

submission sub:
	@./submission.sh

clean:
	rm -rf *~ design.bit syn.dcp vhdl.tcl .srcs .Xil Reports \
	       Board_Files/arty-z7-20/A.0/ps7_init* \
	       Board_Files/arty-z7-20/A.0/tutorial_bd_wrapper.bit \
	       2018.2 debug_nets.ltx top_level.ltx \
	       usage_statistics_webtalk.* \
	       *.o *.cap work-obj93.cf sphere.bin simulator julia.hex
