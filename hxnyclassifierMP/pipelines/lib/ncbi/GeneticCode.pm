package ncbi::GeneticCode;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use FileHandle;
use Getopt::Std;
use Pod::Usage;

use util::Constants;

use fields qw(
  error_mgr
  genetic_code
  nucleotides
  reverse_nucleotide
  tools
  undefined_codon
  undefined_nucleotide
  utils
);

################################################################################
#
#			            Static Class Constants
#
################################################################################

sub START_CODON { return 'M'; }
sub STOP_CODON  { return 'Stop'; }

sub ALANINE_AA       { return 'Alanine'; }
sub ARGININE_AA      { return 'Arginine'; }
sub ASPARAGINE_AA    { return 'Asparagine'; }
sub ASPARTATE_AA     { return 'Aspartate'; }
sub CYSTEINE_AA      { return 'Cysteine'; }
sub GLUTAMATE_AA     { return 'Glutamate'; }
sub GLUTAMINE_AA     { return 'Glutamine'; }
sub GLYCINE_AA       { return 'Glycine'; }
sub HISTIDINE_AA     { return 'Histidine'; }
sub ISOLEUCINE_AA    { return 'Isoleucine'; }
sub LEUCINE_AA       { return 'Leucine'; }
sub LYSINE_AA        { return 'Lysine'; }
sub METHIONINE_AA    { return 'Methionine'; }
sub PHENYLALANINE_AA { return 'Phenylalanine'; }
sub PROLINE_AA       { return 'Proline'; }
sub SERINE_AA        { return 'Serine'; }
sub THREONINE_AA     { return 'Threonine'; }
sub TRYPTOPHAN_AA    { return 'Tryptophan'; }
sub TYROSINE_AA      { return 'Tyrosine'; }
sub VALINE_AA        { return 'Valine'; }

sub amino2Three {
  return (
    &ALANINE_AA       => 'Ala',
    &ARGININE_AA      => 'Arg',
    &ASPARAGINE_AA    => 'Asn',
    &ASPARTATE_AA     => 'Asp',
    &CYSTEINE_AA      => 'Cys',
    &GLUTAMATE_AA     => 'Glu',
    &GLUTAMINE_AA     => 'Gln',
    &GLYCINE_AA       => 'Gly',
    &HISTIDINE_AA     => 'His',
    &ISOLEUCINE_AA    => 'Ile',
    &LEUCINE_AA       => 'Leu',
    &LYSINE_AA        => 'Lys',
    &METHIONINE_AA    => 'Met',
    &PHENYLALANINE_AA => 'Phe',
    &PROLINE_AA       => 'Pro',
    &SERINE_AA        => 'Ser',
    &THREONINE_AA     => 'Thr',
    &TRYPTOPHAN_AA    => 'Trp',
    &TYROSINE_AA      => 'Tyr',
    &VALINE_AA        => 'Val',
  );
}

sub amino2One {
  return (
    &ALANINE_AA       => 'A',
    &ARGININE_AA      => 'R',
    &ASPARAGINE_AA    => 'N',
    &ASPARTATE_AA     => 'D',
    &CYSTEINE_AA      => 'C',
    &GLUTAMATE_AA     => 'E',
    &GLUTAMINE_AA     => 'Q',
    &GLYCINE_AA       => 'G',
    &HISTIDINE_AA     => 'H',
    &ISOLEUCINE_AA    => 'I',
    &LEUCINE_AA       => 'L',
    &LYSINE_AA        => 'K',
    &METHIONINE_AA    => START_CODON,
    &PHENYLALANINE_AA => 'F',
    &PROLINE_AA       => 'P',
    &SERINE_AA        => 'S',
    &THREONINE_AA     => 'T',
    &TRYPTOPHAN_AA    => 'W',
    &TYROSINE_AA      => 'Y',
    &VALINE_AA        => 'V',
  );
}

sub aminoNames {
  return (
    PHENYLALANINE_AA, PHENYLALANINE_AA, LEUCINE_AA,    LEUCINE_AA,
    LEUCINE_AA,       LEUCINE_AA,       LEUCINE_AA,    LEUCINE_AA,
    ISOLEUCINE_AA,    ISOLEUCINE_AA,    ISOLEUCINE_AA, METHIONINE_AA,
    VALINE_AA,        VALINE_AA,        VALINE_AA,     VALINE_AA,
    SERINE_AA,        SERINE_AA,        SERINE_AA,     SERINE_AA,
    PROLINE_AA,       PROLINE_AA,       PROLINE_AA,    PROLINE_AA,
    THREONINE_AA,     THREONINE_AA,     THREONINE_AA,  THREONINE_AA,
    ALANINE_AA,       ALANINE_AA,       ALANINE_AA,    ALANINE_AA,
    TYROSINE_AA,      TYROSINE_AA,      STOP_CODON,    STOP_CODON,
    HISTIDINE_AA,     HISTIDINE_AA,     GLUTAMINE_AA,  GLUTAMINE_AA,
    ASPARAGINE_AA,    ASPARAGINE_AA,    LYSINE_AA,     LYSINE_AA,
    ASPARTATE_AA,     ASPARTATE_AA,     GLUTAMATE_AA,  GLUTAMATE_AA,
    CYSTEINE_AA,      CYSTEINE_AA,      STOP_CODON,    TRYPTOPHAN_AA,
    ARGININE_AA,      ARGININE_AA,      ARGININE_AA,   ARGININE_AA,
    SERINE_AA,        SERINE_AA,        ARGININE_AA,   ARGININE_AA,
    GLYCINE_AA,       GLYCINE_AA,       GLYCINE_AA,    GLYCINE_AA
  );
}

###
### Properties
###
sub NUCLEOTIDES { return [ 'T', 'C', 'A', 'G', ]; }
sub PAX_FRAMESHIFT_NUCLEOTIDES { return [ 'T', 'C' ]; }

sub REVERSENUCLEOTIDE {
  return {
    A => 'T',
    C => 'G',
    G => 'C',
    T => 'A',
  };
}
sub UNDEFINEDCODON      { return 'X'; }
sub UNDEFINEDNUCLEOTIDE { return 'N'; }

################################################################################
#
#				   Private Methods
#
################################################################################

sub _getCodonMapping {
  my ncbi::GeneticCode $this = shift;

  $this->{genetic_code} = {};

  my @aminoNames = aminoNames;
  my %amino2One  = amino2One;
  foreach my $na_2 ( @{ $this->{nucleotides} } ) {    ### the columns
    $this->{error_mgr}->printMsg("Column = $na_2");
    foreach my $na_1 ( @{ $this->{nucleotides} } ) {
      foreach my $na_3 ( @{ $this->{nucleotides} } ) {
        my $triple = $na_1 . $na_2 . $na_3;
        my $amino  = shift(@aminoNames);
        my $one    = $amino2One{$amino};
        if ( $amino eq STOP_CODON ) { $one = STOP_CODON; }
        $this->{error_mgr}->printMsg("($triple, $amino, $one)");
        $this->{error_mgr}->printHeader("triple = $triple\namino = $amino")
          if ( util::Constants::EMPTY_LINE($one) );
        $this->{genetic_code}->{$triple} = $one;
      }
    }
  }
  $this->{tools}->printStruct( 'genetic_code', $this->{genetic_code} );
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::GeneticCode $this = shift;
  my ( $error_mgr, $tools, $utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr}            = $error_mgr;
  $this->{nucleotides}          = NUCLEOTIDES;
  $this->{reverse_nucleotide}   = REVERSENUCLEOTIDE;
  $this->{tools}                = $tools;
  $this->{undefined_codon}      = UNDEFINEDCODON;
  $this->{undefined_nucleotide} = UNDEFINEDNUCLEOTIDE;
  $this->{utils}                = $utils;

  $this->_getCodonMapping;

  return $this;
}

sub getAminoAcid {
  my ncbi::GeneticCode $this = shift;
  my ($codon) = @_;
  return undef
    if ( util::Constants::EMPTY_LINE($codon)
    || length($codon) != 3 );
  my $aminoacid = $this->{genetic_code}->{$codon};
  if ( !defined($aminoacid) ) { $aminoacid = $this->{undefined_codon}; }

  return $aminoacid;
}

sub getMotifs {
  my ncbi::GeneticCode $this = shift;
  my ( $prefix_motif, $suffix_motif ) = @_;
  my $motifs = {};
  foreach my $serineNucleotide ( @{ $this->{nucleotides} } ) {
    foreach my $frameShiftNucleotide ( @{ $this->{nucleotides} } ) {
      my $key =
        $serineNucleotide . util::Constants::COLON . $frameShiftNucleotide;
      $motifs->{$key} =
          $prefix_motif
        . $serineNucleotide
        . $suffix_motif
        . $frameShiftNucleotide;
    }
  }
  return $motifs;
}

sub getPaxMotifs {
  my ncbi::GeneticCode $this = shift;
  my ($motif)                = @_;
  my $motifs                 = {};
  foreach my $frameShiftNucleotide ( @{ $this->{nucleotides} } ) {
    $motifs->{$frameShiftNucleotide} = $motif . $frameShiftNucleotide;
  }
  return $motifs;
}

sub reverseStrand {
  my ncbi::GeneticCode $this = shift;
  my ($seq) = @_;
  my @seq_array = split( //, $seq );

  my $rseq = util::Constants::EMPTY_STR;
  foreach my $nuc ( reverse @seq_array ) {
    my $rnuc = undef;
    if ( $this->{utils}->foundPattern( $nuc, $this->{nucleotides} ) ) {
      $rnuc = $this->{reverse_nucleotide}->{$nuc};
    }
    else {
      $rnuc = $this->{undefined_nucleotide};
    }
    $rseq .= $rnuc;
  }

  return $rseq;
}

################################################################################
1;

__END__

=head1 NAME

GeneticCode.pm

=head1 SYNOPSIS

  use ncbi::GeneticCode;

=head1 DESCRIPTION

The genetic code translator.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::GeneticCode(error_mgr, tools, utils)>

This is the constructor for the class.

=cut
