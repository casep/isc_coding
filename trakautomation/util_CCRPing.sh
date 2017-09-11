#!/bin/sh -e
# check connectivity to CCR

tries=0
success=0

while true; do
	tries=$(($tries+1))
	if wget --max-redirect=0 --no-check-certificate --timeout=2 --tries=1 --output-document=- http://ccr.intersystems.com/ 2>&1 | grep -q 'Location: https://ccr.intersystems.com/ccr/index\.csp'; then
		success=$(($success+1))
		echo "Success ($success/$tries = $((100*$success/$tries))% success)"
	else
		echo "Fail ($success/$tries = $((100*$success/$tries))% success)"
	fi
	sleep 2
done


