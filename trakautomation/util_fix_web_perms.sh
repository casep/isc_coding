#!/bin/sh -e
. ./functions.sh

for inst in `cache_getinstances.pl`; do
	cachedir=`cache_instance2path.pl $inst`
	dir=`echo $cachedir | sed 's/^\(.*\)\/[^\/]*$/\1/'`
	[ -d $dir/web/ ] || continue
	# override user/group based on ownership of mgr/
	CACHEUSR=`ls -ld $cachedir/mgr/ | awk '{print $3}'`
	CACHEGRP=`ls -ld $cachedir/mgr/ | awk '{print $4}'`
	echo "Found $dir/web/"
	echo "* aim to set $CACHEUSR:$CACHEGRP with directories 2770 and files 660"
	echo "Do this? (y/N)"
	read ans
	if [ "$ans" != 'Y' -a "$ans" != 'y' ]; then
		echo "Skipping"
		echo
		continue
	fi
	echo "Set ownership...."
	chown -R $CACHEUSR:$CACHEGRP $dir/web/
	echo "Set directory permissions...."
	find $dir/web/ -type d -exec chmod 2770 {} \;
	echo "Set file permissions...."
	find $dir/web/ -type f -exec chmod 660 {} \;
	echo
done


