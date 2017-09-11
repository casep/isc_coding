#!/usr/bin/perl
BEGIN { unshift @INC, "$ENV{TRAKAUTOMATIONDIR}/functions"; }	# should come from functions.sh
# This parses a .ini format (Caché / CSP config), takes arguments for updateS:
#	[section]parameter=value (add / update)
#	-[section]parameter (delete parameter)
#	-[section] (delete section)
# Then updates it writing a new file (same ownership, permissions)
# Glen Pitt-Pladdy (ISC)
# Usage: $0 <.ini file> <update> [update]....
use strict;
use warnings;
require ISC::iniFile;




# check parameters
if ( @ARGV < 2 ) {
	die "$0: invalid arguments given\nUsage: $0 <.ini file> <update> [update]....\n";
} elsif ( ! -f $ARGV[0] ) {
	warn "$0: file \"$ARGV[0]\" not found\n";
	die "$0: invalid arguments given\nUsage: $0 <.ini file> <update> [update]....\n";
}
# get the object with the file loaded
my ( $file, @updates ) = @ARGV;
my $ini = new ISC::iniFile ( $file, 'rw' );
if ( ! defined ( $ini ) ) { exit 1; }
# apply updates
for my $update (@updates) {
	if ( $update =~ /^\[([^\]]+)\]([^=]+)=(.*)$/ ) {
		# set new value
		$ini->{parameters}->{$1}->{$2} = $3;
	} elsif ( $update =~ /^-\[([^\]]+)\]([^=]+)$/ ) {
		# remove a parameter
		delete ( $ini->{parameters}->{$1}->{$2} );
	} elsif ( $update =~ /^-\[([^\]]+)\]$/ ) {
		# remove a parameter
		delete ( $ini->{parameters}->{$1} );
	} else {
		die "$0: invalid update spec:\n\t[section]parameter=value (add / update)\n\t-[section]parameter (delete parameter)\n\t-[section] (delete section)\n";
	}
}

# write the file
if ( $ini->write() ) { exit 0; }
exit 1;



