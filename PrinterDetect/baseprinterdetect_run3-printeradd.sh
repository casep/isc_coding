#!/bin/sh

# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBEDP" on "socket://192.168.12.41:9100"'
lpadmin -p 'WBEDP' -D "Wristband" -L "ED Paediatrics" -m 'raw' -v 'socket://192.168.12.41:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "PPR6" on "socket://192.168.129.185:9100"'
lpadmin -p 'PPR6' -D "Letter" -L "Medical records main library " -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.129.185:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "DC5" on "socket://192.168.132.1:9100"'
lpadmin -p 'DC5' -D "OCM and Reports" -L "C5 (SSOP)" -m 'raw' -v 'socket://192.168.132.1:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBJW" on "socket://192.168.14.103:9100"'
lpadmin -p 'WBJW' -D "Wristband" -L "Jasmine Ward" -m 'raw' -v 'socket://192.168.14.103:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBNNU" on "socket://192.168.14.122:9100"'
lpadmin -p 'WBNNU' -D "Wristband" -L "Neonatal Unit" -m 'raw' -v 'socket://192.168.14.122:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBCOT1" on "socket://192.168.14.71:9100"'
lpadmin -p 'WBCOT1' -D "Wristband" -L "Maternity 1st Floor" -m 'raw' -v 'socket://192.168.14.71:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBM1" on "socket://192.168.14.79:9100"'
lpadmin -p 'WBM1' -D "Wristband" -L "Maternity 1st Floor" -m 'raw' -v 'socket://192.168.14.79:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBBC" on "socket://192.168.14.82:9100"'
lpadmin -p 'WBBC' -D "Wristband" -L "Birth Centre" -m 'raw' -v 'socket://192.168.14.82:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBM3" on "socket://192.168.14.96:9100"'
lpadmin -p 'WBM3' -D "Wristband" -L "Maternity 3rd Floor - MAT Triage" -m 'raw' -v 'socket://192.168.14.96:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "MAF4" on "socket://192.168.15.44:9100"'
lpadmin -p 'MAF4' -D "OCM and Reports" -L "Maternity 4th Floor" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.15.44:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBEDR" on "socket://192.168.16.11:9100"'
lpadmin -p 'WBEDR' -D "Wristband" -L "ED Reception" -m 'raw' -v 'socket://192.168.16.11:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "AE14" on "socket://192.168.16.197:9100"'
lpadmin -p 'AE14' -D "OCM and Reports" -L "AE - Paediatric Unit" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.16.197:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBXRA" on "socket://192.168.19.15:9100"'
lpadmin -p 'WBXRA' -D "Wristband" -L "X-ray A" -m 'raw' -v 'socket://192.168.19.15:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBDMOP" on "socket://192.168.28.31:9100"'
lpadmin -p 'WBDMOP' -D "Wristband" -L "DMOP" -m 'raw' -v 'socket://192.168.28.31:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBMS" on "socket://192.168.44.221:9100"'
lpadmin -p 'WBMS' -D "Wristband" -L "Maple Suite" -m 'raw' -v 'socket://192.168.44.221:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBOPT" on "socket://192.168.5.61:9100"'
lpadmin -p 'WBOPT' -D "Wristband" -L "Out-Patient Theatre" -m 'raw' -v 'socket://192.168.5.61:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBEDM" on "socket://192.168.53.10:9100"'
lpadmin -p 'WBEDM' -D "Wristband" -L "ED Main Base" -m 'raw' -v 'socket://192.168.53.10:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "WBTHA" on "socket://192.168.56.139:9100"'
lpadmin -p 'WBTHA' -D "Wristband" -L "Tree House" -m 'raw' -v 'socket://192.168.56.139:9100' -E
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "PPR11" on "socket://192.168.57.16:9100"'
lpadmin -p 'PPR11' -D "Letter" -L "Treehouse (2nd Floor, Rm 218)Secs" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.57.16:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "PPR1" on "socket://192.168.59.155:9100"'
lpadmin -p 'PPR1' -D "Letter" -L "Outpatients Booking rm 73 cedar" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.59.155:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "GOP1" on "socket://192.168.65.110:9100"'
lpadmin -p 'GOP1' -D "OCM and Reports" -L "Gynae Outpatients" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.110:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "OPB1" on "socket://192.168.65.118:9100"'
lpadmin -p 'OPB1' -D "OCM and Reports" -L "OPB IHS" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.118:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "XBMO" on "socket://192.168.65.128:9100"'
lpadmin -p 'XBMO' -D "OCM and Reports" -L "X Ray B Main Office" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.128:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "XBV2" on "socket://192.168.65.129:9100"'
lpadmin -p 'XBV2' -D "OCM and Reports" -L "X Ray B Viewing Area 2" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.129:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "XACT" on "socket://192.168.65.131:9100"'
lpadmin -p 'XACT' -D "OCM and Reports" -L "X Ray A CT Viewing Rm" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.131:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "XMU" on "socket://192.168.65.133:9100"'
lpadmin -p 'XMU' -D "OCM and Reports" -L "Maternity Ultrasound" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.133:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "FER1" on "socket://192.168.65.138:9100"'
lpadmin -p 'FER1' -D "OCM and Reports" -L "Fertility Clinic" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3005-pcl3.ppd' -v 'socket://192.168.65.138:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "NEO" on "socket://192.168.65.147:9100"'
lpadmin -p 'NEO' -D "OCM and Reports" -L "Neonatal main office" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.147:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "EPU" on "socket://192.168.65.151:9100"'
lpadmin -p 'EPU' -D "OCM and Reports" -L "Maternity - EPU - Mat3 - Mat Triage" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.151:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "MAT11" on "socket://192.168.65.16:9100"'
lpadmin -p 'MAT11' -D "Letter" -L "Maternity Medical Records" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.16:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "MAT12" on "socket://192.168.65.17:9100"'
lpadmin -p 'MAT12' -D "OCM and Reports" -L "Maternity Office" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.17:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "DCCL" on "socket://192.168.65.196:9100"'
lpadmin -p 'DCCL' -D "OCM and Reports" -L "Cardiac Cath Lab" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.196:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "PR6" on "socket://192.168.65.20:9100"'
lpadmin -p 'PR6' -D "Letter" -L "Appointments call centre" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.20:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "DJAS" on "socket://192.168.65.40:9100"'
lpadmin -p 'DJAS' -D "OCM and Reports" -L "Jasmine" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.40:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "DMAU" on "socket://192.168.65.53:9100"'
lpadmin -p 'DMAU' -D "OCM and Reports" -L "MAU" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.53:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "JAU" on "socket://192.168.65.97:9100"'
lpadmin -p 'JAU' -D "OCM and Reports" -L "Jasmine Asses Unit" -m 'drv:///hp/hpcups.drv/hp-laserjet_p3010_series-pcl3.ppd' -v 'socket://192.168.65.97:9100' -E -o PageSize=A4
# name from CSV "CUPS name"
# description from CSV "CUPS description"
# location from CSV "CUPS location"
echo 'Adding "CHC2" on "socket://192.168.7.25:9100"'
lpadmin -p 'CHC2' -D "OCM and Reports" -L "Lung Function,Chest Clinic" -m 'drv:///hp/hpcups.drv/hp-color_laserjet_cp3525-pcl3.ppd' -v 'socket://192.168.7.25:9100' -E -o PageSize=A4
