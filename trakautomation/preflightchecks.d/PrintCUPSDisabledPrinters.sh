#!/bin/sh -e
# Checks for CUPS printers being disabled
# Based on suggestion from LucaP 20130322

. ./functions.sh

check_Unix() {
	if ! which lpstat >/dev/null 2>&1; then
		echo "=CRITICAL - \"lpstat\" can't be found"
		return 0
	fi
	# get total printers and "not enabled" printers
	total=`lpstat -p 2>/dev/null | grep -v 'Ready to print' | wc -l`
	disabled=`lpstat -p 2>/dev/null | grep -v '.  enabled since '| wc -l`
	# check the results
	if [ -z "$total" -o -s "$disabled" ]; then
		echo "=CRITICAL - Could not determine total printers and/or disabled printers"
	elif [ $total -eq 0 ]; then
		echo "=ALERT - Found NO printers"
	else
		percent=$((($disabled*100)/$total))
		if [ $percent -gt 50 ]; then
			echo "=CRITICAL - Found $percent% of printers ($disabled / $total) not enabled"
		elif [ $percent -gt 5 ]; then
			echo "=ALERT - Found $percent% of printers ($disabled / $total) not enabled"
		elif [ $disabled -gt 0 ]; then
			echo "=NOTE - Found $percent% of printers ($disabled / $total) not enabled"
		else
			# prsumably its 2000 or more then
			echo "=OK - All ($total) printers enabled"
		fi
	fi
}

# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - CUPS Printers Disabled"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit print $FUNCTIONS
# would have bailed above if no match
osspecific check

