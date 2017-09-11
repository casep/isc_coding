#!/usr/bin/perl
BEGIN { unshift @INC, "$ENV{TRAKAUTOMATIONDIR}/functions"; }	# should come from functions.sh
# This converts a Caché instance name to path
# Glen Pitt-Pladdy (ISC)
use strict;
use warnings;
require ISC::CacheInstances;




# check parameters
if ( @ARGV != 1 ) {
	die "$0: invalid arguments given\nUsage: $0 <instance>\n";
}
# get the object with the file loaded
my ( $instance ) = @ARGV;
# get the object
my $inst = new ISC::CacheInstances ();
if ( ! defined ( $inst ) ) { exit 1; }
# output
if ( ! exists ( $inst->{byname}->{$instance} ) ) {
	warn "$0: Caché instance matching name \"$instance\" not found\n";
	die "$0: invalid arguments given\nUsage: $0 <instance>\n";
}
print $inst->{byname}->{$instance}->{path}."\n";
