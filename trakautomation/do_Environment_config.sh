#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh
# TODO automate tuning of Ensemble/HSF
# TODO check GMHeap, Locksiz


echo "########################################"
if [ $# -ne 7 ]; then
	echo "Usage: $0 <Site Code> <Environment> <Type>[Version] <routine buffers in MiB> <global buffers in MiB> <lock table size in B> <gmheap in kiB" >&2
	exit 1
fi
# check args TODO check functions.sh cacheconfig()
SITE=$1
ENV=$2
TYPE=`echo $3 | sed 's/2[0-9]\{3\}$//'`
VER=`echo $3 | sed 's/^.*\(2[0-9]\{3\}\)$/\1/'`
[ $3 == $VER ] && VER=''
INST=`instname $SITE $ENV $TYPE$VER`
TRAKPATH=`trakpath $SITE $ENV $TYPE$VER`

ROUTINEBUFFER_MB=$4
GLOBALBUFER_MB=$5
LOCKTABLE_B=$6
GMHEAP_KB=$7

echo "Configuring Environment $INST"

# sanitise lock table size
lockblocked=$((($LOCKTABLE_B/65536)*65536))
if [ $LOCKTABLE_B -ne $lockblocked ]; then
	echo "FATAL - Illegal locksiz detected of \"LOCKTABLE_B\": must be a multiple of 64KiB (65536B)" >&2
	exit 1
fi

#for subdir in cache ensemble hs hsf hsap; do
#	if [ -f $TRAKPATH/$subdir/cache.cpf ]; then
#		cachedir=$TRAKPATH/$subdir
#		config=$#cachedir/cache.cpf
#		break
#	fi
#done
#if [ -z "$config" ]; then
#	echo "FATAL - can't find .cpf for path \"$TRAKPATH\"" >&2
#	exit 1
#fi
## now find the environment name from ccontrol qlist
#for inst in `ccontrol qlist | sed 's/^\([^\^]\+\^[^\^]\+\)\^.*$/\1/'`; do
#	if [ `echo $inst | cut -d^ -f2` = $cachedir ]; then
#		INST=`echo $inst | cut -d^ -f1`
#		break
#	fi
#done
#if [ -z "$INST" ]; then
#	echo "FATAL - can't find instance with path \"$TRAKPATH\"" >&2
#	exit 1
#fi
#config=`cache_instance2path.pl "$INST"`/cache.cpf
config=$(ccontrol qlist | grep "$INST"|cut -d"^" -f2)/cache.cpf
if [[ ! -f "$config" ]]; then
	echo "FATAL - Cache config file not found"
fi

echo "Environment Configuration for $SITE : $ENV ($INST)"
# sanity check
if [ -z "$config" -o ! -f "$config" ]; then
	echo "FATAL - Expecting file \"$config\" to exist" >&2
	exit 1
fi
if [ ! -f ${config}.original ]; then
	cp -a ${config} ${config}.original
	args=''
	# set routine buffers
	if [ $ROUTINEBUFFER_MB -gt 0 ]; then args="$args [config]routines=$ROUTINEBUFFER_MB"; fi
	# set global 8k buffers
	if [ $GLOBALBUFER_MB -gt 0 ]; then args="$args [config]globals=0,0,$GLOBALBUFER_MB,0,0,0"; fi
	# set locksiz
	if [ $LOCKTABLE_B -gt 0 ]; then args="$args [config]locksiz=$LOCKTABLE_B"; fi
	# set gmheap
	if [ $GMHEAP_KB -gt 0 ]; then args="$args [config]gmheap=$GMHEAP_KB"; fi
	# set the journals - if available
	for dir in jrn/pri/ jrn/ db/jrn/pri/ db/jrn/ hsap/jrn/pri hsap/jrn/pri hsf/jrn/pri ensemble/jrn/pri cache/jrn/pri hs/jrn hsap/jrn hsf/jrn ensemble/jrn cache/jrn; do
		if [ -d $TRAKPATH/$dir ]; then
			echo Pri Journal $TRAKPATH/$dir
			args="$args [Journal]CurrentDirectory=$TRAKPATH/$dir"
			break
		fi
	done
	for dir in jrn/alt/ db/jrn/alt/ hs/jrn/alt hsap/jrn/alt hsf/jrn/alt ensemble/jrn/alt cache/jrn/alt; do
		if [ -d $TRAKPATH/$dir ]; then
			echo Alt Journal $TRAKPATH/$dir
			args="$args [Journal]AlternateDirectory=$TRAKPATH/$dir"
			break
		fi
	done
	# set the WIJ if available
	for dir in wij/ hs/wij/ hsap/wij/ hsf/wij/ ensemble/wij/ cache/wij/; do
		if [ -d $TRAKPATH/$dir ]; then
			echo WIJ $TRAKPATH/$dir
			args="$args [config]wijdir=$TRAKPATH/$dir"
			break
		fi
	done
	# set Journal Freeze on Error
	args="$args [Journal]FreezeOnError=1"
	# apply this
	ini_update.pl ${config} $args
	# restart this hsf
	ccontrol stop $INST restart nouser
else
	echo "Already configured... skipping"
fi


