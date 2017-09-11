#!/bin/bash
#Script para actualizacion de ambientes
#Casep 20110107, Copia de web tambien
#Casep, 20110718, Valida parametros, agrego llamada rutina
#Casep, 20111216, Cambio en rutina de Toques finales por TRC 93844
#Casep, 20120413, Path SSMOC 2010

#Valido recibir  el paremetro
if [ $# -lt 1 ]; then
 echo "uso /usr/bin/actualiza.sh instancia"
 echo "instancia = sdaruatdb,sdcluatdb,sdcnuatdb,sdcquatdb,sdoruatdb,sdsruatdb,sdtluatdb,sdvnuatdb,sdvpuatdb,smocuatdb"
 exit
fi

instancia=$1

if [ $instancia != 'sdaruatdb' ] || [ $instancia != 'sdcluatdb' ] || [ $instancia != 'sdcnuatdb' ] || [ $instancia != 'sdcquatdb' ] || [ $instancia != 'sdoruatdb' ] || [ $instancia != 'sdsruatdb' ] || [ $instancia != 'sdtluatdb' ] || [ $instancia != 'sdvnuatdb' ] || [ $instancia != 'sdvpuatdb' ] || [ $instancia != 'smocuatdb' ]; then
 echo "Instancia no encontrada (sdaruatdb,sdcluatdb,sdcnuatdb,sdcquatdb,sdoruatdb,sdsruatdb,sdtluatdb,sdvnuatdb,sdvpuatdb,smocuatdb)"
 exit
fi

path_ambiente=`echo $instancia|cut -c -4`

#Valido existencia archivo credenciales
archivoCredenciales=/refresh/credenciales\_$path_ambiente
if [ ! -e $archivoCredenciales ]; then
  echo "No existe archivo de Credenciales"
  echo "generarlo en $archivoCredenciales"
  exit
fi

path_restore=$path_ambiente
if [ $path_restore == 'smoc' ]; then
 path_restore="ssmoc"
 path_ambiente="ssmoc2010"
fi
path_db=/trak/UAT/$path_ambiente/db
path_web=/trak/UAT/$path_ambiente/web

archivoWebsys=/routines/websys.ConfigurationD\_$instancia.xml
if [ ! -e $archivoWebsys ]; then
 echo "No existe archivo de respaldo de websys.Configuration"
 echo "generarlo en $archivoWebsys"
 exit
fi

echo "Deteniendo Cache"
ccontrol stop $instancia quietly

echo " "
echo "Eliminando versiones anteriores"
rm -rf $path_db/*
rm -rf $path_web/* 

echo " "
echo "Copiando versiones actualizadas"
cp -r /RESTORED/trak/$path_restore/PRD/db/* $path_db/
cp -r /RESTORED/trak/$path_restore/PRD/web/* $path_web/ 

echo " "
echo "Cambiando permisos"
chown -R cacheusr.cacheusr $path_db
chown -R cacheusr.cacheusr $path_web

echo " "
echo "Eliminando locks"
find $path_db/ -name cache.lck | xargs rm -f

echo " " 
echo "Iniciando instancia"
cat $archivoCredenciales | ccontrol start $instancia quietly

echo " "
echo "Toques finales"
su - casep -c "csession $instancia -UUSER \"actualizaAmbiente\""
cat $archivoCredenciales | xargs rm -f
rm -rf $archivoCredenciales

echo " "
echo "Sincronizacion"
sync-web $instancia Actualizacion-$instancia

echo " "
echo "Fin proceso"
echo $(date)

