package newik::cnode;

use strict;
use warnings;

use newik::node;

our @ISA = qw(newik::node);

sub _init {
  my $self = shift;

  $self->{cnode} = {};
  $self->{lnode} = {};
}

sub addNode {
  my $self = shift;
  my ($node) = @_;

  if ( $node->type eq 'cnode' ) {
    $self->{cnode}->{ $node->{name} } = $node;
  }
  else {
    $self->{lnode}->{ $node->{name} } = $node;
  }
}

sub getLNode {
  my $self = shift;
  return $self->{lnode};
}

sub getCNode {
  my $self = shift;
  return $self->{cnode};
}

return 1;
