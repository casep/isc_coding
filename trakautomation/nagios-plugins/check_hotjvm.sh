#!/bin/sh -e


set +e
hotjvm=`ps ax| grep java | grep -- -fop-config-file`
set -e
if [ ! -z "$hotjvm" ]; then
	echo "OK: HotJVM/FOP: Running"
	exit 0
else
	echo "CRITICAL: HotJVM/FOP: Not Running (capacity will be impacted)"
	exit 2
fi


