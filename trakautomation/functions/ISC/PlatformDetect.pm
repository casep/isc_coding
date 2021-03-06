package ISC::PlatformDetect;
# Class for handling Platform Detection
# Glen Pitt-Pladdy (ISC)
#
# When a new object is created the following info is available:
#
# $self->{OShierarchy}=[]	# most specific to most generic OS classification
# $self->{OStry}=[]	# as above, but this would include aditional compatible classifications (eg. CentOS would include RHEL classificaitons)
# $self->{processor} = (x86|x86_64|powerpc)
# $self->{cpus} = NN
# $self->{bits} = (32|64)
# $self->{system}=""	# has the system/platform description (eg. from dmidecode on Linux)
# $self->{virtual}=""	# has the virtual system/platform description (eg. from dmidecode on Linux), empty/nonexistant for non-virtual
# $self->{memory} TODO
# 

use strict;
use warnings;



sub new {
	my ( $class ) = @_;
	my $self = {};

	# find the major OS
	if ( defined ( $ENV{PLATFORM_OShierarchy} ) and defined ( $ENV{PLATFORM_OStry} ) ) {
		# we already found the relevant info in the environment, use that if available to avoid re-detection
		foreach my $var (keys %ENV) {
			if ( $var =~ /^PLATFORM_(\w+)$/ ) {
				$self->{$1} = $ENV{$var};
			}
		}
		foreach ('OShierarchy','OStry') {
			my @list = split ( ' ', $self->{$_} );
			$self->{$_} = \@list;
		}
	} elsif ( $^O eq 'linux' ) {
		$self->{OShierarchy} = [ 'LINUX', 'Unix' ];
		$self->{OStry} = [ 'LINUX', 'Unix' ];
		my $id;
		my %detail;
		# CentOS /etc/centos-release and /etc/redhat-release so must be before RH
		if ( _readid ( '/etc/centos-release', \$id ) ) {
			# eg. CentOS release 6.3 (Final)
			# CentOS Linux release 7.1.1503 (Core)
#
#			if ( $id !~ /^(CentOS) release ([\d\.]+) \(\w+\)$/ ) {
#				if ( $id !~ /^(CentOS) Linux release ([\d\.]+) \(\w+\)$/ ) {
#					warn __PACKAGE__.':'.__LINE__." can't parse /etc/centos-release id: $id\n";
#					return 0;
#				}
#			}
			my $specificos = 'CentOS';
			#my $specificos = $1;
			my $os = 'RHEL';	# should be compatible - try last
			my $version = '7.1'; 
			#my $version = $2;
			unshift @{$self->{OShierarchy}}, $os;
			unshift @{$self->{OStry}}, $os;
			foreach (split ( '.', $version )) {
				$os .= "_$_";
				unshift @{$self->{OStry}}, $os;
			}
			$os = $specificos;
			unshift @{$self->{OShierarchy}}, $os;
			unshift @{$self->{OStry}}, $os;
			foreach (split ( /\./, $version )) {
				$os .= "_$_";
				unshift @{$self->{OShierarchy}}, $os;
				unshift @{$self->{OStry}}, $os;
			}
		}
		# RedHat puts info in /etc/redhat-release
		elsif ( _readid ( '/etc/redhat-release', \$id ) ) {
			# eg. Red Hat Enterprise Linux Server release 6.3 (Santiago)
			if ( $id !~ /^(Red Hat Enterprise Linux Server) release ([\d\.]+) \(\w+\)$/ ) {
				warn __PACKAGE__.':'.__LINE__." can't parse /etc/redhat-release id: $id\n";
				return 0;
			}
			my $os = 'RHEL';
			my $version = $2;
			unshift @{$self->{OShierarchy}}, $os;
			unshift @{$self->{OStry}}, $os;
			foreach (split ( /\./, $version )) {
				$os .= "_$_";
				unshift @{$self->{OShierarchy}}, $os;
				unshift @{$self->{OStry}}, $os;
			}
		}
		# SuSE puts info in /etc/SuSE-release
		elsif ( _readid ( '/etc/SuSE-release', \$id, \%detail ) ) {
			# eg. SUSE Linux Enterprise Server 11 (x86_64)\nVERSION = 11\nPATCHLEVEL = 2
			if ( $id !~ /^(SUSE Linux Enterprise Server) / or ! exists ( $detail{VERSION} ) or ! exists ( $detail{PATCHLEVEL} ) ) {
				warn __PACKAGE__.':'.__LINE__." can't parse /etc/SuSE-release id: $id\n";
				return 0;
			}
			my $os = 'SLES';
			unshift @{$self->{OShierarchy}}, $os;
			unshift @{$self->{OStry}}, $os;
			foreach ($detail{VERSION},$detail{PATCHLEVEL}) {
				$os .= "_$_";
				unshift @{$self->{OShierarchy}}, $os;
				unshift @{$self->{OStry}}, $os;
			}

		}
		# Debian / Ubuntu puts info in /etc/os-release
		elsif ( _readid ( '/etc/os-release', \$id, \%detail ) ) {
			# eg. NAME="Ubuntu"\nVERSION="12.04.3 LTS, Precise Pangolin"\nID=ubuntu\nID_LIKE=debian\nPRETTY_NAME="Ubuntu precise (12.04.3 LTS)"\nVERSION_ID="12.04"
			# eg. PRETTY_NAME="Debian GNU/Linux 7 (wheezy)"\nNAME="Debian GNU/Linux"\nVERSION_ID="7"\nVERSION="7 (wheezy)"\nID=debian\nANSI_COLOR="1;31"\nHOME_URL="http://www.debian.org/"\nSUPPORT_URL="http://www.debian.org/support/"\nBUG_REPORT_URL="http://bugs.debian.org/"
			my $os;
			my $version;
			if ( $detail{NAME} eq "Debian GNU/Linux" ) {
				$os = "Debian";
				$version = $detail{VERSION_ID};
			} elsif ( $detail{NAME} eq "Ubuntu" ) {
				unshift @{$self->{OStry}}, "Debian";
				$os = $detail{NAME};
				$version = $detail{VERSION_ID};
			} else {
				# got a Debian-like system, but not one we can identify
				warn __PACKAGE__.':'.__LINE__." can't identify this Debian-like system... yet!\n";
				return undef;
			}
			unshift @{$self->{OShierarchy}}, $os;
			unshift @{$self->{OStry}}, $os;
			foreach (split ( /\./, $version )) {
				$os .= "_$_";
				unshift @{$self->{OShierarchy}}, $os;
				unshift @{$self->{OStry}}, $os;
			}
		}
		# detect architecture
		$self->{processor} = `uname -p`;
		chomp $self->{processor};	# uname -p / uname --machine = x86_64
		if ( $self->{processor} !~ /^x86/ ) {
			# not complete for Linux, but we only run with Linux on x86
			warn __PACKAGE__.':'.__LINE__." not getting valid (x86) output from \"uname -p\"\n";
			return undef;
		}
		# detect bits
		if ( $self->{processor} eq 'x86_64' ) {
			$self->{bits} = 64;
		} else {
			$self->{bits} = 32;
		}
		# also detect if virtual
		$self->{system} = `dmidecode -s system-product-name`;
		chomp $self->{system};
		if ( $self->{system} !~ /^\w/ ) {
			# invalid
			warn __PACKAGE__.':'.__LINE__." not getting valid output from \"dmidecode -s system-product-name\"\n";
			return undef;
		}
		if ( $self->{system} =~ /^(VMware|VirtualBox)/ ) {
			$self->{virtual} = $self->{system};
		}
		# detect number of CPUs
		$self->{cpus} = `grep ^processor /proc/cpuinfo | tail -n 1`;
		chomp $self->{cpus};
		if ( $self->{cpus} !~ s/^processor\s+:\s*(\d+)$/$1/ ) {
			# invalid
			warn __PACKAGE__.':'.__LINE__." not getting valid output from \"grep ^processor /proc/cpuinfo | tail -n 1\"\n";
			return undef;
		}
		++$self->{cpus};
		# amount of memory in Bytes
		$self->{memory} = `grep ^MemTotal: /proc/meminfo`;
		chomp $self->{memory};
		if ( $self->{memory} !~ s/^MemTotal:\s*(\d+)\s*kB$/$1/ ) {
			# invalid
			warn __PACKAGE__.':'.__LINE__." not getting valid output from \"grep ^MemTotal: /proc/meminfo\"\n";
			return undef;
		}
		$self->{memory} *= 1024;
	} elsif ( $^O eq 'aix' ) {
		my $os = 'AIX';
		my $version = `oslevel`;
		chomp $version;
		$self->{OShierarchy} = [ $os, 'UNIX', 'Unix' ];
		$self->{OStry} = [ $os, 'UNIX', 'Unix' ];
		foreach (split ( /\./, $version )) {
			$os .= "_$_";
			unshift @{$self->{OShierarchy}}, $os;
			unshift @{$self->{OStry}}, $os;
		}
		# detect architecture
		$self->{processor} = `uname -p`;
		chomp $self->{processor};	# uname -p = powerpc
		if ( $self->{processor} !~ /^power/ ) {
			# not complete for AIX, but we only run with Linux on x86
			warn __PACKAGE__.':'.__LINE__." not getting valid (power*) output from \"uname -p\"\n";
			return undef;
		}
 		# detect bits
		$self->{bits} = `prtconf -k`;	# prtconf -k = 64-bit
		chomp $self->{bits};
		if ( $self->{bits} !~ s/^Kernel Type: (\d+)-bit$/$1/ ) {
			# can't match the line
			warn __PACKAGE__.':'.__LINE__." not getting valid (Kernel Type: NN-bit) output from \"prtconf -k\"\n";
			return undef;
		}
		# TODO also detect if virtual (LPAR/wPAR) TODO
		# wPAR on AIX: uname -W = 0 on host
		# detect number of CPUs
		$self->{cpus} = `prtconf | grep '^Number Of Processors: '`;	# = Number Of Processors: 8
		chomp $self->{cpus};
		if ( $self->{cpus} !~ s/^Number Of Processors:\s*(\d+)$/$1/ ) {
			# can't match the line
			warn __PACKAGE__.':'.__LINE__." not getting valid (Number Of Processors: NN) output from \"printconf\"\n";
			return undef;
		}
		# amount of memory in Bytes TODO
		$self->{memory} = `bootinfo -r`;
		chomp $self->{memory};
		if ( $self->{memory} !~ /^\d+$/ ) {
			# can't match the output
			warn __PACKAGE__.':'.__LINE__." not getting valid NN... output from \"bootinfo -r\"\n";
			return undef;
		}
		$self->{memory} *= 1024;
	} else {
		# there are lots of other options: http://perldoc.perl.org/perlvar.html#%24OSNAME
		# this is one we haven't been taught about yet
		warn __PACKAGE__.':'.__LINE__." we don't know about \$^O = \"$^O\"... yet!\n";
		return undef;
	}




	return bless ( $self, $class );
}


sub _readid {
	my ( $file, $id, $detail ) = @_;
	if ( ! -f $file ) { return undef; }
	my $fh;
	if ( ! open $fh, '<', $file ) {
		warn __PACKAGE__.':'.__LINE__." can't read \"$file\": $!\n";
		return '';
	}
	$$id = <$fh>;
	chomp $$id;
	if ( $$id =~ s/^(\w+)\s?=\s?"(.*)"$/$2/ or $$id =~ s/^(\w+)\s?=\s?(.*?)$/$2/ ) {
		my ( $field, $value ) = ( $1, $2 );
		if ( defined $detail ) {
			$detail->{id} = $value;
			$detail->{$field} = $value;
		}
	}
	# get any named parameters if we can
	if ( defined $detail ) {
		while ( defined ( my $line = <$fh> ) ) {
			chomp $line;
			if ( $line =~ /^(\w+)\s?=\s?"(.*)"$/ or $line =~ /^(\w+)\s?=\s?(.*?)$/ ) {
				my ( $field, $value ) = ( $1, $2 );
				$detail->{$field} = $value;
			}
		}
	}
	close $fh;
	return $$id;
}


# module must return true
1;
