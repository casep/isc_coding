#!/bin/sh -e
# Checks db/ directory for the given environment

. ./functions.sh

check_Unix() {
	# find the relevant cache.cpf in the standard path
	dbdir=`trakpath $SITE $ENV DB$VER`/db/
	if [ ! -d "$dbdir" ]; then
		echo "=CRITICAL - can't find \"$dbdir\""
		return 0
	fi
	errors=0
	# check all ownership
	badownership=`find "$dbdir" ! -user $CACHEUSR | wc -l | sed 's/ //g'`
	if [ $badownership -gt 0 ]; then
		errors=$(($errors+$badownership))
		echo "=ALERT - $badownership nodes found in \"$dbdir\" not owned by \"$CACHEUSR\" (run: find \"$dbdir\" ! -user $CACHEUSR)"
	fi
	# check all groups (more important)
	badgroup=`find "$dbdir" ! -group $CACHEGRP | wc -l | sed 's/ //g'`
	if [ $badgroup -gt 0 ]; then
		errors=$(($errors+$badgroup))
		echo "=ALERT - $badgroup nodes found in \"$dbdir\" not owned by group \"$CACHEGRP\" (run: find \"$dbdir\" ! -group $CACHEGRP)"
	fi
	# check bad directory permissions
	baddirperms=`find "$dbdir" -type d ! -perm -0775 | grep -v "$dbdir$" | wc -l | sed 's/ //g'`
	if [ $baddirperms -gt 0 ]; then
		errors=$(($errors+$baddirperms))
		echo "=ALERT - $baddirperms directories found in \"$dbdir\" not with at last 0775 bits set (run: find \"$dbdir\" -type d ! -perm -0775)"
	fi
	# check bad file permissions
	badfileperms=`find "$dbdir" -type f ! -perm -660 | wc -l | sed 's/ //g'`
	if [ $badfileperms -gt 0 ]; then
		errors=$(($errors+$badfileperms))
		echo "=ALERT - $badfileperms files found in \"$dbdir\" not with at last 660 bits set (run: find \"$dbdir\" -type f ! -perm -660)"
	fi
	badfileperms=`find "$dbdir" -type f -perm +111 | wc -l | sed 's/ //g'`
	if [ $badfileperms -gt 0 ]; then
		errors=$(($errors+$badfileperms))
		echo "=ALERT - $badfileperms files found in \"$dbdir\" with Execute bits set (run: find \"$dbdir\" -type f -perm +111)"
	fi
	# ok if no errors
	if [ $errors -eq 0 ]; then
		echo "=OK - permissions in \"$dbdir\" are not obviously wrong"
	fi
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - TrakCare db/ Filesystem Permissions"
checkfieldquit TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database $FUNCTIONS
# override user/group based on ownership of mgr/
export CACHEUSR=`ls -ld \`trakpath $SITE $ENV DB$VER\`/*/mgr/ | awk '{print $3}'`
export CACHEGRP=`ls -ld \`trakpath $SITE $ENV DB$VER\`/*/mgr/ | awk '{print $4}'`

# would have bailed above if no match
osspecific check

