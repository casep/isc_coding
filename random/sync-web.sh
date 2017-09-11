#!/usr/bin/bash
# -*- coding: utf-8 -*-
#
#  sync-web.sh
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

# Sincroniza web
# Copiar $IDENTITYFILE.pub en cada GW en $GWs en /home/cacheusr/.ssh/authorized_keys

RSYNC=/usr/bin/rsync
ECHO=/usr/bin/echo
CCONTROL=/usr/bin/ccontrol
GREP=/usr/bin/grep
WC=/usr/bin/wc

ORIGEN=$1
DESTINO=$2
INSTANCIA=$3
IDENTITYFILE=/home/cacheusr/.ssh/id_rsa
GWs='172.18.64.25 172.18.64.26 172.18.64.27'
RSYNCLOGIN=cacheusr


$ECHO "Instancia arriba?"
if [ `$CCONTROL all | $GREP $INSTANCIA | $GREP up | $WC -l` -eq 0 ]; then
 $ECHO "Instancia abajo"
 exit
fi
$ECHO "Instancia OK"

$ECHO ""
$ECHO "Inicio loop sincronizaciones"
# Sync del proyecto
for gw in $GWs
 do
  set -x
  $RSYNC -avzr --delete-after -e "ssh -i $IDENTITYFILE" $ORIGEN $RSYNCLOGIN@$gw:$DESTINO
 done
