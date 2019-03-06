package parallel::Component::RunTool::fomaSNP::naSeq;
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
sub MINCDSSIZE_PROP      { return 'minCDSsize'; }
sub MUSCLECUTOFF_PROP    { return 'muscleCutoff'; }
sub PANDEMIC_PROP        { return 'pandemic'; }
sub RSCRIPTPATH_PROP     { return 'rScriptPath'; }
sub RUNNA_PROP           { return 'runNa'; }
sub RUNPLOTPATH_PROP     { return 'runPlotPath'; }
sub RUNSNP_PROP          { return 'runSnp'; }
sub SEQLEN_PROP          { return 'seqLen'; }
sub SPECIALSNPSTART_PROP { return 'specialSnpStart'; }
sub SPECIALSNPSTOP_PROP  { return 'specialSnpStop'; }
sub TERMINALCODONS_PROP  { return 'terminalCodons'; }

sub NASEQ_PROPERTIES {
  return [
    MINCDSSIZE_PROP,     MUSCLECUTOFF_PROP, PANDEMIC_PROP,
    RSCRIPTPATH_PROP,    RUNNA_PROP,        RUNPLOTPATH_PROP,
    RUNSNP_PROP,         SEQLEN_PROP,       SPECIALSNPSTART_PROP,
    SPECIALSNPSTOP_PROP, TERMINALCODONS_PROP,
  ];
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::RunTool::fomaSNP::naSeq $this =
    $that->SUPER::new( NASEQ_PROPERTIES, $controller, $utils, $error_mgr,
    $tools );

  return $this;
}

################################################################################

1;

__END__

=head1 NAME

naSeq.pm

=head1 DESCRIPTION

This class defines the basics capabilities running tools in data parallelism
without any other than the basic run tool properties.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::RunTool::fomaSNP::naSeq(controller, utils, error_mgr, tools)>

This is the constructor for the class.

=cut
