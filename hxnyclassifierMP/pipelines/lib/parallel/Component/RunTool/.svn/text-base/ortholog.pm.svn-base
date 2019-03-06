package parallel::Component::RunTool::ortholog;
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
sub CHANGESUFFIX_PROP       { return 'changeSuffix'; }
sub DELETESUFFIX_PROP       { return 'deleteSuffix'; }
sub FASTASUFFIX_PROP        { return 'fastaSuffix'; }
sub GROUPSFILE_PROP         { return 'groupsFile'; }
sub MAPPSUFFIX_PROP         { return 'mapSuffix'; }
sub ORTHOLOGSUFFIX_PROP     { return 'orthologSuffix'; }
sub ORTHOMCLCONFIGFILE_PROP { return 'orthomclConfigFile'; }
sub PRIORRUNROOT_PROP       { return 'priorRunRoot'; }
sub RESTARTSTEP_PROP        { return 'restartStep'; }
sub RUNVERSION_PROP         { return 'runVersion'; }
sub SEQMAPFILE_PROP         { return 'seqMapFile'; }

sub ORTHOLOG_PROPERTIES {
  return [
    CHANGESUFFIX_PROP,       DELETESUFFIX_PROP, FASTASUFFIX_PROP,
    GROUPSFILE_PROP,         MAPPSUFFIX_PROP,   ORTHOLOGSUFFIX_PROP,
    ORTHOMCLCONFIGFILE_PROP, PRIORRUNROOT_PROP, RESTARTSTEP_PROP,
    RUNVERSION_PROP,         SEQMAPFILE_PROP,
  ];
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::RunTool::ortholog $this =
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

This class defines the basics capabilities running tools in data parallelism
without any other than the basic run tool properties.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::RunTool::ortholog(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
