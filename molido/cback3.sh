#!/bin/sh 
#
#  cback3.sh
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
#  Simple backup script for Cache
#  
#  Based on the one used by US Tech Help
#  Minor tidying up 

CLEANUPMONTHLY=0
CHECKFORDR=0
DRMODE="/etc/admin/drmode.active"
DAYSTOKEEP=7
SECONDARYDC="va.intersystems.com"
NFSSOURCE="uk-dc01-emc-dd-01"
ALERTEMAIL="ukhosting@intersystems.com"
BACKUPDIR="/backup"
STATUSFILE="/tmp/backupstatus.txt"

SCRIPTSTART="`date`"
NOWDATE="`date +%Y%m%d`"
HOST="`hostname`"
ERROR=0
RSYNCPARAMS="-auvz"
TAPELISTCHECK="/etc/admin/CacheUtil/TapeList.pl"
TAPELISTCHECKOUT="/etc/admin/CacheUtil/TapeList.pl.cback3.sh.out"
RESOLVFILE="/etc/resolv.conf"

#Everybody loves alerts
function alertEmails {
     totalT="$(($(date +%s)-startT))"    
     if [ $ERROR -ne 0 ] ; then
          /bin/echo "BACKUP FAILURE on ${HOSTNAME}. ${ERRMSG}" | /bin/mailx -s "${HOSTNAME} Backup Problem" ${ALERTEMAIL}
          /bin/echo "0,${INSTANCE},${HOSTNAME},${ERRMSG},`date +%s`,0" >> ${STATUSFILE}
     elif [ ! -f ${LOGFILE} ] ; then
          /bin/echo "Missing backup log file for ${INSTANCE} on ${HOSTNAME} : ${NOWDATE}" | /bin/mailx -s "${INSTANCE} on ${HOSTNAME} Backup Problem!" ${ALERTEMAIL}
          /bin/echo "0,${INSTANCE},${HOSTNAME},Missing backup log file,`date +%s`,0" >> ${STATUSFILE}
     else
          /bin/grep "***FINISHED BACKUP***" ${LOGFILE} > /dev/null 2>&1
          if [ $? -eq 0 ]; then
               /bin/echo "BACKUP OKAY on ${INSTANCE} on ${HOSTNAME} : ${NOWDATE}" | /bin/mailx -s "${INSTANCE} on ${HOSTNAME} Backup Finished-Backup *OKAY*" ${ALERTEMAIL}
               /bin/echo "1,${INSTANCE},${HOSTNAME},BACKUP OK,`date +%s`,${totalT}" >> ${STATUSFILE}
          else
               /bin/echo "BACKUP FAILURE on ${INSTANCE} on ${HOSTNAME} : ${NOWDATE}" | /bin/mailx -s "${INSTANCE} on ${HOSTNAME} Backup Failure" ${ALERTEMAIL}
               /bin/echo "0,${INSTANCE},${HOSTNAME},BACKUP FAILURE,`date +%s`,0" >> ${STATUSFILE}
          fi
     fi
}

#The function that actually perform the backup
function cacheBackup {
	/usr/bin/rsync ${RSYNCPARAMS} ${DIR}/mgr/cachelib/CACHE.DAT ${BACKUPDIR}/${INSTANCE}/cachelibdb/CACHE.DAT

	SUBJECT="Full Cache Backup for ${INSTANCE} for ${NOWDATE}"
	BACKUPFILE="${BACKUPDIR}/${INSTANCE}/${NOWDATE}${INSTANCE}.cbk"
	LOGFILE="${BACKUPDIR}/${INSTANCE}/LOG${NOWDATE}${INSTANCE}.log"

     csession ${INSTANCE} -U%SYS <<-EOF
     set start =\$PIECE(\$HOROLOG,",",2)
     write "Start Time: "_\$ZTIME(start)
     do BACKUP^DBACK("","F","${SUBJECT}","${BACKUPFILE}","","${LOGFILE}","NOINPUT")
     set end = \$PIECE(\$HOROLOG,",",2)
     write "Finish Time: "_\$ZTIME(end)
     write "Total Time: "_\$ZTIME(end-start)
     set filename = "${BACKUPDIR}/${INSTANCE}/backupdirlist.txt"
     write filename
     set file = ##class(%Library.File).%New(filename)
     do file.Open("WSN")
     set rset=##class(%Library.ResultSet).%New("Backup.General:DatabaseList")
     do rset.Execute()
     while rset.Next() {set DBdir=rset.Data("Directory")  set line=DBdir_","_DBdir_",Y"  do file.WriteLine(line) }
     do file.Close()
     h
EOF

alertEmails
}

#Auxiliary function to create required dirs
function makeDirs {
     /bin/mkdir -pv ${BACKUPDIR}/${INSTANCE}/{monthly,archive,cachelibdb}
}

#Re-arrange the available backups into archive folders
function mvCacheBackups {
	#NetWorker compatibility
	/bin/cat > ${BACKUPDIR}/${INSTANCE}/archive/.nsr << \EOF
<< . >>
               +skip: .
EOF
	/bin/find ${BACKUPDIR}/${INSTANCE}/ -maxdepth 1 -type f -mtime +1 \( -name '2*01[A-Z]*.cbk' -o -name 'LOG2*01[A-Z]*.log' \) -exec mv -v {} ${BACKUPDIR}/${INSTANCE}/monthly/ \;
	/bin/find ${BACKUPDIR}/${INSTANCE}/ -maxdepth 1 -type f -mtime +1 \( -name '2*[A-Z]*.cbk' -o -name 'LOG2*[A-Z]*.log' \) -exec mv -v {} ${BACKUPDIR}/${INSTANCE}/archive/ \;
}

#Clean old backups
function rmOldCacheBackup {
	/bin/find ${BACKUPDIR}/${INSTANCE}/archive/ -maxdepth 1 -type f -mtime +${DAYSTOKEEP} \( -name '2*[A-Z]*.cbk' -o -name 'LOG2*[A-Z]*.log' \) -exec rm -fv {} \;
}

#Function used to check the existance of the backup on the Tape system (US)
function cleanUpMonthly {
	if [ -d ${BACKUPDIR}/${INSTANCE}/monthly/ ]; then
		/bin/find ${BACKUPDIR}/${INSTANCE}/monthly/ -maxdepth 1 -type f \( -name '2*01[A-Z]*.cbk' -o -name 'LOG2*01[A-Z]*.log' \) -exec ls -l {} \; | /bin/awk -F\  '{ print $9 }' | while read CBKFILE; do
			${TAPELISTCHECK} ${CBKFILE} >> ${TAPELISTCHECKOUT}
			${TAPELISTCHECK} ${CBKFILE}|/bin/grep -i monthly
			MONTHLYRESULT=$?
			/bin/echo "MONTHLYRESULT: "${MONTHLYRESULT}
			if [ ${MONTHLYRESULT} = 0 ]; then
				/bin/echo "${CBKFILE} on monthly tape"
				mv ${CBKFILE} ${BACKUPDIR}/${INSTANCE}/archive/
			else
				/bin/find ${CBKFILE} -maxdepth 1 -type f -mtime +15 -exec /bin/echo {} \; | /bin/grep cbk > /dev/null
				if [ $? = 0 ]; then
					/bin/echo "Cache Online Backup - Monthly Tape Warning: ${CBKFILE} is more than 15 days old and is not on a monthly backup tape.  ${NOWDATE}" | /bin/mailx -s "Cache Online Backup - Monthly Tape Warning ${NOWDATE}" ${ALERTEMAIL}
				fi
				/bin/echo "${CBKFILE} not on monthly tape"
			fi
          done
fi
}

#Horrible inherited hack, not sure why, maybe a NetWorker thing
n=$RANDOM
hangTime=$(( n %= 60 ))
/bin/sleep $hangTime

rm -fv ${STATUSFILE}

#DR and backup disabled
if [ ${CHECKFORDR} == 1 ]; then
	/bin/grep ${SECONDARYDC} ${RESOLVFILE} >/dev/null
	if [ $? -eq 0 ] && [ ! -f ${DRMODE} ]; then
		/bin/echo
		/bin/echo "    Host is in SECONDARY DC - ${HOSTNAME} AND DR Active Flag is not enabled. No backup required."
		/bin/echo
		/bin/echo "**************************************"                                                                                                              
		/bin/echo "**************************************"
		/bin/echo                                                                                                                                                       
		exit 0
	fi 
fi

#Is Cache installed?
which /bin/ccontrol > /dev/null 2>&1
if [ $? -ne 0 ]; then
	/bin/echo
	/bin/echo "    Warning - Cache not installed on ${HOSTNAME}"
	/bin/echo
	/bin/echo "**************************************"
	/bin/echo "**************************************"
	/bin/echo
	exit 1
fi

#Should we backup this machine
if  [[ "$HOST" == *query ]]; then
	/bin/echo
	/bin/echo "    Query Machine Detected - Do not backup - ${HOSTNAME}"
	/bin/echo
	/bin/echo "**************************************"
	/bin/echo "**************************************"
	/bin/echo
	exit 0
fi

#Is the Backup folder created?
if [ ! -d ${BACKUPDIR} ]; then
	/bin/mkdir ${BACKUPDIR}
	if [ ! -d ${BACKUPDIR} ]; then
		/bin/echo
		/bin/echo "    Fatal Error - Can't access ${BACKUPDIR} on ${HOST}"
		ls -lad ${BACKUPDIR}
		/bin/echo
		ERROR=1
		ERRMSG="    Fatal Error - Can't access ${BACKUPDIR} on ${HOST}"
		alertEmails
		exit 1
	fi
fi

#Can I mount the NFS resource?
/bin/df ${BACKUPDIR} | /bin/grep ${NFSSOURCE} > /dev/null
result=$?
if [ ${result} -eq 1 ]; then
	/bin/mount ${BACKUPDIR}
fi

#Is the NFS resource available?
/bin/df ${BACKUPDIR} | /bin/grep ${NFSSOURCE} > /dev/null
result=$?
if [ ${result} -eq 1 ]; then
	/bin/echo "Fatal error: Unable to mount ${BACKUPDIR}!"
	ERROR=1
	ERRMSG="Fatal error: Unable to mount ${BACKUPDIR} on ${HOSTNAME}"
	alertEmails
fi

/bin/echo
/bin/echo "Instances Installed: "
/bin/ccontrol qlist | /bin/awk -F\^ '{ print $1 }'
/bin/echo
/bin/echo
/bin/echo "Instances Running: "
/bin/ccontrol qlist | /bin/grep running | /bin/awk -F\^ '{ print $1 }'
/bin/echo
/bin/echo
/bin/echo "Instances Not-Backed-up: "
/bin/ccontrol qlist | /bin/grep -v running | /bin/awk -F\^ '{ print $1 }' | while read NOTRUNNING; do
	/bin/echo "0,${NOTRUNNING},${HOSTNAME},NOT RUNNING,`date +%s`,0" >> ${STATUSFILE}
done
/bin/echo
/bin/echo

if [ ${ERROR} -ne 0 ]; then
    /bin/echo
    /bin/echo "    Warning - Error detected - Stopping backup attempt - ${HOSTNAME}"
    /bin/echo
    /bin/echo "**************************************"
    /bin/echo "**************************************"
    /bin/echo
	exit 1
fi

/bin/ccontrol qlist | /bin/awk -F'^' '{ print $1" "$2" "$4 }'| while read INSTANCE DIR RUNNING; do
    /bin/echo
    makeDirs
    mvCacheBackups
    if [[ ${RUNNING} == *"running"* ]]; then
        startT="$(date +%s)" 
        /bin/echo "    Backing up instance ${INSTANCE} now"
        cacheBackup  
    else
        /bin/echo "    Cleaning up DOWN instance ${INSTANCE} now"
    fi
    /bin/echo
    rmOldCacheBackup
    if [ ${CLEANUPMONTHLY} == 1 ]; then
        cleanUpMonthly
    fi
done

#Is the script tired?
/bin/sleep 10

/bin/echo
/bin/echo "    Backup script completed"
/bin/echo
/bin/echo "    Hostname:    ${HOST}"
/bin/echo "    Start date:  ${SCRIPTSTART}"
/bin/echo "    End date:    `date`"
/bin/echo "**************************************"
/bin/echo "**************************************"
/bin/echo
 
exit 0
