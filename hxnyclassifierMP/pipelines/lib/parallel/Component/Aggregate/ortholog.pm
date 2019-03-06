package parallel::Component::Aggregate::ortholog;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use base 'parallel::Component::Aggregate';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Ortholog Specific Properties
###
sub ORTHOLOG_PROPERTIES { return []; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::Aggregate::ortholog $this =
    $that->SUPER::new( ORTHOLOG_PROPERTIES, 'ortholog', $controller, $utils,
    $error_mgr, $tools );

  return $this;
}

################################################################################

1;

__END__

=head1 NAME

ortholog.pm

=head1 DESCRIPTION

This class defines the aggregation component for orthologs.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Aggregate::ortholog(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
