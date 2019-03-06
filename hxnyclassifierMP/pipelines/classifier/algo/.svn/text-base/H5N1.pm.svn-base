package algo::H5N1;

use strict;
use algo::Algo;
use warnings;
use newik::newicktree;

our @ISA = qw(algo::Algo);

sub getClassification {
  my $self = shift;
  my ( $treeFile, $accession ) = @_;

  my $tree = newik::newicktree->new(
    file   => $treeFile,
    lookup => \%{ $self->{lookup} }
  );
  return $tree->getH5N1Classification($accession);
}

1;
