#!/usr/bin/perl
BEGIN { unshift @INC, "$ENV{TRAKAUTOMATIONDIR}/functions"; }	# should come from functions.sh
# This will take all paltform parameters and output script to set these as environment variables
# The tyypical way this will be used is: eval `Platform2ENV.pl`
# Glen Pitt-Pladdy (ISC)
use strict;
use warnings;
require ISC::PlatformDetect;



# if environment variables already exist then skip - no point in repeating
if ( exists ( $ENV{PLATFORM_OShierarchy} ) and exists ( $ENV{PLATFORM_OStry} ) ) {
	exit 0;
}


# get the object with the file loaded
my $platform = new ISC::PlatformDetect ();
if ( ! defined ( $platform ) ) { exit 1; }
# output as shell variables that can be eval'd
print "PLATFORM_OShierarchy=\"".join(' ',@{$platform->{OShierarchy}})."\"; export PLATFORM_OShierarchy;\n";
print "PLATFORM_OStry=\"".join(' ',@{$platform->{OStry}})."\"; export PLATFORM_OStry;\n";
foreach ('processor','cpus','bits','system','virtual','memory') {
	if ( ! defined ( $platform->{$_} ) ) { next; }
	print "PLATFORM_$_=\"".$platform->{$_}."\"; export PLATFORM_$_;\n";
}





