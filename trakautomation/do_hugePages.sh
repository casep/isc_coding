#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# do_hugePages.sh
#  
#  Copyright 2018 Carlos "casep" Sepulveda <casep@fedoraproject.org>
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
# Quick and dirty deploy of Apache configuration files
# Works on RedHat, I don't care about Suse

#  Update the memory configuration for Huge Pages
#  https://community.intersystems.com/post/linux-transparent-hugepages-and-impact-cach%C3%A9

checkPreviousConfig() {
	return $(grep "TrakCare" $CONF | wc -l)
}

memoryAllocationCheck() {
	memory=$(cat /proc/meminfo | grep MemTotal | tr -d " " | cut -d":" -f2)
	if [ $(( $(echo "${memory::-2}") - ( $HUGEPAGES * 2048 ) )) -lt 0 ] ; then 
		echo "Check memory allocation values, possible over allocation"
		exit 1
	fi
}

generateConfig() {
	echo "# ISC TrakCare OS tuning" >> $CONF
	echo "kernel.shmmax=649278259200" >> $CONF
	echo "vm.nr_hugepages=$HUGEPAGES" >> $CONF
	echo "vm.swappiness=5" >> $CONF
	echo "vm.dirty_background_ratio=5" >> $CONF
	echo "vm.dirty_ratio=10" >> $CONF
}

echo "########################################"
echo "Huge Pages memory configuration"

# check for args
if [ $# -ne 1 ]; then
	echo "Usage: $0 <Huge Pages number>" >&2
	exit 1
fi
HUGEPAGES=$1
CONF=/etc/sysctl.d/99-sysctl.conf

# Check value
memoryAllocationCheck 

if [ checkPreviousConfig ]; then
	echo "Generating configuration"
	generateConfig
else	
	echo "Configuration exists, exiting"
fi

