package ncbi::Genes::Single;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use Pod::Usage;

use util::Constants;

use base 'ncbi::Genes';

use fields qw(
);

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ( $that, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  my ncbi::Genes::Single $this =
    $that->SUPER::new( $error_mgr, $tools, $utils, $ncbi_utils );

  return $this;
}

sub getProteinLen {
  my ncbi::Genes::Single $this = shift;
  return $this->{specifics}->{len};
}

sub getGeneTypeValues {
  my ncbi::Genes::Single $this = shift;
  my $gene_values = [
    join( util::Constants::HYPHEN, $this->getGeneSymbol, $this->getProteinLen ),
    join( util::Constants::HYPHEN, $this->getGeneSymbol, $this->OTHER_NAME ),
  ];
  return $gene_values;
}

sub determineGeneProductName {
  my ncbi::Genes::Single $this = shift;
  my ($aminoacids) = @_;

  my $gene = $this->UNKNOWN_GENE_NAME;
  if ( !util::Constants::EMPTY_LINE($aminoacids) ) {
    $gene = $this->getGeneSymbol . util::Constants::HYPHEN;
    if ( length($aminoacids) == $this->getProteinLen ) {
      $gene .= length($aminoacids);
    }
    else {
      $gene .= $this->OTHER_NAME;
    }
  }
  $this->{error_mgr}->printMsg( "gene (" . length($aminoacids) . ") = $gene" );
  return $gene;
}

sub findRefMotif {
  my ncbi::Genes::Single $this = shift;
  my ( $gb_gi, $gb_accession, $gap_info ) = @_;

  my $greater_than = util::Constants::GREATER_THAN;

  my $mstruct = undef;

  my $ncbi_utils = $this->{ncbi_utils};
  my $specifics  = $this->{specifics};
  my $seq        = $gap_info->{useq};
  my $seq_str    = join( util::Constants::EMPTY_STR,
    @{$seq}[ $specifics->{start} - 1 .. $#{$seq} ] );
  ###
  ### These coordinates are sequence array coordinates!
  ### Note:  The specifics are nucleotide coordinates!
  ###
  my $gapped_ref_start = $gap_info->{non2gapped}->{ $specifics->{start} - 1 };
  my $gapped_ref_stop  = $gap_info->{non2gapped}->{ $specifics->{stop} - 1 };
  ###
  ### All these coordinates are 1-based coordinates
  ###
  my ( $start, $end, $protein ) = $this->_getProtein($seq_str);
  if ( defined($start) ) {
    $start += $specifics->{start} - 1;
    if ( $end eq util::Constants::HYPHEN ) {
      $end = util::Constants::GREATER_THAN . (scalar @{$seq});
    }
    else {
      $end += $specifics->{start} - 1;
    }
  }

  my $interval = $this->_determineSingleIntProt( $start, $end );

  my $gene = $this->determineGeneProductName($protein);

  my ( $protein_gi, $protein_id, $cds_start, $cds_end ) =
    $this->_determineProtGiId( $gb_gi, $start, $end );
  if ( defined($cds_end) && $cds_end =~ /^$greater_than/ ) {
    $cds_end = util::Constants::EMPTY_STR;
    $protein_gi =~ s/$greater_than//;
    $protein_id =~ s/$greater_than//;
  }

  return $mstruct
    if ( !defined($start)
    || !defined($end) );
  $mstruct = {
    cds_end      => $cds_end,
    cds_start    => $cds_start,
    gene         => $gene,
    interval     => $interval,
    is_reverse   => 'N',
    end          => $end,
    seq_str      => $seq_str,
    protein      => $protein,
    protein_gi   => $protein_gi,
    protein_id   => $protein_id,
    start        => $start,
    seq          => join( util::Constants::EMPTY_STR, @{$seq} ),
    gb_gi        => $gb_gi,
    gb_accession => $gb_accession,
    variant      => $this->NONE_VARIANT_NAME,

    gapped_ref_start => $gapped_ref_start,
    gapped_ref_stop  => $gapped_ref_stop,
  };
  $mstruct->{len} = $mstruct->{end} - $mstruct->{start} + 1;

  return $mstruct;
}

sub findMotif {
  my ncbi::Genes::Single $this = shift;
  my ( $gap_info, $gb_gi, $ref_data ) = @_;

  my $greater_than = util::Constants::GREATER_THAN;

  my $mstruct = undef;
  my $seq     = $gap_info->{ungapped_seq};
  ###
  ### These coordinates are sequence array coordinates!
  ###
  my $ungapped_start =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_start} };
  my $ungapped_stop = $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_stop} };
  ###
  ### Short sequence cannot find frameshift, return immediately
  ###
  return $mstruct
    if ( !defined($ungapped_start) || !defined($ungapped_stop) );

  my $seq_str = join( util::Constants::EMPTY_STR,
    @{ $gap_info->{useq} }[ $ungapped_start .. $#{$gap_info->{useq}} ] );

  $this->{error_mgr}->printHeader( "findMotif\n"
      . "ungapped_start = $ungapped_start\n"
      . "ungapped_stop  = $ungapped_stop\n" );

  $this->{error_mgr}->printMsg( "seq     = $seq\n" . "seq_str = $seq_str\n" );
  ###
  ### These coordinates are 1-based coordinates and
  ### ungapped_start is 0-based coordinate
  ###
  my ( $start, $end, $protein ) = $this->_getProtein($seq_str);
  if ( defined($start) ) {
    $start += $ungapped_start;
    if ( $end eq util::Constants::HYPHEN ) {
      $end = util::Constants::GREATER_THAN . ( scalar @{$gap_info->{useq}} );
    }
    else {
      $end += $ungapped_start;
    }
  }

  my $interval = $this->_determineSingleIntProt( $start, $end );

  my $gene = $this->determineGeneProductName($protein);

  my ( $protein_gi, $protein_id, $cds_start, $cds_end ) =
    $this->_determineProtGiId( $gb_gi, $start, $end );
  if ( defined($cds_end) && $cds_end =~ /^$greater_than/ ) {
    $cds_end = util::Constants::EMPTY_STR;
    $protein_gi =~ s/$greater_than//;
    $protein_id =~ s/$greater_than//;
  }

  $mstruct = {
    cds_end    => $cds_end,
    cds_start  => $cds_start,
    gene       => $gene,
    interval   => $interval,
    is_reverse => 'N',
    end        => $end,
    seq_str    => $seq_str,
    protein    => $protein,
    protein_gi => $protein_gi,
    protein_id => $protein_id,
    start      => $start,
    seq        => $seq,
    variant    => $this->NONE_VARIANT_NAME,

  };
  return $mstruct;
}

sub assignMotif {
  my ncbi::Genes::Single $this = shift;
  my ( $struct, $mstruct ) = @_;

  my $geneticCode = $this->{genetic_code};

  my $fileType = undef;
  my $seqType  = $this->_determineSeqType( $mstruct->{seq} );

  if ( !defined( $mstruct->{start} ) ) {
    $fileType = $seqType;
    $mstruct->{gene} = $this->UNKNOWN_GENE_NAME;
  }
  elsif ( $mstruct->{gene} eq $this->UNKNOWN_GENE_NAME ) {
    $fileType = $seqType;
  }
  else {
    $fileType = $this->MOTIF_TYPE;
    my $sfh = $this->_getFh( $this->SID_TYPE, util::Constants::TRUE );
    $sfh->print(
      join( util::Constants::SPACE,
        $struct->{gb_accession}, $struct->{na_sequence_id},
        $struct->{gb_accession}
        )
        . util::Constants::NEWLINE
    );
  }
  $this->_addDiscardFile($struct)
    if ( $fileType ne $this->MOTIF_TYPE );
  my $fh = $this->_getFh($fileType);
  $fh->print(
    join( util::Constants::TAB,
      util::Constants::EMPTY_STR, $struct->{na_sequence_id},
      $struct->{gb_accession},    $struct->{type},
      $mstruct->{protein_id},     $mstruct->{protein_gi},
      length( $mstruct->{seq} ),  $mstruct->{gene},
      $mstruct->{interval},       $mstruct->{cds_start},
      $mstruct->{cds_end},        $mstruct->{protein},
      $mstruct->{seq},            $mstruct->{variant},
      $mstruct->{is_reverse}
      )
      . util::Constants::NEWLINE
  );
  $this->_computeStats( $seqType, $mstruct->{gene}, $struct->{type},
    $mstruct->{variant}, $fileType, length( $mstruct->{seq} ),
  );
}

################################################################################
1;

__END__

=head1 NAME

Single.pm

=head1 SYNOPSIS

  use ncbi::Genes::Single;

=head1 DESCRIPTION

The Single strand gene processor.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Genes::Single(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
