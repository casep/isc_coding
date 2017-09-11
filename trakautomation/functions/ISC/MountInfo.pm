package ISC::MountInfo;
# Class for handling Mountpoint Info
# Glen Pitt-Pladdy (ISC)
use strict;
use warnings;
require ISC::PlatformDetect;



sub new {
	my ( $class, $platforminfo ) = @_;
	my $self = {};
	if ( defined ( $platforminfo ) ) {
		$self->{platforminfo} = $platforminfo;
	} else {
		$self->{platforminfo} = new ISC::PlatformDetect ();
	}
	if ( ! defined ( $self->{platforminfo} ) ) { return undef; }
	# we need the class to be valid already....
	my $obj = bless ( $self, $class );
	# gather info for the particular platform
	foreach (@{$self->{platforminfo}->{OStry}}) {
		if ( $_ eq 'LINUX' ) {
			$obj->_mounts_LINUX ();
			last;
		} elsif ( $_ eq 'AIX' ) {
			$obj->_mounts_AIX ();
			last;
		}
	}
	if ( ! $self->{mountinfo} ) { return undef; }	# OS not supported / matched
	return $obj;
}


# query mount info for a mountpoint, searching the most appropriate mountpoint
sub mountinfo {
	my ( $self, $path ) = @_;
	$path =~ s/(.)\/$/$1/;
	my $matchedmountpoint;
	foreach my $mountpoint (reverse sort keys %{$self->{mountinfo}}) {	# sort reverse to match longest mountpoints first
		if ( $mountpoint eq $path ) {	# exact match
			$matchedmountpoint = $mountpoint;
			last;
		}
		my $parent = substr ( $path, 0, length ( $mountpoint ) );
		if ( $parent ne $mountpoint ) { next; }
		my $remainder = substr ( $path, length ( $mountpoint ) );
		if ( $remainder =~ /^\// or $parent eq '/' ) {
			# got it
			$matchedmountpoint = $mountpoint;
			last;
		}
	}
	if ( ! defined ( $matchedmountpoint ) ) {
		return undef;	# can't find mountpoint\n";
	}
	return ( $matchedmountpoint, $self->{mountinfo}->{$matchedmountpoint} );
}



sub _mounts_AIX {
	my ( $self ) = @_;
	open ( my $fh, '-|', 'mount | tail -n +3' ) or die "$0: FATAL - can't run 'mount': $!\n";	# starts at 3rd line
	while ( defined ( my $line = <$fh> ) ) {
		chomp $line;
		if ( $line eq '' ) { next; }
		my ( $node, $device, $mountpoint, $filesystem, $options );
		if ( $line =~ /^([^ ]+) +([^ ]+) +(\/[^ ]*) +([^ ]+) +\d+ \w+ \d+\:\d+ +([^ ]+) *$/ ) {	# NFS with options
			( $node, $device, $mountpoint, $filesystem, $options ) = ( $1, $2, $3, $4, $5 );
			$device = "$node:$device";
		} elsif ( $line =~ /^([^ ]+) +([^ ]+) +(\/[^ ]*) +([^ ]+) +\d+ \w+ \d+\:\d+ *$/ ) {	# NFS no options
			( $node, $device, $mountpoint, $filesystem, $options ) = ( $1, $2, $3, $4, '' );
			$device = "$node:$device";
		} elsif ( $line =~ /^ +([^ ]+) +(\/[^ ]*) +([^ ]+) +\d+ \w+ \d+\:\d+ +([^ ]+) *$/ ) {	# Block with options
			( $device, $mountpoint, $filesystem, $options ) = ( $1, $2, $3, $4 );
		} elsif ( $line =~ /^ +([^ ]+) +(\/[^ ]*) +([^ ]+) +\d+ \w+ \d+\:\d+ *$/ ) {		# Block no options
			( $device, $mountpoint, $filesystem, $options ) = ( $1, $2, $3, '' );
		} else {
			die "$0: FATAL - can't parse 'mount' line: $line\n";
		}
		$mountpoint =~ s/(.)\/$/$1/;
		$self->{mountinfo}->{$mountpoint} = {
			mountpoint => $mountpoint,
			device => $device,
			filesystem => $filesystem,
			options => $options,
		};
	}
	close ( $fh );
}
sub _mounts_LINUX {
	my ( $self ) = @_;
	open ( my $fh, '<', '/proc/mounts' ) or die "$0: FATAL - can't open '/proc/mounts': $!\n";
	while ( defined ( my $line = <$fh> ) ) {
		chomp $line;
		if ( $line !~ /^([^ ]+) (\/[^ ]*) ([^ ]+) ([^ ]+) \d+ \d+$/ ) {
			die "$0: FATAL - can't parse '/proc/mounts' line: $line\n";
		}
		my ( $device, $mountpoint, $filesystem, $options ) = ( $1, $2, $3, $4 );
		if ( $device eq 'rootfs' ) { next; }
		$mountpoint =~ s/(.)\/$/$1/;
		$self->{mountinfo}->{$mountpoint} = {
			mountpoint => $mountpoint,
			device => $device,
			filesystem => $filesystem,
			options => $options,
		};
	}
	close ( $fh );
}


1;
