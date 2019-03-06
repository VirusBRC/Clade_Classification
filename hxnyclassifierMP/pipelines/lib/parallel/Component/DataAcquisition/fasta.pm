package parallel::Component::DataAcquisition::fasta;
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

use parallel::File::DataDups;
use parallel::File::DataFiles;
use parallel::File::FamilyNames;
use parallel::Query;

use base 'parallel::Component::DataAcquisition';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Fasta Specific Properties the Controller Configuration
###
sub ENDDATE_PROP     { return 'endDate'; }
sub FAMILYNAMES_PROP { return 'familyNames'; }
sub FEATUREIDS_PROP  { return 'featureIds'; }
sub MINLENGTH_PROP   { return 'minLength',; }
sub NUMSEQS_PROP     { return 'numSeqs'; }
sub SEQWIDTH_PROP    { return 'seqWidth'; }
sub STARTDATE_PROP   { return 'startDate'; }

sub FASTA_PROPERTIES {
  return [
    ENDDATE_PROP, FAMILYNAMES_PROP, FEATUREIDS_PROP, MINLENGTH_PROP,
    NUMSEQS_PROP, SEQWIDTH_PROP,    STARTDATE_PROP,
  ];
}
###
### Query Specific Properties from its Configuration
###
sub GENERATEFAMILYNAMES_PROP { return 'generateFamilyNames'; }
sub MAXELEMENTS_PROP         { return 'maxElements'; }
sub QUERYFAMILYNAME_PROP     { return 'queryFamilyName'; }
sub QUERYID_PROP             { return 'queryId'; }
sub QUERYPARAMSUBS_PROP      { return 'queryParamSubs'; }
sub QUERYPARAMS_PROP         { return 'queryParams'; }
sub QUERYRESULTSORD_PROP     { return 'queryResultsOrd'; }
sub QUERYSEQ_PROP            { return 'querySeq'; }
sub QUERY_PROP               { return 'query'; }

sub QUERY_PROPERTIES {
  return [
    MAXELEMENTS_PROP, QUERYID_PROP,         QUERYPARAMSUBS_PROP,
    QUERYPARAMS_PROP, QUERYRESULTSORD_PROP, QUERYSEQ_PROP,
    QUERY_PROP,       QUERYFAMILYNAME_PROP, GENERATEFAMILYNAMES_PROP,
  ];
}
###
### Fasta Suffix
###
sub FASTA_SUFFIX { return 'fasta'; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _determineNumLen {
  my parallel::Component::DataAcquisition::fasta $this = shift;
  my ( $numSeqs, $seqChunk ) = @_;

  my $numFiles = $numSeqs / $seqChunk + 1;
  my $n        = 0;
  while ( 10**$n <= $numFiles ) {
    $n++;
    last if ( $numFiles < 10**$n );
  }
  $this->{num_len} = ( $n < 3 ) ? 3 : $n;
}

sub _openFastaFile {
  my parallel::Component::DataAcquisition::fasta $this = shift;
  my ( $fileNum, $properties ) = @_;

  my $fastaFilePrefix = $this->generateFilePrefix($fileNum);
  my $fastaFile       = join( util::Constants::SLASH,
    $this->getWorkspaceRoot,
    join( util::Constants::DOT, $fastaFilePrefix, FASTA_SUFFIX ) );
  unlink($fastaFile);
  my $fh = new FileHandle;
  $this->setErrorStatus(
    $this->ERR_CAT, 1,
    [ 'fasta file', $fastaFile, ],
    !$fh->open( $fastaFile, '>' )
  );
  return if ( $this->getErrorStatus );
  $fh->autoflush(util::Constants::TRUE);
  my $fastaSeq = new Bio::SeqIO( -fh => $fh, -format => FASTA_SUFFIX );
  $fastaSeq->width( $properties->{&SEQWIDTH_PROP} );
  return ( $fastaFilePrefix, $fastaFile, $fh, $fastaSeq );
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::DataAcquisition::fasta $this =
    $that->SUPER::new( FASTA_PROPERTIES, 'fasta', $controller, $utils,
    $error_mgr, $tools );

  return $this;
}

sub acquire_data {
  my parallel::Component::DataAcquisition::fasta $this = shift;

  return util::Constants::FALSE if ( !$this->getRun );
  ###
  ### Get the data
  ###
  my $query = new parallel::Query( $this, $this->{error_mgr}, $this->{tools} );
  my $properties = $this->getLocalDataProperties(QUERY_PROPERTIES);
  my @data       = $this->filterData( $query->getData($properties) );
  return if ( $this->getErrorStatus );
  ###
  ### Determine the unique set of sequence and duplicates
  ### Also, removing minimum sequences
  ###
  my $queryId             = $properties->{&QUERYID_PROP};
  my $querySeq            = $properties->{&QUERYSEQ_PROP};
  my $queryFamilyName     = $properties->{&QUERYFAMILYNAME_PROP};
  my $generateFamilyNames = $properties->{&GENERATEFAMILYNAMES_PROP};
  my $seqs                = {};
  my $minLength           = $properties->{&MINLENGTH_PROP};
  my $numSeqs             = 0;
  my $allIds              = {};

  my $dataDups =
    new parallel::File::DataDups( $this->getDataDupsFile, $this->{error_mgr} );
  my $familyNames =
    new parallel::File::FamilyNames( $this->getFamilyNamesFile,
    $this->{error_mgr} );

  foreach my $struct (@data) {
    my $id  = $struct->{$queryId};
    my $seq = $struct->{$querySeq};
    if ( length($seq) < $minLength ) {
      $this->{error_mgr}->printMsg("seq = $id below minimum length ($seq)");
      next;
    }
    next if ( defined( $allIds->{$id} ) );
    $allIds->{$id} = util::Constants::EMPTY_STR;
    $familyNames->addIdFamilyName( $id, $struct->{$queryFamilyName} )
      if ($generateFamilyNames);
    if ( !defined( $seqs->{$seq} ) ) {
      $dataDups->createDataDup($id);
      $seqs->{$seq} = $id;
      $numSeqs++;
    }
    else {
      $dataDups->addDataDup( $seqs->{$seq}, $id );
    }
  }
  $this->setErrorStatus( $this->ERR_CAT, 1,
    [ 'dataDupsFile', $this->getDataDupsFile, ],
    $dataDups->writeFile );
  return if ( $this->getErrorStatus );
  if ($generateFamilyNames) {
    $this->setErrorStatus( $this->ERR_CAT, 1,
      [ 'familyNamesFile', $this->getFamilyNamesFile, ],
      $familyNames->writeFile );
    return if ( $this->getErrorStatus );
  }
  $this->_determineNumLen( $numSeqs, $properties->{&NUMSEQS_PROP} );
  ###
  ### Now generate fasta files
  ###
  my $dataFiles = new parallel::File::DataFiles( $this->getDataFiles, $this->{error_mgr} );
  my $currCount = 0;
  my $fileNum   = 1;
  my ( $fastaFilePrefix, $fastaFile, $fh, $fastaSeq ) =
    $this->_openFastaFile( $fileNum, $properties );
  return if ( $this->getErrorStatus );
  foreach my $seq ( keys %{$seqs} ) {
    $currCount++;
    if ( $currCount > $properties->{&NUMSEQS_PROP} ) {
      $fh->close;
      $dataFiles->addDataFile( $fastaFilePrefix, $fastaFile );
      $fileNum++;
      $currCount = 0;
      ( $fastaFilePrefix, $fastaFile, $fh, $fastaSeq ) =
        $this->_openFastaFile( $fileNum, $properties );
      return if ( $this->getErrorStatus );
    }
    my $bioSeq = new Bio::Seq( -display_id => $seqs->{$seq}, -seq => $seq );
    $fastaSeq->write_seq($bioSeq);
  }
  if ( $currCount > 0 ) {
    $fh->close;
    $dataFiles->addDataFile( $fastaFilePrefix, $fastaFile );
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

fasta.pm

=head1 DESCRIPTION

This class defines the fasta data acquisition component

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::DataAcquisition::fasta(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
