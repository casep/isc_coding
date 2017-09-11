#!/usr/bin/perl
BEGIN { unshift @INC, $ENV{TRAKAUTOMATIONDIR}; }	# should come from functions.sh
# This outputs the section from the first argument between lines matching the second and third arguments
# Glen Pitt-Pladdy (ISC)
use strict;
use warnings;


if ( @ARGV != 3 ) {
	warn "Usage: $0 <file> <Regex1> <Regex2>\n";
	exit 1;
} elsif ( ! -f $ARGV[0] ) {
	warn "File \"$ARGV[0]\" does not exist\n";
	warn "Usage: $0 <Apache .conf file> <Regex1> <Regex2>\n";
	exit 1;
}


# read the file
my $conf;
if ( ! open ( $conf, '<', $ARGV[0] ) ) {
	warn "$0:".__LINE__." can't read file \"$ARGV[0]\": $!\n";
	exit 1;
}
# find the start pattern
my $line;
my ( $start, $stop ) = @ARGV[1,2];
while ( defined ( $line = <$conf> ) and $line !~ /$start/ ) {}
if ( ! defined ( $line ) ) {
	warn "$0:".__LINE__." start pattern not matched\n";
	exit 1;
}
# output until stop pattern
while ( defined ( $line = <$conf> ) and $line !~ /$stop/ ) {
	print $line;
}
close $conf;

exit 0;



