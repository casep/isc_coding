#!/usr/bin/perl
BEGIN { unshift @INC, "$ENV{TRAKAUTOMATIONDIR}/functions"; }	# should come from functions.sh
# This will take the filesytem as a prameter and output relevant info, one per line
# Glen Pitt-Pladdy (ISC)
use strict;
use warnings;
require ISC::MountInfo;


# check parameters
if ( @ARGV != 1 ) {
	die "$0: invalid arguments given\nUsage: $0 <directory>\n";
} elsif ( ! -d $ARGV[0] ) {
	warn "$0: file \"$ARGV[0]\" not found\n";
	die "$0: invalid arguments given\nUsage: $0 <directory>\n";
}


# Get class online
my $mount = new ISC::MountInfo ();
if ( ! defined ( $mount ) ) { die "$0: failed to create \$mount object\n"; }

# output info
my ( $mountpoint, $info ) = $mount->mountinfo ( $ARGV[0] );
print "mount:$mountpoint\n";
print "device:$info->{device}\n";
print "filesystem:$info->{filesystem}\n";
print "options:$info->{options}\n";


