#!/bin/sh -e
# Checks entire TrakCare tree for world writable files/directories

. ./functions.sh

check_LINUX() {
	# find the relevant cache.cpf in the standard path
	trakdir=`trakpath $SITE $ENV DB$VER`
	if [ ! -d "$trakdir" ]; then
		echo "=CRITICAL - can't find \"$trakdir\""
		return 0
	fi
	errors=0
	# check bad directory permissions
	baddirperms=`find "$trakdir" -type d -perm /o+w | grep -v /store/temp$ | wc -l | sed 's/ //g'`
	if [ $baddirperms -gt 0 ]; then
		errors=$(($errors+$baddirperms))
		echo "=ALERT - $baddirperms directories found in \"$trakdir\" world writable (run: find \"$trakdir\" -type d -perm /o+w | grep -v /store/temp$)"
	fi
	# check bad file permissions
	# Exclusions base on:
	#	* http://mailman.iscinternal.com/pipermail/cachesys/2013-September/023506.html
	#	* http://devlogarchive:8024/devlog/34xxx/34409.htm
	badfileperms=`find "$trakdir" -type f -perm /o+w | grep -v -e /bin/clock$ -e /mgr/cconsole.log -e /mgr/cconsole.old_ | wc -l | sed 's/ //g'`
	if [ $badfileperms -gt 0 ]; then
		errors=$(($errors+$badfileperms))
		echo "=ALERT - $badfileperms files found in \"$trakdir\" world writable (run: find \"$trakdir\" -type f -perm /o+w | grep -v -e /bin/clock$ -e /mgr/cconsole.log -e /mgr/cconsole.old_)"
	fi
	# ok if no errors
	if [ $errors -eq 0 ]; then
		echo "=OK - permissions in \"$trakdir\" are not obviously wrong"
	fi
}
check_UNIX() {
	# find the relevant cache.cpf in the standard path
	trakdir=`trakpath $SITE $ENV DB$VER`
	if [ ! -d "$trakdir" ]; then
		echo "=CRITICAL - can't find \"$trakdir\""
		return 0
	fi
	errors=0
	# check bad directory permissions
	baddirperms=`find "$trakdir" -type d -perm +o+w | grep -v /store/temp$ | wc -l | sed 's/ //g'`
	if [ $baddirperms -gt 0 ]; then
		errors=$(($errors+$baddirperms))
		echo "=ALERT - $baddirperms directories found in \"$trakdir\" world writable (run: find \"$trakdir\" -type d -perm +o+w | grep -v /store/temp$)"
	fi
	# check bad file permissions
	# Exclusions base on:
	#	* http://mailman.iscinternal.com/pipermail/cachesys/2013-September/023506.html
	#	* http://devlogarchive:8024/devlog/34xxx/34409.htm
	badfileperms=`find "$trakdir" -type f -perm +o+w | grep -v -e /bin/clock$ -e /mgr/cconsole.log -e /mgr/cconsole.old_ | wc -l | sed 's/ //g'`
	if [ $badfileperms -gt 0 ]; then
		errors=$(($errors+$badfileperms))
		echo "=ALERT - $badfileperms files found in \"$trakdir\" world writable (run: find \"$trakdir\" -type f -perm +o+w | grep -v -e /bin/clock$ -e /mgr/cconsole.log -e /mgr/cconsole.old_)"
	fi
	# ok if no errors
	if [ $errors -eq 0 ]; then
		echo "=OK - permissions in \"$trakdir\" are not obviously wrong"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - TrakCare Directory Unsafe Permissions"
checkfieldquit TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database $FUNCTIONS
# override user/group based on ownership of mgr/
export CACHEMGR=`ls -ld \`trakpath $SITE $ENV DB$VER\`/*/mgr/ | awk '{print $3}'`
export CACHEGRP=`ls -ld \`trakpath $SITE $ENV DB$VER\`/*/mgr/ | awk '{print $4}'`

# would have bailed above if no match
osspecific check

