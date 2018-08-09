#!/bin/sh -e
# This is an example master script using the tools created
# It expects HSAP-*.tar.gz to be in the same directory
export TMPDIR=/trak/iscbuild/tmp
export SITE=schl
export ENV=TRAIN
export VER=2016
export TYPE=DB
MONITORIP=10.111.3.166
#
# Various overrides exist to allow customisation of behaviour
# This section details those overrides
#
#
# Add custom enironment names - used in functions.sh
# export EXTRAENVS=PLAY,SUPPORT
#
# Force a custom base path - used for non-standard paths. Expect hs*/ db/ web/ etc. below this
export TRAKROOT=/trak/schlTRN/tc
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
export TRAKPRINTID=2003

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
	getpass "Caché Password to use" CACHEPASS
	# read in the password for the TrakCare .zip
	#getpass "TrakCare .zip Password" TRAKZIPPASS
	#echo
fi
export TRAKZIPPASS="not needed"

# disable SELINUX
#./do_SELINUXdisable.sh

# set users/groups
./do_Users.sh

# stop messing about with Caché Terminal from wrong users
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
./do_HSAP2015_Install.sh $SITE $ENV $TYPE$VER

# install license keys - without args does this for all instances found
./do_Environment_key.sh

# set HS config
# Usage: ./do_Environment_config.sh
# <Site Code> <Environment> <Type>[Version] <routine buffers in MiB> <global buffers in MiB> <lock table size in B> <gmheap in kiB>
# https://www.gbmb.org/megabytes
# DB 2016 1000MB 4000MB 32MB 128MB
./do_Environment_config.sh $SITE $ENV $TYPE$VER 1000 4000 33554432 131072

# printing & preview
./do_CUPS.sh
./do_FOPConf.sh $SITE $ENV $TYPE$VER 256m 256m

# do Trak install
./do_TrakVanillaT2016_Install.sh
./do_TrakCare2016_ApacheCSP.sh $TYPE

# load in specific tools we need - NOTE: these will probably fail without licenses in place
./do_zCustom.CheckSNMP_Install.sh $TYPE
./do_zCustom.SnapBackup_Install.sh $TYPE

# SysAdminTasks (was TrakCareCustomTasks) / TCMon Stuff
./do_zCustom.TrakCareCustomTasks_Install.sh $TYPE

# Huge Pages configuration
./do_hugePages.sh 3300

# Fonts for barcodes
./do_PMSFonts.sh

# set to auto-start
./do_SetAutostart.sh

echo
echo Probably worth rebooting to ensure no memory fragmentation and test the config...

