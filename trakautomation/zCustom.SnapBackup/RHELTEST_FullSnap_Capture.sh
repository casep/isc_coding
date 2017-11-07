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
lvcreate --size 1G --name snap_trak_test --snapshot /dev/vg00/trak_test || backuperror=$?
lvcreate --size 1G --name snap_trak_test_db --snapshot /dev/vg00/trak_test_db || backuperror=$?
lvcreate --size 1G --name snap_trak_test_hsf --snapshot /dev/vg00/trak_test_hsf || backuperror=$?
lvcreate --size 1G --name snap_trak_test_web --snapshot /dev/vg00/trak_test_web || backuperror=$?
lvcreate --size 1G --name snap_trak_test_integration --snapshot /dev/vg00/trak_test_integration || backuperror=$?

# thaw all write daemons
heading 'Thaw Cache'
$CALLIN Thaw _ALL || backuperror=$?

# mount all the snapshots (manual config)
heading "Mount Snapshots under $MOUNTPOINT"
makemount / $MOUNTPOINT -o bind || backuperror=$?
makemount /boot/ $MOUNTPOINT/boot/ -o bind || backuperror=$?
makemount /dev/vg00/snap_trak_test $MOUNTPOINT/trak/isc/TEST -o noatime || backuperror=$?
makemount /dev/vg00/snap_trak_test_db $MOUNTPOINT/trak/isc/TEST/db/ -o noatime || backuperror=$?
makemount /dev/vg00/snap_trak_test_hsf $MOUNTPOINT/trak/isc/TEST/hsf/ -o noatime || backuperror=$?
makemount /dev/vg00/snap_trak_test_web $MOUNTPOINT/trak/isc/TEST/web/ -o noatime || backuperror=$?
makemount /dev/vg00/snap_trak_test_integration $MOUNTPOINT/trak/isc/TEST/integration/ -o noatime || backuperror=$?

# TODO optionally put in integrity checks

# sort the overall status
echo
exitwithstatus $backuperror


