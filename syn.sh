#!/bin/sh

. ./conf.sh

vivado -log Reports/Synthesis.log -mode batch -nojournal -source syn.tcl || exit 1
mv NA/ps7_summary.html Reports/
rmdir NA
