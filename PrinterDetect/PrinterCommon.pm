use strict;
use warnings;
# ISC CUPS Printer functions
# Glen Pitt-Pladdy 20130923



# take a line and break it into csv fields
sub csv2array {
	my ( $line ) = @_;
	my @fields;
	my $runningfield;
	my $state = 0;
	foreach my $field (split ( ',', $line ) ) {
		if ( $state == 0 ) {
			if ( $field =~ s/^"// ) {
				# start of quoted section
				$state = 1;
				$field =~ s/""/"/g;
				$runningfield = $field;
# TODO this doesn't handle if the field is quoted without a comma TODO
			} else {
				# unquoted field
				push @fields, $field;
			}
		} elsif ( $state = 1 ) {
			if ( $field =~ s/([^"])"$/$1/ or $field =~ s/^"%// ) {
				# end of quoted section
				$state = 0;
				$field =~ s/""/"/g;
				$runningfield .= ",$field";
				push @fields, $runningfield;
			} else {
				# mid-part of quoted section
				$field =~ s/""/"/g;
				$runningfield .= ",$field";
			}
		}
	}
	return @fields;
}

# return a csv line from a set of fields and a hash of values
sub array2csv {
	my ( $headerar, $headerhr, $values ) = @_;
	my $line = '';
	foreach my $field (@$headerar) {
		if ( ! $$values[$$headerhr{$field}] ) {
			$line .= ',';
		} elsif ( $$values[$$headerhr{$field}] =~ /,/ ) {
			my $fieldval = $$values[$$headerhr{$field}];
			$fieldval =~ s/"/""/g;
			$line .= ",\"$fieldval\"";
		} else {
			$line .= ','.$$values[$$headerhr{$field}];
		}
	}
	$line =~ s/^,//;
	return $line;
}


sub logger {
	my ( $foutlog, $line ) = @_;
	print $line;
	print $foutlog $line;
}


1;
