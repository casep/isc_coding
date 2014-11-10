#!/bin/bash
# -*- coding: utf-8 -*-
#
#  apache_HDD_to_hdd.sh
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


# Cambia la configuracion de Apache para utilizar archivos locales
# en vez de HDD.
# En estado normal /etc/httpd/conf.d/trak.conf -> trak_NFS.conf

RSYNC=/usr/bin/rsync
ECHO=/bin/echo
CCONTROL=/usr/bin/ccontrol
GREP=/usr/bin/grep
WC=/usr/bin/wc
DATE=/bin/date
LN=/bin/ln
RM=/bin/rm
SERVICE=/sbin/service

SERVICIOAPACHE=httpd
APACHEHDD=/etc/httpd/conf.d/trak_hdd.conf
APACHECONF=/etc/httpd/conf.d/trak.conf

$ECHO ""
$ECHO "Verificando configuracion"

if [ ! -e $APACHEHDD ]; then
 $ECHO "Archivo de configuracion HDD no existe "$APACHEHDD
 exit
fi

$ECHO ""
$ECHO "Creando nueva configuracion"
$LN -fs $APACHEHDD $APACHECONF

$ECHO ""
$ECHO "Reiniciando Apache"
$SERVICE $SERVICIOAPACHE reload

$ECHO "Fin"
