#!/usr/bin/perl
BEGIN { unshift @INC, "$ENV{TRAKAUTOMATIONDIR}/functions"; }	# should come from functions.sh
# This parses the cache.key file specified and outputs a Unix Epoc of the expiry date
# Glen Pitt-Pladdy (ISC)
# Usage: $0 <path to cache.key>
use strict;
use warnings;
require ISC::iniFile;
use POSIX;




# check parameters
if ( @ARGV !=1  or ! -f $ARGV[0] ) {
	die "$0: invalid arguments given\nUsage: $0 <path to cache.key>\n";
}
# get the object with the file loaded
my ( $file ) = @ARGV;
my $ini = new ISC::iniFile ( $file, 'r' );
if ( ! defined ( $ini ) ) { exit 1; }
# if the parameter doesn't exist then bail
if ( ! $ini->{parameters}->{License}->{ExpirationDate} ) {
	warn __FILE__.": section \"License\" parameter \"ExpirationDate\" not found in \"$file\"\n";
	exit 1;
}
# verify the format
if ( $ini->{parameters}->{License}->{ExpirationDate} !~ /^(\d+)\/(\d+)\/(\d+)$/ ) {
	warn __FILE__.": section \"License\" parameter \"ExpirationDate\" invalid \"$ini->{parameters}->{License}->{ExpirationDate}\" in \"$file\"\n";
	exit 1;
}
# convert
if ( $3 >= 2038 ) {
	# POSIX 32-bit calculations might be broken due to rollover
	print ( (2**32-1)."\n" );
	warn __FILE__.':'.__LINE__." Risk of POSIX 32-bit rollover occuring with these dates - using hard coded limit\n";
} else {
	print POSIX::mktime ( 0,0,0, $2, $1 - 1, $3 - 1900 )."\n";
}



