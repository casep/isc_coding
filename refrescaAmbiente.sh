#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
#  refrescaAmbiente.sh
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

#Script para actualizacion de ambientes
#Casep, 20101109, casep@intersys.com, version inicial
#Casep, 20110705, cambio en las paths, validar cantidad de parámetros, invocacion rutina COS
#Casep, 20110706, compatible para bld tst y trn
#Casep, 20111027, compatible con Support
#Casep, 20111114, cambio ubicacion archivos credenciales
#Casep, 20111216, cambio en rutina de Toques finales por TRC 93844
#Casep, 20120222, cambio en path RESTORE
#Casep, 20120314, cambio path DBs ssmoc 2010
#Casep, 20120713, cambio * por nombres de BDs en support (sysconfig de 2011/ccr)
#Casep, 20120718, no mas Monitor
#Casep, 20121022, Paths 2011
#Casep, 20121031, DATA en Test
#Casep, 20121220, SDCQ 2011
#Casep, 20130415, Se eliminan globales Live para Test
#Casep, 20130504, websys.Document
#Casep, 20130807, SDSR 2012
#Casep, 20130823, Nuevo metodo de copia
#lucup, 20130910, Restore desde TSM con verificacion previa 
#Casep, 20131111, Nuevas path support
#Casep, 20141202, Cambio en mecanismo de borrado de BDs
#Casep, 20141203, Train tiene nombre de instancia distinto
#Casep, 20141203, Deployed via git
#Casep, 20140403, Ya no es necesario esto, pero lo seguimos haciendo, ja ja, cuarto parametro de fecha
#Casep, 20150225, 775 en vez de 770 para los permisos

# Valido recibir 2 los parametros
if [ $# -lt 2 ]; then
 echo "uso /usr/bin/refrescaAmbiente.sh proyecto ambiente borraCredenciales"
 echo "proyecto = sdar,sdcl,sdcq,sdor,sdsr,sdtl,sdvn,sdvp,smoc"
 echo "ambiente = scratch,base,train,uat" 
 echo "borraCredenciales = yes, no (Borra credenciales o no)"
 echo "TSMTODAY = 2014-12-04 (Fecha a utilizar para el respaldo)"
 exit
fi

# Debo borrar las credenciales?
borrar_credenciales=yes
if [ ! -z $3 ]; then
 borrar_credenciales=$3
fi

TSMTODAY=$(date +%Y-%m-%d)
if [ ! -z $4 ]; then
 TSMTODAY=$4
fi

proyecto=$1
ambiente=$2
userCache="casep"

#Validar existencia de Backup del dia.
echo "Verificando Backup del dia:"
/usr/bin/ksh /etc/tsm/checkbackup.sh $proyecto\_$ambiente $TSMTODAY
if [[ "$?" != "0" ]]; then 
        echo "No existe Backup del $TSMTODAY"
        exit 1
fi

#Valido existencia archivo credenciales
archivoCredenciales=/refresh/credenciales\_$proyecto
if [ ! -e $archivoCredenciales ]; then
 echo "No existe archivo de Credenciales"
 echo "generarlo en $archivoCredenciales"
 exit
fi

#Valido existencia archivo rutinas
archivoRutinas=/routines/UActualizaAmbiente\_$proyecto\_$ambiente.xml
if [ ! -e $archivoRutinas ]; then
 echo "No existe archivo de respaldo de UActualizaAmbiente"
 echo "generarlo en $archivoRutinas"
 exit
fi

# Nombre de la instancia
instancia=$proyecto"trak"$ambiente
if [ $ambiente == 'train' ]; then
 instancia=$proyecto$ambiente
fi

echo "Inicio Proceso " 
echo $(date)
echo " "
echo "Deteniendo Cache "$instancia
ccontrol stop $instancia quietly

echo " "
echo "Eliminando versiones anteriores"
cat /etc/tsm/$proyecto\_$ambiente/RESTORE.fs | grep -v '^;' | while read source target  ; do echo $target ; rm -rf $target; done

echo " "
echo "Copiando versiones actualizadas"
/usr/bin/ksh /etc/tsm/restaurar.sh $proyecto\_$ambiente $TSMTODAY

echo " "
echo "Cambiando permisos"
cat /etc/tsm/$proyecto\_$ambiente/RESTORE.fs | grep -v '^;' | while read source target  ; do chown -R cacheusr.cacheusr $target; done
cat /etc/tsm/$proyecto\_$ambiente/RESTORE.fs | grep -v '^;' | while read source target  ; do chmod -R 775 $target; done

echo "Elimiando locks"
cat /etc/tsm/$proyecto\_$ambiente/RESTORE.fs | grep -v '^;' | while read source target  ; do rm -rf $target/cache.lck ; done 

echo "Iniciando instancia"
cat $archivoCredenciales | ccontrol start $instancia quietly

echo " "
echo "Toques finales"
su - $userCache -c "csession $instancia -UUSER \"UCargaRutinas\""
if [ $borrar_credenciales == 'yes' ]; then
 cat $archivoCredenciales | xargs rm -f
 rm -rf $archivoCredenciales
fi

echo " "
echo "Fin proceso"
echo $(date)
