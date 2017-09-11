#!/bin/sh -e
# ========================================================================
# Note that InterSystems provides this script as an exxample of backups
# of a TrakCare system and does not support this script nor include it in
# the SLA. It is provided as a basis that sites may use as an example or
# extend it as required.
# ========================================================================

. `dirname $0`/snaplib.sh



backuperror=0

# check for things already mounted
if ! ismounted $MOUNTPOINT; then
	echo "ERROR - already mounts under \"$MOUNTPOINT\"" >&2
	exit 1
fi

# freeze all write daemons
heading 'Freeze Cache'
$CALLIN Freeze _ALL || backuperror=$?


heading 'Creating LVM2 Snapshots'
# create LVM Snapshots of all (manual config)
# IMPORTANT: The sizes have to be sufficient to track canges for the full time snapshots are in use
lvcreate --size 1G --name snap_trak_E2010 --snapshot /dev/vg00/trak_E2010 || backuperror=$?
lvcreate --size 1G --name snap_trak_HSAP2013 --snapshot /dev/vg00/trak_HSAP2013 || backuperror=$?
lvcreate --size 1G --name snap_trak_BASE --snapshot /dev/vg00/trak_BASE || backuperror=$?
lvcreate --size 1G --name snap_trak_BASE_hsf --snapshot /dev/vg00/trak_BASE_hsf || backuperror=$?
lvcreate --size 1G --name snap_trak_BASE_db --snapshot /dev/vg00/trak_BASE_db || backuperror=$?
#lvcreate --size 256M --name snap_trak_BASE_db --snapshot /dev/vg00/trak_BASE_db || backuperror=$?

# thaw all write daemons
heading 'Thaw Cache'
$CALLIN Thaw _ALL || backuperror=$?

# mount all the snapshots (manual config)
heading "Mount Snapshots under $MOUNTPOINT"
makemount /dev/vg00/snap_trak_E2010 $MOUNTPOINT/E2010 -o nouuid,noatime || backuperror=$?
makemount /dev/vg00/snap_trak_HSAP2013 $MOUNTPOINT/HSAP2013 -o nouuid,noatime || backuperror=$?
makemount /dev/vg00/snap_trak_BASE $MOUNTPOINT/BASE -o nouuid,noatime || backuperror=$?
makemount /dev/vg00/snap_trak_BASE_hsf $MOUNTPOINT/BASE/hsf -o nouuid,noatime || backuperror=$?
makemount /dev/vg00/snap_trak_BASE_db $MOUNTPOINT/BASE/db -o nouuid,noatime || backuperror=$?

# TODO optionally put in integrity checks

# sort the overall status
echo
exitwithstatus $backuperror


