package ISC::CacheInstances;
# Class for querying Caché instances
# Glen Pitt-Pladdy (ISC)
#
# Provides hashes containing fields:
#	name
#	path
#	version
#	status
#	info
#	config
#	superserverport
#	smpport
#	TODOport
# These are indexed in a number of ways:
#	$self->{byname}->{$Name}->{$field}
#	$self->{bypath}->{$Path}->{$field}
#	$self->{bysuperserverport}->{$SuperserverPort}->{$field}
#	$self->{bysmpport}->{$SMPPort}->{$field}
#
use strict;
use warnings;



sub new {
	my ( $class ) = @_;
	my $self = {};

	# parse ccontrol qlist
	my $cc;
	if ( ! open ( $cc, '-|', 'ccontrol qlist' ) ) {
		warn __PACKAGE__.':'.__LINE__." failed to run \"ccontrol qlist\": $!\n";
		return undef;
	}
	while ( defined ( my $line = <$cc> ) ) {
		chomp $line;
#		if ( $line !~ /^(\w+)\^(\/[^\^]+)\^(\d[\d\.]+)\^(\w+), (\w[^\^]+)\^([^\^]+)\^(\d+)\^(\d+)\^(\d+)\^(\w*)\^$/
		if ( $line !~ /^(\w+)\^(\/[^\^]+)\^(\d[\d\.]+)\^(\w+), (\w[^\^]+)\^([^\^]+)\^(\d+)\^(\d+)\^(\d+)\^(\w*)\^$/
			and $line !~ /^(\w+)\^(\/[^\^]+)\^(\d[\d\.]+)\^(\w+), (\w[^\^]+)\^([^\^]+)\^(\d+)\^(\d+)\^(\d+)\^$/ ) {
			warn __PACKAGE__.':'.__LINE__." can't parse output of \"ccontrol qlist\": $line\n";
			return undef;
		}
		$self->{byname}->{$1} = {
			name => $1,
			path => $2,
			version => $3,
			status => $4,
			info => $5,
			config => $6,
			superserverport => $7,
			smpport => $8,
			TODOport => $9,
		};
		if ( $5 eq 'directory may be deleted' or ! -d $self->{byname}->{$1}->{path} ) {
			$self->{byname}->{$1}->{present} = 0;
		} else {
			$self->{byname}->{$1}->{present} = 1;
		}
		if ( defined ( $10 ) ) {
			$self->{byname}->{$1}->{alerts} = $10;
		}
		$self->{bypath}->{$2} = $self->{byname}->{$1};
		$self->{bysuperserverport}->{$7} = $self->{byname}->{$1};
		$self->{bysmpport}->{$7} = $self->{byname}->{$1};
	}
	close $cc;


	return bless ( $self, $class );
}






# module must return true
1;
