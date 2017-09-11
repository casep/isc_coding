#!/usr/bin/python

import commands
import sys
import smtplib
import syslog

sidra=sys.argv[1][0:4]

fromaddr = '"Integrity Check" <casep@intersystems.com>'
toaddrs = '"Casep" <casep@intersystems.com>'
subject = "INTEGRITY ISSUE " + sidra
cacheusr = 'casep'
smtp_server='172.18.19.101'

commands.getstatusoutput('find /RESTORED/trak/'+sidra+' -name cache.lck|xargs rm -f')

if commands.getstatusoutput('ccontrol start ' + sidra)[0] == 0:
 comando="su - " + cacheusr +  " -c \"csession " + sidra + " -U\"USER\" \"zIntegridadBases\" | grep -v Node | grep -i " + sidra + "\""
 resultado=commands.getoutput(comando)
  
 msg = " " + resultado + " "
 m = "From: %s\r\nTo: %s\r\nSubject: %s\r\nX-Mailer: My-Mail\r\n\r\n" % (fromaddr, toaddrs, subject)

 commands.getoutput('sudo ccontrol stop ' + sidra + ' quietly')
  
 if resultado.find('0') > -1:
  s = smtplib.SMTP(smtp_server)
  s.sendmail(fromaddr, toaddrs, m+msg)
  s.quit()
  syslog.syslog(subject)
  sys.exit(2)
 else:
  syslog.syslog('Integrity Sidra '+ sidra + ' OK')
  sys.exit(0)

else:
 syslog.syslog('Error starting instance ' + sidra)
 sys.exit(1)
