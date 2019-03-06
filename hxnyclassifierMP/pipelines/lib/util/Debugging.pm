package util::Debugging;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

################################################################################
#
#			  Static Class Global Variable
#
################################################################################

my $_GLOBALS_ = { is_debug => util::Constants::FALSE, };

################################################################################
#
#			Setter and Getter Static Methods
#
################################################################################

sub set   { $_GLOBALS_->{is_debug} = util::Constants::TRUE; }
sub unset { $_GLOBALS_->{is_debug} = util::Constants::FALSE; }
sub on    { return $_GLOBALS_->{is_debug}; }

################################################################################

1;

__END__

=head1 NAME

Debugging.pm

=head1 SYNOPSIS

use util::Debugging

=head1 DESCRIPTION

This static class exports static global debugging switch.  It exports
the following static methods.

=head1 STATIC SETTER METHODS

The following static methods set the debugging switch.

=head2 B<set>

This method sets debugging on.

=head2 B<unset>

This method sets debugging off.

=head1 STATIC GETTER METHODS

The following static method accesses the current state of debugging.

=head2 B<on>

This method returns TRUE (1) if debugging is on, otherwise it returns
FALSE (0).

=cut
