#!/bin/sh -e
# ========================================================================
# Note that InterSystems provides this script as an exxample of backups
# of a TrakCare system and does not support this script nor include it in
# the SLA. It is provided as a basis that sites may use as an example or
# extend it as required.
# ========================================================================

. `dirname $0`/snaplib.sh



backuperror=0


# run through mountpoint and unmount everything
heading "Unmounting everything below $MOUNTPOINT"
umountall "$MOUNTPOINT" || backuperror=$?


# remove snapshots (manual config)
heading "Remove LVM2 Snapshots"
for lv in \
	/dev/vg00/snap_trak_test \
	/dev/vg00/snap_trak_test_db \
	/dev/vg00/snap_trak_test_hsf \
	/dev/vg00/snap_trak_test_web \
	/dev/vg00/snap_trak_test_integration \
; do
	linuxlvremovesafe $lv || backuperror=$?
done

# Put in Backup History
#[ $backuperror -eq 0 ] && $CALLIN History _ALL
[ $backuperror -eq 0 ] && $CALLIN History HSAP2013

# sort the overall status
echo
exitwithstatus $backuperror


