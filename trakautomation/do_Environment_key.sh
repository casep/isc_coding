#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


echo "########################################"
echo "Installing licenses..."
# check args
if [ -n "$1" -a -n "$2" -a -n "$3" ]; then
	# specified environment
	paths=`trakpath $1 $2 $3`
	if [ -d $paths/hs/mgr/ ]; then
		paths=hs/mgr
	elif [ -d $paths/hsap/mgr/ ]; then
		paths=hsap/mgr
	elif [ -d $paths/hsf/mgr/ ]; then
		paths=hsf/mgr
	elif [ -d $paths/ensemble/mgr/ ]; then
		paths=ensemble/mgr
	elif [ -d $paths/cache/mgr/ ]; then
		paths=cache/mgr
	else
		paths=
	fi
elif [ -n "$1" -o -n "$2" -o -n "$3" ]; then
	echo "Usage: $0 [<Site Code> <Environment> <Type[Version]>]" >&2
	exit 1
elif [ ! -x "`which ccontrol`" ]; then
	echo "FATAL - can't find \"ccontrol\" in the path" >&2
	exit 1
else
	# assume we do this automatically
	paths=
	for dir in `ccontrol qlist | cut -d^ -f2`; do
		if [ -d $dir/mgr/ ]; then
			paths="$paths $dir/mgr"
		fi
	done
fi

# find key
checked=''
for dir in `pwd` /tmp ~ ../installers ../InstallKit; do
	if [ -f $dir/licensekey.txt ]; then
		license=$dir/licensekey.txt
	elif [ -f $dir/cache.key ]; then
		license=$dir/cache.key
	fi
	checked="$checked $dir"
done
echo $license
if [ ! -f "$license" ]; then
	echo "FATAL - can't find a license key (licensekey.txt or cache.key) in any of: $checked" >&2
	exit 1
fi


timestamp=`date ++%Y%m%d-%H%M%S`

for path in $paths; do
	echo "Installing license for $path"
	if [ -f $path/cache.key-replaced-$timestamp ]; then
		echo "NOTE - backup of existing key \"$path/cache.key-replaced-$timestamp\" exists - skipping...."
		continue
	fi
	if [ -f $path/cache.key ]; then
		cp -an $path/cache.key $path/cache.key-replaced-$timestamp
	fi
	cp -a $license $path/cache.key
	# set sane ownership & permissions
	chown $CACHEUSR:$CACHEGRP $path/cache.key
	chmod -x $path/cache.key
	chmod ug+r $path/cache.key
	chmod u+w $path/cache.key
done



