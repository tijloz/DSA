#!/bin/sh

u=`echo "${USER}" | tr '[:upper:]' '[:lower:]'`

[ -d "${u}" ] || mkdir "${u}"

(
    cd ${u}
    
    for d in \
        2019-01-31_Lab_01 \
        2019-02-07_Lab_02 \
        2019-02-14_Lab_03 \
        2019-02-21_Lab_04 \
        2019-02-28_Lab_05 \
        2019-03-07_Lab_06 \
        2019-03-14_Lab_07 \
        2019-03-15_Lab_08 \
        2019-03-21_Lab_09 \
        2019-03-28_Lab_10 \
        2019-04-05_Lab_11
    do
    
        [ -d "${d}" ] || mkdir "${d}"
    
    done
)

echo ""
tar cjvf "Coursework_EE3DSD_${u}.tar.bz2" "${u}" | sort
echo ""
echo "Please verify that all relevant files have been"
echo "included in the archive above."
echo ""
echo "If everything is fine, please upload the file"
echo "\"Coursework_EE3DSD_${u}.tar.bz2\" to Blackboard."
echo ""
