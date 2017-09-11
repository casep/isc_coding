#!/usr/bin/perl
use strict;
use warnings;


# read in to header
my @fields;
while ( defined ( my $line = <STDIN> ) ) {
	chomp $line;
	$line =~ s/\r$//;
	my %fields = map { $_ => 1 } split ( ',', $line );
	foreach (keys %fields) { print ">$_\n"; }
	print "\n";
	if (exists ($fields{Name} )
		and exists ( $fields{'ISC username'} )
		and exists ( $fields{'%wheel'} )
		and exists ( $fields{'%cachegrp'} )
		and exists ( $fields{'%trakcache'} )
		and exists ( $fields{'%trakprint'} )
		and exists ( $fields{'Initial password'} )
	) {
		@fields = split ( ',', $line );
		last;
	}
}
if ( @fields == 0 ) { die "FATAL - could not find valid header\n"; }
# read and process users
while ( defined ( my $line = <STDIN> ) ) {
	chomp $line;
	$line =~ s/\r$//;
	my $count = 0;
	my %user = map { $fields[$count++] => $_ } split ( ',', $line );
	# sanity check
	if ( $user{'ISC username'} !~ /^\w+$/ ) { die "FATAL - user \"$user{'ISC username'}\" is not alphanumeric\n"; }
	# check if user exists
	if ( getpwnam ( $user{'ISC username'} ) ) {
		print "Existing $user{'ISC username'} ($user{Name})\n";
		next;
	} else {
		print "Adding $user{'ISC username'} ($user{Name})\n";
	}
	# work out our groups
	my %groups;
	if ( $user{'%wheel'} =~ /^yes$/i ) { $groups{wheel} = 1; }
	if ( $user{'%cachegrp'} =~ /^yes$/i ) { $groups{cachegrp} = 1; }
	if ( $user{'%trakcache'} =~ /^yes$/i ) { $groups{trakcache} = 1; }
	if ( $user{'%trakprint'} =~ /^yes$/i ) { $groups{trakprint} = 1; }
	# add the user - prepare the command
	my @command = ( 'useradd', '--create-home', '--comment', $user{Name} );
	if ( $groups{cachegrp} ) {
		push ( @command, '--gid', 'cachegrp' );
		delete $groups{cachegrp};
	}
	push ( @command, '--groups', join ( ',', keys %groups ) );
	push ( @command, $user{'ISC username'} );
	print "Executing: ".join(' ',@command)."\n";
	system ( @command ) == 0 or die "FATAL - adding user failed with exit $?\n";
	# set the password
	open my $pw, '|-', "passwd '$user{'ISC username'}'" or die "FATAL - can't run passwd: $!\n";
	print $pw "$user{'Initial password'}\n";
	print $pw "$user{'Initial password'}\n";
	close $pw;
	# all done
	print "\n";
}





