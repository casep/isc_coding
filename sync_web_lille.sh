#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
#  sync_web_lille.sh
#  
#  Copyright 2014 Carlos "casep" Sepulveda <casep@intersystems.com>
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
# Simple Sync script

RSYNC=/usr/bin/rsync
ECHO=/bin/echo
RSYNC_FLAGS=avzr
SOURCE=/trakcare/FRGH/LIVE/web/
USER=cachesys
SERVER=172.18.1.116
DESTINATION=/trakcare/FRGH/LIVE/webTC2014/
LOG=/var/log/rsync.log
DATE=$(date +%Y%m%d_%H%M)

$ECHO "---------------" >> $LOG
$ECHO $DATE "Start" >> $LOG
$RSYNC -$RSYNC_FLAGS $SOURCE $USER@$SERVER:$DESTINATION >> $LOG
$ECHO $DATE "Finish" >> $LOG
$ECHO "---------------" >> $LOG
