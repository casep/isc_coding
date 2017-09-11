#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
#  pButtonsFolderCleanup.sh
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

### Crompress / clean up pButtons folder

pButtonsPath="/hs/cmc/live/temp/pButtons"
daysBeforeCompress=2
daysBeforePurge=60

/usr/bin/find ${pButtonsPath} -type f -mtime +${daysBeforeCompress} -name "*.html" -exec /usr/bin/gzip -9 {} \;
/usr/bin/find ${pButtonsPath} -type f -mtime +${daysBeforePurge} -name "*.gz" -exec rm -fv {} \;

exit 0
