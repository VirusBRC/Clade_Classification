package parallel::Component::RunTool::fomaSNP::aaSeq;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use base 'parallel::Component::RunTool::fomaSNP';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Run Tool Properties
###
sub ONE2THREE_PROP { return 'one2three'; }

sub AASEQ_PROPERTIES {
  return [ ONE2THREE_PROP, ];
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::RunTool::fomaSNP::aaSeq $this =
    $that->SUPER::new( AASEQ_PROPERTIES, $controller, $utils, $error_mgr,
    $tools );

  return $this;
}

################################################################################

1;

__END__

=head1 NAME

aaSeq.pm

=head1 DESCRIPTION

This class defines the basics capabilities running tools in data parallelism
without any other than the basic run tool properties.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::RunTool::fomaSNP::aaSeq(controller, utils, error_mgr, tools)>

This is the constructor for the class.

=cut
