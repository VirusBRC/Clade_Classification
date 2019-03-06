package parallel::Component::RunTool::fomaSNP;
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
sub CLUSTALWFORSKIPGROUP_PROP   { return 'clustalwForSkipGroup'; }
sub CLUSTALWPATH_PROP           { return 'clustalWPath'; }
sub CLUSTERALIGNPATH_PROP       { return 'clusterAlignPath'; }
sub GETORFPATH_PROP             { return 'getOrfPath'; }
sub LENGTHCUTOFF_PROP           { return 'lengthCutoff'; }
sub LOGBASE_PROP                { return 'logBase'; }
sub MINNUMSEQ_PROP              { return 'minNumSeq'; }
sub MUSCLEPATH_PROP             { return 'musclePath'; }
sub RUNCLUSTALW_PROP            { return 'runClustalw'; }
sub SEQSFILEORD_PROP            { return 'seqsFileOrd'; }
sub SKIPGROUPS_PROP             { return 'skipGroups'; }
sub STRAINNAMECUTOFF_PROP       { return 'strainNameCutoff'; }
sub UCLUSTERPATH_PROP           { return 'uclusterPath'; }
sub UNKNOWNCONSENSUSSYMBOL_PROP { return 'unknownConsensusSymbol'; }

sub FOMASNP_PROPERTIES {
  return (
    CLUSTALWFORSKIPGROUP_PROP, CLUSTALWPATH_PROP,
    CLUSTERALIGNPATH_PROP,     GETORFPATH_PROP,
    LENGTHCUTOFF_PROP,         LOGBASE_PROP,
    MINNUMSEQ_PROP,            MUSCLEPATH_PROP,
    RUNCLUSTALW_PROP,          SEQSFILEORD_PROP,
    SKIPGROUPS_PROP,           STRAINNAMECUTOFF_PROP,
    UCLUSTERPATH_PROP,         UNKNOWNCONSENSUSSYMBOL_PROP
  );
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$$) {
  my ( $that, $properties, $controller, $utils, $error_mgr, $tools ) = @_;

  push( @{$properties}, FOMASNP_PROPERTIES );

  my parallel::Component::RunTool::fomaSNP $this =
    $that->SUPER::new( $properties, 'fomaSNP', $controller, $utils, $error_mgr,
    $tools );

  return $this;
}

################################################################################

1;

__END__

=head1 NAME

fomaSNP.pm

=head1 DESCRIPTION

This class defines the basics capabilities running tools in data parallelism
without any other than the basic run tool properties.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::RunTool::fomaSNP(properties, controller, utils, error_mgr, tools)>

This is the constructor for the class.

=cut
