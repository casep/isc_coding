#!/usr/bin/perl
use strict;
use warnings;
use PrinterCommon;
# ISC CUPS Printer Set Tray
# Glen Pitt-Pladdy 20130917

# Takes CSV input with columns: CUPSName, Tray
# First line is heading
#
# If there is something in the Tray column then it sets that CUPSName to that Tray


# map detection & CUPS fields from CSV headings
my %FIELDMAP = (
	'name' => 'CUPS name',		# required
	'tray' => 'Tray number (if applicable)',	# required
);

# check the arguments
if ( $#ARGV != 1 ) {
	die "Usage: $0 <input file .csv> <output file prefix>\n";
}
my $infile = $ARGV[0];
my $outprefix = $ARGV[1];

# open files
open my $csvin, '<', $infile or die "FATAL - can't read \"$infile\": $!\n";
my $csverr = "$outprefix-errors.csv";
my $log = "$outprefix.log";
foreach my $file ($csverr,$log) {
	if ( -f $file ) { die "FATAL - output file \"$file\" exists\n"; }
}
open my $fouterr, '>', $csverr or die "FATAL - can't open output file \"$csverr\": $!\n";
open my $foutlog, '>', $log or die "FATAL - can't open output file \"$log\": $!\n";


# read in .csv data and process
my %header;
my @header;
my %stats = (
	'printer:count' => 0,		# for every printer (line)
	'printer:dupskip' => 0,		# duplicate names
	'printer:try' => 0,		# ones we are trying to use
	'printer:noprinter' => 0,	# failed to find printer
	'printer:trayfail' => 0,	# failed to find trays
	'printer:matchfail' => 0,	# failed to match trays
	'printer:success' => 0,		# printers successfully configured
);
my %dups;
my %usednames;
# on with the show
logger ( $foutlog, "processing printer list...\n" );
while ( defined ( my $line = <$csvin> ) ) {
	chomp $line;
	$line =~ s/\r$//;
	my @fields = csv2array ( $line );
	# grab the header if needed
	if ( ! %header ) {
		my $count = 0;
		for (@fields) {
			if ( $_ eq '' ) { next; }
			push @header, $_;
			$header{$_} = $count++;
		}
		if ( ! exists ( $header{'Detect Error'} ) ) {
			push @header, 'Detect Error';
			$header{'Detect Error'} = $count++;
		}
		print $fouterr array2csv ( \@header, \%header, \@header )."\n";
		next;
	}
	# remaining normal data lines
	logger ( $foutlog, "\n" );
	logger ( $foutlog, "name: ".$fields[$header{$FIELDMAP{'name'}}]."\n" );
	++$stats{'printer:count'};
	if ( ! $fields[$header{$FIELDMAP{'tray'}}] ) {
		logger ( $foutlog, "SKIP - no tray\n" );
		next;
	}
	if ( exists ( $dups{$fields[$header{$FIELDMAP{'name'}}]} ) ) {
		++$dups{$fields[$header{$FIELDMAP{'name'}}]};
		++$stats{'printer:dupskip'};
		logger ( $foutlog, "DUP!\n" );
		next;
	}
	$dups{$fields[$header{$FIELDMAP{'name'}}]} = 1;
	# we have one to investigate
	++$stats{'printer:try'};

	# try and match the tray
	open my $opt, '-|', "lpoptions -p ".$fields[$header{$FIELDMAP{'name'}}]." -l 2>&1" or die "FATAL - can't run lpoptions on ".$fields[$header{$FIELDMAP{'name'}}].": $!\n";
	my $tray;
	while ( defined ( my $line = <$opt> ) ) {
		chomp $line;
		if ( $line =~ /^InputSlot\/Media Source:\s+(\S.*)$/
			or $line =~ /^InputSlot\/InputSlot:\s+(\S.*)$/ ) {
			$tray = $1;
			last;
		} elsif ( $line =~ /: The printer or class was not found\.$/ ) {
			$fields[$header{'Detect Error'}] = "Printer not found";
			++$stats{'printer:noprinter'};
			last;
		}
	}
	close $opt;
	if ( ! defined ( $tray ) ) {
		if ( ! $fields[$header{'Detect Error'}] ) {
			$fields[$header{'Detect Error'}] = "Did not find any tray";
			++$stats{'printer:trayfail'};
		}
		logger ( $foutlog, "ERROR - ".$fields[$header{'Detect Error'}]." for ".$fields[$header{$FIELDMAP{'name'}}]."\n" );
		print $fouterr array2csv ( \@header, \%header, \@fields )."\n";
		next;
	}
	$tray =~ s/\*//;
	my @trays = split ( /\s+/, $tray );
	my $target;
	foreach my $source (@trays) {
		if ( $source eq $fields[$header{$FIELDMAP{'tray'}}]	# raw name
			or $source eq "Tray".$fields[$header{$FIELDMAP{'tray'}}]	# tray numbers
			or $source eq $fields[$header{$FIELDMAP{'tray'}}]."Tray" ) {
			$target = $source;
			last;
		}
	}
	if ( ! defined ( $target ) ) {
		logger ( $foutlog, "ERROR - did not find tray \"".$fields[$header{$FIELDMAP{'tray'}}]."\" for ".$fields[$header{$FIELDMAP{'name'}}]."\n" );
		logger ( $foutlog, "Available Trays: $tray\n" );
		$fields[$header{'Detect Error'}] = "No valid tray \"".$fields[$header{$FIELDMAP{'tray'}}]."\" - available are: ".join ( ', ', @trays );
		print $fouterr array2csv ( \@header, \%header, \@fields )."\n";
		++$stats{'printer:matchfail'};
		next;
	}
	# TODO found - we can set this now TODO
print "** $target\n";
	system ( 'lpoptions', '-o', "InputSlot=$target", '-p', $fields[$header{$FIELDMAP{'name'}}] );
	++$stats{'printer:success'};
}
# display stats
logger ( $foutlog, "\n\n" );
foreach (sort keys %stats) { logger ( $foutlog, "$_ = $stats{$_}\n" ); }
# close files
close $csvin;
close $fouterr;
close $foutlog;


