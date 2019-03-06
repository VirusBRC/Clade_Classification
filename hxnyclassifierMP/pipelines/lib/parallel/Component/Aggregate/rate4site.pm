package parallel::Component::Aggregate::rate4site;
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
### Rate4Site Specific Properties
###
sub R4S_PROPERTIES { return []; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::Aggregate::rate4site $this =
    $that->SUPER::new( R4S_PROPERTIES, 'rate4site', $controller, $utils,
    $error_mgr, $tools );

  return $this;
}

################################################################################

1;

__END__

=head1 NAME

rate4site.pm

=head1 DESCRIPTION

This class defines the aggregation component for rate4site.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Aggregate::rate4site(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
