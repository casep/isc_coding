#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  checkShadow.py 
#  
#  Copyright 2015 Carlos "casep" Sepulveda <carlos.sepulveda@gmail.com>
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
#  This routine check the status of the Shadow (Latency)
# Negative Latency or high latency raise an exception

import commands
import sys
import smtplib
import argparse

parser = argparse.ArgumentParser(prog='checkShadow.py',
 description='Check Latency for a Shadow',
 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('--instance',
 help='Instance Name',
 type=str, required=True)
parser.add_argument('--shadow',
 help='Shadow',
 type=str, required=True)
args=parser.parse_args()
instance=args.instance
shadow=args.shadow

fromaddr = '"Shadow Problem" <monitoreo@intersystems.com>'
toaddrs = '"Datacenter_Chile" <Datacenter_Chile@intersystems.com>'
subject = 'Shadow problem on instance '+instance
smtp_server='172.18.19.101'
thresholdValue=100

comando='csession '+instance+' -U\"%SYS\" \"getLatency^UCheckShadow(\\"'+shadow+'\\")\" '
try:
	resultado=float(commands.getoutput(comando))
except ValueError:
	print 'Ups, something funny going on'
	msg=' OMG WTF! Check the darn routine '
	m = "From: %s\r\nTo: %s\r\nSubject: %s\r\nX-Mailer: My-Mail\r\n\r\n" % (fromaddr, toaddrs, subject)
	s = smtplib.SMTP(smtp_server)
	s.sendmail(fromaddr, toaddrs, m+msg)
	s.quit()
	sys.exit(2)

if resultado>thresholdValue or resultado==-1:
	print 'Problem with shadow'
	msg = ' Problem with Shadow \"'+shadow+'\" on Instance \"'+instance+'\"'
	m = "From: %s\r\nTo: %s\r\nSubject: %s\r\nX-Mailer: My-Mail\r\n\r\n" % (fromaddr, toaddrs, subject)
	s = smtplib.SMTP(smtp_server)
	s.sendmail(fromaddr, toaddrs, m+msg)
	s.quit()
	sys.exit(1)
else:
	print 'Everything OK'	
	sys.exit(0)
