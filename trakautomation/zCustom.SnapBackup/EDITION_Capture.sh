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
# create LVM Snapshots of all (auto config)
[ -b /dev/vg_trak/lv_hs ] && lvcreate --size 512M --name snap_lv_hs --snapshot /dev/vg_trak/lv_hs
[ -b /dev/vg_trak/lv_jrn_pri ] && lvcreate --size 1G --name snap_lv_jrn_pri --snapshot /dev/vg_trak/lv_jrn_pri
[ -b /dev/vg_trak/lv_jrn_alt ] && lvcreate --size 512M --name snap_lv_jrn_alt --snapshot /dev/vg_trak/lv_jrn_alt
[ -b /dev/vg_trak/lv_db ] && lvcreate --size 2G --name snap_lv_db --snapshot /dev/vg_trak/lv_db
[ -b /dev/vg_trak/lv_perforce ] && lvcreate --size 512M --name snap_lv_perforce --snapshot /dev/vg_trak/lv_perforce
[ -b /dev/vg_trak/lv_store ] && lvcreate --size 1G --name snap_lv_store --snapshot /dev/vg_trak/lv_store
[ -b /dev/vg_trak/lv_web ] && lvcreate --size 512M --name snap_lv_web --snapshot /dev/vg_trak/lv_web
[ -b /dev/vg_lab/lv_hs ] && lvcreate --size 512M --name snap_lv_hs --snapshot /dev/vg_lab/lv_hs
[ -b /dev/vg_lab/lv_jrn_pri ] && lvcreate --size 512M --name snap_lv_jrn_pri --snapshot /dev/vg_lab/lv_jrn_pri
[ -b /dev/vg_lab/lv_jrn_alt ] && lvcreate --size 512M --name snap_lv_jrn_alt --snapshot /dev/vg_lab/lv_jrn_alt
[ -b /dev/vg_lab/lv_db ] && lvcreate --size 1G --name snap_lv_db --snapshot /dev/vg_lab/lv_db
[ -b /dev/vg_integration/lv_hs ] && lvcreate --size 512M --name snap_lv_hs --snapshot /dev/vg_integration/lv_hs
[ -b /dev/vg_integration/lv_jrn_pri ] && lvcreate --size 512M --name snap_lv_jrn_pri --snapshot /dev/vg_integration/lv_jrn_pri
[ -b /dev/vg_integration/lv_jrn_alt ] && lvcreate --size 512M --name snap_lv_jrn_alt --snapshot /dev/vg_integration/lv_jrn_alt
[ -b /dev/vg_integration/lv_db ] && lvcreate --size 1G --name snap_lv_db --snapshot /dev/vg_integration/lv_db
[ -b /dev/vg_analytics/lv_hs ] && lvcreate --size 512M --name snap_lv_hs --snapshot /dev/vg_analytics/lv_hs
[ -b /dev/vg_analytics/lv_jrn_pri ] && lvcreate --size 1G --name snap_lv_jrn_pri --snapshot /dev/vg_analytics/lv_jrn_pri
[ -b /dev/vg_analytics/lv_jrn_alt ] && lvcreate --size 512M --name snap_lv_jrn_alt --snapshot /dev/vg_analytics/lv_jrn_alt
[ -b /dev/vg_analytics/lv_db ] && lvcreate --size 4G --name snap_lv_db --snapshot /dev/vg_analytics/lv_db

# thaw all write daemons
heading 'Thaw Cache'
$CALLIN Thaw _ALL || backuperror=$?

# mount all the snapshots (manual config)
heading "Mount Snapshots under $MOUNTPOINT"
makemount / $MOUNTPOINT -o bind || backuperror=$?
makemount /boot/ $MOUNTPOINT/boot/ -o bind || backuperror=$?
makemount /home/ $MOUNTPOINT/home/ -o bind || backuperror=$?
makemount /tmp/ $MOUNTPOINT/tmp/ -o bind || backuperror=$?
makemount /trak/ $MOUNTPOINT/trak/ -o bind || backuperror=$?
makemount /var/ $MOUNTPOINT/var/ -o bind || backuperror=$?
makemount /var/spool/ $MOUNTPOINT/var/spool/ -o bind || backuperror=$?

while read line; do
	if echo $line | grep -qv ' /trak/..xx'; then continue; fi
	lv=`echo $line | cut -d' ' -f1`
	mountpoint=`echo $line | cut -d' ' -f2`
	snaplv=`echo $lv | sed 's/-lv_/-snap_lv_/'`
	makemount $snaplv $MOUNTPOINT/$mountpoint -o ro || backuperror=$?
done </proc/mounts

# sort the overall status
echo
exitwithstatus $backuperror


