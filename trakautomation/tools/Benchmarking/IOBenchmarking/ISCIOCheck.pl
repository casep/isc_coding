#!/usr/bin/perl
use strict;
use warnings;
# Basic OS Storage check for Caché deployment
# Glen Pitt-Pladdy (InterSystems)
#
my $VERSION = '20130806';
# Set the target dd and iozone space usage in MiB:
my $iozonesize=16384;
# where to put stuff
my $workdir='ISCIOCheckWorkDir';
my $logdir='/tmp/';	# could also be '.' for start directory
# iozone parameters
my $threads = 8;
my $request = '8k';
# minimum metrics - totals
my %thresholds = (
	'STlinW' => 30000,	# if we can't do the easy stuff it's pointless
	'STlinR' => 30000,
	'MTlinW' => 30000,
	'MTlinR' => 30000,
	'MTrandR' => 6400,	# equivalent to 800 IOPS
	'MTrandW' => 6400,	# equivalent to 800 IOPS
	'TOT' => 1,			# to use for overall score
);
my $margin = 1.2;
# what iozone to use
my %iozonebyOS = (
	'RHEL' => 'iozone3_397_iozone-RHEL5.x_x64',
	'SLES' => 'iozone3_397_iozone-SLES11SP2_x64',
);








#############################################################################
# main starts here
#############################################################################
use Cwd;
my $startdir = getcwd;
$SIG{'INT'} = 'exitclean';


# work out OS specific iozone
my $IOZONE = `which iozone 2>/dev/null`;	# takes care of OS distributed (Debian / Ubuntu etc.)
chomp $IOZONE;
if ( ! -x $IOZONE ) {
	# not a system-wide one - look for custom builds by OS
	open my $fp, '<', '/etc/issue' or die "FATAL - can't read /etc/issue: $!\n";
	my $osline;
	while ( defined ( $osline = <$fp> ) and $osline !~ /\w/ ) {}
	chomp $fp;
	close $fp;
	# find the OS
	if ( $osline =~ /^Red Hat Enterprise Linux Server release / and -x $iozonebyOS{'RHEL'} ) {
		$IOZONE = "$startdir/$iozonebyOS{RHEL}";
	} elsif ( $osline =~ /SUSE Linux Enterprise Server / and -x $iozonebyOS{'SLES'} ) {
		$IOZONE = "$startdir/$iozonebyOS{SLES}";
	} elsif ( $osline =~ /^CentOS release / and -x $iozonebyOS{'CENTOS'} ) {
		$IOZONE = "$startdir/$iozonebyOS{CENTOS}";
	} else {
		die "FATAL - can't find a usable iozone\n";
	}
}

# check we have enough space
my $space = `df -k .`;
chomp $space;
if ( $space !~ /^.*\s+(\d+)\s+\d+%\s\/.*$/m ) {
	die "FATAL - can't find free space\n";
}
$space = $1;
if ( $space < $iozonesize * 1.3 * 1024 ) {
	die "FATAL - don't have enough space: need ".($iozonesize * 1.3)."MiB\n";
}

# check we are root
#if ( $< !=0 ) {
#	die "FATAL - must be run as root\n";
#}


# check and create workdir
if ( ! -d $workdir ) {
	mkdir $workdir or die "FATAL - can't create workdir \"$workdir\": $!\n";
}
chdir $workdir or die "FATAL - can't change to the work directory\n";

# ready to go
if ( $logdir eq '.' ) { $logdir = $startdir; }
my @timeparts = localtime $^T;
my $timestr = sprintf ( '%04d-%02d-%02d %02d:%02d:%02d',
	$timeparts[5]+1900,
	$timeparts[4]+1,
	$timeparts[3],
	$timeparts[2],
	$timeparts[1],
	$timeparts[0]
);
my $timestamp = sprintf ( '%04d%02d%02d-%02d%02d%02d',
	$timeparts[5]+1900,
	$timeparts[4]+1,
	$timeparts[3],
	$timeparts[2],
	$timeparts[1],
	$timeparts[0]
);
open my $log, '>', "$logdir/ISCIOCheck_log_$timestamp.txt"
	or die "FATAL - can't write log \"ISCIOCheck_log_$^T.txt\": $!\n";
my $ofh = select $log;
$| = 1;
select $ofh;

# titles
printl ( "==================\n" );
printl ( "InterSystems IO Check Suite\n" );
printl ( "Glen Pitt-Pladdy $VERSION\n" );
printl ( "\n\n" );
printl ( "This gives a basic IO Benchmark check that\nwe are in the right \"ball park\" for the site\n" );
printl ( "\n\n" );
printl ( "Started: $timestr\n" );
printl ( "\n\n" );
printl ( "Logging to: $logdir/ISCIOCheck_log_$^T.txt\n" );
printl ( "\n\n" );
printl ( "Running in: $startdir\n" );
printl ( "\n\n" );

# get a description
print "Enter a Description of this run: ";
my $descrip = <STDIN>;
printl ( "Description:\n$descrip" );
printl ( "\n\n" );

# get system info
printl ( "Mounts\n======\n" );
open my $mounts, '<', '/proc/mounts' or die "$0: FATAL - can't read /proc/mounts: $!\n";
while ( defined ( my $line = <$mounts> ) ) {
	printl ( $line );
}
close $mounts;
printl ( "\n" );


# get prepared
use Term::ANSIColor qw(:constants);
my $score = 0;
my $marginal = 0;
my $maxscore = 0;


# multi-threaded io
my $mtsize = $iozonesize / $threads;
printl ( "==================\n" );
printl ( "Multi-threaded IO\n" );
printl ( "==================\n" );
my $ioz;
open $ioz, '-|', "$IOZONE -T -t $threads -s $mtsize"."m -r $request -I -i0 -i1 -i2"
	or die "FATAL - can't start \"$IOZONE\" test: $!\n";
my $start = 0;
while ( defined ( my $line = <$ioz> ) ) {
	chomp $line;
	if ( $line =~ /^\tEach thread writes a \d+ Kbyte file in \d+ Kbyte records/ ) { $start = 1; }
	if ( $start ) { printl ( ":: $line\n" ); }
	evalline ( $line );
}
close $ioz;

# single-threaded io
printl ( "==================\n" );
printl ( "Single-threaded IO\n" );
printl ( "==================\n" );
open $ioz, '-|', "$IOZONE -T -t 1 -s $iozonesize"."m -r $request -I -i0 -i1"
	or die "FATAL - can't start \"$IOZONE\" test: $!\n";
$start = 0;
while ( defined ( my $line = <$ioz> ) ) {
	chomp $line;
	if ( $line =~ /^\tEach thread writes a \d+ Kbyte file in \d+ Kbyte records/ ) { $start = 1; }
	if ( $start ) { printl ( ":: $line\n" ); }
	evalline ( $line );
}
close $ioz;


# overall
printl ( "==================\n" );
printl ( "Overall Status\n" );
printl ( "==================\n" );
printl ( "Passed $score / $maxscore\n" );
if ( $score == $maxscore ) {
	evalthresh ( ($marginal>0)?1:2, 'TOT' );
} else {
	evalthresh ( 0, 'TOT' );
}


# clean up
exitclean ();






sub evalline {
	my ( $line ) = @_;
	if ( $line =~ /^\tChildren see throughput for \s*\d+ initial writers\s*=\s*([\d\.]+) KB\/sec\r*$/ ) {
		evalthresh ( $1, 'MTlinW' );
	} elsif ( $line =~ /^\tChildren see throughput for \s*\d+ rewriters\s*=\s*([\d\.]+) KB\/sec\r*$/ ) {
		evalthresh ( $1, 'MTlinW' );
	} elsif ( $line =~ /^\tChildren see throughput for \s*\d+ readers\s*=\s*([\d\.]+) KB\/sec\r*$/ ) {
		evalthresh ( $1, 'MTlinR' );
	} elsif ( $line =~ /^\tChildren see throughput for \s*\d+ re-readers\s*=\s*([\d\.]+) KB\/sec\r*$/ ) {
		evalthresh ( $1, 'MTlinR' );
	} elsif ( $line =~ /^\tChildren see throughput for \s*\d+ random readers\s*=\s*([\d\.]+) KB\/sec\r*$/ ) {
		evalthresh ( $1, 'MTrandR' );
	} elsif ( $line =~ /^\tChildren see throughput for \s*\d+ random writers\s*=\s*([\d\.]+) KB\/sec\r*$/ ) {
		evalthresh ( $1, 'MTrandW' );
	}

}

sub evalthresh {
	my ( $result, $type ) = @_;
	++$maxscore;
	local $Term::ANSIColor::AUTORESET = 1;
	if ( $result >= $thresholds{$type} * $margin ) {
		print BOLD GREEN '******** PASS ********';
		print $log '******** PASS ********';
		if ( $type eq 'TOT' ) { printl ( "\nYay! :-)" ); }
		++$score;
	} elsif ( $result >= $thresholds{$type} ) {
		print BOLD YELLOW '******** MARGINAL ********';
		print $log '******** MARGINAL ********';
		if ( $type eq 'TOT' ) { printl ( "\nA tad more would be good for safety!" ); }
		++$score;
		++$marginal;
	} else {
		print BOLD RED '******** FAIL FAIL FAIL ********';
		print $log '******** FAIL FAIL FAIL ********';
	}
	printl ( "\n" );
}

sub printl {
	print @_;
	print $log @_;
}

sub exitclean {
	if ( defined $ioz ) { close $ioz; }
	close $log;
	chdir $startdir;
	rmdir $workdir or die "WARNING - failed to remove \"$workdir\": $!\n";
	exit 1;
}





