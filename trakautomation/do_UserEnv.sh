#!/bin/sh -e
# add login and non-login shell code to:
#	- Generate user-friendly messages and aliases
#	- Prevent inappropriate users launching Cache Terminal
# TODO work in progress
# Glen Pitt-Pladdy (ISC)
. ./functions.sh




check_LINUX() {
	# count the config we have
	someconfig=0
	# check user exists
	if ! grep -q ^$CACHEUSR: /etc/passwd; then
		return 2
	fi
	# check for profile config
	profilefile=
	if [ -d /etc/profile.d/ ]; then
		profilefile=/etc/profile.d/isc-trakenv.sh
	fi
	for file in /etc/profile.d/isc-trakenv.sh /etc/profile; do
		if [ -f $file ]; then
			if [ -z "$profilefile" ]; then
				profilefile=$file
			fi
			if grep -q '# Added by ISC TrakCare Automation' $file; then
				someconfig=$(($someconfig+1))
			fi
		fi
	done
	# check for bashrc config
	bashrcfile=
	for file in /etc/bash.bashrc /etc/bashrc; do
		if [ -f $file ]; then
			if [ -z "$bashrcfile" ]; then
				bashrcfile=$file
			fi
			if grep -q '# Added by ISC TrakCare Automation' $file; then
				someconfig=$(($someconfig+1))
			fi
		fi
	done
	# figure out the situation
	if [ -z "$profilefile" -o -z "$bashrcfile" ]; then
		# can't work out files to use
		return 3
	elif [ $someconfig -eq 0 ]; then
		# no config
		return 4
	elif [ $someconfig -ne 2 ]; then
		# we have a problem - partial config
		return 1
	fi
	# complete config
	return 0
}

setup_LINUX() {
	# profile
	cat >>$profilefile <<EOFPROFILE

##########################################################################
# Added by ISC TrakCare Automation

# This should be included in login shells to set ISC TrakCare security related parameters


# ----- Keep All text below this to fit neatly on standard terminals -----|
setcache() {
	cat <<EOFCACHE
You have access to files used by Cache as well as being able to use Cache 
Terminal. With this comes a level of responisbility and assumptions of 
basic Unix skills. For your convenience the following aliases have been set:

EOFCACHE
	for instance in \`ccontrol qlist | cut -d^ -f1\`; do
		case \$instance in
			*LABDB)
				if type -a cachelabdb >/dev/null 2>&1; then continue; fi
				echo "    cachelabdb - TrakCare Lab Database(\$instance)"
				alias cachelabdb="csession \$instance"
			;;
			*DB)
				if type -a cachetrakdb >/dev/null 2>&1; then continue; fi
				echo "    cachetrakdb - TrakCare Database (\$instance)"
				alias cachetrakdb="csession \$instance"
			;;
			*INTEGRATION)
				if type -a cacheintegration >/dev/null 2>&1; then continue; fi
				echo "    cacheintegration - Integration (\$instance)"
				alias cacheintegration="csession \$instance"
			;;
			*ANALYTICS)
				if type -a cacheanalytics >/dev/null 2>&1; then continue; fi
				echo "    cacheanalytics - TrakCare Analytics (\$instance)"
				alias cacheanalytics="csession \$instance"
			;;
			*APP*)
				if type -a cachetrakapp >/dev/null 2>&1; then continue; fi
				echo "    cachetrakapp - TrakCare Appserver (\$instance)"
				alias cachetrakapp="csession \$instance"
			;;
			*PRT*)
				if type -a cacheprt >/dev/null 2>&1; then continue; fi
				echo "    cacheprt - TrakCare Print/EPS Server (\$instance)"
				alias cacheprt="csession \$instance"
			;;
		esac
	done
	echo
}


# ----- Keep All text below this to fit neatly on standard terminals -----|
setcachesudo() {
	cat <<EOFCACHESUDO
You have access to sudo to "cacheusr". With this comes a level of 
responisbility and assumptions of basic Unix skills. For your convenience 
the following alias has been set:

    sudocacheusr

EOFCACHESUDO
	alias sudocacheusr='sudo -u cacheusr -i'
}



##########################################################################
#                      Setup according to groups
##########################################################################
if [ \`whoami\` != '$CACHEBACKUP' ]; then
	echo
	for mygroup in \`groups\`; do
		case \$mygroup in
			$CACHEGRP)
				# flag that we are in this group
				export incachegrp=1
				# set a safe umask
				umask 0007
				# print cachegrp messages
				setcache
			;;
			wheel)
				# TODO do we need to actually say anything - these users should be smart eough!
			;;
			$TRAKCACHE)
				# can sudo -u cacheusr
				setcachesudo
			;;
			$TRAKPRINT)
			;;
		esac
	done
	# set lock alias
	if [ -z "\$incachegrp" ]; then
#		alias cache='echo "Cache Terminal should not be run as a non-login shell or any not designated users" >&2; echo >/dev/null'
		alias cache='echo "_Cache Terminal should not be run as a non-login shell or any not designated users" >&2'
		alias csession='echo "_Cache Terminal should not be run as a non-login shell or any not designated users" >&2'
	fi
fi


# End of added by ISC TrakCare Automatio
##########################################################################

EOFPROFILE
	# bashrc
	cat >>$bashrcfile <<EOFBASHRC

##########################################################################
# Added by ISC TrakCare Automation

# This should be included in non-login shells to set ISC TrakCare security related parameters

##########################################################################
#                      Setup according to groups
##########################################################################
if [ \`whoami\` != '$CACHEBACKUP' ]; then
	for mygroup in \`groups\`; do
		case \$mygroup in
			$CACHEGRP)
				# set a safe umask
				umask 0007
			;;
			wheel)
			;;
			$TRAKCACHE)
			;;
			$TRAKPRINT)
			;;
		esac
	done
	# set lock alias on all non-login
	if [ -z "\$incachegrp" ]; then
		alias cache='echo "Cache Terminal should not be run as a non-login shell or any not designated users" >&2'
		alias csession='echo "Cache Terminal should not be run as a non-login shell or any not designated users" >&2'
	fi
fi
# prevent non-login sub-shells using Cache Terminal
unset incachegrp

# End of added by ISC TrakCare Automatio
##########################################################################

EOFBASHRC
	# sudoers - for this we use a "helper" which acts as the editor for "visudo"
	#export VISUAL=`dirname $0`/helper_UserEnv_sudoers.sh
	#export EDITOR=$VISUAL
	#visudo
	echo "# ISC TrakCare: sudo -u cacheusr" > /etc/sudoers.d/trakcare
	echo "%trakcache ALL=(cacheusr) ALL" >> /etc/sudoers.d/trakcare
}






echo "########################################"
set +e
osspecific check
ret=$?
set -e
case $ret in
	0)
		echo "TrakCare Shell Environment Configuration exists" >&2
		exit 0
	;;
	1)
		echo "FATAL - Partial TrakCare Shell Environment Configuration exists" >&2
		exit 1
	;;
	2)
		echo "TrakCare Shell Environment requires users $CACHEUSR & $CACHEBACKUP to exist first" >&2
		exit 1
	;;
	3)
		echo "TrakCare Shell Environment can't determine config files" >&2
		exit 1
	;;
	4)
		# no config - create it
		echo "TrakCare Shell Environment Configuration"
		osspecific setup
		exit 0
	;;
	*)
		echo "TrakCare Shell Environment Check returned unexpected value $ret" >&2
		exit 1
	;;
esac


