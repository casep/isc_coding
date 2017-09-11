#!/usr/bin/perl
BEGIN { unshift @INC, "$ENV{TRAKAUTOMATIONDIR}/functions"; }	# should come from functions.sh
# This parses a .ini format (Caché / CSP config), listing the section headers
# Glen Pitt-Pladdy (ISC)
# Usage: $0 <.ini file>
use strict;
use warnings;
require ISC::iniFile;




# check parameters
if ( @ARGV != 1  or ! -f $ARGV[0] ) {
	die "$0: invalid arguments given\nUsage: $0 <.ini file>\n";
}
# get the object with the file loaded
my ( $file, $section, $parameter ) = @ARGV;
my $ini = new ISC::iniFile ( $file, 'r' );
if ( ! defined ( $ini ) ) { exit 1; }
# if the parameter exists then output it
if ( ! exists ( $ini->{sectionorder } ) ) {
	warn __FILE__.": sections can't be determined in \"$file\"\n";
	exit 1;
}
foreach my $section (@{$ini->{sectionorder }}) {
	print "$section\n";
}

