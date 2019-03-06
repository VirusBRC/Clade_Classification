package parallel::Component::RunTool::rate4site;
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
sub LOG4JFILE_PROP { return 'log4jFile'; }
sub R4S_PROPERTIES { return [ LOG4JFILE_PROP, ]; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::RunTool::rate4site $this =
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

This class defines the basics capabilities running tools in data parallelism
without any other than the basic run tool properties.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::RunTool::rate4site(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
