package parallel::Component::Preprocess::fixTmhmm;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use Bio::SeqIO;

use util::Constants;

use parallel::File::DataDups;

use base 'parallel::Component::Preprocess';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Fix tmhmm Specific Properties the Controller Configuration
###
sub TMHMMDATADUPSFILE_PROP       { return 'tmhmmDataDupsFile'; }
sub TMHMMDATAROOT_PROP           { return 'tmhmmDataRoot'; }
sub TMHMMFASTAFILES_PROP         { return 'tmhmmFastaFiles'; }
sub TMHMMFEATUREIDSFILE_PROP     { return 'tmhmmFeatureIdsFile'; }
sub TMHMMFEATUREIDSPROPERTY_PROP { return 'tmhmmFeatureIdsProperty'; }

sub FIXTMHMM_PROPERTIES {
  return [
    TMHMMDATADUPSFILE_PROP, TMHMMDATAROOT_PROP,
    TMHMMFASTAFILES_PROP,   TMHMMFEATUREIDSFILE_PROP,
    TMHMMFEATUREIDSPROPERTY_PROP,
  ];
}
###
### Amino Acids NOT Allowed by tmhmm
###
sub BAD_AMINO_ACIDS_PATTERN { return 'J|U|\*|-'; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::Preprocess::fixTmhmm $this =
    $that->SUPER::new( FIXTMHMM_PROPERTIES, 'fixTmhmm', $controller, $utils,
    $error_mgr, $tools );

  return $this;
}

sub preprocess_data {
  my parallel::Component::Preprocess::fixTmhmm $this = shift;

  my $controller    = $this->getController;
  my $properties    = $this->getLocalDataProperties;
  my $tmhmmDataRoot = $properties->{tmhmmDataRoot};
  ###
  ### Get the data duplicates properties
  ###
  my $dataDupsFile = join( util::Constants::SLASH,
    $tmhmmDataRoot, $properties->{tmhmmDataDupsFile} );
  my $dataDups =
    new parallel::File::DataDups( $dataDupsFile, $this->{error_mgr} );
  $dataDups->readFile;
  ###
  ### Set feature ids file
  ###
  my $tmhmmFeatureIdsFile = $properties->{tmhmmFeatureIdsFile};
  my $featureIdsFile      = join( util::Constants::SLASH,
    $this->getWorkspaceRoot, $tmhmmFeatureIdsFile );
  ###
  ### Process the fasta files
  ###
  my $tmhmmFastaFiles         = $properties->{tmhmmFastaFiles};
  my $fh                      = new FileHandle;
  my $allFeatureIds           = {};
  my $bad_amino_acids_pattern = BAD_AMINO_ACIDS_PATTERN;
  foreach my $index ( 0 .. $#{$tmhmmFastaFiles} ) {
    my $fastaFile =
      join( util::Constants::SLASH, $tmhmmDataRoot,
      $tmhmmFastaFiles->[$index] );
    $fh->open( $fastaFile, '<' );
    my $fasta       = new Bio::SeqIO( -fh => $fh, -format => "fasta" );
    my $found_first = util::Constants::FALSE;
    while ( my $seq = $fasta->next_seq ) {
      my $id   = $seq->display_id;
      my $mseq = uc( $seq->seq );
      if ( $mseq =~ /$bad_amino_acids_pattern/ ) {
        $found_first = util::Constants::TRUE;
        next;
      }
      else {
        next if ( !$found_first );
        $allFeatureIds->{$id} = util::Constants::EMPTY_STR;
        foreach my $dupId ( $dataDups->getDupIds($id) ) {
          $allFeatureIds->{$dupId} = util::Constants::EMPTY_STR;
        }
      }
    }
    $fh->close;
  }
  ###
  ### At the completion of processing
  ### set the feature ids property
  ###
  $fh->open( $featureIdsFile, '>' );
  $fh->autoflush(util::Constants::TRUE);
  foreach my $id ( sort keys %{$allFeatureIds} ) { $fh->print("$id\n"); }
  $fh->close;
  my $featureIdProperty = $properties->{tmhmmFeatureIdsProperty};
  $this->{error_mgr}->printMsg("Computed Property\n"
			       . "  property = $featureIdProperty\n"
			       . "  value    = $featureIdsFile");
  my $da_comp =
    $controller->getComponent($this->{utils}->DATAACQUISITION_COMP);
  return if (!defined($da_comp));
  $da_comp->setProperty($featureIdProperty, $featureIdsFile);
  $this->{error_mgr}->printMsg("Set Property\n"
			       . "  property = $featureIdProperty\n"
			       . "  value    = $featureIdsFile");
}

################################################################################

1;

__END__

=head1 NAME

fixTmhmm.pm

=head1 DESCRIPTION

This class defines the mechanism for generating an ids file to re-run
for tmhmm because of the 'J', 'U', '*', or '-' amino-acids issue.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Preprocess::fixTmhmm(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
