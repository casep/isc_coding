package ISC::iniFile;
# Class for handling .ini files
# Glen Pitt-Pladdy (ISC)
use strict;
use warnings;



sub new {
	my ( $class, $file, $mode ) = @_;
	my $self = {};
	$self->{file} = $file;
	$self->{mode} = $mode;
	$self->{format} = 'Unix';
	if ( ! defined ( $mode ) or $mode =~ /r/ ) {
		$self->{modeR} = 1;
		# must read this file in
		my $fp;
		if ( ! open $fp, '<', $file ) {
			warn __PACKAGE__.":".__LINE__." Error reading \"$file\": $!\n";
			return undef;
		}
		my $section;
		my $linecount = 0;
		while ( defined ( my $line = <$fp> ) ) {
			chomp $line;
			if ( $line =~ s/\r$// ) { $self->{format} = 'DOS'; }
			++$linecount;
			if ( $line =~ /^;/ or $line =~ /^$/ ) {
				# comment/blank
				next;
			} elsif ( $line =~ /^\[([^\]]+)\]/ ) {
				# got a section
				$section = $1;
				push @{$self->{sectionorder}}, $1;
			} elsif ( $line =~ /^([^=]+)=(.*)$/ ) {
				if ( ! defined ( $section ) ) {
					warn __PACKAGE__.":".__LINE__." got parameter without section in \"$file\"\n";
					return undef;
				} else {
					push @{$self->{parameterorder}->{$section}}, $1;
					$self->{parameters}->{$section}->{$1} = $2;
				}
			} else {
				warn __PACKAGE__.":".__LINE__." can't parse line $linecount in \"$file\"\n";
				return undef;
			}
		}
		close $fp;
	}
	if ( $mode =~ /w/ ) {
		$self->{modeW} = 1;
		# writing enabled
	}

	return bless ( $self, $class );
}


sub write {
	my ( $self ) = @_;
	if ( ! $self->{modeW} ) {
		warn __PACKAGE__.':'.__LINE__." write mode not enabled on this object\n";
		return 0;
	}

	# TODO TODO TODO TODO TODO
	# append any new sections onto @{$self->{sectionorder}}
	my %existsect = map { $_ => 1 } @{$self->{sectionorder}};
	foreach (sort keys (%{$self->{parameters}})) {
		if ( ! $existsect{$_} ) { push @{$self->{sectionorder}}, $_; }
	}
	# append any new parameters onto @{$self->{parameterorder}->{$section}}
	foreach my $section (@{$self->{sectionorder}}) {
		if ( ! exists ( $self->{parameters}->{$section} ) ) { next; }
		my %existing = map { $_ => 1 } @{$self->{parameterorder}->{$section}};
		foreach (sort keys (%{$self->{parameters}->{$section}})) {
			if ( ! $existing{$_} ) {
				push @{$self->{parameterorder}->{$section}}, $_;
			}
		}
	}
	# write to temporary file
	my $fd;
	if ( ! open ( $fd, '>', "$self->{file}.TMP" ) ) {
		warn "Can't write file \"$self->{file}.TMP\": $!\n";
		return undef;
	}
	my $existingsections = 0;
	foreach my $section (@{$self->{sectionorder}}) {
		if ( ! exists ( $self->{parameters}->{$section} ) ) { next; }
		if ( $existingsections ) { print $fd "\n"; }
			else { ++$existingsections; }
		print $fd "[$section]\n";
		foreach my $parameter (@{$self->{parameterorder}->{$section}}) {
			if ( ! exists ( $self->{parameters}->{$section}->{$parameter} ) ) { next; }
			print $fd "$parameter=$self->{parameters}->{$section}->{$parameter}\n";
		}
	}
	close ( $fd );
	# set the permissions from the old file
	my @stat = stat ( $self->{file} );
	if ( ! chown ( $stat[4], $stat[5], "$self->{file}.TMP" ) ) {	# owner, group
		warn "Can't set owner/group file \"$self->{file}.TMP\": $!\n";
		return undef;
	}
	if ( ! chmod ( $stat[2], "$self->{file}.TMP" ) ) {	# permissions
		warn "Can't set owner/group file \"$self->{file}.TMP\": $!\n";
		return undef;
	}
	# TODO rename file, overwriting the original
	if ( ! rename ( "$self->{file}.TMP", $self->{file} ) ) {
		warn "Can't rename \"$self->{file}.TMP\" to \"$self->{file}\": $!\n";
		return undef;
	}
	return 1;
}



# module must return true
1;
