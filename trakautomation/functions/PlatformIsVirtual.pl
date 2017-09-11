#!/usr/bin/perl
BEGIN { unshift @INC, "$ENV{TRAKAUTOMATIONDIR}/functions"; }	# should come from functions.sh
# Return 0 if Virtualised, 1 otherwise, 2 on error, plus platform string on STDOUT
# Glen Pitt-Pladdy (ISC)
use strict;
use warnings;
require ISC::PlatformDetect;




# get the object with the file loaded
my $platform = new ISC::PlatformDetect ();
if ( ! defined ( $platform ) ) { exit 2; }
# check what we have
print $platform->{system}."\n";
if ( $platform->{virtual} ) {
	exit 0;
} else {
	exit 1;
}






