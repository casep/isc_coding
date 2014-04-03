#!/usr/bin/python
#Casep, 20120628, primera version

import commands
import sys
import smtplib

fromaddr = '"Automatic load monitoring" <casep@intersystems.com>'
#toaddrs = '"Alerts DC-CHILE" <alerts_dc_chile@intersystems.com>'
toaddrs = '"Casep" <casep@intersystems.com'
subject = "Load Issue on " + commands.getoutput("/usr/bin/hostname")
cacheusr = 'casep'
smtp_server='172.18.19.101'

#Este caso es cuanod es otro usuario
#comando="su - " + cacheusr +  " -c \"csession sdapp -U\"USER\" \"UInvocaMtop\" \" "
comando="csession sdapp -U\"USER\" \"UInvocaMtop\" "
resultado=commands.getoutput(comando)
  
msg = " " + resultado + " "
m = "From: %s\r\nTo: %s\r\nSubject: %s\r\nX-Mailer: My-Mail\r\n\r\n" % (fromaddr, toaddrs, subject)

s = smtplib.SMTP(smtp_server)
s.sendmail(fromaddr, toaddrs, m+msg)
s.quit()
sys.exit(2)

