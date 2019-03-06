package tool::interproScan;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

use base 'tool::Tool';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Interproscan Properties
###
sub INTERPROSCAN_PROPERTIES { return []; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $utils, $error_mgr, $tools ) = @_;
  my tool::interproScan $this =
    $that->SUPER::new( 'interproscan', INTERPROSCAN_PROPERTIES, $utils,
    $error_mgr, $tools );
  return $this;
}

sub run {
  my tool::interproScan $this = shift;

  my $properties = $this->getProperties;
  my $tools      = $this->{tools};

  my $params = join( util::Constants::SPACE,
    '-i ' . $properties->{dataFile},
    '-o ' . $properties->{outputFile}
  );
  my $status = $this->executeTool($params);
  $tools->setStatus( $tools->FAILED ) if ($status);
}

################################################################################

1;

__END__

=head1 NAME

interproScan.pm

=head1 DESCRIPTION

This class defines the runner for interproscan.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::interproScan(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
