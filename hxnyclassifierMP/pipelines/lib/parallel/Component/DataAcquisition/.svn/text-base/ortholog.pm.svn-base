package parallel::Component::DataAcquisition::ortholog;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use Bio::Seq;
use Bio::SeqIO;

use util::Constants;

use parallel::File::DataFiles;
use parallel::File::OrthologMap;
use parallel::Query;

use base 'parallel::Component::DataAcquisition';

use fields qw(
  family_names
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Ortholog Specific Properties the Controller Configuration
###
sub FAMILYNAMES_PROP { return 'familyNames'; }
sub SEQMAPFILE_PROP  { return 'seqMapFile'; }

sub ORTHOLOG_PROPERTIES { return [ FAMILYNAMES_PROP, SEQMAPFILE_PROP, ]; }
###
### Query Specific Properties from its Configuration
###
sub MAXELEMENTS_PROP     { return 'maxElements'; }
sub QUERYFAMILYNAME_PROP { return 'queryFamilyName'; }
sub QUERYID_PROP         { return 'queryId'; }
sub QUERYNAME_PROP       { return 'queryName'; }
sub QUERYPARAMSUBS_PROP  { return 'queryParamSubs'; }
sub QUERYPARAMS_PROP     { return 'queryParams'; }
sub QUERYRESULTSORD_PROP { return 'queryResultsOrd'; }
sub QUERYSEQ_PROP        { return 'querySeq'; }
sub QUERY_PROP           { return 'query'; }

sub QUERY_PROPERTIES {
  return [
    MAXELEMENTS_PROP,     QUERYFAMILYNAME_PROP, QUERYID_PROP,
    QUERYNAME_PROP,       QUERYPARAMSUBS_PROP,  QUERYPARAMS_PROP,
    QUERYRESULTSORD_PROP, QUERYSEQ_PROP,        QUERY_PROP,
  ];
}
###
### Fasta Suffix
###
sub FAA_SUFFIX   { return 'faa'; }
sub FASTA_SUFFIX { return 'fasta'; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _addSequenceToMap {
  my parallel::Component::DataAcquisition::ortholog $this = shift;
  my ( $struct, $properties ) = @_;

  my $queryFamilyName = $properties->{&QUERYFAMILYNAME_PROP};
  my $queryId         = $properties->{&QUERYID_PROP};
  my $queryName       = $properties->{&QUERYNAME_PROP};

  my $familyName = $struct->{$queryFamilyName};
  my $name       = $struct->{$queryName};
  my $map        = $this->{family_names}->{$familyName}->{map};

  $map->addSequence( $struct->{$queryId}, $struct->{gi}, $name,
    $struct->{swissprot}, $map->READ_STATUS );
}

sub _addSequenceToFile {
  my parallel::Component::DataAcquisition::ortholog $this = shift;
  my ( $struct, $properties ) = @_;

  my $queryFamilyName = $properties->{&QUERYFAMILYNAME_PROP};
  my $queryId         = $properties->{&QUERYID_PROP};
  my $queryName       = $properties->{&QUERYNAME_PROP};
  my $querySeq        = $properties->{&QUERYSEQ_PROP};

  my $familyName = $struct->{$queryFamilyName};
  my $id         = $struct->{$queryId};
  my $name       = $struct->{$queryName};
  my $seq        = $struct->{$querySeq};

  my $faaFile = join( util::Constants::SLASH,
    $this->{family_names}->{$familyName}->{dir},
    join( util::Constants::DOT, $name, FAA_SUFFIX )
  );
  my $fh = new FileHandle;
  $this->setErrorStatus(
    $this->ERR_CAT, 1,
    [ 'fasta file', $faaFile, ],
    !$fh->open( $faaFile, '>>' )
  );
  return if ( $this->getErrorStatus );
  $fh->autoflush(util::Constants::TRUE);
  my $length = length($seq) + 1;
  my $fastaSeq = new Bio::SeqIO( -fh => $fh, -format => FASTA_SUFFIX );
  $fastaSeq->width($length);
  my $fid = join( util::Constants::PIPE,
    $queryId, $id, 'gi', $struct->{gi}, 'UniProtKB', $struct->{swissprot},
    'Organism',
    join( util::Constants::TAB, $struct->{organism}, $struct->{strain} ) );
  my $bioSeq = new Bio::Seq( -display_id => $fid, -seq => $seq );
  $fastaSeq->write_seq($bioSeq);
  $fh->print(util::Constants::NEWLINE);
  $fh->close;
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::DataAcquisition::ortholog $this =
    $that->SUPER::new( ORTHOLOG_PROPERTIES, 'ortholog', $controller, $utils,
    $error_mgr, $tools );

  $this->{family_names} = {};

  return $this;
}

sub acquire_data {
  my parallel::Component::DataAcquisition::ortholog $this = shift;

  my $tools = $this->{tools};
  my $cmds  = $tools->cmds;

  $this->{family_names} = {};
  my $familyNames = $this->{family_names};

  return util::Constants::FALSE if ( !$this->getRun );
  ###
  ### Get the data
  ###
  my $query = new parallel::Query( $this, $this->{error_mgr}, $this->{tools} );
  my $properties = $this->getLocalDataProperties(QUERY_PROPERTIES);
  my @data       = $this->filterData( $query->getData($properties) );
  return if ( $this->getErrorStatus );
  ###
  ### Generate the fasta files
  ###
  my $queryFamilyName = $properties->{&QUERYFAMILYNAME_PROP};
  my $queryId         = $properties->{&QUERYID_PROP};
  my $allIds          = {};
  my $dataFiles =
    new parallel::File::DataFiles( $this->getDataFiles, $this->{error_mgr} );
  foreach my $struct (@data) {
    my $familyName = $struct->{$queryFamilyName};
    my $id         = $struct->{$queryId};
    my $gi         = $struct->{gi};
    my $key        = join( util::Constants::PIPE, $familyName, $id, $gi );
    if ( defined( $allIds->{$key} ) ) {
      $this->{error_mgr}->printMsg(
        "Repeats seq = ($id, $gi) for family = $familyName, skipping");
      next;
    }
    $this->{error_mgr}
      ->printMsg("Using seq = ($id, $gi) for family = $familyName")
      ;
    $allIds->{$key} = util::Constants::EMPTY_STR;
    if ( !defined( $familyNames->{$familyName} ) ) {
      my $familyDirectory = $cmds->createDirectory(
        join( util::Constants::SLASH, $this->getWorkspaceRoot, $familyName ),
        'creating family directory',
        util::Constants::TRUE
      );
      my $mapFile = join( util::Constants::SLASH,
        $familyDirectory, $properties->{seqMapFile} );
      $familyNames->{$familyName} = {
        dir => $familyDirectory,
        map => new parallel::File::OrthologMap( $mapFile, $this->{error_mgr} ),
      };
      $dataFiles->addDataFile( $familyName, $familyDirectory );
    }
    $this->_addSequenceToMap( $struct, $properties );
    $this->_addSequenceToFile( $struct, $properties );
    return if ( $this->getErrorStatus );
  }
  ###
  ### Generate the sequence maps
  ###
  foreach my $familyName ( keys %{$familyNames} ) {
    my $map = $familyNames->{$familyName}->{map};
    $this->setErrorStatus( $this->ERR_CAT, 1,
      [ "write map file $familyName", $map->getMapFile, ],
      $map->writeFile );
    return if ( $this->getErrorStatus );
  }
  ###
  ### now generate data files
  ###
  $this->setErrorStatus( $this->ERR_CAT, 1,
    [ 'dataFiles', $this->getDataFiles, ],
    $dataFiles->writeFile );
}

################################################################################

1;

__END__

=head1 NAME

ortholog.pm

=head1 DESCRIPTION

This class defines the ortholog fasta data acquisition component

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::DataAcquisition::ortholog(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
