#!/bin/sh -e
# Checks perforce diretory for the given environment

. ./functions.sh



check_Unix() {
	# find the relevant cache.cpf in the standard path
	perforcedir=`trakpath $SITE $ENV DB$VER`/perforce/
	if [ ! -d "$perforcedir" ]; then
		echo "=CRITICAL - can't find \"$perforcedir\""
		return 0
	fi
	errors=0
	# check all ownership
	badownership=`find "$perforcedir" ! -name lost+found ! -user $CACHEUSR | wc -l | sed 's/ //g'`
	if [ $badownership -gt 0 ]; then
		errors=$(($errors+$badownership))
		echo "=ALERT - $badownership nodes found in \"$perforcedir\" not owned by \"$CACHEUSR\" (run: find \"$perforcedir\" ! -name lost+found ! -user $CACHEUSR)"
	fi
	# check all groups (more important)
	badgroup=`find "$perforcedir" ! -name lost+found ! -group $CACHEGRP | wc -l | sed 's/ //g'`
	if [ $badgroup -gt 0 ]; then
		errors=$(($errors+$badgroup))
		echo "=ALERT - $badgroup nodes found in \"$perforcedir\" not owned by group \"$CACHEGRP\" (run: find \"$perforcedir\" ! -name lost+found ! -group $CACHEGRP)"
	fi
	# check bad directory permissions - directories must be read/write
	baddirperms=`find "$perforcedir" ! -name lost+found -type d ! -perm -2770 | wc -l | sed 's/ //g'`
	if [ $baddirperms -gt 0 ]; then
		errors=$(($errors+$baddirperms))
		echo "=ALERT - $baddirperms directories found in \"$perforcedir\" not with at least 2770 bits set (run: find \"$perforcedir\" ! -name lost+found -type d ! -perm -2770)"
	fi
	# check bad file permissions - files must be readable
	badfileperms=`find "$perforcedir" -type f ! -perm -440 | wc -l | sed 's/ //g'`
	if [ $badfileperms -gt 0 ]; then
		errors=$(($errors+$badfileperms))
		echo "=ALERT - $badfileperms files found in \"$perforcedir\" not with at least 440 bits set (readable) (run: find \"$perforcedir\" -type f ! -perm -440)"
	fi
	# ok if no errors
	if [ $errors -eq 0 ]; then
		echo "=OK - permissions in \"$perforcedir\" are not obviously wrong"
	fi
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - TrakCare Perforce/CCR Filesystem Permissions"
checkfieldquit GoLive $STAGE
checkfieldquit database $FUNCTIONS
checkfieldquit BASE,TEST,PRD `echo $ENV | sed 's/[0-9]\+$//'`
# override user/group based on ownership of mgr/
export CACHEMGR=`ls -ld \`trakpath $SITE $ENV DB$VER\`/*/mgr/ | awk '{print $3}'`
export CACHEGRP=`ls -ld \`trakpath $SITE $ENV DB$VER\`/*/mgr/ | awk '{print $4}'`
# would have bailed above if no match
osspecific check

