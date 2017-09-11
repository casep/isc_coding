#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


echo "########################################"
echo "Setting Autostart...."
# check args
if [ -n "$1" ]; then
	# specified environment
	instances=`instname $SITE $ENV $1$VER`
	if [ -z "$instances" ]; then
		echo "Usage: $0 [Type]" >&2
		exit 1
	fi
else
	# assume we do this automatically
	#instances=`cache_getinstances.pl`
	instances=$(ccontrol qlist|cut -d"^" -f1)
fi




addinstances() {
	i=$#
	while [ $i -gt 0 ]; do
		eval "instance=\$$i"
		if GetSection.pl /etc/init.d/isccache '^startinst="' '^"' | grep -q $instance; then
			echo "WARNING - $instance already exists, skipping! Start order may not be as expected" >&2
		else
			echo "Setting Autostart for $instance"
			sed --in-place "/^startinst=\"/ a \\\t$instance" /etc/init.d/isccache
		fi
		i=$(($i-1))
	done
}

addinstances $instances

