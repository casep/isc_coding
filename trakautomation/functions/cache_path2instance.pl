#!/usr/bin/perl
BEGIN { unshift @INC, "$ENV{TRAKAUTOMATIONDIR}/functions"; }	# should come from functions.sh
# This converts a Caché instapnce path into name
# Glen Pitt-Pladdy (ISC)
use strict;
use warnings;
require ISC::CacheInstances;




# check parameters
if ( @ARGV != 1 ) {
	die "$0: invalid arguments given\nUsage: $0 <path>\n";
} elsif ( ! -d $ARGV[0] ) {
	warn "$0: path \"$ARGV[0]\" not found\n";
	die "$0: invalid arguments given\nUsage: $0 <path>\n";
}
# get the object with the file loaded
my ( $path ) = @ARGV;
# get the object
my $inst = new ISC::CacheInstances ();
if ( ! defined ( $inst ) ) { exit 1; }
# output
if ( ! exists ( $inst->{bypath}->{$path} ) ) {
	warn "$0: Caché inscance matching path \"$path\" not found\n";
	die "$0: invalid arguments given\nUsage: $0 <path>\n";
}
print $inst->{bypath}->{$path}->{name}."\n";
