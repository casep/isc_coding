# CHANGELOG: Added Ability to use TST as environment type - TMcA 20170103
# General useful functions common to all tools
# Glen Pitt-Pladdy (ISC)
# define the stanard users (if not already defined)
if [ -z "$CACHEUSR" ]; then export CACHEUSR=cacheusr; fi
if [ -z "$CACHEBACKUP" ]; then export CACHEBACKUP=cachebackup; fi
if [ -z "$TRAKSMB" ]; then export TRAKSMB=traksmb; fi
# define the stanard groups(if not already defined)
if [ -z "$CACHEGRP" ]; then export CACHEGRP=cachegrp; fi
if [ -z "$CACHEMGR" ]; then export CACHEMGR=cachemgr; fi
if [ -z "$TRAKCACHE" ]; then export TRAKCACHE=trakcache; fi
if [ -z "$TRAKPRINT" ]; then export TRAKPRINT=trakprint; fi
# be safe - check we have not disabled key Cache stuff
if [ "$CACHEUSR" = '!' -o "$CACHEGRP" = '!' -o "$CACHEMGR" = '!' ]; then
	echo "FATAL - can't have core Caché users/groups disabled" >&2
	exit 1
fi
# define region (if not already defined)
if [ -z "$REGION" ]; then export REGION=UK; fi


# include functions/ in path if needed
if ! which ini_getparam.pl >/dev/null 2>&1; then
	export PATH=$PATH:`pwd`/functions
fi

# set the tools directory
if [ -z "$TRAKAUTOMATIONDIR" -a -f functions.sh ]; then
	# not set, and we are in the right place
	export TRAKAUTOMATIONDIR=`pwd`
fi
if [ ! -f "$TRAKAUTOMATIONDIR/functions.sh" ]; then
	echo "$0: FATAL - \"\$TRAKAUTOMATIONDIR\" doesn't contain a valid path" >&2
	exit 1
fi

# set legacy warnings TODO
#export LEGACYWARNING=1



# validate the environment variables needed common to all
checkvars() {
	if [ -z "$SITE" ]; then
		echo "checkvars() - \$SITE is not set"
		return 1
	elif [ -z "$ENV" ]; then
		echo "checkvars() - \$ENV is not set"
		return 1
	elif [ -z "$VER" ]; then
		echo "checkvars() - \$VER is not set"
		return 1
	fi
	export SITE_LC=`echo $SITE | tr '[A-Z]' '[a-z]'`
	export SITE_UC=`echo $SITE | tr '[a-z]' '[A-Z]'`
	if [ $SITE != $SITE_LC ]; then
		echo "checkvars() - \$SITE must be lower case (eg. scxx)"
		return 1
	fi
	export ENV_LC=`echo $ENV | tr '[A-Z]' '[a-z]'`
	export ENV_UC=`echo $ENV | tr '[a-z]' '[A-Z]'`
	if [ $ENV != $ENV_UC ]; then
		echo "checkvars() - \$ENV must be upper case (eg. BASE)"
		return 1
	fi
	if echo $VER | grep -v '^[0-9]\{4\}$'; then
		echo "checkvars() - \$VER must be 4 digits (eg. 2014)"
		return 1
	fi
	# check ENV against a known good list
	case $ENV in
		DR|REP|UAT|PRD|TEST|TST|BASE|SCRATCH|TRAIN*|DTO*|EDITION|DEMO|CONFIG)
		;;
		*)
			if [ -n "$EXTRAENVS" ] || ! listunion $EXTRAENVS $ENV; then
				echo "checkvars() - \$ENV=$ENV does not match one of the expected list: $ENVIRONMENTS"
				return 1
			fi
		;;
	esac

}


# calculate network address from ip/prefix
ip2netaddr() {
	addr=`echo $1|cut -d/ -f1`
	oct4=`echo $addr|cut -d. -f1`
	oct3=`echo $addr|cut -d. -f2`
	oct2=`echo $addr|cut -d. -f3`
	oct1=`echo $addr|cut -d. -f4`
	prefix=`echo $1|cut -d/ -f2`
	bits=$((32-$prefix))
	i=1
	while [ $bits -ge 8 ]; do
		case $i in
			1) oct1=0 ;;
			2) oct2=0 ;;
			3) oct3=0 ;;
			4) oct4=0 ;;
		esac
		bits=$(($bits-8))
		i=$(($i+1))
	done
	case $i in
		1) oct=$oct1 ;;
		2) oct=$oct2 ;;
		3) oct=$oct3 ;;
		4) oct=$oct4 ;;
	esac
	j=$bits
	while [ $j -gt 0 ]; do
		oct=$(($oct/2))
		j=$(($j-1))
	done
	j=$bits
	while [ $j -gt 0 ]; do
		oct=$(($oct*2))
		j=$(($j-1))
	done
	case $i in
		1) oct1=$oct ;;
		2) oct2=$oct ;;
		3) oct3=$oct ;;
		4) oct4=$oct ;;
	esac
	echo $oct4.$oct3.$oct2.$oct1/$prefix
}


# escape a path for regexp use
path2regexp() {
	echo $1 | sed 's/\//\\\//g'
}


# work out standard environment naming
# 3 args:
#	SITE (lower case)
#	ENVIRONMENT (upper case: prd, dr, test, base, train\d*, dto\d+)
#	TYPE[Version] (APP\d+, PRT\d+, DB, ANALYTICS, INTEGRATION, INTEGRITY\d*, SHADOW???, REPORTING, CSP, LABDB)
instname() {
	ORGUC=`echo $1 | tr '[:lower:]' '[:upper:]'`
	ENVCLEAN=`echo $2 | sed 's/\/.*$//'`
	TYPE=`echo $3 | sed 's/2[0-9]\{3\}$//'`
	ENVYEAR=`echo $3 | sed 's/^.*\(2[0-9]\{3\}\)$/\1/'`
	[ $3 == $ENVYEAR ] && ENVYEAR=''
# TODO this is now covered in checkvars
	ENVIRONMENTS='DR|REP|UAT|TEST|TST|BASE|SCRATCH|TRAIN*|DTO*|EDITION|DEMO|CONFIG'
	if [ -n "$EXTRAENVS" ]; then
		ENVIRONMENTS="$ENVIRONMENTS|"`echo $EXTRAENVS | sed 's/,/|/g'`
	fi
	# check type
	case $TYPE in
		DB|APP*|PRT*|ANALYTICS|INTEGRATION|INTEGRITY*|SHADOW|REPORTING|CSP|LABDB)
		;;
		*)
			echo "FATAL - don't know about type \"$TYPE\" in functions.sh instancename()" >&2
			exit 1
		;;
	esac
	# check Environment
	case $ENVCLEAN in
		PRD)
			echo $ORGUC$ENVYEAR$TYPE
			return 0
		;;
		DR|RR|UAT|TEST|TST|BASE|SCRATCH|TRAIN*|DTO*|EDITION|DEMO|CONFIG)
			echo $ORGUC$ENVCLEAN$ENVYEAR$TYPE
			return 0
		;;
		*)
			if [ -n "$EXTRAENVS" ] && listunion $EXTRAENVS $ENVCLEAN; then
				echo $ORGUC$ENVCLEAN$ENVYEAR$TYPE
				return 0
			else
				echo "FATAL - don't know about Environment \"$ENVCLEAN\" in functions.sh instancename()" >&2
				exit 1
			fi
		;;
	esac
}

# calculate the UK Standard TrakCare Namespace from SITE and Environment
# Args: 
#	SITE (lower case)
#	ENVIRONMENT
traknamespace() {
	ORGUC=`echo $1 | tr '[:lower:]' '[:upper:]'`
	ENVCLEAN=`echo $2 | sed 's/\/.*$//'`
	# TODO cleaning year from NS should no longer be needed 
	ENVCLEAN=`echo $ENVCLEAN | sed 's/[0-9]*$//'`
	echo $ORGUC-$ENVCLEAN
}


# Scotland - maintain this for consistency between PMS Boards
trakpath_SC() {
	export SUBDIR=`echo $TYPE | tr '[A-Z]' '[a-z]'`
	case $TYPE in
		DB)	# TrakCare Database
			SUBDIR=''
		;;
		APP*)	# TrakCare App Server - using (above) matching path
		;;
		PRT*)	# TrakCare Print (EPS) Server
			SUBDIR=`echo $TYPE | sed 's/^PRT/PRINT/' | tr '[A-Z]' '[a-z]'`
		;;
		CSP)	# Generic CSP instance - no actual install
			SUBDIR=''
		;;
		ANALYTICS)	# TrakCare Analytics Server - using (above) matching path
		;;
		INTEGRATION)	# TrakCare Integration - using (above) matching path
		;;
		INTEGRITY*)	# TrakCare Integrity Check - using (above) matching path
		;;
		REPORTING)	# TrakCare Reporting Server - using (above) matching path
		;;
		SHADOW)	# TrakCare Generic Shadow Server - using (above) matching path
		;;
		LABDB)	# TrakCare Lab Server
			SUBDIR='lab'
		;;
		SC)	# TrakCare SimpleCode Server - using (above) matching path
		;;
		*)
			echo "$0: ERROR - unknown environment type \"$TYPE\"" >&2
			return 1
		;;
	esac
	# check for forced subdirs
	if echo $ENV | grep -q /; then
		SUBDIR=`echo $ENV | cut -d/ -f2-`
		echo "$0: NOTE - instance directory forced to \"$SUBDIR\""
		ENV=`echo $ENV | cut -d/ -f1`
	fi
	# done - output the path
	if [ -n "$SUBDIR" ]; then
		#echo /trak/$SITE/$ENV$VER/$SUBDIR
		echo /trak/$SITE/$ENV/$SUBDIR
	else
		#echo /trak/$SITE/$ENV$VER
		echo /trak/$SITE/$ENV
	fi
	return 0
}

# calculate the UK Standard TrakCare environment paths
# Args: 
#	SITE (lower case)
#	ENVIRONMENT[/forcsubdir]
#	TYPE[Version]
trakpath() {
	SITE=$1
	ENV=$2
	TYPE=`echo $3 | sed 's/2[0-9]\{3\}$//'`
	VER=`echo $3 | sed 's/^.*\(2[0-9]\{3\}\)$/\1/'`
	[ $3 == $VER ] && VER=''
	export REGION=`echo $SITE | tr '[a-z]' '[A-Z]' | sed 's/^\(..\).*$/\1/'`
	# look for any region specific versions - SER Commented out for SCFI
	#if type trakpath_$REGION >/dev/null 2>&1; then
	#	trakpath_$REGION "$@"
	#	return $?
	#fi
	# no region specific version so use generic UK Standard
	export SUBDIR="tc$VER`echo $TYPE | tr '[A-Z]' '[a-z]'`"
	case $TYPE in
		DB)
			# TrakCare Database
			SUBDIR="tc$VER"
			SUBDIR="tc"
		;;
		APP*)
			# TrakCare App Server - using (above) matching path
		;;
		PRT*)
			# TrakCare Print (EPS) Server
			#SUBDIR="tc$VER"`echo $TYPE | sed 's/^PRT/PRINT/' | tr '[A-Z]' '[a-z]'`
			SUBDIR="tc"`echo $TYPE | sed 's/^PRT/PRINT/' | tr '[A-Z]' '[a-z]'`
		;;
		CSP)
			# Generic CSP instance - no actual install
		;;
		ANALYTICS)
			# TrakCare Analytics Server - using (above) matching path
		;;
		INTEGRATION)
			# TrakCare Integration
			#SUBDIR="integration$VER"
			#SUBDIR="int"
		;;
		INTEGRITY*)
			# TrakCare Integrity Check - these are generic, we only care about the version
			if echo $TYPE | grep -q '[0-9]$'; then
				# numbered
				#SUBDIR="`echo $TYPE | tr '[A-Z]' '[a-z]'`-$VER"
				SUBDIR="`echo $TYPE | tr '[A-Z]' '[a-z]'`"
			else
				#SUBDIR="`echo $TYPE | tr '[A-Z]' '[a-z]'`$VER"
				SUBDIR="`echo $TYPE | tr '[A-Z]' '[a-z]'`"
			fi
		;;
		REPORTING)
			# TrakCare Reporting Server - using (above) matching path
		;;
		SHADOW)
			# TrakCare Generic Shadow Server - using (above) matching path
		;;
		LABDB)
			# TrakCare Lab Server
			#SUBDIR="lab$VER"
			SUBDIR="lab"
		;;
		SC)
			# TrakCare SimpleCode Server
			#SUBDIR="sc$VER"
			SUBDIR="sc"
		;;
		*)
			echo "$0: ERROR - unknown environment type \"$TYPE\"" >&2
			return 1
		;;
	esac
	# check for forced subdirs
	if echo $ENV | grep -q /; then
		SUBDIR=`echo $ENV | cut -d/ -f2-`
		echo "$0: NOTE - instance directory forced to \"$SUBDIR\""
		ENV=`echo $ENV | cut -d/ -f1`
	fi
	# done - output the path
	if [ -n "$TRAKROOT" ]; then
		# overridden
		echo "$TRAKROOT"
	elif [ -n "$SUBDIR" ]; then
		echo /trak/$SITE$ENV/$SUBDIR
	else
		echo /trak/$SITE$ENV
	fi
	return 0
}


# run OS specific function / callback
# This tries a version specific version first with "_" separators (eg. <Command>_RHEL_6_3 or <Command>_SLES_11_2)
# Then it trims off each version (_<Number>) part until it can go no further (eg. <Command>_RHEL)
# Failing that it falls back to generic OS type (eg. <Command>_LINUX or <Command>_UNIX)
# And then goes to totally generic (eg. <Command>_Unix)
# If that still doesn't work it coughs up blood and dies
osspecific() {
	eval `Platform2ENV.pl`
	COMMAND=$1
	shift 1
	# run the list
	firstcommand=''
	lastcommand=''
	for oscommand in $PLATFORM_OStry; do
		if [ -z "$firstcommand" ]; then firstcommand=${COMMAND}_$oscommand; fi
		lastcommand=${COMMAND}_$oscommand
		if type ${COMMAND}_$oscommand >/dev/null 2>&1; then
			${COMMAND}_$oscommand "$@"
			return $?
		fi
	done
	echo "$0: FATAL - can't find version specific function \"$firstcommand\" or any less specific functions down to \"$lastcommand\"" >&2
	return 1
}


# install dependencies if needed
installdepends_SLES() {
	zypper install --no-confirm "$1"
}
installdepends_RHEL() {
	yum install -y "$1"
}
# $0 <executable to check> <package to install>
installdepends() {
	[ -x "$1" ] && return 0
	osspecific installdepends "$2"
}


# check for overlab in two comma separated lists (union)
listunion() {
	for arg1 in `echo $1 | sed 's/,/ /g'`; do
		for arg2 in `echo $2 | sed 's/,/ /g'`; do
			if [ $arg1 = $arg2 ]; then return 0; fi
		done
	done
	return 1
}

# based on this quit with a not active message
checkfieldquit() {
	if ! listunion $1 $2; then
		echo "=SKIP - would be active for Stage(s)/function(s) \"$1\""
		exit 0
	fi
}


# output a section between patterns
#getsection() {
#	# first arg is file path, second and third are limiting regex
#	# try a search stopping at a blank line, if not found just show the full output
#	if [ "$LEGACYWARNING" = 1 ]; then echo "WARNING - using lecacy $0 instead of ini_getsection.pl" >&2; fi
#	# redirect this to the new perl helper
#	ini_getsection.pl "$@"
#	
#}

# get a specific config parameter from a Caché / CSP config
#getconfigparam() {
#	# first arg config file
#	# second arg section
#	# third arg parameter (label left of =)
#	 if [ "$LEGACYWARNING" = 1 ]; then echo "WARNING - using legacy $0 instead of ini_getparam.pl" >&2; fi
#	# redirect this to the new Perl helper
#	ini_getparam.pl "$@"
#}


# generic usage check for preflight check scripts
preflightargs() {
	# expects site, env, project stage, functions - call with: preflightargs $@
	if [ $# -ne 5 ]; then
		preflightusage
		exit 1
	fi
	# check we have a trakcare dir
	if [ $4 != 'OSSkeleton' ]; then
		if listunion $5 database,web && [ ! -d `trakpath $1 $2 DB$3` ]; then
			echo "Expect at least `trakpath $1 $2 DB$3` directory to exist" >&2
			preflightusage
			exit 1
		elif listunion $5 print && [ ! -d `trakpath $1 $2 DB$3` -a ! -d `trakpath $1 $2 PRT$3`* ]; then
			echo "Expect at least `trakpath $1 $2 PRT$3`* directory to exist" >&2
			preflightusage
			exit 1
		elif listunion $5 app && [ ! -d `trakpath $1 $2 APP$3`* ]; then
			echo "Expect at least `trakpath $1 $2 APP$3`* directory to exist" >&2
			preflightusage
			exit 1
		elif listunion $5 analytics && [ ! -d `trakpath $1 $2 ANALYTICS$3` ]; then
			echo "Expect at least `trakpath $1 $2ANALYTICS$3` directory to exist" >&2
			preflightusage
			exit 1
		fi
	fi
	# check stage is valid
	if [ $4 != 'OSSkeleton' -a $4 != 'OSHandover' -a $4 != 'CacheBuild' -a $4 != 'TrakUpgrade' -a $4 != 'TrakBuild' -a $4 != 'GoLive' ]; then
		echo "Invalid <stage> of \"$4\"" >&2
		preflightusage
		exit 1
	fi
	# check functions are valid
	for function in `echo $5 | sed 's/,/ /g'`; do
		if [ $function != 'database' -a $function != 'web' -a $function != 'print' -a $function != 'preview' -a $function != 'app' -a $function != 'analytics' ]; then
			echo "Invalid <function> of \"$function\"" >&2
			preflightusage
			exit 1
		fi
	done
	# setup
	export SITE=$1
	export ENV=$2
	export VER=$3
	export STAGE=$4
	export FUNCTIONS=$5
}
preflightusage() {
	echo "Usage: $0 <site> <env> <Version> <stage> <functions>" >&2
	echo "    <stage> is one of:" >&2
	echo "        OSSkeleton (no Trak Directories/Mountpoints)" >&2
	echo "        OSHandover (basic OS with Trak Directories/Mountpoints ready to build on)" >&2
	echo "        CacheBuild (basic OS & Caché build done)" >&2
	echo "        TrakUpgrade (basic OS, Caché build, Previous Trak data)" >&2
	echo "        TrakBuild (basic OS, Caché build, Trak build done)" >&2
	echo "        GoLive (complete, ready to roll)" >&2
	echo "    <functions> is a comma separated list of:" >&2
	echo "        database - TrakCare Database" >&2
	echo "        web - Web Serving (single-tier,Web Server,App Server)" >&2
	echo "        print - Paper Printing with EPS" >&2
	echo "        preview - TrakCare Report Preview serving" >&2
	echo "        app - Application Server" >&2
	echo "        analytics - TrakCare Analytics Server" >&2
}


# Universal parametraised mapping check
# This assumes Preflight Check environment variables setup
# Usage: $0 <Required Mapping eg. Global_ERRORS> <Requied Database eg. SYSCONFIG (Namespace will be prepended)>
checkmapping_Unix() {
	reqmapping=$1
	reqdatabase=`echo $2 | sed 's/^\.//'`
	if [ $reqdatabase != $2 ]; then absolutedatabase='true'; fi
	# find the relevant cache.cpf in the standard path
	# itterate through all instances until we find a Trak one
	for instance in `cache_getinstances.pl`; do
		path=`cache_instance2path.pl "$instance"`
		conf="$path/cache.cpf"
		if [ ! -f "$conf" ]; then
			echo "=CRITICAL - can't find cache.cpf \"$conf\" for instance \"$instance\""
			continue
		fi
		if echo "$instance" | grep -q 'DB$'; then
			# main database
			namespace=`traknamespace $SITE $ENV`
		elif echo "$instance" | grep -q 'APP[0-9]*$'; then
			# App instance
			namespace=`traknamespace $SITE $ENV`
		elif echo "$instance" | grep -q 'PRT[0-9]*$'; then
			# Print instance
			namespace=EPS
		else
			continue;
		fi
		# check for the namespace
		nsconfig=`ini_getparam.pl $conf "Namespaces" "$namespace" 2>/dev/null`
		if [ -z "$nsconfig" ]; then
			echo "=ALERT - No Namespace \"$namespace\" in \"$conf\", not checking for mappings"
			continue
		fi
		# work out full database name
		if [ -z "$absolutedatabase" ]; then
			fulldatabase="$namespace-$reqdatabase"
		else
			fulldatabase=$reqdatabase
		fi
		if [ ! -f "$conf" ]; then
			echo "=CRITICAL - can't find cache.cpf in \"$conf\""
			return 0
		fi
		# get & check mapping
		set +e
		mapping=`ini_getparam.pl $conf "Map.$namespace" "$reqmapping" 2>/dev/null`
		set -e
		if [ -z "$mapping" ]; then
			echo "=ALERT - No mapping found for $reqmapping for Namespace \"$namespace\" in \"$conf\""
		elif [ "$mapping" = "$fulldatabase" ]; then
			echo "=OK - Found valid mapping for $reqmapping for Namespace \"$namespace\" in \"$conf\""
		else
			echo "=ALERT - Mapping for $reqmapping for Namespace \"$namespace\" in \"$conf\" should be to \"$fulldatabase\""
		fi
	done
}  



# create a directory if needed, report it exists if required
mkdirifneeded () {
	# first arg is the directory name
	# if second arg exists then will report if exists
	if [ ! -d $1 ]; then
		mkdir -p $1
	elif [ ! -z "$2" ]; then
		echo "NOTE - $0 not creating \"$1\" as it exists"
	fi
}


# password prompt
# arguments: <prompt> <variable> [flag not to confirm]
getpass() {
	local getpass
	local confirmpass
	stty -echo
	echo -n "$1: "
	read getpass
	echo
	if [ -z "$3" ]; then
		echo -n "Confirm: "
		read confirmpass
		echo
	fi
	stty echo
	if [ -z "$getpass" ]; then
		echo "FATAL - blank password" >&2
		return 1
	elif [ -z "$3" -a "$getpass" != "$confirmpass" ]; then
		echo "FATAL - passwords don't match" >&2
		return 1
	fi
	export $2="$getpass"
}


# locate a file pattern in a list of directories
# arguments: <Filepattern> <directory> [directory] ..... [directory]
locatefile() {
	local filepattern=$1
	shift 1
	local count=0
	local filepath=
	for dir in "$@"; do
		local found=`ls $dir/$filepattern 2>/dev/null | wc -l`
		count=$(($count+$found))
		if [ $found -eq 1 ]; then
			filepath=`ls $dir/$filepattern 2>/dev/null`
		fi
	done
	if [ $count -eq 0 ]; then
		echo "No files matching \"$filepattern\" in: $@" >&2
		return 1
	elif [ $count -gt 1 ]; then
		echo "Multiple files matching \"$filepattern\" in: $@" >&2
		return 2
	else
		readlink -f $filepath
		return 0
	fi
}

# locate file in standard locations
# arguments: <Filepattern>
locatefilestd() {
	locatefile $1 `pwd` /tmp ~ .. ../installers ../InstallKit ../Kit ../setup ../tools
}



expandunit() {
	if echo $1 | grep -q '[0-9]$'; then
		echo $1
	elif echo $1 | grep -qi 'k'; then
		echo $((`echo $1 | sed 's/ *[kK]$//'`*1024))
	elif echo $1 | grep -qi 'm'; then
		echo $((`echo $1 | sed 's/ *[mM]$//'`*1024*1024))
	elif echo $1 | grep -qi 'g'; then
		echo $((`echo $1 | sed 's/ *[gG]$//'`*1024*1024*1024))
	elif echo $1 | grep -qi 't'; then
		echo $((`echo $1 | sed 's/ *[tT]$//'`*1024*1024*1024*1024))
	fi
}


# TODO new (common) function to calculate required features for a Caché instance
# Takes args: $0 <code> <environment>[/subdir] <function>[version] [optional version string... ignored]
# sets variables:
cacheconfig() {
	# check args
	if [ -z "$1" -o -z "$2" -o $# -lt 3 -o $# -gt 4 ]; then
		echo "Usage: $0 <Site Code> <Environment> <Type>[Version] [optional version string - eg. 2013.1.1.501.1]" >&2
		return 1
	fi
	export SITE=$1
	export ENV=$2
	TYPE=`echo $3 | sed 's/2[0-9]\{3\}$//'`
	VER=`echo $3 | sed 's/^.*\(2[0-9]\{3\}\)$/\1/'`
	[ $3 == $VER ] && VER=''
	export VERSTR=$4
	# things we are going to work out
	export CSP=1
	export CSPONLY=0
	export INST=`instname $SITE $ENV $TYPE$VER`

	case $TYPE in
		DB)
		;;
		APP*)
		;;
		PRT*)
		;;
		CSP)
			CSPONLY=1
		;;
		ANALYTICS)
		;;
		INTEGRATION)
		;;
		INTEGRITY*)
			CSP=0
		;;
		REPORTING)
			CSP=0
		;;
		SHADOW)
			CSP=0
		;;
		LABDB)
			CSP=0
		;;
		SC)
			CSP=0
		;;
		*)
			echo "$0: ERROR - unknown environment type \"$3\"" >&2
			return 1
		;;
	esac
	if [ $CSP -eq 1 -a -f /opt/cspgateway/bin/CSP.ini ]; then
		echo "$0: NOTE - Skipping CSP as already installed - \"/opt/cspgateway/bin/CSP.ini\" exists"
		CSP=0
	fi
	if [ $CSP -eq 1 -a ! -f /usr/sbin/httpd2 -a ! -f /usr/sbin/httpd ]; then
		echo "$0: FATAL - can't install with CSP as Apache not found" 2>&1
		return 1
	fi
	# finalise path
	#export TRAKPATH=`trakpath $SITE $ENV $TYPE$VER`
	export TRAKPATH=`trakpath $SITE $ENV $TYPE`
}






# IMPORTNAT: This should always be last to ensure regional overrides work
if [ -f regionfunctions.sh ]; then . regionfunctions.sh; fi
