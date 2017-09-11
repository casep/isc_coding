#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
#  zClassDeployer.sh
#  
#  Copyright 2016 Carlos "casep" Sepulveda <casep@fedoraproject.org>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  


### Deploy XML classes to the instance/NS to automate task for puppet

# set exist codes - some backup systems require non-standard ones
EXITFAILURE=1
EXITSUCCESS=0

# what user to use for call-ins - if unset this will not "su"
CACHEUSER=cacheusr

# the timestamp we use
TIMESTAMP=`date +%Y%m%d-%H%M%S`


usage() {
	echo "Usage: $0 <Instance|_ALL> <Namespace> <FileToUpload>" >&2
	exit $EXITFAILURE
}

#$INSTANCE $NAMESPACE $CLASS $FLAGS
execute() {
	local instance=`ccontrol qlist | cut -d^ -f1 | grep -i $1`
	if [ -z "$instance" ]; then
		badinstance=1
		deployerror=1
		echo "ERROR - Instance \"$1\" not found" >&2
		return 1
	fi
	status=`ccontrol qlist | grep -i ^$1^ | cut -d^ -f4 | cut -d, -f1`
	if [ -z "$status" -o "$status" != "running" ]; then
		deployerror=1
		echo "ERROR - Instance \"$1\" not running (status: $status)" >&2
		return 1
	fi
	cachedir=`ccontrol qlist | grep -i ^$1^ | cut -d^ -f2`
	tmpdir=$cachedir/mgr/Temp
	if [ ! -d $tmpdir ]; then
		deployerror=1
		echo "ERROR - Instance \"$1\" can't find Temp directory ($tempdir)" >&2
		return 1
	fi
	statusfile=$tmpdir/zClassDeployer-$TIMESTAMP-$$-$1_Status.txt
	if [ -f $statusfile ]; then
		deployerror=1
		echo "ERROR - Instance \"$1\" already has Status file ($statusfile)" >&2
		return 1
	fi	
	if [ -z "$CACHEUSER" ]; then
		csession $instance -U'%SYS' "##class(%SYSTEM.OBJ).Load(\"$CLASS\",\"$FLAGS\")" > $statusfile
		ret=$?
	else
		su - $CACHEUSER -c "csession $instance -U'$NAMESPACE' '##class(%SYSTEM.OBJ).Load(\"$CLASS\",\"$FLAGS\")'" > $statusfile
		ret=$?
	fi
	echo "call complete (returns $ret) for $instance"
	#For verbosity on the log
	cat $statusfile
	# check how we did
	if [ $ret -ne 0 ]; then
		deployerror=1
		echo "ERROR - Instance \"$1\" call-in returned $ret" >&2
		return $ret
	#file doesn't exists Cache return 0
	else
		ret=$(grep "ERROR #5012" $statusfile | wc -l)
		if [ $ret -ne 0 ]; then
			deployerror=1
			echo "ERROR - Instance \"$1\" call-in returned $ret" >&2
			return $ret
		fi	
	fi
	
	rm -f $statusfile
	echo

	# we got success (possibly with a warning)
	return 0
}	
	
#############################################################################
#                            main
#############################################################################


# check arguments
if [ $# -lt 3 ]; then
	usage
fi

INSTANCE=$1
NAMESPACE=$2
CLASS=$3
FLAGS="fck"

badinstance=0
deployerror=0
if [ "$INSTANCE" = '_ALL' ]; then
	for instance in `ccontrol qlist | cut -d^ -f1`; do
		echo "** $instance $NAMESPACE $CLASS $FLAGS **"
		set +e
		execute $instance $NAMESPACE $CLASS $FLAGS "$@"
		set -e
	done
else
	echo "** $@ **"
	execute $INSTANCE $NAMESPACE $CLASS $FLAGS "$@"
fi

# sort the overall status
echo
if [ $deployerror -eq 0 ]; then
	echo "* Deploy Completed"
	exit $EXITSUCCESS
else
	echo "* Deploy Completed with ERRORS - see above"
	exit $EXITFAILURE
fi
