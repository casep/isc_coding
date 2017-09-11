#!/usr/bin/perl
BEGIN { unshift @INC, "$ENV{TRAKAUTOMATIONDIR}/functions"; }	# should come from functions.sh
# This parses a .ini format (Caché / CSP config), exiting the contents of the specified section
# Glen Pitt-Pladdy (ISC)
# Usage: $0 <.ini file> <section> <parameter>
use strict;
use warnings;
require ISC::iniFile;




# check parameters
if ( @ARGV !=2  or ! -f $ARGV[0] ) {
	die "$0: invalid arguments given\nUsage: $0 <.ini file> <section>\n";
}
# get the object with the file loaded
my ( $file, $section, $parameter ) = @ARGV;
my $ini = new ISC::iniFile ( $file, 'r' );
if ( ! defined ( $ini ) ) { exit 1; }
# if the parameter exists then output it
if ( exists ( $ini->{parameterorder}->{$section} ) ) {
	my %todolist;
	foreach (keys %{$ini->{parameters}->{$section}}) { $todolist{$_} = 1; }
	foreach my $parameter (@{$ini->{parameterorder}->{$section}}) {
		print "$parameter=".$ini->{parameters}->{$section}->{$parameter}.(($ini->{format}eq'DOS')?"\r\n":"\n");
		delete $todolist{$parameter};
	}
	foreach my $parameter (sort keys %todolist) {
		print "$parameter=".$ini->{parameters}->{$section}->{$parameter}.(($ini->{format}eq'DOS')?"\r\n":"\n");
	}
	exit 0;
} else {
	warn __FILE__.": section \"$section\" not found in \"$file\"\n";
	exit 1;
}



