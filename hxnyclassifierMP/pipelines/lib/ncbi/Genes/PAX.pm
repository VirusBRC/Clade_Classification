package ncbi::Genes::PAX;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use Pod::Usage;

use ncbi::ErrMsgs;

use util::Constants;

use base 'ncbi::Genes';

use fields qw(
  motifs
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::GENES_CAT; }

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ( $that, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  my ncbi::Genes::PAX $this =
    $that->SUPER::new( $error_mgr, $tools, $utils, $ncbi_utils );

  $this->{motifs} =
    $this->{genetic_code}->getPaxMotifs( $this->{specifics}->{motif} );

  return $this;
}

sub getGeneTypeValues {
  my ncbi::Genes::PAX $this = shift;
  my $gene_values = [
    join( util::Constants::EMPTY_STR,
      $this->getGeneSymbol, $this->{specifics}->{short_len}
    ),
    join( util::Constants::EMPTY_STR,
      $this->getGeneSymbol, $this->{specifics}->{long_len}
    ),
    join( util::Constants::EMPTY_STR, $this->getGeneSymbol, $this->OTHER_NAME ),
  ];
  return $gene_values;
}

sub getNativeGeneName {
  my ncbi::Genes::PAX $this = shift;
  ##############################
  ### Re-implmentable Method ###
  ##############################
  return $this->{specifics}->{native};
}

sub determineGeneProductName {
  my ncbi::Genes::PAX $this = shift;
  my ($saminoacids) = @_;

  my $gene = $this->UNKNOWN_GENE_NAME;
  if ( !util::Constants::EMPTY_LINE($saminoacids) ) {
    $gene = $this->getGeneSymbol;
    if ( length($saminoacids) == $this->{specifics}->{short_len}
      || length($saminoacids) == $this->{specifics}->{long_len} )
    {
      $gene .= length($saminoacids);
    }
    else {
      $gene .= $this->OTHER_NAME;
    }
  }
  $this->{error_mgr}->printMsg( "gene (" . length($saminoacids) . ") = $gene" );

  return $gene;
}

sub findRefMotif {
  my ncbi::Genes::PAX $this = shift;
  my ( $gb_gi, $gb_accession, $gap_info ) = @_;

  my $ncbi_utils = $this->{ncbi_utils};

  my $mstruct = undef;
  my $seq     = $gap_info->{ungapped_seq};
  my $motif_prefix =
      $this->{specifics}->{ref_motif_prefix}
    . $this->{specifics}->{ref_frameshift};
  my $motif    = $motif_prefix . $this->{specifics}->{ref_motif_suffix};
  my $patterns = [$motif];
  if ( !$this->{utils}->foundPattern( $seq, $patterns ) ) {
    $this->{error_mgr}
      ->registerError( ERR_CAT, 5, [$gb_accession], util::Constants::TRUE );
    return $mstruct;
  }
  $seq =~ /$motif/;
  my $prefix = $`;
  my $suffix = $';    #';

  my $ungapped_ref_start = length($prefix) + 3;
  my $gapped_ref_start   = $gap_info->{non2gapped}->{$ungapped_ref_start};
  my $ungapped_ref_end   = length($prefix) + length($motif_prefix) - 1;
  my $gapped_ref_end     = $gap_info->{non2gapped}->{$ungapped_ref_end};

  $this->{error_mgr}->printHeader( "_findRefMotif\n"
      . "ungapped_ref_start = $ungapped_ref_start\n"
      . "gapped_ref_start   = $gapped_ref_start\n"
      . "ungapped_ref_end   = $ungapped_ref_end\n"
      . "gapped_ref_end     = $gapped_ref_end\n" );

  my $motif_str = substr( $motif_prefix, 0, length($motif_prefix) - 1 );
  my $prefix_str .= $prefix . $motif_str;
  my ( $pstart, $pend, $paminoacids ) =
    $this->_getPrefixProtein( $gap_info, $prefix_str, undef );

  my ( $sstart, $send, $saminoacids ) =
    $this->_getSuffixProtein( $this->{specifics}->{ref_motif_suffix} . $suffix,
    $pend + 2 );

  my ( $interval, $protein ) =
    $this->_determineIntProt( $pstart, $pend, $paminoacids, $sstart, $send,
    $saminoacids );

  my $gene = $this->determineGeneProductName($saminoacids);

  my ( $protein_gi, $protein_id, $cds_start, $cds_end ) =
    $this->_determineProtGiId( $gb_gi, $pstart, $send );

  $mstruct = {
    cds_end      => $cds_end,
    cds_start    => $cds_start,
    gene         => $gene,
    interval     => $interval,
    is_reverse   => 'N',
    motif        => $this->{specifics}->{motif},
    paminoacids  => $paminoacids,
    pend         => $pend,
    prefix       => $prefix,
    protein      => $protein,
    protein_gi   => $protein_gi,
    protein_id   => $protein_id,
    pstart       => $pstart,
    saminoacids  => $saminoacids,
    send         => $send,
    seq          => $seq,
    sstart       => $sstart,
    suffix       => $suffix,
    variant      => $this->{specifics}->{ref_frameshift},
    gb_gi        => $gb_gi,
    gb_accession => $gb_accession,

    ungapped_ref_start => $ungapped_ref_start,
    gapped_ref_start   => $gapped_ref_start,
    ungapped_ref_end   => $ungapped_ref_end,
    gapped_ref_end     => $gapped_ref_end,
  };
  $mstruct->{prefix_len} = $mstruct->{pend} - $mstruct->{pstart} + 1;

  return $mstruct;
}

sub findMotif {
  my ncbi::Genes::PAX $this = shift;
  my ( $gap_info, $gb_gi, $ref_data ) = @_;

  my $mstruct = undef;
  my $seq     = $gap_info->{ungapped_seq};
  my $ungapped_seq_motif_start =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_start} };
  my $ungapped_seq_motif_end =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_end} };
  ###
  ### Short sequence cannot find frameshift, return immediately
  ###
  return $mstruct
    if ( !defined($ungapped_seq_motif_start)
    || !defined($ungapped_seq_motif_end) );

  my $seqMotif = join( util::Constants::EMPTY_STR,
    @{ $gap_info->{useq} }
      [ $ungapped_seq_motif_start .. $ungapped_seq_motif_end ] );

  my $prefixIndex = $ungapped_seq_motif_start - 1;
  my $prefix      = join( util::Constants::EMPTY_STR,
    @{ $gap_info->{useq} }[ 0 .. $prefixIndex ] );
  my $suffixIndex = $ungapped_seq_motif_end + 1;
  my $suffix      = join( util::Constants::EMPTY_STR,
    @{ $gap_info->{useq} }[ $suffixIndex .. $#{ $gap_info->{useq} } ] );

  $this->{error_mgr}->printHeader( "findMotif\n"
      . "ungapped_seq_motif_start = $ungapped_seq_motif_start\n"
      . "ungapped_seq_motif_end   = $ungapped_seq_motif_end\n"
      . "seqMotif                 = $seqMotif\n"
      . "prefixIndex              = $prefixIndex\n"
      . "suffixIndex              = $suffixIndex\n" );

  $this->{error_mgr}->printMsg(
    "seq    = $seq\n" . "prefix = $prefix\n" . "suffix = $suffix\n" );

  foreach my $variant ( keys %{ $this->{motifs} } ) {
    my $motif = $this->{motifs}->{$variant};
    next if ( $seqMotif ne $motif );

    my $motif_str = substr( $motif, 0, length($motif) - 1 );
    my $prefix_str .= $prefix . $motif_str;
    my ( $pstart, $pend, $paminoacids ) =
      $this->_getPrefixProtein( $gap_info, $prefix_str, $ref_data );

    my ( $sstart, $send, $saminoacids ) =
      $this->_getSuffixProtein( $suffix, $pend + 2 );

    my ( $interval, $protein ) =
      $this->_determineIntProt( $pstart, $pend, $paminoacids, $sstart, $send,
      $saminoacids );

    my $gene = $this->determineGeneProductName($saminoacids);

    my ( $protein_gi, $protein_id, $cds_start, $cds_end ) =
      $this->_determineProtGiId( $gb_gi, $pstart, $send );

    $mstruct = {
      cds_end     => $cds_end,
      cds_start   => $cds_start,
      gene        => $gene,
      interval    => $interval,
      is_reverse  => 'N',
      motif       => $motif,
      paminoacids => $paminoacids,
      pend        => $pend,
      prefix      => $prefix,
      protein     => $protein,
      protein_gi  => $protein_gi,
      protein_id  => $protein_id,
      pstart      => $pstart,
      saminoacids => $saminoacids,
      send        => $send,
      seq         => $seq,
      sstart      => $sstart,
      suffix      => $suffix,
      variant     => $variant,
    };
    last;
  }
  return $mstruct;
}

sub assignMotif {
  my ncbi::Genes::PAX $this = shift;
  my ( $struct, $mstruct ) = @_;

  my $bad_frameshift   = $this->{specifics}->{bad_frameshift};
  my $geneticCode      = $this->{genetic_code};
  my $stopCodonPattern = $geneticCode->STOP_CODON;

  my $fileType = undef;
  my $seqType  = $this->_determineSeqType( $mstruct->{seq} );
  ###
  ### It is an error for the variant to be a bad_frameshift;
  ###
  if ( defined( $bad_frameshift->{ $mstruct->{variant} } ) ) {
    $this->{error_mgr}->registerError( ERR_CAT, 3,
      [ $mstruct->{variant}, $struct->{gb_accession} ],
      util::Constants::TRUE );
    $fileType = $this->ERROR_TYPE;

  }
  elsif ( !defined( $mstruct->{pstart} )
    || !defined( $mstruct->{sstart} ) )
  {
    $fileType = $seqType;
    $mstruct->{gene} = $this->UNKNOWN_GENE_NAME;
  }
  elsif ( $mstruct->{paminoacids} =~ /$stopCodonPattern/ ) {
    $fileType = $this->TRANSLATION_TYPE;
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

PAX.pm

=head1 SYNOPSIS

  use ncbi::Genes::PAX;

=head1 DESCRIPTION

The PA-X gene processor.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Genes::PAX(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
