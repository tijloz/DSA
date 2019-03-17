#!/bin/sh

. ./conf.sh

vivado -log Reports/Implementation.log -mode batch -nojournal -source impl.tcl || exit 1
