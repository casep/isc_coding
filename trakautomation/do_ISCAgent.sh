#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# do_Firewall.sh
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
# Quick and dirty enable ISCAgent
# Works on RedHat, I don't care about Suse

. ./functions.sh


check_LINUX() {
        return 1
}

install_LINUX() {
	systemctl enable ISCAgent
	systemctl start ISCAgent
}

echo "########################################"
echo "Enabling ISCAgent"

install_LINUX

