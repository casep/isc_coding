#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
#  capturaServerStatus.sh
#  
#  Copyright 2014 Carlos "casep" Sepulveda <casep@fedoraproject.org>
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

# Captura contenido de /server-status para futura investigacion

LINKS=/usr/bin/links
LINKS_FLAGS="-source "
URL=http://127.0.0.1/server-status
OUTPUTFOLDER=/tmp
DATE=$(date +%Y%m%d_%H%M%S)

$LINKS $LINKS_FLAGS $URL > $OUTPUTFOLDER/server_status_$DATE.html
