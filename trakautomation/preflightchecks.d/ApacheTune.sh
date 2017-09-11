#!/bin/sh -e
# Checks for sane ServerLimit, MaxClients and KeepAliveTimeout
# With inappropriate setting performancy may be poor to the point that service is lost

. ./functions.sh


check_SLES() {
	CONF=/etc/apache2/server-tuning.conf
	check_LinuxGen
	return $?
}
check_RHEL() {
	CONF=/etc/httpd/conf/httpd.conf
	check_LinuxGen
	return $?
}
check_LinuxGen() {
	# ServerLimit
# TODO implement Apache config parse TODO
	line=`GetSection.pl $CONF '<IfModule prefork.c>' '</IfModule>' | grep --perl-regexp '\s*ServerLimit\s' | cat`
	value=`echo "$line" | sed 's/^[\t ]*ServerLimit[\t ]\+//' | sed 's/[\t ]\+//g'`
	if [ -z "$value" ]; then
		echo "=ALERT - ServerLimit is not set"
	elif [ $value -lt 1024 ]; then
		echo "=ALERT - ServerLimit of $value is abnormally low for a production site"
	else
		echo "=OK - ServerLimit of $value is sane"
	fi
	# MaxClients
	line=`GetSection.pl $CONF '<IfModule prefork.c>' '</IfModule>' | grep --perl-regexp '^\s*MaxClients\s'`
	limit=$value
	value=`echo "$line" | sed 's/^[\t ]*MaxClients[\t ]\+//' | sed 's/[\t ]\+//g'`
	if [ -z "$value" ]; then
		echo "=ALERT - MaxClients is not set"
	elif [ ! -z "$value" -a $value -gt $limit ]; then
		echo "=ALERT - MaxClients of $value is greater than ServerLimit of $limit - should be less to or equal"
	elif [ $value -lt 256 ]; then
		echo "=ALERT - MaxClients of $value is abnormally low (below Apache default)"
	elif [ $value -lt 512 ]; then
		echo "=NOTE - MaxClients of $value is low for a busy production site"
	else
		echo "=OK - MaxClients of $value is sane"
	fi
	# KeepAliveTimeout TODO maybe we should check for no KeepAlive after the problems TODO
#	if grep -q --perl-regexp '^\s*KeepAlive\s+On$' $CONF; then
#		value=`grep --perl-regexp '^\s*KeepAliveTimeout\s' $CONF | sed 's/^[\t ]*KeepAliveTimeout[\t ]\+//' | sed 's/[\t ]\+//g'`
#		if [ -z "$value" ]; then
#			echo "=ALERT - KeepAliveTimeout is not set"
#		elif [ $value -gt 5 ]; then
#			echo "=ALERT - KeepAliveTimeout of $value is very high (default 5) and likely to tie up resources without reason"
#		elif [ $value -gt 2 ]; then
#			echo "=NOTE - KeepAliveTimeout of $value is high for a production site with a fast network (LAN)"
#		else
#		echo "=OK - KeepAliveTimeout of $value is sane"
#		fi
#	else
#		echo "=NOTE - KeepAlive Disabled"
#	fi
	if grep -q --perl-regexp '^\s*KeepAlive\s+Off$' $CONF; then
		echo "=OK - KeepAlive Disabled which is sane (safe with MSIE)"
	else
		echo "=ALERT - KeepAlive Enabled. This can cause Hyperevent errors due to a (mis)behaviour of MSIE up to version 9."
	fi
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Apache tuning config"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit web,print $FUNCTIONS
# would have bailed above if no match
osspecific check

