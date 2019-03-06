package parallel::Component::DataAcquisition::fomaSNP::naSeq;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

use parallel::Query;

use base 'parallel::Component::DataAcquisition::fomaSNP';

use fields qw(
  genbank_refseq_query
  refseqs
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### NA Sequence Specific Properties the Controller Configuration
###
sub GENBANKREFSEQQUERY_PROP { return 'genbankRefSeqQuery'; }

sub NASEQ_PROPERTIES { return [ GENBANKREFSEQQUERY_PROP, ]; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::DataAcquisition::fomaSNP::naSeq $this =
    $that->SUPER::new( NASEQ_PROPERTIES, $controller, $utils, $error_mgr,
    $tools );

  my $lproperties = $this->getLocalDataProperties( [] );

  $this->{genbank_refseq_query} = $lproperties->{&GENBANKREFSEQQUERY_PROP};
  $this->{refseqs}              = {};

  return $this;
}

sub fileGroupTag {
  my parallel::Component::DataAcquisition::fomaSNP::naSeq $this = shift;
  my ($datum) = @_;
  ###
  ### As per Wei's suggestion
  ### This is only to used for file names
  ###
  my $groupTag = $this->groupTag($datum);
  $groupTag =~ s/'//g;    ###'
  return $groupTag;
}

sub initializeFomaSnpData {
  my parallel::Component::DataAcquisition::fomaSNP::naSeq $this = shift;

  $this->{refseqs} = {};

  my $query = new parallel::Query( $this, $this->{error_mgr}, $this->{tools} );
  my @data = $query->getData( $this->{genbank_refseq_query} );
  $this->setErrorStatus( $this->ERR_CAT, 12,
    [ $this->{genbank_refseq_query}->{query} ],
    $query->getErrorStatus );
  return
    if ( $this->getErrorStatus );
  foreach my $struct (@data) {
    my $ncbiacc = $struct->{ncbiacc};
    my $refseq  = $struct->{refseq};
    $ncbiacc =~ s/^(.+)\.\d+$/$1/g;
    $refseq  =~ s/^(.+)\.\d+$/$1/g;
    $this->{refseqs}->{$ncbiacc} = $refseq;
  }
}

sub filterData {
  my parallel::Component::DataAcquisition::fomaSNP::naSeq $this = shift;
  my (@data) = @_;

  my @fData = ();
  foreach my $datum (@data) {
    my $seq       = $datum->{seq};
    my $align_seq = $datum->{align_seq};
    next
      if (
      (
           util::Constants::EMPTY_LINE($align_seq)
        && util::Constants::EMPTY_LINE($seq)
      )
      || $seq =~ /N{50}/
      );
    push( @fData, $datum );
  }

  return @fData;
}

sub addEntity {
  my parallel::Component::DataAcquisition::fomaSNP::naSeq $this = shift;
  my ($datum) = @_;

  my $cmds = $this->{tools}->cmds;
  ###
  ### Determine length and fix alignment seq
  ###
  my $align_seq     = $datum->{align_seq};
  my $align_seq_len = 0;
  if ( !util::Constants::EMPTY_LINE($align_seq) ) {
    $align_seq =~ s/~/-/g;
    $align_seq_len = length($align_seq);
  }
  else {
    $align_seq = util::Constants::EMPTY_STR;
  }
  $datum->{align_seq} = $align_seq;
  ###
  ### Determine length and fix seq
  ###
  my $seq_len = 0;
  my $seq     = $datum->{seq};
  if ( !util::Constants::EMPTY_LINE($seq) ) {
    $seq_len = length($seq);
  }
  else { $seq = util::Constants::EMPTY_STR; }
  $datum->{seq} = $seq;
  ###
  ### Get the group data
  ###
  my $groupData = $this->getGroup( $datum, $seq_len, $align_seq_len );
  ###
  ### Add host, strain, and refseq map
  ###
  my $ncbiacc = $datum->{ncbiacc};
  $groupData->{hosts}->addAccVal( $ncbiacc,   $datum->{orig_host} );
  $groupData->{strains}->addAccVal( $ncbiacc, $datum->{strainname} );
  $groupData->{refseqs}->addAccVal( $ncbiacc, $this->{refseqs}->{$ncbiacc} )
    if ( defined( $this->{refseqs}->{$ncbiacc} ) );
  ###
  ### Update the properties
  ###
  my $properties = $groupData->{properties};
  my $count      = $properties->getProperty('count');
  $count++;
  $properties->setProperty( 'count', $count );

  $properties->setProperty( 'max_seq_len', $seq_len )
    if ( $seq_len > $properties->getProperty('max_seq_len') );
  $properties->setProperty( 'realign', util::Constants::TRUE )
    if ( $align_seq_len != $properties->getProperty('align_len') );
  $properties->setProperty( 'realign', util::Constants::TRUE )
    if ( util::Constants::EMPTY_LINE($align_seq) );
  ###
  ### Determine Offset, Trailing
  ###
  my ( $offset, $trailing, $aseq ) =
    $this->{utils}->getOffsetTrailing($align_seq);
  $properties->setProperty( 'offset', $offset )
    if ( $properties->getProperty('offset') > $offset );
  $properties->setProperty( 'trailing', $trailing )
    if ( $properties->getProperty('trailing') < $trailing );
  ###
  ### Add the sequence
  ###
  $this->addSeqData( $groupData, $datum );
}

################################################################################

1;

__END__

=head1 NAME

naSeq.pm

=head1 DESCRIPTION

This class defines the NA sequence acquisition for fomaSNP

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::DataAcquisition::fomaSNP::fomaSNP::naSeq(controller, utils, error_mgr, tools)>

This is the constructor for the class.

=cut
