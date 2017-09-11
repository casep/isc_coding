#!/usr/bin/perl
use strict;
use warnings;
use PrinterCommon;
# ISC CUPS Printer Detection Script
# Glen Pitt-Pladdy 20130618

# Takes CSV input with columns: IP Address, Model (optional) - mapped below
# First line is heading
#
# For each IP Address:
# * pings
# * probes with snmp and http
# * tries to match against "lpinfo -m"
# * tries to match against %DRIVERMAP
# * tests port 9100 and 515 for printing
# * produces commands to add/delete printer based on naming/fields from %FIELDMAP
#
# Creates set of files with specified prefix
#
# TODO need to disable or handle auth with w3m TODO

my $DEFAULTPAPER = 'A4';

# map detection & CUPS fields from CSV headings
my %FIELDMAP = (
	'ip' => 'IP address',		# absolutely required
	'model' => 'Model',		# fallback column if it can't be detected
					# CUPS fields
	'name' => 'CUPS name',		# by default this would use the Reverse DNS, then generate from IP Address
	'description' => 'CUPS description',		# by default this would use the Model detected
	'location' => 'CUPS location',	# by default this would be blank, but if a column is given that will be used
	'paper' => '',		# uses defualt paper above, else this column specifies paper size
);

# map detected printer strings to drivers where they can't be determined automatically
my %DRIVERMAP = (
	# HP
	'HP LaserJet p2015' => 'drv:///hp/hpcups.drv/hp-laserjet_p2015_series-pcl3.ppd',	# printer ID doesn't match CUPS
	'HP LaserJet p2015 Series' => 'drv:///hp/hpcups.drv/hp-laserjet_p2015_series-pcl3.ppd',	# printer ID doesn't match CUPS
#	'HP LaserJet CP1525N' => 'foomatic:Generic-PostScript_Printer-Postscript.ppd',		# doesn't seem to be supported in standard distro
#	'HP LaserJet 400 M401dn' => 'pxlmono.ppd',	# doesn't seem to be supported in standard distro
#	'HP Laserjet Pro400 m401dn' => 'pxlmono.ppd',	# doesn't seem to be supported in standard distro
#	'HP Laserjet Pro400 m451dn' => 'pxlmono.ppd',   # doesn't seem to be supported in standard distro
#	'HP Laserjet 2605dn' => 'pxlmono.ppd',   # doesn't seem to be supported in standard distro
	'HP Laserjet P2600n' => 'drv:///hp/hpcups.drv/hp-color_laserjet_2600n.ppd',   # printer ID doesn't match CUPS
#	'HP Officejet Pro 8000n' => 'drv:///hp/hpcups.drv/hp-officejet_pro_8000_a809.ppd', 
	'hp LaserJet 1300' => 'drv:///hp/hpcups.drv/hp-laserjet_1300n-pcl3.ppd',
#	'HP Laserjet Pro600 m601n' => 'pxlmono.ppd',
#	'ES2232' => 'foomatic:Generic-PostScript_Printer-Postscript.ppd',	# OKI ES2232
	# Konica Minolta
	'konica minolta bizhub c224' => 'foomatic:Generic-PostScript_Printer-Postscript.ppd',
	# Lexmark
#	'Lexmark X544' => 'foomatic:Generic-PostScript_Printer-Postscript.ppd',		# doesn't seem to be supported in standard distro
	# Ricoh
	'RICOH Aficio MP 5002' => 'foomatic-db-ppds/Ricoh/PXL/Ricoh-Aficio_MP_5000_PXL.ppd.gz',		# Use series driver
	'RICOH Aficio MP C4501' => 'foomatic-db-ppds/Ricoh/PXL/Ricoh-Aficio_MP_C4500_PXL.ppd.gz',	# Use series driver
#	'RICOH Aficio MP C2051' => 'foomatic-db-ppds/Ricoh/PXL/Ricoh-Aficio_MP_2000_PXL.ppd.gz',
#	'RICOH Aficio C5503' => 'foomatic-db-ppds/Ricoh/PXL/Ricoh-Aficio_MP_5500_PXL.ppd.gz',
#	'Ricoh Aficio MP C5503' => 'foomatic-db-ppds/Ricoh/PXL/Ricoh-Aficio_MP_C5000_PXL.ppd.gz', 
#	'Ricoh Aficio MP C5501' => 'foomatic-db-ppds/Ricoh/PXL/Ricoh-Aficio_MP_C5000_PXL.ppd.gz',
#	'Ricoh Aficio MP 201' => 'foomatic-db-ppds/Ricoh/PXL/Ricoh-Aficio_MP_171_PXL.ppd.gz', 
#	'Ricoh Aficio MP 2851' => 'foomatic-db-ppds/Ricoh/PXL/Ricoh-Aficio_MP_2000_PXL.ppd.gz',
#	'Ricoh Aficio MP 4502' => 'foomatic-db-ppds/Ricoh/PXL/Ricoh-Aficio_MP_4500_PXL.ppd.gz',
	# Zebra (label) - Always RAW
	'Zebra Printer' => 'raw',
	'ZebraNet PrintServer' => 'raw',
	# Zebra from "model" column (SCHL)
	'Zebra LP2824' => 'raw',
	'Zebra LP2824-Z' => 'raw',
	'Zebra ZTC Z4MPlus - 200dpi' => 'raw',
	'Zebra GK420d' => 'raw',
);




# real work starts
use IO::Socket::INET;

# check neccessary tools are available
foreach my $prog ( 'lpinfo', 'snmpget', 'snmpwalk', 'w3m', 'wget', 'curl' ) {
	my $path = `which $prog`;
	chomp $path;
	if ( ! -x $path ) {
		die "FATAL - need \"$prog\" for auto-detection\n";
	}
}

# check the arguments
if ( $#ARGV != 1 ) {
	die "Usage: $0 <input file .csv> <output file prefix>\n";
}
my $infile = $ARGV[0];
my $outprefix = $ARGV[1];

# open files
open my $csvin, '<', $infile or die "FATAL - can't read \"$infile\": $!\n";
my $printeradd = "$outprefix-printeradd.sh";
my $printerdel = "$outprefix-printerdel.sh";
my $csverr = "$outprefix-errors.csv";
my $log = "$outprefix.log";
my $trakimport = "$outprefix-TrakPrinterImport.tsv";
foreach my $file ($printeradd,$printerdel,$csverr,$log) {
	if ( -f $file ) { die "FATAL - output file \"$file\" exists\n"; }
}
open my $foutadd, '>', $printeradd or die "FATAL - can't open output file \"$printeradd\": $!\n";
open my $foutdel, '>', $printerdel or die "FATAL - can't open output file \"$printerdel\": $!\n";
open my $fouterr, '>', $csverr or die "FATAL - can't open output file \"$csverr\": $!\n";
open my $foutlog, '>', $log or die "FATAL - can't open output file \"$log\": $!\n";
open my $fouttrakimport, '>', $trakimport or die "FATAL - can't open output file \"$trakimport\": $!\n";


# read in available model info
logger ( $foutlog, "reading in \"lpinfo -m\"...\n" );
open my $lpinfo, '-|', 'lpinfo -m' or die "FATAL - can't run \"lpinfo -m\": $!\n";
my %drivermap;
my %gotid;
while ( defined ( my $line = <$lpinfo> ) ) {
	chomp $line;
	if ( $line !~ /^([^\s]+)\s+([^\s].*)$/ ) {
		die "FATAL - can't understand  \"lpinfo -m\" line: $line\n";
	}
	my ( $driver, $id ) = ( $1, lc $2 );
	$id =~ s/,.*$//;
	$id =~ s/\s+foomatic\/[^\s]+$//;
	$id =~ s/\s+pcl\d*$//;
	$id =~ s/\s+postscript$//;
	$id =~ s/\s+ps$//i;
	if ( ! exists ( $gotid{$id} ) ) {
		$drivermap{$id} = $driver;
		$gotid{$id} = 1;
	} elsif ( $gotid{$id}++ == 1 ) {
		logger ( $foutlog, "WARNING - multiple id's for \"$id\" - require manual mapping\n" );
	}
}
close $lpinfo;
# add manual mappings
foreach my $id (keys %DRIVERMAP) {
	if ( exists ( $gotid{$id} ) ) {
		logger ( $foutlog, "WARNING - manual override for \"$id\"\n" );
	}
	$drivermap{lc $id} = $DRIVERMAP{$id};
}


# read in .csv data and process
my $state = 0;
my %header;
my @header;
my %stats = (
	'printer:count' => 0,		# for every printer (line)
	'printer:dupskip' => 0,		# for every printer (line) skipped as a duplicate
	'printer:try' => 0,		# valid printer (line) we try to identify
	'printer:success' => 0,		# printers successfully configured

	'ping:try' => 0,
	'ping:success' => 0,
	'ping:fail' => 0,

	'snmp:try' => 0,
	'snmp:success' => 0,
	'snmp:fail' => 0,

	'snmp:match:try' => 0,
	'snmp:match:success' => 0,
	'snmp:match:fail' => 0,

	'http:try' => 0,
	'http:success' => 0,		# got a connection
	'http:fail' => 0,		# no connection

	'http:match:try' => 0,
	'http:match:success' => 0,
	'http:match:fail' => 0,

	'printport:try' => 0,
	'printport:success' => 0,
	'printport:fail' => 0,

);
my %dups;
my %usednames;
# on with the show
logger ( $foutlog, "processing printer list...\n" );
print $foutadd "#!/bin/sh\n\n";
print $foutdel "#!/bin/sh\n\n";
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
	logger ( $foutlog, "ip: ".$fields[$header{$FIELDMAP{'ip'}}]."\n" );
	++$stats{'printer:count'};
	if ( exists ( $FIELDMAP{'name'} ) and exists ( $header{$FIELDMAP{'name'}} ) and $fields[$header{$FIELDMAP{'name'}}] ) {
		logger ( $foutlog, "name: ".$fields[$header{$FIELDMAP{'name'}}]."\n" );
		if ( exists ( $dups{$fields[$header{$FIELDMAP{'name'}}]} ) ) {
			++$dups{$fields[$header{$FIELDMAP{'name'}}]};
			++$stats{'printer:dupskip'};
			logger ( $foutlog, "DUP!\n" );
			next;
		}
	} else {
		# fall back to IP based de-DUP
		if ( exists ( $dups{$fields[$header{$FIELDMAP{'ip'}}]} ) ) {
			++$dups{$fields[$header{$FIELDMAP{'ip'}}]};
			++$stats{'printer:dupskip'};
			logger ( $foutlog, "DUP!\n" );
			next;
		}
	}
	if ( exists ( $FIELDMAP{'name'} ) and exists ( $header{$FIELDMAP{'name'}} ) ) {
		$dups{$fields[$header{$FIELDMAP{'name'}}]} = 1;		# TODO fails if no name column TODO
	}
	$dups{$fields[$header{$FIELDMAP{'ip'}}]} = 1;
	# we have one to investigate
	++$stats{'printer:try'};
	my @errors;
	my $pingstatus = ping ( $fields[$header{$FIELDMAP{'ip'}}], \@errors );
	my $model;
	if ( $pingstatus ) {
		$model = probeid ( $fields[$header{$FIELDMAP{'ip'}}], \@errors );
		if ( ! $model and exists ( $FIELDMAP{'model'} ) and exists ( $header{$FIELDMAP{'model'}} ) and $fields[$header{$FIELDMAP{'model'}}] ) {
			$model = lc $fields[$header{$FIELDMAP{'model'}}];
			if ( $model eq '' ) {
				undef $model;
				logger ( $foutlog, "from CSV: NONE\n" );
			} else {
				logger ( $foutlog, "from CSV: $model\n" );
			}
		}
	}
# probe trays if needed TODO
#my @trays = probetrays ( $fields[$header{$FIELDMAP{'ip'}}], \@errors );
	my $success;
	if ( $model ) {
		if ( exists ( $drivermap{$model} ) ) {
			# output commands to configure this printer
			$success = printer2sh ( $fields[$header{$FIELDMAP{'ip'}}], $model, \%header, \@fields, \@errors );
		} else {
			# failed to find printer driver
			push @errors, 'Unmatched Driver';
		}
	}
	if ( ! $success ) {
		# pass the leftovers back out
		$fields[$header{'Detect Error'}] = join ( ':', @errors );
		print $fouterr array2csv ( \@header, \%header, \@fields )."\n";
	} else {
		++$stats{'printer:success'};
	}
}
# display stats
logger ( $foutlog, "\n\n" );
foreach (sort keys %stats) { logger ( $foutlog, "$_ = $stats{$_}\n" ); }
# close files
close $csvin;
close $foutadd;
chmod 0775, $printeradd;
close $foutdel;
chmod 0775, $printerdel;
close $fouterr;
close $foutlog;
close $fouttrakimport;



# try to ping the printer
sub ping {
	my ( $ip, $errors ) = @_;
	++$stats{'ping:try'};
	my $ret = system ( "ping -c 1 -n -q '$ip' >/dev/null" );
	if ( $ret != 0 ) {
		logger ( $foutlog, "no ping to printer \"$ip\"\n" );
		++$stats{'ping:fail'};
		push @$errors, 'No Ping';
		return;
	}
	++$stats{'ping:success'};
	return 1;
}

# try to identify printer, returning the model string
sub probeid {
	my ( $ip, $errors ) = @_;
	# probe with snmpget
	++$stats{'snmp:try'};
	my @snmpoids = (
		'HOST-RESOURCES-MIB::hrDeviceDescr.1',	# usual device make/model string
		'SNMPv2-SMI::mib-2.43.5.1.1.16.1',
		'SNMPv2-SMI::mib-2.43.14.1.1.9.1.7',
		'SNMPv2-SMI::mib-2.43.14.1.1.9.1.8',
		'SNMPv2-MIB::sysDescr.0',	# shows up Zebra Printservers
	);
	open my $snmp, '-|', "snmpget -v1 -cpublic '$ip' ".join ( ' ', @snmpoids ).' 2>&1';
	my @ids;
	while ( defined ( my $line = <$snmp> ) ) {
		chomp $line;
		if ( $line =~ s/^[^=]+=\s*// ) {
			if ( $line !~ /^""$/ and $line !~ /^No Such Instance currently exists at this OID/ ) {
				$line =~ s/^STRING:\s+//;
				$line =~ s/^"(.+)"$/$1/;
				$line =~ s/^\s+//;
				$line =~ s/\s+$//;
				push @ids, lc ( $line );
			}
		} elsif ( $line =~ /^Timeout: No Response from / ) {
			# got no SNMP
#logger ( $foutlog, "$line\n" );
			push @ids, 'FAIL';
		} elsif ( $line ne ''
		and $line !~ /^Error in packet/
		and $line !~ /^Reason: \(noSuchName\) There is no such variable name in this MIB/
		and $line !~ /^Failed object: /
			) {
			logger ( $foutlog, "UNKNONW SNMP: $line\n" );
		}
	}
	close $snmp;
	if ( @ids ) {
		if ( $ids[0] eq 'FAIL' ) {
			logger ( $foutlog, "snmp: $ids[0]\n" );
			++$stats{'snmp:fail'};
			push @$errors, 'No SNMP';
		} else {
			# TODO majority vote / match known printers TODO
			++$stats{'snmp:success'};	# got access (connect)
			++$stats{'snmp:match:try'};
			foreach (@ids) {
				if ( exists ( $drivermap{$_} ) ) {
					logger ( $foutlog, "success: $_\n" );
					++$stats{'snmp:match:success'};
					return $_;
				}
				logger ( $foutlog, "snmp: unmatched: $_\n" );
			}
			push @$errors, 'No Match from SNMP';
			++$stats{'snmp:match:fail'};
		}
	} else {
		logger ( $foutlog, "snmp:NONE\n" );
		++$stats{'snmp:success'};	# got access (connect)
		push @$errors, 'No ID from SNMP';
	}
	# probe with http
	++$stats{'http:try'};
	# test connect
	my $socket;
	$socket = new IO::Socket::INET (
		PeerHost => $ip,
		PeerPort => 80,
		Proto => 'tcp',
		Timeout => 2,
	);
	if ( ! $socket ) {
		logger ( $foutlog, "http: no connect\n" );
		push @$errors, 'No HTTP Connect';
		++$stats{'http:fail'};
		return;
	}
	++$stats{'http:success'};	# got a connection
	# probe common URLs
	my $state;
	# OKI ES2232... possibly others
	$state = 0;
	++$stats{'http:match:try'};
	foreach my $line (w3m2array ( "$ip/header_st.htm", $errors )) {
		if ( $state == 0 and $line =~ /^\s*[^\s].*\[printer_na\]$/ ) {
			# found!
			$line =~ s/^\s+//;
			$line =~ s/\s*\[printer_na\]$//;
			if ( exists ( $drivermap{lc $line} ) ) {
				++$stats{'http:match:success'};
				logger ( $foutlog, "success: $line\n" );
				return lc ( $line );
			}
			logger ( $foutlog, "http: unmatched1: $line\n" );
			last;
		}
		$state = 1;
	}
	# HP LaserJet 1200... possibly ohters
	$state = 0;
	++$stats{'http:match:try'};
	foreach my $line (w3m2array ( "$ip/index_info.htm", $errors )) {
		if ( $line =~ /^[^\s]/ ) { $state = 0; }
		if ( $state == 0 and $line =~ /^Device Info$/ ) {
			$state = 1;
		} elsif ( $state == 1 ) {
			if ( $line =~ s/^\s+Device:\s+// ) {
				# found!
				if ( exists ( $drivermap{lc $line} ) ) {
					++$stats{'http:match:success'};
					logger ( $foutlog, "success: $line\n" );
					return lc ( $line );
				}
				logger ( $foutlog, "http: unmatched1: $line\n" );
				last;
			}
		}
	}
	# HP LaserJet P2015 Series... possibly others
	$state = 0;
	foreach my $line (curl2array ( "$ip", $errors )) {
		if ( $line =~ /^[^\s]/ ) { $state = 0; }
		if ( $state == 0 and $line =~ /^<head>$/i ) {
			$state = 1;
		} elsif ( $state == 1 ) {
			if ( $line =~ s/^\s*<title>([\w\s]+)&nbsp;&nbsp;&nbsp;[\.\d]+<\/title>\s*$/$1/ ) {
				# found!
				if ( exists ( $drivermap{lc $line} ) ) {
					++$stats{'http:match:success'};
					logger ( $foutlog, "success: $line\n" );
					return lc ( $line );
				}
				logger ( $foutlog, "http: unmatched2: $line\n" );
				last;
			}
		}
	}
	#  Lexmark X544... possibly others
	$state = 0;
	foreach my $line (curl2array ( "$ip", $errors )) {
		if ( $state == 0 and $line =~ /^<head>$/i ) {
			$state = 1;
		} elsif ( $state == 1 ) {
			if ( $line =~ s/^<TITLE>([\w\s]+)<\/TITLE>$/$1/ ) {
				# found!
				if ( exists ( $drivermap{lc $line} ) ) {
					++$stats{'http:match:success'};
					logger ( $foutlog, "success: $line\n" );
					return lc ( $line );
				}
				logger ( $foutlog, "http: unmatched2: $line\n" );
				last;
			}
		}
	}
	# Ricoh Aficio MP 201... possibly others
	$state = 0;
	++$stats{'http:match:try'};
	foreach my $line (w3m2array ( "$ip/web/guest/en/websys/webArch/topPage.cgi", $errors )) {
		if ( $line =~ /Server/ ) { $state = 0; }
		if ( $state == 0 and $line =~ /^\s+_\s+Server\s+_\s+\[spacer\]$/ ) {
			$state = 1;
		} elsif ( $state == 1 ) {
			if ( $line =~ s/^.+\s+Device Name :\s+// ) {
				# found!
print "3::: $line\n";
				$line =~ s/\s+\[machineIma\]\s*$//;
				if ( exists ( $drivermap{lc $line} ) ) {
					++$stats{'http:match:success'};
					logger ( $foutlog, "success: $line\n" );
					return lc ( $line );
				}
				logger ( $foutlog, "http: unmatched3: $line\n" );
				last;
			}
		}
	}

# TODO other URLs
	push @$errors, 'No Match from HTTP';
	++$stats{'http:match:fail'};
	logger ( $foutlog, "http: no match overall\n" );

	return;
}

# probe for trays TODO just count them for now
#sub probetrays {
#	my ( $ip, $errors ) = @_;
#TODO snmpwalk -v1 -cpublic '$ip' SNMPv2-SMI::mib-2.43.8.2.1.13.1
#TODO snmpwalk -v1 -cpublic '$ip' SNMPv2-SMI::mib-2.43.8.2.1.18.1
# get CUPS info with: lpoptions -p PRINTERNAME -l
# InputSlot/Media Source:
# actually need to parse .ppd for "^*InputSlot"
#}

# probe for a means to print, and return the url
sub probeprinterport {
	my ( $ip, $errors ) = @_;
	my $socket;
	++$stats{'printport:try'};
	# try standard appsocket (TCP 9100) TODO
	$socket = new IO::Socket::INET (
		PeerHost => $ip,
		PeerPort => 9100,
		Proto => 'tcp',
		Timeout => 2,
	);
	if ( $socket ) {
		++$stats{'printport:success'};
		return "socket://$ip:9100";
	}
	push @$errors, 'No Appsocket (TCP 9100)';
	# try lpr (TCP 515) TODO
	$socket = new IO::Socket::INET (
		PeerHost => $ip,
		PeerPort => 515,
		Proto => 'tcp',
		Timeout => 2,
	);
	if ( $socket ) {
		++$stats{'printport:success'};
		return "lpr://$ip:515";
	}
	push @$errors, 'No LPR (TCP 515)';
	++$stats{'printport:fail'};
	return;
}

# return an array of lines from w3m
sub w3m2array {
	my ( $url, $errors ) = @_;
	# complete URLs
	if ( $url !~ /^https?:\/\// ) {
		$url = "http://$url";
	}
	# put in dummy authentication
	$url =~ s/^(https?:\/\/)/$1:@/;
	# read the contents
	open my $http, '-|', "yes | w3m -dump '$url' 2>&1";
	my @lines = <$http>;
	chomp @lines;
	close $http;
	foreach my $line (@lines) {
		if ( $line =~ /^Wrong username or password/ ) {
			logger ( $foutlog, "HTTP: Authentication Requred (not supported)\n" );
			push @$errors, "HTTP Bad \"$url\" Authentication Requred (not supported)";
		} elsif ( $line =~ /^w3m: Can't load / ) {
			logger ( $foutlog, "HTTP: $line\n" );
			push @$errors, "HTTP Bad \"$url\"";
			return;
		}
	}
	return @lines;
}
# return an array of lines from wget
sub wget2array {
	my ( $url, $errors ) = @_;
	# complete URLs
	if ( $url !~ /^https?:\/\// ) {
		$url = "http://$url";
	}
	open my $http, '-|', "wget --output-document=- --tries=1 --timeout=2 '$url' 2>&1";
	my @lines = <$http>;
	chomp @lines;
	close $http;
	foreach my $line (@lines) {
		if ( $line =~ /^wget: unable to resolve host address /
			or  $line =~ /^Connecting to .+\.\.\. failed: Connection refused/
			or  $line =~ /^Connecting to .+\.\.\. failed: Connection timed out/
			or  $line =~ /^HTTP request sent, awaiting response\.\.\. 505 HTTP Version not supported/
			or  $line =~ /^HTTP request sent, awaiting response\.\.\. 404 Not Found/ ) {
			logger ( $foutlog, "HTTP: $line\n" );
			push @$errors, "HTTP failed \"$url\"";
			return;
		}
	}
	return @lines;
}
# return an array of lines from wget
sub curl2array {
	my ( $url, $errors ) = @_;
	# complete URLs
	if ( $url !~ /^https?:\/\// ) {
		$url = "http://$url";
	}
	open my $http, '-|', "curl --connect-timeout 2 '$url' 2>&1";
	my @lines = <$http>;
	chomp @lines;
	close $http;
	foreach my $line (@lines) {
		if ( $line =~ /^curl: \(6\) Couldn't resolve host /
			or  $line =~ /^curl: (7) Failed to connect to /
			or  $line =~ /^curl: (52) Empty reply from server/
			or  $line =~ /^404 Not Found$/ ) {
			logger ( $foutlog, "HTTP: $line\n" );
			push @$errors, "HTTP failed \"$url\"";
			return;
		}
	}
	return @lines;
}

# generate the command to add
sub printer2sh {
	my ( $ip, $model, $header, $fields, $errors ) = @_;
	# translate to something sane
	$model =~ s/^zebra .*$/zebra printer/;

	# find a connection URL
	my $printport = probeprinterport ( $ip, $errors );
	if ( $printport ) {
		# TODO output commands to configure this printer
		logger ( $foutlog, "_MODEL: $model\n" );
		if ( exists ( $drivermap{$model} ) ) {
			logger ( $foutlog, "_DRIVER: $drivermap{$model}\n" );
		} else {
			logger ( $foutlog, "_DRIVER: UNKNOWN: $model\n" );
		}
		logger ( $foutlog, "_PORT: $printport\n" );
		if ( exists ( $drivermap{$model} ) ) {
			my $name;
			if ( exists  ( $FIELDMAP{'name'} ) and exists ( $$header{$FIELDMAP{'name'}} ) and $$fields[$$header{$FIELDMAP{'name'}}] ) {
				$name = $$fields[$$header{$FIELDMAP{'name'}}];
				print $foutadd "# name from CSV \"$FIELDMAP{name}\"\n";
			} else {
				$name = `host '$ip'`;
				chomp $name;
				if ( $name =~ / not found: / ) {
					$name = sprintf ( 'prt%03d%03d%03d%03d', split ( /\./, $ip ) );
					print $foutadd "# auto name from IP Address\n";
				} else {
					$name =~ s/^.+domain name pointer //;
					$name =~ s/\..*$//;
					print $foutadd "# auto name Reverse DNS\n";
				}
			}
			$name =~ s/[^\w]+/_/g;
			my $descrip;
			if ( exists ( $$header{$FIELDMAP{'description'}} ) and $$fields[$$header{$FIELDMAP{'description'}}] ) {
				$descrip = $$fields[$$header{$FIELDMAP{'description'}}];
				print $foutadd "# description from CSV \"$FIELDMAP{description}\"\n";
			} else {
				$descrip = $model;
				print $foutadd "# auto description from Model\n";
			}
			my $location;
			if ( exists ( $$header{$FIELDMAP{'location'}} ) and $$fields[$$header{$FIELDMAP{'location'}}] ) {
				$location = $$fields[$$header{$FIELDMAP{'location'}}];
				print $foutadd "# location from CSV \"$FIELDMAP{location}\"\n";
			} else {
				$location = '';
			}
			# check for duplications
			if ( exists ( $usednames{$name} ) ) {
				print $foutadd "# Commented out due to duplicate names\n";
				print $foutdel "# Commented out due to duplicate names\n";
				++$usednames{$name};
				logger ( $foutlog, "WARNING - duplicate printer name \"$name\"\n" );
			}
			# output script
			print $foutadd "echo 'Adding \"$name\" on \"$printport\"'\n";
			if ( exists ( $usednames{$name} ) ) { print '#'; }
# escape shell metacharacters TODO verify this
$location =~ s/\\/\\\\"/g;
$location =~ s/`/\\`/g;
$location =~ s/\$/\\\$/g;
$location =~ s/"/\\"/g;
$descrip =~ s/\\/\\\\"/g;
$descrip =~ s/`/\\`/g;
$descrip =~ s/\$/\\\$/g;
$descrip =~ s/"/\\"/g;
			print $foutadd "lpadmin -p '$name' -D \"$descrip\" -L \"$location\" -m '$drivermap{$model}' -v '$printport' -E";
			if ( $drivermap{$model} ne 'raw' ) {
				my $paper = $DEFAULTPAPER;
				if ( exists ( $$header{$FIELDMAP{'paper'}} ) and $$fields[$$header{$FIELDMAP{'paper'}}] ) {
print "map: ".$FIELDMAP{'paper'}."\n";
print "header: ".$$header{$FIELDMAP{'paper'}}."\n";
					$paper=$$fields[$$header{$FIELDMAP{'paper'}}];
}
				print $foutadd " -o PageSize=$paper";
			}
			print $foutadd "\n";
			print $foutdel "echo 'Deleting \"$name\"'\n";
			if ( exists ( $usednames{$name} ) ) { print $foutdel '#'; }
			print $foutdel "lpadmin -x '$name'\n";
			# output Trak Import file - Tab separate:
			# Printer Code[TAB]Description[TAB]CUPSDevice[TAB]BatchPrint[TAB]PostScript[TAB]PrinterDisabled[TAB]PrinterGroup.Code
			# TODO test this TODO
			print $fouttrakimport "$name\t$descrip\t$name\n";
			# all done - mark that we've done this one
			$usednames{$name} = 1;
		} else {
			# failed to find printer driver
			push @$errors, 'Unmatched Driver';
			return;
		}
	} else {
		# failed to find printer interface
		push @$errors, 'No Print Port';
		return;
	}
	return 1;
}


