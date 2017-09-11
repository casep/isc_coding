#!/usr/bin/perl
BEGIN { unshift @INC, "$ENV{TRAKAUTOMATIONDIR}/functions"; }	# should come from functions.sh
# This provides a list of available Caché instances
# Glen Pitt-Pladdy (ISC)
use strict;
use warnings;
require ISC::CacheInstances;




# get the object
my $inst = new ISC::CacheInstances ();
if ( ! defined ( $inst ) ) { exit 1; }
# output
foreach (sort keys ( %{$inst->{bysuperserverport}} )) {
	if ( $inst->{bysuperserverport}->{$_}->{present} ) {
		print "$inst->{bysuperserverport}->{$_}->{name}\n";
	}
}
