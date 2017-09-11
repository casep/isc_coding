#!/usr/bin/bash
# -*- coding: utf-8 -*-
#
#  get_patients.sh
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

# Recupera pacientes y los disponibiliza en servidor FTP

SFTP=/usr/bin/sftp
RM=/usr/bin/rm
SU=/usr/bin/su
ECHO=/usr/bin/echo
CSESSION=/usr/bin/csession

ARCHIVO=/trak/sdtl/PRD/db/queryManager/PAPerson.csv
# No debe tener namespace asignado en perfil
USERCACHE=polmos
INSTANCIA=SDTL2011DB
NAMESPACE=SDTL
BATCHFILE=/home/cacheusr/sube_archivo
IDENTITYFILE=/home/cacheusr/.ssh/id_rsa
USERSFTP=uploader
SFTPSERVER=172.18.64.13

# Elimino archivo anterior
$RM -rf $ARCHIVO

$ECHO "Generando archivo"
# Genero archivo
$SU - $USERCACHE -c "$CSESSION $INSTANCIA -U$NAMESPACE \"GETALLPATIENTS(1,2000000)\" "

$ECHO ""
# Si archivo existe
if [ ! -e $ARCHIVO ]; then
 $ECHO "Archivo no generado"
 exit
fi

$ECHO "Iniciando copia"
$SFTP -b $BATCHFILE -o IdentityFile=$IDENTITYFILE $USERSFTP@$SFTPSERVER

$ECHO ""
$ECHO "Copia finalizada"
