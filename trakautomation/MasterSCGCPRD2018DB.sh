#!/bin/sh -e
# This is an example master script using the tools created
# It expects HSAP-*.tar.gz to be in the same directory
export TMPDIR=/tmp
export SITE=scgc
export ENV=PRD
export VER=2018
export TYPE=DB
MONITORIP=10.20.0.12
#
# Various overrides exist to allow customisation of behaviour
# This section details those overrides
#
#
# Add custom enironment names - used in functions.sh
export EXTRAENVS=PLAY,SUPPORT,UPGRADE,DR
#
# Force a custom base path - used for non-standard paths. Expect hs*/ db/ web/ etc. below this
#export TRAKROOT=/trak/tc
#
# Set custom Users/Groups TODO this is largely untested - use with due caution
# Setting usersnames/groupnames to "!" disables them, but take care since it will break if they are actually needed
export CACHEUSR=cacheusr
export CACHEUSRID=2001
export TRAKSMB=!
export TRAKSMBID=3001
export CACHEBACKUP=cachebackup
export CACHEBACKUPID=2003
export CACHESYSUSR=cachesys
export CACHESYSUSRID=2002

export CACHEGRP=cachegrp
export CACHEGRPID=2001
export CACHEMGR=cachemgr
export CACHEMGRID=2002
export TRAKCACHE=!
export TRAKCACHEID=3002
export TRAKPRINT=cupsAdministrator
export TRAKPRINTID=3003

# bring in functions and defaults - this must be first!
. ./functions.sh
checkvars

# check for Package source
#./do_PackageCheck.sh

# check we are root
./do_rootCheck.sh

# check we have basic Perl available
./do_PerlCheck.sh

# pick up passwords if available (eg. test systems) else prompt
if [ -f /tmp/testcredentials ]; then
	# this should just be shell code exporting CACHEPASS and TRAKZIPPASS
	. /tmp/testcredentials
else
	echo
	# read in password for Caché - this will be inherited by all Caché installs in this script
	getpass "Cache Password to use" CACHEPASS
fi
export TRAKZIPPASS="not needed"

# set users/groups
./do_Users.sh

# stop messing about with Cache Terminal from wrong users
./do_UserEnv.sh

# Trak Directories
./do_Trak_dirs.sh

# SMR dirs - Scotland only
./do_TrakSMR_dirs.sh

# install standard utilities
./do_Utilities.sh

# snmpd
./do_SNMP.sh $MONITORIP

# cacti template config
./do_cacti_snmp.sh cacti-apache
./do_cacti_snmp.sh cacti-cups
./do_cacti_snmp.sh cacti-iostat
./do_cacti_snmp.sh cacti-processes+
./do_cacti_snmp.sh cacti-TCMon
./do_cacti_snmp.sh cacti-vmstat
./do_cacti_snmp.sh cacti-hugepages

# nagios
# IMPORTANT - this is not on the RH DVD so will install RPMs from RPMForge
# This is also not fully implimented (auto thershold calculation) so needs manually editing after install
./do_nagios-nrpe.sh $MONITORIP DB,PRT,WEB TODO-licenses TODO-episodes

# apache
./do_apache.sh
./do_apacheTune.sh

# samba
#./do_samba.sh WORKGROUP `hostname | cut -d. -f1` "Test Server" $SITE_UC

# install HS
echo HealthShare
./do_HSAP2017_Install.sh $SITE $ENV $TYPE$VER

# install license keys - without args does this for all instances found
./do_Environment_key.sh

# set HS config
# Usage: ./do_Environment_config.sh
# <Site Code> <Environment> <Type>[Version] <routine buffers in MiB> <global buffers in MiB> <lock table size in B> <gmheap in kiB>
# 1023MB 243000MB 128MB 512MB
# https://www.gbmb.org/kilobytes
./do_Environment_config.sh $SITE $ENV $TYPE$VER 1023 243000 134217728 524288

# printing & preview
./do_CUPS.sh
./do_FOPConf.sh $SITE $ENV $TYPE$VER 128m 128m
./do_PMSFonts.sh

# load in specific tools we need - NOTE: these will probably fail without licenses in place
./do_zCustom.CheckSNMP_Install.sh $TYPE
./do_zCustom.SnapBackup_Install.sh $TYPE

# do Trak install
./do_TrakVanillaT2018_Install.sh
./do_TrakCare2018_ApacheCSP.sh $TYPE

# SysAdminTasks (was TrakCareCustomTasks) / TCMon Stuff
./do_zCustom.TrakCareCustomTasks_Install.sh $TYPE

# Fix DB names. Instance will remain stoped 
./do_TrakVanillaT2018_FixUKDBNames.sh

# Huge Pages configuration
./do_hugePages.sh 129024

# set to auto-start
./do_SetAutostart.sh

# VMware hooks
./do_VMwareHandlers.sh

# Java SUN
./do_Java.sh

# Firewall configuration
./do_Firewall.sh 1972/tcp 80/tcp 443/tcp 57772/tcp 631/tcp 2188/tcp 111/tcp 111/udp 2049/tcp 2049/udp 111/tcp 111/udp 4001/tcp 4001/udp

# Fix SELinux permissions
./do_selinuxManage.sh

# ISCAgent
./do_ISCAgent.sh

# Patch GW
./do_CSPGW2018Upg.sh

# Patch adhoc
./do_Patch18375.sh

echo
echo Probably worth rebooting to ensure no memory fragmentation and test the config...

