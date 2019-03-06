package parallel::Component::RunTool::vanilla;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use base 'parallel::Component::RunTool';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Run Tool Properties
###
sub VANILLA_PROPERTIES { return []; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::RunTool::vanilla $this =
    $that->SUPER::new( VANILLA_PROPERTIES, 'vanilla', $controller, $utils,
    $error_mgr, $tools );

  return $this;
}

################################################################################

1;

__END__

=head1 NAME

vanilla.pm

=head1 DESCRIPTION

This class defines the basics capabilities running tools in data parallelism
without any other than the basic run tool properties.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::RunTool::vanilla(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
