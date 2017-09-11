#!/usr/bin/perl

use strict;
use warnings;

my $mode = '';
my %iozoneresults;
my %generalresults;
$generalresults{'directreadtiming'}{'cachedreadscount'} = 0;
$generalresults{'directreadtiming'}{'diskreadscount'} = 0;
$generalresults{'directreadtiming'}{'cachedreadsmin'} = 1e100;
$generalresults{'directreadtiming'}{'cachedreads'} = 0;
$generalresults{'directreadtiming'}{'cachedreadsmax'} = -1;
$generalresults{'directreadtiming'}{'diskreadsmin'} = 1e100;
$generalresults{'directreadtiming'}{'diskreads'} = 0;
$generalresults{'directreadtiming'}{'diskreadsmax'} = -1;
$generalresults{'readtiming'}{'cachedreadscount'} = 0;
$generalresults{'readtiming'}{'diskreadscount'} = 0;
$generalresults{'readtiming'}{'cachedreadsmin'} = 1e100;
$generalresults{'readtiming'}{'cachedreads'} = 0;
$generalresults{'readtiming'}{'cachedreadsmax'} = -1;
$generalresults{'readtiming'}{'diskreadsmin'} = 1e100;
$generalresults{'readtiming'}{'diskreads'} = 0;
$generalresults{'readtiming'}{'diskreadsmax'} = -1;

while ( defined ( my $line = <STDIN> ) ) {
	chomp $line;
	$line =~ s/\s+$//;
	if ( $line =~ /^==================/ ) {
		# divider - reset
		$mode = '';
	} elsif ( $line =~ /^seeker test on / ) {
		$mode = 'seeker';
	} elsif ( $line =~ /^dd direct write test/ ) {
		$mode = 'directwrite';
	} elsif ( $line =~ /^dd write test/ ) {
		$mode = 'write';
	} elsif ( $line =~ /^Direct read timing / ) {
		$mode = 'directreadtiming';
	} elsif ( $line =~ /^read timing / ) {
		$mode = 'readtiming';
	} elsif ( $line =~ /^dd direct read test/ ) {
		$mode = 'directread';
	} elsif ( $line =~ /^dd read test/ ) {
		$mode = 'read';
	} elsif ( $line =~ /iozone (\d+) threads, \d+MB files, (\d+)([kMGT]?) records, DirectIO, read\/re-read, random-read\/write/ ) {
		$mode = "directiozone";
		$iozoneresults{'threads'} = $1;
		$iozoneresults{'unit'} = tobaseunit ( $2, $3 );
	} elsif ( $line =~ /iozone (\d+) threads, \d+MB files, (\d+)([kMGT]?) records, read\/re-read, random-read\/write/ ) {
		$mode = "iozone";
		$iozoneresults{'threads'} = $1;
		$iozoneresults{'unit'} = tobaseunit ( $2, $3 );
	}


	my $type='';
	my $basemode = $mode;
	if ( $mode =~ /^direct(.+)$/ ) {
		$type='direct';
		$basemode = $1;
	}
	if ( $basemode eq 'seeker' ) {
		if ( $line =~ /^Results: \d+ seeks\/second, ([0-9\.]+) ms random access time$/ ) {
			$generalresults{'seek'} = $1;
		}
	} elsif ( $basemode eq 'write' ) {
		if ( $line =~ /^\d+ bytes \([\d\.]+ [KMGT]B\) copied, [\d\.]+ s, ([\d\.]+) ([KMGT]?)B\/s$/ ) {
			$generalresults{"${type}write"} = tobaseunit ( $1, $2 );
		}
	} elsif ( $basemode eq 'readtiming' ) {
		if ( $line =~ /^ Timing O_DIRECT cached reads:\s*\d+ [TGMK]?B in  [\d\.]+ seconds = ([\d\.]+) ([TGMK]?)B\/sec/
			or $line =~ /^ Timing cached reads:\s*\d+ [TGMK]?B in  [\d\.]+ seconds = ([\d\.]+) ([TGMK]?)B\/sec/ ) {
			my $speed = tobaseunit ( $1, $2 );
			++$generalresults{$mode}{'cachedreadscount'};
			$generalresults{$mode}{'cachedreads'} += $speed;
			if ( $speed < $generalresults{$mode}{'cachedreadsmin'} ) {
				$generalresults{$mode}{'cachedreadsmin'} = $speed;
			}
			if ( $speed > $generalresults{$mode}{'cachedreadsmax'} ) {
				$generalresults{$mode}{'cachedreadsmax'} = $speed;
			}
		} elsif ( $line =~ /^ Timing O_DIRECT disk reads:\s*\d+ [GMK]?B in  [\d\.]+ seconds = ([\d\.]+) ([GMK]?)B\/sec/
			or $line =~ /^ Timing buffered disk reads:\s*\d+ [GMK]?B in  [\d\.]+ seconds = ([\d\.]+) ([GMK]?)B\/sec/ ) {
			my $speed = tobaseunit ( $1, $2 );
			++$generalresults{$mode}{'diskreadscount'};
			$generalresults{$mode}{'diskreads'} += $speed;
			if ( $speed < $generalresults{$mode}{'diskreadsmin'} ) {
				$generalresults{$mode}{'diskreadsmin'} = $speed;
			}
			if ( $speed > $generalresults{$mode}{'diskreadsmax'} ) {
				$generalresults{$mode}{'diskreadsmax'} = $speed;
			}
		}
	} elsif ( $basemode eq 'read' ) {
		if ( $line =~ /^\d+ bytes \([\d\.]+ [KMGT]B\) copied, [\d\.]+ s, ([\d\.]+) ([KMGT]?)B\/s$/ ) {
			$generalresults{$mode} = tobaseunit ( $1, $2 );
		}
	} elsif ( $basemode eq 'iozone' ) {
		my $param = '';
		my $unit;
		if ( $line =~ /^\s*Parent sees throughput for \s*(\d+) initial writers\s*=\s*([\d\.]+) ([KMGT]?)B\/sec$/ ) {
			$param = 'linearwrite';
		} elsif ( $line =~ /^\s*Parent sees throughput for \s*(\d+) rewriters\s*=\s*([\d\.]+) ([KMGT]?)B\/sec$/ ) {
			$param = 'linearrewrite';
		} elsif ( $line =~ /^\s*Parent sees throughput for \s*(\d+) readers\s*=\s*([\d\.]+) ([KMGT]?)B\/sec$/ ) {
			$param = 'linearread';
		} elsif ( $line =~ /^\s*Parent sees throughput for \s*(\d+) re-readers\s*=\s*([\d\.]+) ([KMGT]?)B\/sec$/ ) {
			$param = 'linearreread';
		} elsif ( $line =~ /^\s*Parent sees throughput for \s*(\d+) random readers\s*=\s*([\d\.]+) ([KMGT]?)B\/sec$/ ) {
			$param = 'randomread';
		} elsif ( $line =~ /^\s*Parent sees throughput for \s*(\d+) random writers\s*=\s*([\d\.]+) ([KMGT]?)B\/sec$/ ) {
			$param = 'randomwriters';
		}
		if ( $param ne '' ) {
			$iozoneresults{"${type}throughput"}{$iozoneresults{'threads'}}{$param} = tobaseunit ( $2, $3 );
			$unit = $3;
			$iozoneresults{"${type}iops"}{$iozoneresults{'threads'}}{$param} = $iozoneresults{"${type}throughput"}{$iozoneresults{'threads'}}{$param} / $iozoneresults{'unit'};
		}
	}
}

# output .csv report
if ( exists $generalresults{'seek'} ) { print "seek,$generalresults{seek},ms\n"; }
if ( exists $generalresults{'directwrite'} ) { print "directwrite,".($generalresults{directwrite}/1048576).",MB/s\n"; }
if ( exists $generalresults{'directread'} ) { print "directread,".($generalresults{directread}/1048576).",MB/s\n"; }
if ( exists $generalresults{'write'} ) { print "write,".($generalresults{write}/1048576).",MB/s\n"; }
if ( exists $generalresults{'read'} ) { print "read,".($generalresults{read}/1048576).",MB/s\n"; }
if ( $generalresults{'directreadtiming'}{'cachedreadscount'} > 0 ) {
	$generalresults{'directreadtiming'}{'cachedreads'} /= $generalresults{'directreadtiming'}{'cachedreadscount'};
	print "directcachedreads,".($generalresults{'directreadtiming'}{'cachedreadsmin'}/1048576).",".($generalresults{'directreadtiming'}{'cachedreads'}/1048576).",".($generalresults{'directreadtiming'}{'cachedreadsmax'}/1048576).",MB/s (min/avg/max)\n";
}
if ( $generalresults{'directreadtiming'}{'diskreadscount'} > 0 ) {
	$generalresults{'directreadtiming'}{'diskreads'} /= $generalresults{'directreadtiming'}{'diskreadscount'};
	print "directdiskreads,".($generalresults{'directreadtiming'}{'diskreadsmin'}/1048576).",".($generalresults{'directreadtiming'}{'diskreads'}/1048576).",".($generalresults{'directreadtiming'}{'diskreadsmax'}/1048576).",MB/s (min/avg/max)\n";
}
if ( $generalresults{'readtiming'}{'cachedreadscount'} > 0 ) {
	$generalresults{'readtiming'}{'cachedreads'} /= $generalresults{'readtiming'}{'cachedreadscount'};
	print "cachedreads,".($generalresults{'readtiming'}{'cachedreadsmin'}/1048576).",".($generalresults{'readtiming'}{'cachedreads'}/1048576).",".($generalresults{'readtiming'}{'cachedreadsmax'}/1048576).",MB/s (min/avg/max)\n";
}
if ( $generalresults{'readtiming'}{'diskreadscount'} > 0 ) {
	$generalresults{'readtiming'}{'diskreads'} /= $generalresults{'readtiming'}{'diskreadscount'};
	print "diskreads,".($generalresults{'readtiming'}{'diskreadsmin'}/1048576).",".($generalresults{'readtiming'}{'diskreads'}/1048576).",".($generalresults{'readtiming'}{'diskreadsmax'}/1048576).",MB/s (min/avg/max)\n";
}
for my $type ('direct','') {
	if ( $type eq '' ) {
		print "\nStandard (not DirectIO)---------------\n";
	} elsif ( $type eq 'direct' ) {
		print "\nDirectIO------------------------------\n";
	}
	if ( exists $iozoneresults{"${type}throughput"} ) {
		print "\nThroughput (MB/s)\n";
		print "threads";
		foreach my $function ('linearwrite','linearrewrite','linearread','linearreread','randomread','randomwriters') {
			print ",$function";
		}
		print "\n";
		foreach my $threads (sort {$a<=>$b} keys %{$iozoneresults{"${type}throughput"}} ) {
			print $threads;
			foreach my $function ('linearwrite','linearrewrite','linearread','linearreread','randomread','randomwriters') {
				if ( defined $iozoneresults{"${type}throughput"}{$threads}{$function} ) {
					print ",".($iozoneresults{"${type}throughput"}{$threads}{$function}/1048576);	# converted to MB/s
				} else {
					print ",";
				}
			}
			print "\n";
		}
	}
	if ( exists $iozoneresults{"${type}iops"} ) {
		print "\nIOPS\n";
		print "threads";
		foreach my $function ('linearwrite','linearrewrite','linearread','linearreread','randomread','randomwriters') {
			print ",$function";
		}
		print "\n";
		foreach my $threads (sort {$a<=>$b} keys %{$iozoneresults{"${type}iops"}} ) {
			print $threads;
			foreach my $function ('linearwrite','linearrewrite','linearread','linearreread','randomread','randomwriters') {
				if ( $iozoneresults{"${type}iops"}{$threads}{$function} ) {
					print ",".$iozoneresults{"${type}iops"}{$threads}{$function};
				} else {
					print ",";
				}
			}
			print "\n";
		}
		# timing equivalents
		print "\nResponse times (ms)\n";
		print "threads";
		foreach my $function ('linearwrite','linearrewrite','linearread','linearreread','randomread','randomwriters') {
			print ",$function";
		}
		print "\n";
		foreach my $threads (sort {$a<=>$b} keys %{$iozoneresults{"${type}iops"}} ) {
			print $threads;
			foreach my $function ('linearwrite','linearrewrite','linearread','linearreread','randomread','randomwriters') {
				if ( defined $iozoneresults{"${type}iops"}{$threads}{$function} ) {
					print ",".(1000*$threads/$iozoneresults{"${type}iops"}{$threads}{$function});
				} else {
					print ",";
				}
			}
			print "\n";
		}
	}
}



sub tobaseunit {
	my ( $value, $unit ) = @_;
	$unit = lc $unit;
	if ( $unit eq '' ) { return $value; }
	$value *= 1024;
	if ( $unit eq 'k' ) { return $value; }
	$value *= 1024;
	if ( $unit eq 'm' ) { return $value; }
	$value *= 1024;
	if ( $unit eq 'g' ) { return $value; }
	$value *= 1024;
	if ( $unit eq 't' ) { return $value; }
	return -1;
}




