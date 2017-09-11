use strict;
use warnings;
# Glen Pitt-Pladdy 20130305
#
# This class handles shuffling databases around for TrakCare upgrades
#
#


package database_shuffle;


sub new {
	my $class = shift;
	my $self = {
		'org' => shift,
		'environment' => shift,
		# below this are optional
		'basepath' => shift,
		'dbpath' => shift,
		'confpath' => shift,
		'dbprefix' => shift,
		# internal storage hashes / arrays
		'dbconfig' => {},
		'dbflags' => {},
		'create' => [],
		'move' => {},
		'remove' => [],
	};
	# santity check and defaults
	if ( ! defined $self->{'org'} or ! defined $self->{'environment'} ) {
		die "FATAL - requrie at least ORG and Environment as arguments in ".__FILE__." on line ".__LINE__."\n";
	}
	if ( ! defined  $self->{'basepath'} ) {
		$self->{'basepath'} = "/trak/$self->{org}/$self->{environment}";
		warn "NOTE - setting Base Path to \"$self->{basepath}\"\n";
	}
	if ( ! -d $self->{'basepath'} ) {
		die "FATAL - Base Path \"$self->{basepath}\" doesn't exist in ".__FILE__." on line ".__LINE__."\n";
	}
	if ( ! defined $self->{'dbpath'} ) {
		$self->{'dbpath'} = "$self->{basepath}/db";
		warn "NOTE - setting Database Path to \"$self->{dbpath}\"\n";
	}
	if ( ! -d $self->{'dbpath'} ) {
		die "FATAL - Database Path \"$self->{dbpath}\" doesn't exist in ".__FILE__." on line ".__LINE__."\n";
	}
	if ( ! -f "$self->{dbpath}/BLANK/CACHE.DAT" ) {
		die "FATAL - BLANK Database Path \"$self->{dbpath}/BLANK\" isn't valid in ".__FILE__." on line ".__LINE__."\n";
	}
	if ( ! defined $self->{'confpath'} ) {
		$self->{'confpath'} = "$self->{basepath}/hsf/cache.cpf";
		warn "NOTE - setting Config (.cpf) Path to \"$self->{confpath}\"\n";
	}
	if ( ! -f $self->{'confpath'} ) {
		die "FATAL - Config (.cpf) Path \"$self->{confpath}\" doesn't exist in ".__FILE__." on line ".__LINE__."\n";
	}
	if ( ! defined $self->{'dbprefix'} ) {
		$self->{'dbprefix'} = uc ( $self->{'org'} ).'-'.$self->{'environment'};
		warn "NOTE - setting Database Prefix to \"$self->{dbprefix}\"\n";
	}
	# pull in config
	# read in the existing database config
	open my $cpf, '<', $self->{confpath} or die "FATAL - can't read \"$self->{confpath}\": $!\n";
	while ( defined ( my $line = <$cpf> ) ) {
		if ( $line =~ /^\[Databases\]$/ ) { last; }
	}
	while ( ! eof $cpf and  defined ( my $line = <$cpf> ) ) {
		chomp $line;
		if ( $line =~ /^$/ ) { next; }
		if ( $line =~ /^\[/ ) { last; }
		# we have a database line - put it into %dbconfig / %dbflags
		if ( $line !~ s/^([^=]+)=(\/[^,]+)// ) {
			die "FATAL - can't parse: $line\n";
		}
		$self->{dbconfig}->{$1} = "$2/";
		$self->{dbflags}->{$1} = $line;
		$self->{dbconfig}->{$1} =~ s/\/\/$/\//;
	}
	# done - complete object
	bless $self, $class;
	return $self;
}


##############################################################################
# Methods for rearranging databases - call these to set the required canges
##############################################################################

# move/rename a database
sub dbmove {
	my ( $self, $source, $destination ) = @_;
	# generate directory names in lower case
	my $dirfrom = lc $source;
	my $dirto = lc $destination;
	# generate upper case database names
	my $dbfrom = uc $source;
	$dbfrom =~ s/^.*\///;
	$dbfrom = "$self->{dbprefix}-$dbfrom";
	my $dbto = uc $destination;
	$dbto =~ s/^.*\///;
	$dbto = "$self->{dbprefix}-$dbto";
	# find the source and generate the destination directories
	my $pathfrom = "$self->{dbpath}/$dirfrom/";
	$pathfrom =~ s/\/\/$/\//;
	my $pathto = "$self->{dbpath}/$dirto/";
	$pathto =~ s/\/\/$/\//;
	print "queue moving $dbfrom to $dbto\n";
	if ( $self->{dbconfig}->{$dbfrom} ne $pathfrom ) {
		die "FATAL - database path for $dbfrom is \"$self->{dbconfig}->{$dbfrom}\" but expected \"$pathfrom\"\n";
	}
	if ( ! -d $pathfrom ) {
		die "FATAL - \"$pathfrom\" doesn't exist!\n";
	}
	if ( -d $pathto ) {
		die "FATAL - \"$pathto\" already exists!\n";
	}
	if ( exists $self->{dbconfig}->{$dbto} ) {
		die "FATAL - destination database \"$dbto\" already exists in config!\n";
	}
	# set the move
	$self->{move}->{$pathfrom} = $pathto;
	# clear existing config
	my $flags = $self->{dbflags}->{$dbfrom};
	delete $self->{dbconfig}->{$dbfrom};
	delete $self->{dbflags}->{$dbfrom};
	# set new config
	$self->{dbflags}->{$dbto} = $flags;
	$self->{dbconfig}->{$dbto} = $pathto;
}

sub dbcreate {
	my ( $self, $dbname ) = @_;
	# generate directory names in lower case
	my $dir = lc $dbname;
	# generate upper case database name
	my $db = uc $dbname;
	$db =~ s/^.*\///;
	$db = "$self->{dbprefix}-$db";
	# generate the path
	my $path = "$self->{dbpath}/$dir/";
	$path =~ s/\/\/$/\//;
	print "queue creating $db\n";
	if ( -d $path ) {
		die "FATAL - \"$path\" already exists!\n";
	}
	if ( exists $self->{dbconfig}->{$db} ) {
		die "FATAL - database \"$db\" already exists in config!\n";
	}
	# set the create
	push @{$self->{create}}, $path;
	# add config
	$self->{dbconfig}->{$db} = $path;
}

sub dbremove {
	my ( $self, $dbname ) = @_;
	# generate directory names in lower case
	my $dir = lc $dbname;
	# generate upper case database name
	my $db = uc $dbname;
	$db =~ s/^.*\///;
	$db = "$self->{dbprefix}-$db";
	# generate the path
	my $path = "$self->{dbpath}/$dir/";
	$path =~ s/\/\/$/\//;
	print "queue removing $db\n";
	if ( ! -d $path ) {
		die "FATAL - \"$path\" doesn't exist!\n";
	}
	if ( ! exists $self->{dbconfig}->{$db} ) {
		die "FATAL - database \"$db\" doesn't exist in config!\n";
	}
	# set the create
	push @{$self->{remove}}, $path;
	# add config
	delete $self->{dbconfig}->{$db};
}


# IMPORTANT - this actually kicks off the changes for real
sub comit {
	my ( $self ) = @_;
	# make safe
	$self->_stopenv();
	# shuffle databases
	$self->_dboperations();
	# write the config
	$self->_writeconfig();
	# resume operation (hopefully!)
	$self->_startenv();
}




##############################################################################
# Methods that do the work - should not normally be called directly
#	... hence private (not!)
##############################################################################

# create parent directories - internal (privete... not!) use only
sub _createparents {
	my ( $self, $dir, $final ) = @_;
	if ( ! defined $final ) { $final = 0; }
	$dir =~ s/\/+$//;
	my $parent = $dir;
	$parent =~ s/\/[^\/]+$//;
	# if parent doesn't exist create that
	if ( ! -d $parent ) {
		$self->_createparents ( $parent, 0 );
	}
	# create this directory
	if ( ! $final ) {
		mkdir $dir
			or die "FATAL - can't create directory \"$dir\": $!\n";
		my @stat = stat $parent;
		chown $stat[4], $stat[5], $dir
			or die "FATAL - can't change ownership of directory \"$dir\": $!\n";
		chmod $stat[2], $dir
			or die "FATAL - can't change premission of directory \"$dir\": $!\n";
	}
}




sub _writeconfig {
	my ( $self ) = @_;
	# read in the existing database config writing a temporary one
	open my $cpf, '<', $self->{confpath} or die "FATAL - can't read \"$self->{confpath}\": $!\n";
	open my $cpftmp, '>', "$self->{confpath}.TMP" or die "FATAL - can't write \"$self->{confpath}.TMP\": $!\n";
	while ( defined ( my $line = <$cpf> ) ) {
		print $cpftmp $line;
		if ( $line =~ /^\[Databases\]$/ ) { last; }
	}
	foreach my $db (sort keys %{$self->{dbconfig}}) {
		print $cpftmp "$db=$self->{dbconfig}->{$db}";
		if ( exists $self->{dbflags}->{$db} ) {
			print $cpftmp $self->{dbflags}->{$db};
		}
		print $cpftmp "\n";
	}
	print $cpftmp "\n";
	while ( ! eof $cpf and  defined ( my $line = <$cpf> ) ) {
		if ( $line =~ /^\[/ ) {
			print $cpftmp $line;
			last;
		}
	}
	my @lines = <$cpf>;
	print $cpftmp @lines;
	close $cpf;
	close $cpftmp;
	# transfer permissions / ownership
	my @stat = stat $self->{confpath};
	chown $stat[4], $stat[5], "$self->{confpath}.TMP"
		or die "FATAL - can't change ownership of \"$self->{confpath}.TMP\": $!\n";
	chmod $stat[2], "$self->{confpath}.TMP"
		or die "FATAL - can't change premission of \"$self->{confpath}.TMP\": $!\n";
	# move
	rename "$self->{confpath}.TMP", $self->{confpath}
		or die "FATAL - can't rename \"$self->{confpath}.TMP\" to \"$self->{confpath}\": $!\n";
}

sub _dboperations {
	my ( $self ) = @_;
	# move databases
	foreach my $source (sort keys %{$self->{move}}) {
		# create a temporary in-between location to avoid clashes
		my $tmp = $source;
		$tmp =~ s/\/+$//;
		$tmp .= '.TMP';
		print "moving: \"$source\" to \"$self->{move}->{$source}\n";
		system "mv", $source, $tmp;	# in-between to avoid clashes
		$self->_createparents ( $self->{move}->{$source}, 1 );
		system "mv", $tmp, $self->{move}->{$source};
	}
	# create databases
	foreach my $db (sort @{$self->{create}}) {
		print "creating: \"$db\" from \"$self->{dbpath}/BLANK\"\n";
		$self->_createparents ( $db, 1 );
		system 'cp', '-a', "$self->{dbpath}/BLANK", $db;
	}
	# remove databases
	foreach my $db (sort @{$self->{remove}}) {
		print "removing: \"$db\"\n";
		system 'rm', '-r', $db;
	}
}


# make safe before changes
sub _stopenv {
	my ( $self ) = @_;
	my $instance = uc ( $self->{'org'} );
	$instance .= $self->{'environment'};
	$instance .= 'DB';
	system "ccontrol stop $instance nouser";
	if ( $? == -1 ) {
		die "FATAL - failed to stop $instance: $!\n";
	} elsif ( $? & 127 ) {
		die sprintf ( "FATAL - stopping $instance died with signal %d\n", $? & 127 );
	} else {
		my $ret = $? >> 8;
		if ( $ret != 0 ) {
			die "FATAL - stopping $instance exited with value $ret\n";
		}
	}
}
# resume operation
sub _startenv {
	my ( $self ) = @_;
	my $instance = uc ( $self->{'org'} );
	$instance .= $self->{'environment'};
	$instance .= 'DB';
	system "ccontrol start $instance";
}





1;
