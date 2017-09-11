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
	/dev/vg_trak/snap_lv_hs \
	/dev/vg_trak/snap_lv_jrn_pri \
	/dev/vg_trak/snap_lv_jrn_alt \
	/dev/vg_trak/snap_lv_perforce \
	/dev/vg_trak/snap_lv_store \
	/dev/vg_trak/snap_lv_web \
	/dev/vg_trak/snap_lv_db \
	/dev/vg_lab/snap_lv_hs \
	/dev/vg_lab/snap_lv_jrn_pri \
	/dev/vg_lab/snap_lv_jrn_alt \
	/dev/vg_lab/snap_lv_db \
	/dev/vg_analytics/snap_lv_hs \
	/dev/vg_analytics/snap_lv_jrn_pri \
	/dev/vg_analytics/snap_lv_jrn_alt \
	/dev/vg_analytics/snap_lv_db \
	/dev/vg_integration/snap_lv_hs \
	/dev/vg_integration/snap_lv_jrn_pri \
	/dev/vg_integration/snap_lv_jrn_alt \
	/dev/vg_integration/snap_lv_db \
; do
	linuxlvremovesafe $lv || backuperror=$?
done

# Put in Backup History
[ $backuperror -eq 0 ] && $CALLIN History _ALL

# sort the overall status
echo
exitwithstatus $backuperror


