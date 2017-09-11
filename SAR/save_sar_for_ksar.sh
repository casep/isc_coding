#!/bin/sh
targetfilename=`hostname`"_sar_A_"`date +%Y%m%d_%H%M`".txt"
echo "Saving \"sar -A\" output to file "$targetfilename
LC_ALL=C sar -A | tee $targetfilename

