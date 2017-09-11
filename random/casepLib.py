#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  
#  Copyright 2014 Carlos "casep" Sepulveda <casep@alumnos.inf.utfsm.cl>
#  casepLib.py
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
				
# Set of functions used on different codes of the project
# 

# Casep's random utilities 

import platform						# Windows or Linux?

#
# Is there a trailing / ?
#
def fixPath(folderName):
	pathCharacter = returnPathCharacter()
	# Check for trailing / on the folder
	if folderName[-1] != pathCharacter:
		folderName+=pathCharacter
	
	return folderName


#
# Determine which character use to path contatenation
# 
def returnPathCharacter():
	from platform import system				# Windows or Linux?

	pathCharacter = '/'
	if system() == 'Windows':
		pathCharacter = '\\'
	
	return pathCharacter
	
#
# Determine which character use for path contatenation
# 
def returnPathCharacter():
	pathCharacter = '/'
	if platform.system() == 'Windows':
		pathCharacter = '\\'
	
	return pathCharacter
