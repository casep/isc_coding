#!/bin/sh -e
# Checks for PMS Font set deployed

. ./functions.sh


check_LINUX() {
	pmsfonts=/usr/share/fonts/PMSFonts/
	if [ ! -d $pmsfonts ]; then
		echo "=ALERT - Can't find \"$pmsfonts\" directory"
	elif [ `ls $pmsfonts/ | grep -i \\.ttf$ | wc -l` -lt 12 ]; then
		echo "=ALERT - Expecting at least 12 font files in \"$pmsfonts\" directory"
	else
		echo "=OK - Found \"$pmsfonts\" directory with a plausible number of font files"
	fi
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - PMS Fonts Deployed"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit print,preview $FUNCTIONS
# would have bailed above if no match
osspecific check

