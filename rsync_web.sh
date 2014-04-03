#!/bin/bash
# -*- coding: utf-8 -*-
#
#  rsync-web.sh
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


# Sincroniza web desde NFS mount local a disco local
# 

RSYNC=/usr/bin/rsync
ECHO=/bin/echo
CCONTROL=/usr/bin/ccontrol
GREP=/usr/bin/grep
WC=/usr/bin/wc
DATE=/bin/date

Proyectos='SDAR SDCL SDCQ SDOR SDSR SDTL SDVN SDVP smoc'
RSYNCLOGIN=cacheusr
PATHWEB=/trak/web
PATHDISCO=/home/localweb/
PARAMETROSRSYNC="-avr --delete-after --quiet"
ARCHIVOLOG=/var/log/rsync_web.log

$ECHO $($DATE +%Y%m%d_%H%M%S) > $ARCHIVOLOG
$ECHO "Inicio loop sincronizaciones" >> $ARCHIVOLOG
# Sync de proyectos
for proyecto in $Proyectos
 do
  $ECHO "" >> $ARCHIVOLOG
  $ECHO "Sincronizando "$proyecto >> $ARCHIVOLOG
  $RSYNC $PARAMETROSRSYNC $PATHWEB/$proyecto $PATHDISCO
 done

$ECHO "" >> $ARCHIVOLOG
$ECHO "Fin loop sincronizaciones" >> $ARCHIVOLOG
$ECHO $($DATE +%Y%m%d_%H%M%S) >> $ARCHIVOLOG
$ECHO "" >> $ARCHIVOLOG
