#!/bin/sh -e
# Checks for that FOP+HotJVM and dependant packages are installed, plus config is sane
# see http://pic.dhe.ibm.com/infocenter/wasinfo/v6r0/index.jsp?topic=%2Fcom.ibm.websphere.express.doc%2Finfo%2Fexp%2Fae%2Ftprf_tunejvm.html

. ./functions.sh

check_LINUX() {
	# check Java
	if [ -x /usr/bin/java ]; then
		echo "=OK - Found Java (/usr/bin/java)"
	else
		echo "=ALERT - Expecting Java (/usr/bin/java) installed for FOP"
	fi
	# check HotJVM config for FOP
	if [ -f /etc/fop.conf ]; then
		# check maximum heap (-Xmx) < initial heap size (-Xms)
		. /etc/fop.conf
		# defaults from http://pic.dhe.ibm.com/infocenter/wasinfo/v6r0/index.jsp?topic=%2Fcom.ibm.websphere.express.doc%2Finfo%2Fexp%2Fae%2Ftprf_tunejvm.html
		maxheap=$((512*1024*1024))
		initialheap=$((256*1024*1024))
		younggen=2228224
		# pick up the actual config
		for opt in $JAVA_OPTS; do
			if echo $opt | grep -q '^-Xmx'; then
				maxheap=`echo $opt | sed 's/^-Xmx//'`
				maxheap=`expandunit "$maxheap"`
			elif echo $opt | grep -q '^-Xms'; then
				initialheap=`echo $opt | sed 's/^-Xms//'`
				initialheap=`expandunit "$initialheap"`
			elif echo $opt | grep -q '^-Xmn'; then
				younggen=`echo $opt | sed 's/^-Xmn//'`
				younggen=`expandunit "$younggen"`
			fi
		done
		# check settings
		errorfound=0
		if [ $initialheap -ge $maxheap ]; then
			echo "=ALERT - Java memory settings -Xmx >= -Xms in /etc/fop.conf which will not work"
			errorfound=1
		fi
		if [ $younggen -gt $(($maxheap/3)) ]; then
			echo "=ALERT - Java memory settings -Xmn >= (-Xmx / 3) in /etc/fop.conf which is bad practice (recomended approx -Xmx / 4)"
			errorfound=1
		fi
		if [ $errorfound -eq 0 ]; then
			echo "=OK - Found HotJVM config for FOP (/etc/fop.conf) and seems sane"
		fi
	else
		echo "=ALERT - Expecting HotJVM config for FOP (/etc/fop.conf)"
	fi
}

# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - FOP+HotJVM requiements"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit print,preview $FUNCTIONS
# would have bailed above if no match
osspecific check

