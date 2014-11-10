#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  plotVMstat.py
#  
#  Copyright 2014 Carlos "casep" Sepulveda <casep@alumnos.inf.utfsm.cl>
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

import sys, os 						# OS thingies
import numpy as np					# Numpy can do anything
import matplotlib.pyplot as plt		# Ploting powa
import argparse as ap				# Prety arguments
import casepLib as csl				# Casep library!

def main():
	
	parser = ap.ArgumentParser( prog = 'plotVMstat.py', 
	 description = 'Plot VMstat main values',
	 formatter_class = ap.ArgumentDefaultsHelpFormatter )
	parser.add_argument( '--vmstatFile' , 
	 help = 'vmstat CSV file' , 
	 type = str , default = 'vmstat.csv' , 
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

	vmstatFile = args.vmstatFile
	vmstatFileName = vmstatFile[vmstatFile.rindex(csl.returnPathCharacter()):]
	data = np.genfromtxt(vmstatFile,dtype=None,names=True,delimiter=',')
	lenArray = len(data['us'])

	fig, ax = plt.subplots(1)
	fig.suptitle('US CPU Utilisation')
	ax.fill_between(np.arange(lenArray),0,data['us'], facecolor='blue', alpha=0.5)
	ax.set_ylim(0,100)
	ax.set_xlim(0,lenArray)
	ticks = np.arange(0,lenArray,lenArray/10,dtype=int)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+vmstatFileName+'_us.png')

	fig, ax = plt.subplots(1)
	fig.suptitle('IOWait CPU Utilisation')
	ax.fill_between(np.arange(lenArray),0,data['wa'], facecolor='red', alpha=0.5)
	ax.set_ylim(0,100)
	ax.set_xlim(0,lenArray)
	ticks = np.arange(0,lenArray,lenArray/10,dtype=int)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+vmstatFileName+'_wa.png')

	fig, ax = plt.subplots(1)
	fig.suptitle('b')
	ax.fill_between(np.arange(lenArray),0,data['b'], facecolor='green', alpha=0.5)
	ax.set_ylim(0,100)
	ax.set_xlim(0,lenArray)
	ticks = np.arange(0,lenArray,lenArray/10,dtype=int)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+vmstatFileName+'_b.png')

	fig, ax = plt.subplots(1)
	fig.suptitle('r')
	ax.fill_between(np.arange(lenArray),0,data['r'], facecolor='orange', alpha=0.5)
	ax.set_ylim(0,100)
	ax.set_xlim(0,lenArray)
	ticks = np.arange(0,lenArray,lenArray/10,dtype=int)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+vmstatFileName+'_r.png')

	plt.close('all')

	return 0

if __name__ == '__main__':
	main()

