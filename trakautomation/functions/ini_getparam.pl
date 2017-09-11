#!/usr/bin/perl
BEGIN { unshift @INC, "$ENV{TRAKAUTOMATIONDIR}/functions"; }	# should come from functions.sh
# This parses a .ini format (Caché / CSP config), exiting the value of the specified parameter
# Glen Pitt-Pladdy (ISC)
# Usage: $0 <.ini file> <section> <parameter>
use strict;
use warnings;
require ISC::iniFile;




# check parameters
if ( @ARGV != 3 ) {
	die "$0: invalid arguments given\nUsage: $0 <.ini file> <section> <parameter>\n";
} elsif ( ! -f $ARGV[0] ) {
	warn "$0: file \"$ARGV[0]\" not found\n";
	die "$0: invalid arguments given\nUsage: $0 <.ini file> <section> <parameter>\n";
}
# get the object with the file loaded
my ( $file, $section, $parameter ) = @ARGV;
my $ini = new ISC::iniFile ( $file, 'r' );
if ( ! defined ( $ini ) ) { exit 1; }
# if the parameter exists then output it
if ( exists ( $ini->{parameters}->{$section}->{$parameter} ) ) {
	print $ini->{parameters}->{$section}->{$parameter}."\n";
	exit 0;
} else {
	warn __FILE__.": section \"$section\" parameter \"$parameter\" not found in \"$file\"\n";
	exit 1;
}



