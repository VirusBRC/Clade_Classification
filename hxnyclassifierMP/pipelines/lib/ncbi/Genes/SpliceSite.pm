package ncbi::Genes::SpliceSite;
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
#				   Private Methods
#
################################################################################

sub _createMotifs {
  my ncbi::Genes::SpliceSite $this = shift;

  my $specifics = $this->{specifics};

  $this->{motifs} = {};
  if ( scalar @{ $specifics->{variants} } > 1 ) {
    foreach my $variant ( @{ $specifics->{variants} } ) {
      next if ( $variant eq $this->NONE_VARIANT_NAME );
      my $motif =
          $specifics->{donor_motif_prefix} 
        . $variant
        . $specifics->{acceptor_motif};
      $this->{motifs}->{$variant} = $motif;
    }
  }
  else {
    $this->{motifs}->{ $this->NONE_VARIANT_NAME } =
      $specifics->{donor_motif_prefix} . $specifics->{acceptor_motif};
  }
  $this->{tools}->printStruct( '$motifs', $this->{motifs} );
}

sub _assignVariant {
  my ncbi::Genes::SpliceSite $this = shift;
  my ( $donor_motif, $acceptor_motif ) = @_;

  my $motif   = $donor_motif . $acceptor_motif;
  my $variant = $this->NONE_VARIANT_NAME;
  foreach my $motif_variant ( keys %{ $this->{motifs} } ) {
    my $variant_motif = $this->{motifs}->{$motif_variant};
    next if ( $motif ne $variant_motif );
    $variant = $motif_variant;
    last;
  }
  return $variant;
}

sub _hasMotif {
  my ncbi::Genes::SpliceSite $this = shift;
  my ( $donor_motif, $acceptor_motif ) = @_;

  my $motif     = $donor_motif . $acceptor_motif;
  my $has_motif = util::Constants::FALSE;
  foreach my $motif_variant ( keys %{ $this->{motifs} } ) {
    my $variant_motif = $this->{motifs}->{$motif_variant};
    next if ( $motif ne $variant_motif );
    $has_motif = util::Constants::TRUE;
    last;
  }
  return $has_motif;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ( $that, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  my ncbi::Genes::SpliceSite $this =
    $that->SUPER::new( $error_mgr, $tools, $utils, $ncbi_utils );

  $this->_createMotifs;

  return $this;
}

sub getGeneTypeValues {
  my ncbi::Genes::SpliceSite $this = shift;
  my $gene_values = [ $this->getGeneSymbol, ];
  return $gene_values;
}

sub determineGeneProductName {
  my ncbi::Genes::SpliceSite $this = shift;
  my ($saminoacids) = @_;

  my $gene = $this->UNKNOWN_GENE_NAME;
  if ( !util::Constants::EMPTY_LINE($saminoacids) ) {
    $gene = $this->getGeneSymbol;
  }
  $this->{error_mgr}->printMsg( "gene (" . length($saminoacids) . ") = $gene" );
  return $gene;
}

sub findRefMotif {
  my ncbi::Genes::SpliceSite $this = shift;
  my ( $gb_gi, $gb_accession, $gap_info ) = @_;

  my $specifics = $this->{specifics};
  my $mstruct   = undef;
  my $seq       = $gap_info->{useq};

  my $prefix = join( util::Constants::EMPTY_STR,
    @{$seq}[
      $specifics->{m1_start} - 1 .. ( $specifics->{donor_motif_start} - 1 ) - 1
    ]
  );
  my $donor_motif_prefix = join( util::Constants::EMPTY_STR,
    @{$seq}[ $specifics->{donor_motif_start} - 1 .. $specifics->{m1_stop} - 1 ]
  );
  my $donor_motif_prefix_len =
    $specifics->{m1_stop} - $specifics->{donor_motif_start} + 1;

  my $suffix = join( util::Constants::EMPTY_STR,
    @{$seq}[ $specifics->{m2_start} - 1 .. $specifics->{m2_stop} - 1 ] );

  my $donor_motif = join( util::Constants::EMPTY_STR,
    @{$seq}[
      $specifics->{donor_motif_start} - 1 .. $specifics->{donor_motif_stop} - 1
    ]
  );
  my $acceptor_motif = util::Constants::EMPTY_STR;
  if ( !util::Constants::EMPTY_LINE( $specifics->{acceptor_motif} ) ) {
    $acceptor_motif = join( util::Constants::EMPTY_STR,
      @{$seq}[
        $specifics->{acceptor_motif_start} -
        1 .. $specifics->{acceptor_motif_stop} - 1
      ]
    );
  }
  my $variant = $this->_assignVariant( $donor_motif, $acceptor_motif );
  my $has_motif = $this->_hasMotif( $donor_motif, $acceptor_motif );
  ###
  ### These coordinates are sequence array coordinates!
  ### Note:  The specifics are nucleotide coordinates!
  ###
  my $gapped_ref_m1_start =
    $gap_info->{non2gapped}->{ $specifics->{m1_start} - 1 };
  my $gapped_ref_m1_stop =
    $gap_info->{non2gapped}->{ $specifics->{m1_stop} - 1 };
  my $gapped_ref_m2_start =
    $gap_info->{non2gapped}->{ $specifics->{m2_start} - 1 };
  my $gapped_ref_m2_stop =
    $gap_info->{non2gapped}->{ $specifics->{m2_stop} - 1 };

  my $gapped_ref_donor_motif_start =
    $gap_info->{non2gapped}->{ $specifics->{donor_motif_start} - 1 };
  my $gapped_ref_donor_motif_stop =
    $gap_info->{non2gapped}->{ $specifics->{donor_motif_stop} - 1 };

  my $gapped_ref_acceptor_motif_start =
    $gap_info->{non2gapped}->{ $specifics->{acceptor_motif_start} - 1 };
  my $gapped_ref_acceptor_motif_stop =
    $gap_info->{non2gapped}->{ $specifics->{acceptor_motif_stop} - 1 };
  ###
  ### These coordinates are nucleotide coordinates
  ###
  my ( $pstart, $pend, $paminoacids ) = $this->_getStrictPrefixProtein($prefix);
  ###
  ### pstart and pend are 1-based relative coordinates with
  ### respect to the the prefix (specifics->{m1_start})
  ###
  $pstart += $specifics->{m1_start} - 1;
  $pend   += $specifics->{m1_start} - 1;
  ###
  ### The addition of the donor_motif_prefix length (see below:  this motif prefix is
  ### added to the suffix for translation)
  ###
  $pend += $donor_motif_prefix_len;
  ###
  ### sstart and send are 1-based absolute coordinates with
  ### respect to the the specifics->{m2_start}
  ###
  my ( $sstart, $send, $saminoacids ) =
    $this->_getSuffixProtein( $donor_motif_prefix . $suffix,
    $specifics->{m2_start} - $donor_motif_prefix_len );
  ###
  ### The addition of the donor_motif_prefix length (see above:  this motif prefix is
  ### added to the suffix for translation)
  ###
  $sstart += $donor_motif_prefix_len;

  my ( $interval, $protein ) =
    $this->_determineIntProt( $pstart, $pend, $paminoacids, $sstart, $send,
    $saminoacids );

  my $gene = $this->determineGeneProductName($saminoacids);

  my ( $protein_gi, $protein_id, $cds_start, $cds_end ) =
    $this->_determineProtGiId( $gb_gi, $pstart, $send );

  return $mstruct
    if ( !defined($pstart)
    || !defined($pend)
    || !defined($sstart)
    || !defined($send) );
  $mstruct = {
    cds_end      => $cds_end,
    cds_start    => $cds_start,
    gene         => $gene,
    interval     => $interval,
    is_reverse   => 'N',
    paminoacids  => $paminoacids,
    pend         => $pend,
    prefix       => $prefix,
    protein      => $protein,
    protein_gi   => $protein_gi,
    protein_id   => $protein_id,
    pstart       => $pstart,
    saminoacids  => $saminoacids,
    send         => $send,
    seq          => join( util::Constants::EMPTY_STR, @{$seq} ),
    sstart       => $sstart,
    suffix       => $suffix,
    gb_gi        => $gb_gi,
    gb_accession => $gb_accession,
    has_motif    => $has_motif,
    variant      => $variant,

    gapped_ref_m1_start             => $gapped_ref_m1_start,
    gapped_ref_m1_stop              => $gapped_ref_m1_stop,
    gapped_ref_m2_start             => $gapped_ref_m2_start,
    gapped_ref_m2_stop              => $gapped_ref_m2_stop,
    gapped_ref_donor_motif_start    => $gapped_ref_donor_motif_start,
    gapped_ref_donor_motif_stop     => $gapped_ref_donor_motif_stop,
    gapped_ref_acceptor_motif_start => $gapped_ref_acceptor_motif_start,
    gapped_ref_acceptor_motif_stop  => $gapped_ref_acceptor_motif_stop,
  };
  $mstruct->{prefix_len} = $mstruct->{pend} - $mstruct->{pstart} + 1;

  return $mstruct;
}

sub findMotif {
  my ncbi::Genes::SpliceSite $this = shift;
  my ( $gap_info, $gb_gi, $ref_data ) = @_;

  my $specifics = $this->{specifics};
  my $mstruct   = undef;
  my $seq       = $gap_info->{ungapped_seq};
  ###
  ### These coordinates are sequence array coordinates!!
  ###
  my $ungapped_m1_start =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_m1_start} };
  my $ungapped_m1_stop =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_m1_stop} };
  my $ungapped_m2_start =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_m2_start} };
  my $ungapped_m2_stop =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_m2_stop} };
  my $ungapped_donor_motif_start =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_donor_motif_start} };
  my $ungapped_donor_motif_stop =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_donor_motif_stop} };
  my $ungapped_acceptor_motif_start =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_acceptor_motif_start} };
  my $ungapped_acceptor_motif_stop =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_acceptor_motif_stop} };
  ###
  ### Short sequence cannot find splice site, return immediately
  ###
  return $mstruct
    if ( !defined($ungapped_donor_motif_start)
    || !defined($ungapped_m2_start) );

  my $prefixStartIndex = 0;
  my $prefixStopIndex  = $ungapped_donor_motif_start - 1;
  if ( defined($ungapped_m1_start) ) {
    $prefixStartIndex = $ungapped_m1_start;
  }
  my $prefix = join( util::Constants::EMPTY_STR,
    @{ $gap_info->{useq} }[ $prefixStartIndex .. $prefixStopIndex ] );

  my $donor_motif_prefix = join( util::Constants::EMPTY_STR,
    @{ $gap_info->{useq} }[ $ungapped_donor_motif_start .. $ungapped_m1_stop ]
  );
  my $donor_motif_prefix_len =
    $ungapped_m1_stop - $ungapped_donor_motif_start + 1;

  my $donor_motif = join( util::Constants::EMPTY_STR,
    @{ $gap_info->{useq} }
      [ $ungapped_donor_motif_start .. $ungapped_donor_motif_stop ] );
  my $acceptor_motif = util::Constants::EMPTY_STR;
  if ( !util::Constants::EMPTY_LINE( $specifics->{acceptor_motif} ) ) {
    $acceptor_motif = join( util::Constants::EMPTY_STR,
      @{ $gap_info->{useq} }
        [ $ungapped_acceptor_motif_start .. $ungapped_acceptor_motif_stop ] );
  }
  my $variant = $this->_assignVariant( $donor_motif, $acceptor_motif );
  my $has_motif = $this->_hasMotif( $donor_motif, $acceptor_motif );

  my $suffixStartIndex = $ungapped_m2_start;
  my $suffixStopIndex  = $#{ $gap_info->{useq} };
  if ( defined($ungapped_m2_stop) ) {
    $suffixStopIndex = $ungapped_m2_stop;
  }
  my $suffix = join( util::Constants::EMPTY_STR,
    @{ $gap_info->{useq} }[ $suffixStartIndex .. $suffixStopIndex ] );

  $this->{error_mgr}->printHeader( "findMotif\n"
      . "prefixStartIndex       = $prefixStartIndex\n"
      . "prefixStopIndex        = $prefixStopIndex\n"
      . "SuffixStartIndex       = $suffixStartIndex\n"
      . "suffixStopIndex        = $suffixStopIndex\n"
      . "donor_motif_prefix     = $donor_motif_prefix\n"
      . "donor_motif_prefix_len = $donor_motif_prefix_len\n"
      . "donor_motif            = $donor_motif\n"
      . "acceptor_motif         = $acceptor_motif\n" );

  $this->{error_mgr}->printMsg(
    "seq    = $seq\n" . "prefix = $prefix\n" . "suffix = $suffix\n" );
  ###
  ### These coordinates are nucleotide coordinates
  ###
  my ( $pstart, $pend, $paminoacids ) = $this->_getStrictPrefixProtein($prefix);
  $this->{error_mgr}->printHeader( "findMotif\n"
      . "ungapped_m1_start = $ungapped_m1_start\n"
      . "pstart            = $pstart\n"
      . "pend              = $pend\n" );
  ###
  ### pstart and pend are 1-based relative coordinates with
  ### respect to the prefix which has the 0-based absolute
  ### coordinate ungapped_m1_start
  ###
  if ( defined($pstart) && defined($ungapped_m1_start) ) {
    $pstart += $ungapped_m1_start;
    $pend   += $ungapped_m1_start;
    $pend   += $donor_motif_prefix_len;
  }
  $this->{error_mgr}
    ->printHeader( "findMotif\n" . "pstart = $pstart\n" . "pend   = $pend\n" );
  ###
  ### The sstart and send are 1-based absolute coordinates with
  ### respect to the 1-based absolute coordinate
  ### ( ungapped_m2_start + 1 )
  ###
  my ( $sstart, $send, $saminoacids ) =
    $this->_getSuffixProtein( $donor_motif_prefix . $suffix,
    $ungapped_m2_start - ($donor_motif_prefix_len) + 1 );
  $this->{error_mgr}
    ->printHeader( "findMotif\n" . "sstart = $sstart\n" . "send   = $send\n" );
  ###
  ### The addition of the donor_motif_prefix length (see above:  this motif prefix is
  ### added to the suffix for translation)
  ###
  if ( defined($sstart) ) {
    $sstart += $donor_motif_prefix_len;
  }
  $this->{error_mgr}
    ->printHeader( "findMotif\n" . "sstart = $sstart\n" . "send   = $send\n" );

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
    has_motif   => $has_motif,
    variant     => $variant,

  };
  return $mstruct;
}

sub assignMotif {
  my ncbi::Genes::SpliceSite $this = shift;
  my ( $struct, $mstruct ) = @_;

  my $specifics    = $this->{specifics};
  my $bad_variants = $specifics->{bad_variants};

  my $geneticCode      = $this->{genetic_code};
  my $stopCodonPattern = $geneticCode->STOP_CODON;

  my $fileType = undef;
  my $seqType  = $this->_determineSeqType( $mstruct->{seq} );

  if ( !$mstruct->{has_motif} ) {
    if ( !defined( $mstruct->{sstart} ) ) {
      $fileType = $seqType;
      $mstruct->{gene} = $this->UNKNOWN_GENE_NAME;
    }
    else {
      $fileType = $this->NATIVE_TYPE;
    }
  }
  elsif ( defined( $bad_variants->{ $mstruct->{variant} } ) ) {
    $this->{error_mgr}->registerError( ERR_CAT, 6,
      [ $mstruct->{variant}, $struct->{gb_accession} ],
      util::Constants::TRUE );
    $fileType = $this->ERROR_TYPE;
  }
  elsif ( !defined( $mstruct->{pstart} ) || !defined( $mstruct->{sstart} ) ) {
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

SpliceSite.pm

=head1 SYNOPSIS

  use ncbi::Genes::SpliceSite;

=head1 DESCRIPTION

The SpliceSite gene processor.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Genes::SpliceSite(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
