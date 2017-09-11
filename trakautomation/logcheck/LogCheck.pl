#!/usr/bin/perl
use strict;
use warnings;

sub readrulefiles {
	my ( $glob ) = @_;
	my @rules;
	foreach my $file (glob($glob)) {
		my $fin;
		if ( open $fin, '<', $file ) {
			while ( defined ( my $line = <$fin> ) ) {
				chomp $line;
				if ( $line eq '' or $line =~ /^#/ ) { next; }
				push @rules, $line;
			}
			close $fin;
		} else {
			warn "WARNING - can't read \"$file\": $!\n";
		}
	}
	return \@rules;
}

sub readrules {
	my ( $ruleset ) = @_;
	my %rules;
	$rules{'ignore'} = readrulefiles ( "checks.d/logcheck/$ruleset-rules.d/ignore.d*/*" );
	$rules{'violations'} = readrulefiles ( "checks.d/logcheck/$ruleset-rules.d/violations.d*/*" );
	$rules{'violations.ignore'} = readrulefiles ( "checks.d/logcheck/$ruleset-rules.d/violations.ignore.d*/*" );
	$rules{'cracking'} = readrulefiles ( "checks.d/logcheck/$ruleset-rules.d/cracking.d*/*" );
	return \%rules;
}

sub processLine {
	my ( $prefix, $line, $rules, $reports, $counters ) = @_;
	# process generic gnores - skip if we find a match
	my $skip = 0;
	foreach my $pattern (@{$$rules{'ignore'}}) {
		if ( $line =~ /$pattern/ ) { $skip=1; last; }
	}
	if ( ! $skip ) {
		my $fh = $$reports{'ignore'};
		print $fh "$prefix$line\n";
		++$$counters{'ignore'};
	}
	# process violations, check for, then ignore
	$skip = 1;
	foreach my $pattern (@{$$rules{'violations'}}) {
		if ( $line =~ /$pattern/ ) { $skip = 0; last; }
	}
	if ( ! $skip ) {
		foreach my $pattern (@{$$rules{'violations.ignore'}}) {
			if ( $line =~ /$pattern/ ) { $skip = 1; last; }
		}
	}
	if ( ! $skip ) {
		my $fh = $$reports{'violations'};
		print $fh "$prefix$line\n";
		++$$counters{'violations'};
	}
	# process cracking, check
	foreach my $pattern (@{$$rules{'cracking'}}) {
		if ( $line =~ /$pattern/ ) {
			my $fh = $$reports{'cracking'};
			print $fh "$prefix$line\n";
			++$$counters{'cracking'};
			last;
		}
	}
}

sub processLog {
	my ( $type, $log, $basename, $rules ) = @_;
	my $fin;
	if ( ! open $fin, '<', $log ) {
		warn "ERROR - can't read log \"$log\": $!\n";
		return 0;
	}
	# open output report files
	my %reports;
	my %counters;
	my %reportnames = (
		'ignore' => "$basename-ignore.out", 
		'violations' => "$basename-violations.out", 
		'cracking' => "$basename-cracking.out", 
	);
	foreach my $report (keys %reportnames) {
		$counters{$report} = 0;
		if ( ! open $reports{$report}, '>', $reportnames{$report} ) {
			warn "ERROR - can't write report \"$reportnames{$report}\": $!\n";
			return 0;
		}
	}
	# process the log
	my $prefix = '';
	while ( defined ( my $line = <$fin> ) ) {
		chomp $line;
		$line =~ s/\r$//;
		if ( $type eq 'CSP' ) {
			if ( $line =~ /^>>> Time: / ) {
				$prefix = $line;
			} else {
				processLine ( "$prefix\n", $line, $rules, \%reports, \%counters );
			}
		} elsif ( $type eq 'Cache' ) {
			if ( $line eq '' ) { next; }
			if ( $line =~ /^\d+\/\d+\/\d+-\d+:\d+:\d+:\d+ \(\d+\) 0 $/
) {
#				or $line =~ s/^(Cache-CSTAT \(\d+\) \w+ \w+ \d+ \d+:\d+:\d+ \d{4})$/$1 / ) {
				# this must be the start of a multi-line log
				$prefix = $line;
			} elsif ( $line =~ /^\d+\/\d+\/\d+-\d+:\d+:\d+:\d+ \(\d+\) \d ./
				or $line =~ /^\d+\/\d+-\d+:\d+:\d+:\d+ \(\d+\) \d ./ ) {
				# got a regular log - flush last multi-line first
				$prefix = '';
				processLine ( '', $line, $rules, \%reports, \%counters );
			} else {
				processLine ( $prefix, $line, $rules, \%reports, \%counters );
			}
		} else {
			processLine ( '', $line, $rules, \%reports, \%counters );
		}
	}
	close $fin;
	# wrap up reports
	foreach my $report (keys %reports) {
		close $reports{$report};
		if ( -z $reportnames{$report} ) { unlink $reportnames{$report}; }
	}
}



sub detectOS {
	open my $fin, '<', '/etc/issue' or die "FATAL - can't read \"/etc/issue\": $!\n";
	my %info;
	while ( defined ( my $issue = <$fin> ) ) {
		# check Linux flavours
		if ( $issue =~ /^Red Hat Enterprise Linux Server release ([\d\.]+) \(.*$/ ) {
			$info{'distro'} = 'RHEL';
			$info{'version'} = $1;
		} elsif ( $issue =~ /^Debian GNU\/LINUX ([\d\.]+) .*$/ ) {
			$info{'distro'} = 'Debian';
			$info{'version'} = $1;
		} elsif ( $issue =~ /^CentOS release ([\d\.]+) .*$/ ) {
			$info{'distro'} = 'CentOS';
			$info{'version'} = $1;
		} elsif ( $issue =~ /^.*SUSE Linux Enterprise Server (\d+) SP(\d+) .*$/ ) {
			$info{'distro'} = 'SLES';
			$info{'version'} = "$1SP$2";
		} elsif ( $issue =~ /^Ubuntu ([\d\.]+) .*$/ ) {
			$info{'distro'} = 'Ubuntu';
			$info{'version'} = $1;
		}
		if ( defined $info{'distro'} ) {
			$info{'kernel'} = 'LINUX';
			$info{'family'} = 'Unix';
			last;
		}
		# TODO check others
	}
	close $fin;
	return \%info;
}




my $workdir = "/tmp/ISCLogCheck.$$";
if ( ! -d $workdir ) { mkdir $workdir; }

my $rules;

if ( -f '/opt/cspgateway/bin/CSP.log' ) {
	$rules = readrules ( 'CSP' );
	processLog ( 'CSP', '/opt/cspgateway/bin/CSP.log', "$workdir/CSP", $rules );
}

$rules = readrules ( 'ApacheAccess' );
if ( -f '/var/log/apache/access_log' ) {
	processLog ( 'ApacheError', '/var/log/apache/access_log', "$workdir/ApacheAccess", $rules );
}
if ( -f '/var/log/apache2/access_log' ) {
	processLog ( 'ApacheError', '/var/log/apache2/access_log', "$workdir/ApacheAccess", $rules );
}
if ( -f '/var/log/httpd/access_log' ) {
	processLog ( 'ApacheError', '/var/log/httpd/access_log', "$workdir/ApacheAccess", $rules );
}

$rules = readrules ( 'ApacheError' );
if ( -f '/var/log/apache/error_log' ) {
	processLog ( 'ApacheError', '/var/log/apache/error_log', "$workdir/ApacheError", $rules );
}
if ( -f '/var/log/apache2/error_log' ) {
	processLog ( 'ApacheError', '/var/log/apache2/error_log', "$workdir/ApacheError", $rules );
}
if ( -f '/var/log/httpd/error_log' ) {
	processLog ( 'ApacheError', '/var/log/httpd/error_log', "$workdir/ApacheError", $rules );
}

# need Cache instances
open my $cc, '-|', 'ccontrol qlist' or die "FATAL - can't run \"ccontrol qlist\": $!\n";
while ( defined ( my $line = <$cc> ) ) {
	chomp $line;
	if ( $line !~ /^(\w+)\^([^\^]+)\^/ ) { next; }
	my $name = $1;
	my $instance = $2;
	$rules = readrules ( 'Cache' );
	processLog ( 'Cache', "$instance/mgr/cconsole.log", "$workdir/Cache:$name", $rules );
}
close $cc;

# need to know OS for system logs
my $info = detectOS();
if ( ! defined ( $$info{'kernel'} ) ) {
	die "FATAL - can't detect OS\n";
} elsif ( $$info{'kernel'} eq 'LINUX' ) {
	$rules = readrules ( 'Linux' );
	processLog ( 'Linux', '/var/log/messages', "$workdir/OS", $rules );
}









