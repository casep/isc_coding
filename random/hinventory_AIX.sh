#!/bin/bash
#HInventory script for Solaris
#Thomas BRETON 
#Solaris Contribution Clay Haapala, Marc Demierre, Fahran Ahmed, Jacky
#Copyright (C) 2005  Thomas BRETON
# Adapated from the linux 1.2.6 script by Clay Haapala

#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

VERSION="1.0.0 AIX"

##UNSET des langues
# Jacky begin
# more variables and changed Reportfile Place and if-construct
unset LANG LC_ALL LC_MESSAGES LC_COLLATE LC_CTYPE LC_MONETARY LC_NUMERIC LC_TIME

##Global variables
PATH="$PATH:/usr/bin:/usr/sbin:/usr/ccs/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
HOSTNAME=`hostname`

DATE="`date +%d/%m/%Y` `date +%H:%M:%S`"
PID=$$
PKGFILE=/tmp/pkgtmpfile_$PID
INSTALL_VERZ=`dirname $0`

if [ "$outputdir" == "" ] && [ -d "/var/spool/hinventory" ]; then 
	ReportFile=/var/spool/hinventory/$HOSTNAME.xml
elif [ "$outputdir" != "" ] && [ -d "$outputdir" ]; then 
	ReportFile=$outputdir/$HOSTNAME.xml
else 
	ReportFile=$INSTALL_VERZ/$HOSTNAME.xml
fi
# Jacky end

if [ -f "/var/log/dmesg" ]
	then dmesgvar="cat /var/log/dmesg"
	else dmesgvar="dmesg"
fi

if [ -x '/usr/sbin/ifconfig' ]
	then ifconfig='/usr/sbin/ifconfig'
	else ifconfig='ifconfig'
fi

##################################################################################
#Component writing
#4 functions 
##################################################################################
function writecomment ()
{
echo "<!-- $1 -->" >> $ReportFile
if [ "$debug" = 2 ]
then echo "<!-- $1 -->"
fi
}

# From FreeBSD rc.subr
checkyesno () {
  eval _value=\$${1}
  case $_value in
    #       "yes", "true", "on", or "1"
    [Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]|1)
      return 0
      ;;
    #       "no", "false", "off", or "0"
    [Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|0)
      return 1
      ;;
    *)
      return 1
     ;;
  esac
  }

#
# Solaris doesn't have a nice date +%s output
#
curtime ()
{
    local tm=$(date "+%M" | sed 's/^0*\([0-9][0-9]*\)/\1/g')
    local ts=$(date "+%S" | sed 's/^0*\([0-9][0-9]*\)/\1/g')
    local t=$[ $tm * 60 + $ts ];
    echo $t
}

# Jacky begin
# removed hex2quad, because it not worked in every case and supplied covertmac
# covert the subnetmask I did in another way in detect_network
convertmac ()
{
    orgmac=$1
    o1=`echo $orgmac|cut -d':' -f1`
    o2=`echo $orgmac|cut -d':' -f2`
    o3=`echo $orgmac|cut -d':' -f3`
    o4=`echo $orgmac|cut -d':' -f4`
    o5=`echo $orgmac|cut -d':' -f5`
    o6=`echo $orgmac|cut -d':' -f6`
    if [ ${#o1} -eq 1 ]; then
        o1="0$o1"
    fi
    if [ ${#o2} -eq 1 ]; then
        o2="0$o2"
    fi
    if [ ${#o3} -eq 1 ]; then
        o3="0$o3"
    fi
    if [ ${#o4} -eq 1 ]; then
        o4="0$o4"
    fi
    if [ ${#o5} -eq 1 ]; then
        o5="0$o5"
    fi
    if [ ${#o6} -eq 1 ]; then
        o6="0$o6"
    fi
    echo "$o1:$o2:$o3:$o4:$o5:$o6"
}
# Jacky end
								
##################################################################################
# Sanity check, replace &, < et > with HTML codes
##################################################################################
# Jacky begin
# Replaced the sed command with normal "signs"
correct_var () {
  echo "$1" | sed 's/&/&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g'
  }
# Jacky end

writecomponent () {
  var1=`correct_var "$1"`
  var2=`correct_var "$2"`
  echo "<component>" >> $ReportFile
  echo "<type>$var1</type>" >> $ReportFile
  echo "<name>$var2</name>" >> $ReportFile
  if [ "$debug" = 2 ]; then
    echo "<component>"
    echo "<type>$var1</type>"
    echo "<name>$var2</name>"
  fi
}

writesubcomponent () {
  var1=`correct_var "$1"`
  var2=`correct_var "$2"`
  echo "<attr><name>$var1</name><value>$var2</value></attr>" >> $ReportFile
  if [ "$debug" = 2 ]; then
    echo "<attr><name>$var1</name><value>$var2</value></attr>"
  fi
  }

writeendcomponent () {
  echo "</component>" >> $ReportFile
  if [ "$debug" = 2 ]; then
    echo "</component>"
  fi
  }

##################################################################################
## Temps d execution du script
##################################################################################

timecmd ()
{
diffsec=`expr $2 - $1`
heures=`expr $diffsec / 3600`
minutes1=`expr $diffsec - $heures \* 3600`
minutes=`expr $minutes1 / 60`
secondes1=`expr $diffsec - $minutes \* 60`
secondes=`expr $secondes1 - $heures \* 3600`
timeres="$heures heures $minutes minutes $secondes secondes"
}

##################################################################################
## Couleur
##################################################################################
black='\E[30;47m'
red='\E[31;47m'
green='\E[32;47m'
yellow='\E[33;47m'
blue='\E[34;47m'
magenta='\E[35;47m'
cyan='\E[36;47m'
white='\E[37;47m'

cecho ()                     # Color-echo.
                             # Argument $1 = message
                             # Argument $2 = color
{
local default_msg="No message passed."
                             # Doesn't really need to be a local variable.

message=${1:-$default_msg}   # Defaults to default message.
color=${2:-$black}           # Defaults to black, if not specified.

  echo -e "$color" "$message" 
  tput sgr0                      # Reset to normal.


}


##################################################################################
## Infos de script
##################################################################################

detect_script ()
{
comment=SCRIPT
type=script
name=inventory
version=$VERSION
time=`expr $2 - $1`
if [ "$debug" = 1 ]; then echo "- detect_script: $name"; fi
             if [ "$debug" = 1 ]; then echo "  * Version $version: [$time Sec] ($method)"; fi

writecomment "$comment"
writecomponent "$type" "$name"
writesubcomponent "version" "$version"
writesubcomponent "time" "$time"
writesubcomponent "method" "$method"
writeendcomponent
}



##################################################################################
#Beginning of XML
##################################################################################
function beginXML ()
{
echo "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" ?> " > $ReportFile
echo "<!DOCTYPE computer [" >> $ReportFile
echo "<!ELEMENT computer      (hostname, datetime, component*)>" >> $ReportFile
echo "<!ELEMENT component     (type,name,attr*)>" >> $ReportFile
echo "<!ELEMENT hostname      (#PCDATA)>" >> $ReportFile
echo "<!ELEMENT datetime (#PCDATA)>" >> $ReportFile
echo "<!ELEMENT type          (#PCDATA)>" >> $ReportFile
echo "<!ELEMENT name          (#PCDATA)>" >> $ReportFile
echo "<!ELEMENT attr          (name,value)>" >> $ReportFile
echo "<!ELEMENT value         (#PCDATA)>" >> $ReportFile
echo "]>" >> $ReportFile
#echo "<computer xmlns="http://www.h-inventory.com">" >> $ReportFile
echo "<computer>" >> $ReportFile
echo "<hostname>$HOSTNAME</hostname>"  >> $ReportFile
echo "<datetime>$DATE</datetime>" >> $ReportFile
}

##################################################################################
#End of XML
##################################################################################
function endXML ()
{
echo "</computer>" >> $ReportFile
}


##################################################################################
# Check arguments
##################################################################################
check_login () {
  if [ "$debug" = 1 ]; then echo "- Check login information"; fi
  fail=0
  # Check server
  if [ -z "$server" ]; then
    echo "  Server: Fail (empty)"
    fail=1
  fi
  # Check login
  if [ -z "$user" ]; then
    echo "  Username: Fail (empty)"
    fail=1
  fi
  # Check password
  if [ -z "$password" ] && [ "$method" != scp ] ; then
    echo "  Password: Fail (empty)"
    fail=1
  fi
  # Check public_key
  if [ "$method" = scp ]; then
    if [ -z "$public_key" ]; then
      echo "  Pulic key: Fail (empty)"
      fail=1
    else
      if [ ! -f "$public_key" ]; then
        echo "  Pulic key: Fail (file $public_key not found)"
        fail=1
     fi
   fi
  fi
  # Check mountpoint
  if [ "$method" = smb ] || [ "$method" = nfs ]; then
  	if [ -z "$mountpoint" ] ; then
	    echo "  Mountpoint: Fail (empty)"
	    fail=1
	 fi
  fi
  # If failure
  if [ $fail = 1 ]; then
    echo "Error, on or more problem(s) has been found for method $method. Review your configuration."
    exit 1
  fi
  }


##################################################################################
### DIFFER BETWEEN SCRIPTS
##################################################################################


##################################################################################
# OS detection
##################################################################################
function detect_os ()
{

comment=OS
type="Operating System"
name=`uname -s`
version=`uname -r`

distribution="AIX"
release=`oslevel`
writecomment "$comment"
writecomponent "$type" "$name ($distribution)"
writesubcomponent "version" "$version"
writesubcomponent "distribution" "$distribution"
writesubcomponent "release" "$release"
writeendcomponent

}



##################################################################################
# Software detection
##################################################################################
function detect_software ()
{
# Jacky begin
# Replaced with more a function with more output
comment=APPLICATIONS
type=application

writecomment "$comment"
lslpp -l > $PKGFILE
if [ -s "$PKGFILE" ]; then
	cat $PKGFILE | while read f1 frest
	do
	case "$f1" in
	PKGINST*)
		soft=$frest
		skip=yes
		;;
	VERSION*)
		version=`echo $frest | cut -d',' -f1`
		skip=yes
		;;
	DESC*)
		description=$frest
		;;
	*)
		skip=yes
	;;
	esac
	if [ -z "$skip" ]; then
		writecomponent "$type" "$soft"
		writesubcomponent "comment" "$description"
		writesubcomponent "version" "$version"
		writeendcomponent
	fi
	unset skip
	done
	rm -f dummy $PKGFILE
fi
}

##################################################################################
#Detection PACKAGES UPDATE ON DEBIAZN
##################################################################################
function detect_updates ()
{
comment=UPDATES
type=updates

writecomment "$comment"

}
# Jacky begin
# new function for model
function detect_model ()
{
comment=Model
type=model
name="IBM"
model=`prtconf | grep "System Model" | cut -d":" -f2`
systype=`prtconf | grep "Processor Type" | cut -d":" -f2`
writecomment "$comment"
writecomponent "$type" "$model"
writesubcomponent "manufacturer" "$name"
writesubcomponent "systemtype" "$systype"
writeendcomponent
}
# Jacky end
##################################################################################
#CPU detection (a finir) pb si different proc
# Compat: FreeBSD
##################################################################################
function detect_cpu ()
{
comment=CPU
type=CPU

writecomment "$comment"
# Jacky begin
# changed some commands, because there where some errors on my machines
cpuname=`prtconf | grep "Processor Version" | cut -d":" -f2`
nbcpu=`prtconf | grep "Number Of Processors" | cut -d":" -f2`
cpufreq=`prtconf | grep "Processor Clock Speed" | cut -d":" -f2`
desc=`prtconf | grep "Firmware Version" | cut -d":" -f2`
while [ $nbcpu -ne 0  ]
do
NAME=$cpuname
writecomponent "$type" "$NAME"
writesubcomponent "manufacturer" "Sun Microsystems"
writesubcomponent "speed" "$cpufreq"
writesubcomponent "description" "$desc"
writeendcomponent
nbcpu=`expr $nbcpu - 1`
done
# Jacky end
}


##################################################################################
#Mem detection 
##################################################################################
function detect_ram ()
{
# Jacky begin
# changed command
    RAMsize_u=`prtconf | sed -ne '/^Memory Size/s/Memory Size:[ \t]*//p' | sed -e 's/[ ]*//g'`
# Jacky end
    RAMsize=`echo $RAMsize_u | sed 's/[^0-9.]*//g'`
    case "$RAMsize_u" in
	*GB) RAMsize=`cat /dev/null | awk "BEGIN {print $RAMsize * 1024}"` ;;
	*Megabytes) ;;
	*) RAMsize=0 ;;
    esac

    comment="Memory"
    type="Physical Memory"
    NAME="Physical Memory"

    if [ "$debug" = 1 ]; then
	echo "- detect_ram: $comment"
	echo "  * Size: $RAMsize MB"
    fi
    writecomment "$comment"
    writecomponent "$type" "$NAME"
    writesubcomponent "size" "$RAMsize"
    writeendcomponent

}

##################################################################################
# Swap detection
##################################################################################
function detect_swap ()
{
swaptotal=`swap -l | tail -1 | awk '{print $4/2/1024}'`

comment="Memory"
type="Virtual memory"
name="Virtual Memory"

writecomment "$comment"
writecomponent "$type" "$name"
writesubcomponent "size" "$swaptotal"
writeendcomponent

}


##################################################################################
# SCSI
##################################################################################

#
# Solaris
#
function detect_scsi ()
{
    comment=SCSI
    interface=SCSI
    writecomment "$comment"
    iostat -En | while read f1 frest
    do
      case "$f1" in
      c*)
        sdev=$f1
        type="Hard Disk"
	;;
      rmt*)
        sdev=$f1
        type="Tape"
        ;;
      Vendor*)
        vendor=`echo $frest | awk '{print $1}'`
	model=`echo $frest | awk '{print $3}'`
	name="$vendor $model"
	case "$sdev" in
	    c*)
	      ;;
	    rmt*)
	      writecomponent "$type" "$name"
	      writesubcomponent "interface" "$interface"
	      writeendcomponent
	      sdev=""
	      ;;
	    *)
	      ;;
	esac
	  ;;
       Size*)
	  sizeb=`echo $frest | sed -ne 's/^[0-9.MGB]* <\([0-9]*\) bytes>/\1/p'`
	  size=`expr $sizeb / 1024 / 1024`
	  if [ "$debug" = 1 ]; then echo "- detect_scsi: $comment"; fi
	  if [ "$debug" = 1 ]; then echo "  * $sdev: $name [$size MB] ($interface)"; fi
	  writecomponent "$type" "$name"
	  writesubcomponent "size" "$size"
	  writesubcomponent "interface" "$interface"
	  writeendcomponent
	  ;;
	  *)
	  ;;
      esac
    done
}

#############################################
#Convert Mac Function
#############################################
# Jacky begin
# Removed because I wrote it in the beginning of script
# Jacky end


##################################################################################
#Network detection
##################################################################################
function detect_network ()
{
comment=NETWORK

if [ "$debug" = 1 ]; then echo "- detect_network: $comment"; fi
# Jacky begin
# more networkifaces
for i in `$ifconfig -a | egrep '^en|^ipg|^hme|^qfe|^eth|^eri|^bge|^ce|^pcn|^vmxnet|^vlance' | cut -d" " -f1`
# Jacky end
do
# Jacky begin
# changed several things
name="IBM"
manuf="IBM"
virtual=`$ifconfig -a|grep $i|head -1|cut -d':' -f3`
        if [ "$virtual" ]; then
                iface=`$ifconfig -a|grep $i|cut -d':' -f1,2`
                manuf="Virtual Interface"
                type="Virtual Network Adapter"
        else
                iface=`echo $i|cut -d":" -f1`
        fi
ip=`$ifconfig $iface | awk '/inet/{print $2}'`
orgmac=`$ifconfig "$iface" | grep ether | awk '{print $2}'`
mac=`convertmac $orgmac`
subnetmaskhex=`$ifconfig "$iface" | awk '/netmask/{print $4}'`
subnetmask=`printf "%u.%u.%u.%u\n"  $(echo "$subnetmaskhex"|sed 's/../0x& /g')`
type="Network Adapter"

writecomponent "$type" "$manuf"

if [ -z "$ip" ]; then ip="0.0.0.0"; fi
if [ -z "$subnetmask" ]; then subnetmask="0.0.0.0"; fi
if [ "$debug" = 1 ]; then echo "  * $iface: $name - $manuf - MAC: $mac IP: $ip"; fi

writesubcomponent "interface" "$iface"
# Jacky end
writesubcomponent "mac" "$mac"
writesubcomponent "ip" "$ip"
writesubcomponent "subnetmask" "$subnetmask"
writeendcomponent
done
}


##################################################################################
#Disk Audit
##################################################################################
function disk_audit ()
{
comment=DISK
if [ "$debug" = 1 ]; then echo "- disk_audit: $comment"; fi

nb=`df -lk | grep dev.dsk | wc -l`
nbdisk=`expr $nb - 1`

type="Audit"

for part in `df -lk | grep dev | awk '{ printf "%s;%s;%s;%s;%s;%s\n", $1, $2, $3, $4, $5, $6 }'`; do
  name=`echo $part | cut -d";" -f1`
  filesystem=`df -n $name | awk '{print $3}'`
  size=`echo $part | cut -d";" -f2`
  used=`echo $part | cut -d";" -f3`
  available=`echo $part | cut -d";" -f4`
  percent=`echo $part | cut -d";" -f5`
  mount=`echo $part | cut -d";" -f6`

writecomponent "$type" "Partition $name"

writesubcomponent "filesystem" "$filesystem"
writesubcomponent "size" "$size"
writesubcomponent "freespace" "$available"
writesubcomponent "used" "$used"
writesubcomponent "percent" "$percent"
writesubcomponent "mountpoint" "$mount"

writeendcomponent 
done
}



##################################################################################
#Upload XML file
##################################################################################
uploadXML () {
  case $method in
    local) exit 0 ;;
    ### Upload SCP
    scp)
      if [ "$debug" = 1 ]; then echo "- Starting upload on scp://${user}@${server}/${remote_path}"; fi
      scp -i $public_key $ReportFile $user@$server:$remote_path
      if [ $? = 0 ]; then
        echo "  * Report succesfully uploaded on $server."
      else
        echo "  * Unable to upload report file on $server."
      fi
    ;;
   ### Upload SOAP
   soap)
if [ -f "hisoap_client.pl" ]
        then ./hisoap_client.pl
else if [ -f "/bin/hisoap_client.pl" ]
        then /bin/hisoap_client.pl   
fi
fi
;;
  ### Upload HTTP
  http)
  if [ "$debug" = 1 ]; then echo "- Starting upload on http://${user}@${server}${remote_path}"; fi
  
curl -F file1=@$ReportFile -u ${user}:${password} -F SubBtn=OK ${server}${remote_path};
  #  ./http_upload.pl 
    ;;
  ### Upload FTP
  ftp)
    if [ "$debug" = 1 ]; then echo "- Starting upload on ftp://${user}@${server}/${remote_path}"; fi
      ftp -i -n $server << EOF
user ${user} ${password}
binary
cd $remote_path
put $ReportFile
quit
EOF
    if [ $? = 0 ]; then
      echo "  * Report succesfully uploaded on $server."
    else
      echo "  * Unable to upload report file on $server."
    fi
  ;;
### Upload SMB
  smb)
    if [ "$debug" = 1 ]; then echo "- Starting upload on smb://${user}@${server}/${remote_path}"; fi
    if [ -e $mountpoint ]
       then
       echo
       else
       mkdir $mountpoint
       fi
       mount -t smbfs -o username=$user,password=$password //$server/$remote_path $mountpoint
       cp $ReportFile $mountpoint
    if [ $? = 0 ]; then
      echo "  * Report succesfully uploaded on $server."
    else
      echo "  * Unable to upload report file on $server."
    fi
       umount $mountpoint

    ;;
### Upload NFS
  nfs)
	if [ "$debug" = 1 ]; then echo "- Starting upload on nfs://${user}@${server}:${remote_path}"; fi
	if [ -e $mountpoint ]
       then
       echo
       else
       mkdir $mountpoint
       fi
       mount -t nfs $server:$remote_path $mountpoint
       cp $ReportFile $mountpoint
      if [ $? = 0 ]; then
        echo "  * Report succesfully uploaded on $server."
      else
        echo "  * Unable to upload report file on $server."
      fi
       umount $mountpoint
	;;
  esac
  rm -f $ReportFile
  }

#############HTTP####################
# user pass
#--http-user=USAGER      utiliser le nom de l'USAGER http.
#--http-passwd=MOT_DE_PASSE
# get --post-file


##################################################################################
##################################################################################
# MAIN
##################################################################################
##################################################################################
blnConfFile="false"
if [ -f "/etc/hinventory.conf" ]
then ConfFile="/etc/hinventory.conf"
     blnConfFile="true"
else if [ -f "/etc/hinventory_Linux.conf" ]
	then ConfFile="/etc/hinventory.conf"
	     blnConfFile="true"
     	else if [ -f "`dirname $0`/hinventory.conf" ]
		then ConfFile=`dirname $0`/hinventory.conf
	             blnConfFile="true"
		else if [ -f "`dirname $0`/hinventory_Linux.conf" ]
			then ConfFile="`dirname $0`/hinventory_Linux.conf"
			     blnConfFile="true"
		     fi
		fi	
	fi
fi

if [ $blnConfFile == false ]; then
	echo "Fatal error, configuration file is missing."
  exit 1
else

  # Checking conf
  . $ConfFile

  case $debug in
    0) ;;
    1)
      echo "- Parsing configuration file: $ConfFile" 
      echo "  * debug=$debug"
      ;;
    xml) ;;
    *) echo "Fatal error, debug mode not supported, choose : debug=[0][1][2]"; exit 1;;
  esac

  if [ -z "$remote_path" ]; then
    remote_path=.
  fi

  if [ "$debug" = 1 ]; then
    echo "  * method=$method"
    echo "  * server=$server"
    echo "  * remote_path=$remote_path"
    echo "  * mountpoint=$mountpoint"
    echo "  * user=$user"
    echo "  * password=[XXX]"
    echo
  fi

case $method in
    ftp)
      check_login
      ;;
    http)
      check_login
      ;;
    soap)
      ;;
    local)
      ;;
    smb)
      check_login
      ;;
    nfs)
      check_login
      ;;
    scp)
      check_login
      ;;
    *)
       echo "Fatal error, method not supported, choose : ftp, http, local, smb, nfs or scp"
       exit 1
       ;;
  esac
fi

timedeb=`curtime`
beginXML
detect_model
detect_cpu
detect_ram
detect_scsi
detect_floppy
detect_network
# Jacky begin
# removed detect_pci because there is no function for it
# Jacky end
detect_os
#detect_updates		# No longer works
###audit###
if checkyesno test_software; then detect_software; fi
if checkyesno test_audit; then disk_audit; detect_swap; fi

timefin=`curtime`
detect_script $timedeb $timefin
endXML
timecmd $timedeb $timefin
if [ "$debug" = 1 ]; then
	echo "- Temps d execution:"
	echo $timeres
fi
uploadXML
