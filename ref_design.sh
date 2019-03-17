#!/bin/sh

. ./conf.sh

vivado -log Reports/Upload.log -mode batch -nojournal -source reset_board.tcl || exit 1
sleep 1
xsdk -batch -source ref_design/sdk.tcl || exit 1
