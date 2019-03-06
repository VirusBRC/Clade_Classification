package parallel::Component::Aggregate::fomaSNP;
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
### FomaSNP Specific Properties
###
sub AGGREGATEFILETYPES_PROP { return 'aggregateFileTypes'; }

sub FOMASNP_PROPERTIES { return [ AGGREGATEFILETYPES_PROP, ]; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;

  my parallel::Component::Aggregate::fomaSNP $this =
    $that->SUPER::new( FOMASNP_PROPERTIES, 'fomaSNP', $controller, $utils,
    $error_mgr, $tools );

  return $this;
}

sub setConfig {
  my parallel::Component::Aggregate::fomaSNP $this = shift;

  my $config     = $this->getConfigParams;
  my $properties = $this->getProperties;
  ###
  ### This aggregation scheme requires the
  ### specification of the aggregation files.
  ###
  $config->setProperty( 'aggregateFileTypes',
    $properties->{aggregateFileTypes} );
}

################################################################################

1;

__END__

=head1 NAME

rate4site.pm

=head1 DESCRIPTION

This class defines the aggregation component for fomaSNP.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Aggregate::fomaSNP(properties, controller, error_mgr, tools)>

This is the constructor for the class.

=cut
