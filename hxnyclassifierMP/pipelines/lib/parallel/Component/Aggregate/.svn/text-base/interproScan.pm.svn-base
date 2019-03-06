package parallel::Component::Aggregate::interproScan;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

use base 'parallel::Component::Aggregate';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### interproscan aggregation properties
###
sub ENDDATE_PROP   { return 'endDate'; }
sub STARTDATE_PROP { return 'startDate'; }

sub INTERPROSCAN_PROPERTIES {
  return [ ENDDATE_PROP, STARTDATE_PROP, ];
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::Aggregate::interproScan $this =
    $that->SUPER::new( INTERPROSCAN_PROPERTIES, 'interproscan', $controller,
    $utils, $error_mgr, $tools );

  return $this;
}

sub setConfig {
  my parallel::Component::Aggregate::interproScan $this = shift;

  my $config     = $this->getConfigParams;
  my $controller = $this->getController;
  ###
  ### This aggregation scheme requires the
  ### data acquisition data dups and family names files
  ###
  my $da_comp =
    $controller->getComponent( $this->{utils}->DATAACQUISITION_COMP );
  my $dataDupsFile = $da_comp->getDataDupsFile;
  $config->setProperty( 'dataDupsFile', $dataDupsFile );
  my $familyNamesFile = $da_comp->getFamilyNamesFile;
  $config->setProperty( 'familyNamesFile', $familyNamesFile );
}

################################################################################

1;

__END__

=head1 NAME

interproScan.pm

=head1 DESCRIPTION

This class defines the aggregation component for interproscan.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Aggregate::interproScan(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
