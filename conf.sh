#!/bin/sh

BASE_DIR=""
[ -d /opt/Xilinx ] && BASE_DIR=/opt/Xilinx
[ -d /usr/local/Xilinx ] && BASE_DIR=/usr/local/Xilinx
[ -z "${BASE_DIR}" ] && (echo "No Vivado installation found!" ; exit 1)

SDK_DIR=${BASE_DIR}/SDK/2018.2
VIVADO_DIR=${BASE_DIR}/Vivado/2018.2
BIN_DIR=${SDK_DIR}/bin:${VIVADO_DIR}/ids_lite/ISE/bin/lin64:${VIVADO_DIR}/bin
LIB_DIR=${VIVADO_DIR}/ids_lite/ISE/lib/lin64

if [ -z "${PATH}" ]; then
  export PATH=${BIN_DIR}
else
  export PATH=${BIN_DIR}:${PATH}
fi

if [ -z "${LD_LIBRARY_PATH}" ]; then
  export LD_LIBRARY_PATH=${LIB_DIR}
else
  export LD_LIBRARY_PATH=${LIB_DIR}:${LD_LIBRARY_PATH}
fi

[ -d Reports ] || mkdir Reports
