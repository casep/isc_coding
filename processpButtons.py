#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  processpButtons.py
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
#  Process a pButtons file extracting VMStats and MGstats data
#  20141108, casep, Initil Release
#  20141110, casep, Compressed pButtons

import sys, os 						# OS thingies
import argparse as ap				# Prety arguments
import casepLib as csl				# Casep library!

def main():
	
	parser = ap.ArgumentParser( prog = 'processpButtons.py', 
	 description = 'process pButtons file',
	 formatter_class = ap.ArgumentDefaultsHelpFormatter )
	parser.add_argument( '--pButtonsFile' , 
	 help = 'vmstat CSV file' , 
	 type = str , default = 'mypButtons.hmtl' , 
	 required = True )
	parser.add_argument('--outputFolder',
	 help='Output folder',
	 type=str, required=True)
	args = parser.parse_args()

	outputFolder = csl.fixPath(args.outputFolder)
	if not os.path.exists(outputFolder):
		try:
			os.makedirs(outputFolder)
		except:
			print ''
			print 'Unable to create folder ' + outputFolder
			sys.exit()

	pButtonsFile = args.pButtonsFile
	pButtonsFileName = pButtonsFile[pButtonsFile.rindex(csl.returnPathCharacter())+1:]
	inFile = open(pButtonsFile)

	outFile = open(outputFolder+pButtonsFileName+'_mgstat.csv', "w")
	keepGoing = False
	
	for line in inFile:
		# If we reach the end exit
		if 'end_mgstat' in line:
			break

		if 'beg_mgstat' in line or keepGoing:
			# get rid of extra white spaces
			buffer = ' '.join(line.split()).replace(' ',',').replace(',,,',',,')
			# Cleaning the first line
			if 'beg_mgstat' in buffer:			
				next(inFile,None)
				keepGoing = True
				continue
			keepGoing = True
			# Cleaning the first ,
			outFile.write(buffer.replace(',,',',')+'\n')
	
	outFile.close()
	
	outFile = open(outputFolder+pButtonsFileName+'_vmstat.csv', "w")
	keepGoing = False
	for line in inFile:
		# If we reach the end exit
		if 'end_vmstat' in line:
			break

		if 'beg_vmstat' in line or keepGoing:
			# get rid of extra white spaces
			buffer = ' '.join(line.split()).replace(' ',',')
			# Cleaning the first line
			if 'beg_vmstat' in buffer:				
				buffer = buffer[buffer.index('<pre>')+5:]
				# Unix or Linux
				# Unix, 20 ,
				if buffer.count(',') == 20:
					buffer = buffer[1:len(buffer)-8]+'time'
				# Linux, 19 ,
				else:
					buffer = 'date,time'+buffer[buffer.index(',',10):]
			keepGoing = True
			# Cleaning the first ,
			outFile.write(buffer+'\n')
	
	inFile.close()
	outFile.close()


	return 0

if __name__ == '__main__':
	main()

