#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  plotVMstat.py
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

import sys, os 						# OS thingies
import numpy as np					# Numpy can do anything
import matplotlib.pyplot as plt		# Ploting powa
import argparse as ap				# Prety arguments
import casepLib as csl				# Casep library!

def main():
	
	parser = ap.ArgumentParser( prog = 'plotMGstat.py', 
	 description = 'Plot MGstat main values',
	 formatter_class = ap.ArgumentDefaultsHelpFormatter )
	parser.add_argument( '--mgstatFile' , 
	 help = 'vmstat CSV file' , 
	 type = str , default = 'mgstat.csv' , 
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

	mgstatFile = args.mgstatFile
	mgstatFileName = mgstatFile[mgstatFile.rindex(csl.returnPathCharacter())+1:]
	# dots are evil for LaTeX
	mgstatFileName = mgstatFileName[:mgstatFileName.rindex('.')]

	data = np.genfromtxt(mgstatFile,dtype=None,names=True,delimiter=',')
	lenArray = len(data['Time'])
	ticks = np.arange(0,lenArray,lenArray/10,dtype=int)
	
	fig, ax = plt.subplots(1)
	fig.suptitle('Globals references')
	ax.fill_between(np.arange(lenArray),0,data['Glorefs'], facecolor='blue', alpha=0.5)
	ax.set_xlim(0,lenArray)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['Time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+mgstatFileName+'_Glorefs.png')

	fig, ax = plt.subplots(1)
	fig.suptitle('Remote Globals references')
	ax.fill_between(np.arange(lenArray),0,data['RemGrefs'], facecolor='blue', alpha=0.5)
	ax.set_xlim(0,lenArray)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['Time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+mgstatFileName+'_RemGrefs.png')

	fig, ax = plt.subplots(1)
	fig.suptitle('GRratio')
	ax.fill_between(np.arange(lenArray),0,data['GRratio'], facecolor='blue', alpha=0.5)
	ax.set_xlim(0,lenArray)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['Time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+mgstatFileName+'_GRratio.png')

	fig, ax = plt.subplots(1)
	fig.suptitle('PhyRds')
	ax.fill_between(np.arange(lenArray),0,data['PhyRds'], facecolor='blue', alpha=0.5)
	ax.set_xlim(0,lenArray)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['Time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+mgstatFileName+'_PhyRds.png')

	fig, ax = plt.subplots(1)
	fig.suptitle('Globals Updates')
	ax.fill_between(np.arange(lenArray),0,data['Gloupds'], facecolor='blue', alpha=0.5)
	ax.set_xlim(0,lenArray)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['Time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+mgstatFileName+'_Gloupds.png')
	
	fig, ax = plt.subplots(1)
	fig.suptitle('Physical Writes')
	ax.fill_between(np.arange(lenArray),0,data['PhyWrs'], facecolor='blue', alpha=0.5)
	ax.set_xlim(0,lenArray)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['Time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+mgstatFileName+'_PhyWrs.png')
	
	fig, ax = plt.subplots(1)
	fig.suptitle('Write Daemon Queue Size')
	ax.fill_between(np.arange(lenArray),0,data['WDQsz'], facecolor='blue', alpha=0.5)
	ax.set_xlim(0,lenArray)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['Time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+mgstatFileName+'_WDQsz.png')
	
		
	fig, ax = plt.subplots(1)
	fig.suptitle('Write Daemon Phase')
	ax.fill_between(np.arange(lenArray),0,data['WDphase'], facecolor='blue', alpha=0.5)
	ax.set_xlim(0,lenArray)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['Time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+mgstatFileName+'_WDphase.png')
	
	fig, ax = plt.subplots(1)
	fig.suptitle('WIJ write')
	ax.fill_between(np.arange(lenArray),0,data['WIJwri'], facecolor='blue', alpha=0.5)
	ax.set_xlim(0,lenArray)
	ax.set_xticks(ticks)
	ax.set_xticklabels(data['Time'][ticks],rotation='vertical', fontsize=8)
	plt.grid(True)
	plt.savefig(outputFolder+mgstatFileName+'_WIJwri.png')
	
	plt.close('all')

	return 0

if __name__ == '__main__':
	main()

