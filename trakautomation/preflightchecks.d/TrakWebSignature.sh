#!/bin/sh -e
# Creates a signature/fingerprint of web/ diretory for the given environment
# ... useful to know if systems are consistent

. ./functions.sh


sha1sumlines() {
	while read line; do
		echo "${line#$webdir}"
		[ -f "$line" ] && sha1sum "$line"
	done
}



check_Unix() {
	# find the relevant cache.cpf in the standard path
	webdir=`trakpath $SITE $ENV DB$VER`/web/
	if [ ! -d "$webdir" ]; then
		echo "=CRITICAL - can't find \"$webdir\""
		return 0
	fi
	errors=0
	# generate signature
	cd $webdir
	echo "=NOTE - signature for \"$webdir\": "`find | sort | sha1sumlines | sha1sum | cut -d' ' -f1`
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - TrakCare web/ Filesystem Signature"
checkfieldquit GoLive $STAGE
checkfieldquit database $FUNCTIONS

# would have bailed above if no match
osspecific check

