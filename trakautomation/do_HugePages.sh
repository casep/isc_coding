#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
#  do_HugePages.sh
#  
#  Copyright 2017 Carlos "casep" Sepulveda <casep@fedoraproject.org>
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
#  Update the memory configuration for Huge Pages
#  https://community.intersystems.com/post/linux-transparent-hugepages-and-impact-cach%C3%A9

checkPreviousConfig() {
	return $(grep "TrakCare" /etc/sysctl.d/99-sysctl.conf|wc -l)
}

echo "########################################"
echo "Huge Pages memory configuration"

if [ checkPreviousConfig ]; then
	echo "Generating configuration"
else	
	echo "Configuration exists, exiting"
fi

